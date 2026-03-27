CREATE OR ALTER PROCEDURE dbo.Purge_OldObjects 
	@ObjectTypes	nvarchar(100) = 'U,V,P,IF,FN',
	@Debug			bit = 1
AS
SET NOCOUNT ON;

/*
First, make sure that the ObjectExpiration table is in good shape.
    * Core/built-in objects not configured correctly
    * Renamed objects
    * Anything created while the LogNewObject trigger was not enabled
*/
EXEC dbo.Cleanup_ObjectExpiration @Debug = @Debug;


/*
Now we can do our thing.
*/

DECLARE @sql NVARCHAR(MAX);

/* Lets get this CSV of object types into a tabular format we will use; */
DECLARE @CleanupTypes TABLE (ObjectType sysname COLLATE Latin1_General_CI_AS_KS_WS);
INSERT INTO @CleanupTypes (ObjectType)
SELECT value FROM STRING_SPLIT(@ObjectTypes, ',');
/* If an invalid value is used, throw an error & return; */
IF EXISTS (SELECT 1 FROM @CleanupTypes ct
            WHERE ObjectType NOT IN ('U','V','P','IF','FN'))
BEGIN
    RAISERROR('Invalid object type specified in @ObjectTypes. Valid types are U,V,P,IF,FN', 16, 1);
    RETURN;
END

CREATE TABLE #ObjectsToDrop (DropSQL nvarchar(max));

INSERT INTO #ObjectsToDrop (DropSQL)
SELECT DropSQL = N'
        DROP ' +
        CASE o.type
            WHEN 'U' THEN 'TABLE '
            WHEN 'V' THEN 'VIEW '
            WHEN 'P' THEN 'PROCEDURE '
            WHEN 'IF' THEN 'FUNCTION '
            WHEN 'FN' THEN 'FUNCTION '
            ELSE NULL -- This should never happen since we are filtering by type, but good to have just in case
        END + QUOTENAME(SCHEMA_NAME(o.schema_id)) + N'.' + QUOTENAME(o.name) + N';'
FROM dbo.ObjectExpiration oe
JOIN sys.objects o ON o.object_id = oe.ObjectId
JOIN @CleanupTypes ct ON ct.ObjectType = o.type
WHERE oe.DroppedAt IS NULL
AND oe.KeepUntil < SYSUTCDATETIME();

/* If debug is enabled, print the objects that would be dropped, but don't actually drop them. */
IF @Debug = 1
BEGIN
    SELECT 'Debug mode enabled, no objects will be dropped.' AS Msg;
    SELECT * FROM @CleanupTypes;
    SELECT * FROM #ObjectsToDrop;
END

/* If debug is not enabled, drop the objects and update the DeletedAt column; */
IF @Debug = 0
BEGIN
    DECLARE @drop_cursor CURSOR;
    SET @drop_cursor = CURSOR FOR
        SELECT DropSql FROM #ObjectsToDrop;
    OPEN @drop_cursor;
    FETCH NEXT FROM @drop_cursor INTO @sql;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sp_executesql @sql;
        FETCH NEXT FROM @drop_cursor INTO @sql;
    END

END
GO
