CREATE OR ALTER TRIGGER LogDropObject
ON DATABASE
FOR DROP_TABLE, DROP_PROCEDURE, DROP_VIEW, DROP_FUNCTION
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName sysname = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname');
    DECLARE @ObjectType sysname = @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'sysname');

    PRINT 'Object dropped: ' + @ObjectName + ' of type ' + @ObjectType;
    PRINT OBJECT_ID(@ObjectName)

    /* we just dropped the object, so the objectid is gone. Need to use the name. */
    UPDATE oe
    SET DeletedAt = SYSUTCDATETIME()
    FROM dbo.ObjectExpiration AS oe
    WHERE oe.ObjectName = @ObjectName
    AND DeletedAt IS NULL;
END;
GO
