CREATE OR ALTER PROCEDURE dbo.Cleanup_ObjectExpiration
	@Debug			bit = 1
AS
SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX);

IF (@Debug = 1)
BEGIN
    SELECT  ValidationMessage  = N'Object has been renamed to: ' + o.name,
            oe.ObjectId,
            oe.ObjectName,
            oe.ObjectType,
            oe.CreatedAt,
            oe.CreatedBy,
            oe.KeepUntil
    FROM dbo.ObjectExpiration AS oe
    JOIN sys.objects AS o
        ON o.object_id = oe.ObjectId
    WHERE (o.name <> COALESCE(oe.ObjectName,N'💩') 
            OR o.type COLLATE DATABASE_DEFAULT <> COALESCE(oe.ObjectType,'xx')
            )
    UNION ALL   
    SELECT  ValidationMessage  = 'Core object is missing from ObjectExpiration',
            o.object_id,
            o.name,
            o.type COLLATE DATABASE_DEFAULT,
            o.create_date,
            'am2.co',
            NULL
    FROM sys.objects o
    WHERE o.name IN ('ObjectExpiration','Purge_OldObjects','Cleanup_ObjectExpiration')
    AND NOT EXISTS (SELECT 1 FROM dbo.ObjectExpiration oe
                    WHERE oe.ObjectId = o.object_id
                    )
    UNION ALL
    SELECT  ValidationMessage  = N'Core object has incorrect KeepUntil: ' + CONVERT(nvarchar(max),oe.KeepUntil,120),
            oe.ObjectId,
            oe.ObjectName,
            oe.ObjectType,
            oe.CreatedAt,
            oe.CreatedBy,
            oe.KeepUntil
    FROM dbo.ObjectExpiration AS oe
    WHERE ObjectName IN ('ObjectExpiration','Purge_OldObjects','Cleanup_ObjectExpiration')
    AND KeepUntil <> '21001231'
    UNION ALL   
    SELECT  ValidationMessage  = 'User object is missing from ObjectExpiration',
            o.object_id,
            o.name,
            o.type COLLATE DATABASE_DEFAULT,
            o.create_date,
            '??',
            NULL
    FROM sys.objects o
    WHERE o.type in ('U','V','P','IF','FN')
    AND o.name NOT IN ('ObjectExpiration','Purge_OldObjects','Cleanup_ObjectExpiration')
    AND NOT EXISTS (SELECT 1 FROM dbo.ObjectExpiration oe
                    WHERE oe.ObjectId = o.object_id
                    )
    UNION ALL
    SELECT  ValidationMessage  = N'Object is pending deletion',
            oe.ObjectId,
            oe.ObjectName,
            oe.ObjectType,
            oe.CreatedAt,
            oe.CreatedBy,
            oe.KeepUntil
    FROM dbo.ObjectExpiration AS oe
    WHERE oe.DroppedAt < DATEADD(YEAR,1, SYSUTCDATETIME());
END;

IF (@Debug = 0)
BEGIN
    /*
    First, make sure that if there have been any object renames, we capture that.
    */
    UPDATE oe 
    SET    ObjectName = o.name,
           ObjectType = o.type COLLATE DATABASE_DEFAULT
    FROM dbo.ObjectExpiration AS oe
    JOIN sys.objects AS o
        ON o.object_id = oe.ObjectId
    WHERE (o.name <> COALESCE(oe.ObjectName,N'💩') 
            OR o.type COLLATE DATABASE_DEFAULT <> COALESCE(oe.ObjectType,'xx')
            );

    /*
    Second, make sure that the project's objects are protected from itself.
    */
    INSERT INTO dbo.ObjectExpiration (ObjectId, ObjectName, ObjectType, CreatedBy, KeepUntil)
    SELECT o.object_id, o.name, o.type, 'am2.co', '21001231'
    FROM sys.objects o
    WHERE name IN ('ObjectExpiration','Purge_OldObjects','Cleanup_ObjectExpiration')
    AND NOT EXISTS (SELECT 1 FROM dbo.ObjectExpiration oe
                    WHERE oe.ObjectId = o.object_id
                    );

    UPDATE oe 
    SET    KeepUntil = '21001231'
    FROM dbo.ObjectExpiration AS oe
    WHERE ObjectName IN ('ObjectExpiration','Purge_OldObjects','Cleanup_ObjectExpiration')
    AND KeepUntil <> '21001231';


    /*
    Now, catch anything that might have snuck past the triggers.
    */
    INSERT INTO dbo.ObjectExpiration (ObjectId, ObjectName, ObjectType, CreatedBy)
    SELECT o.object_id, o.name, o.type, '??'
    FROM sys.objects o
    WHERE NOT EXISTS (SELECT 1 FROM dbo.ObjectExpiration oe
                    WHERE oe.ObjectId = o.object_id
                    );
    /*
    Last, cleanup very old records for long-since-dropped objects.
    */
    DELETE oe
    FROM dbo.ObjectExpiration oe
    WHERE oe.DroppedAt < DATEADD(YEAR,1, SYSUTCDATETIME());
END;

GO
