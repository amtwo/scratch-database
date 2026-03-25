CREATE OR ALTER TRIGGER LogDropObject
ON DATABASE
FOR DROP_TABLE, DROP_PROCEDURE, DROP_VIEW, DROP_FUNCTION
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName sysname = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname');
    --DECLARE @ObjectType char(2) = @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'sysname');

    
    /* we just dropped the object, so the objectid is gone. Need to use the name. */
    UPDATE oe
    SET DroppedAt = SYSUTCDATETIME()
    FROM dbo.ObjectExpiration AS oe
    WHERE oe.ObjectName = @ObjectName
    AND DroppedAt IS NULL;
END;
GO
