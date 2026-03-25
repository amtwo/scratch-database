CREATE OR ALTER TRIGGER LogNewObject
ON DATABASE
FOR CREATE_TABLE, CREATE_PROCEDURE, CREATE_VIEW, CREATE_FUNCTION
AS
BEGIN
    SET NOCOUNT ON;

    RAISERROR('Objects created in scratchdb will be automatically dropped after 90 days.', 0, 1) WITH NOWAIT;

    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName sysname = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname');
    DECLARE @ObjectType char(2) = @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'sysname');
    DECLARE @LoginName  sysname = @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'sysname');

    -- Prevent the trigger from logging its own creation or system objects if necessary
    IF @ObjectName IS NOT NULL
    BEGIN
        INSERT INTO dbo.ObjectExpiration (ObjectId, ObjectName, ObjectType, CreatedBy)
        VALUES (
            OBJECT_ID(@ObjectName), 
            @ObjectName,
            @ObjectType,
            @LoginName
        );
    END
END;
GO
