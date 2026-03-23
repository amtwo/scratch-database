CREATE OR ALTER TRIGGER LogNewObject
ON DATABASE
FOR CREATE_TABLE, CREATE_PROCEDURE, CREATE_VIEW, CREATE_FUNCTION
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName sysname = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname');
    DECLARE @ObjectType sysname = @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'sysname');

    -- Prevent the trigger from logging its own creation or system objects if necessary
    IF @ObjectName IS NOT NULL
    BEGIN
        INSERT INTO dbo.ObjectExpiration (ObjectId, ObjectName)
        VALUES (
            OBJECT_ID(@ObjectName), 
            @ObjectName
        );
    END
END;
GO
