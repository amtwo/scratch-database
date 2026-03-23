INSERT INTO dbo.ObjectExpiration (ObjectId, ObjectName)
SELECT o.object_id, o.name
FROM sys.objects o
WHERE name IN ('ObjectExpiration','PurgeOldObjects')
AND NOT EXISTS (SELECT 1 FROM dbo.ObjectExpiration oe WHERE oe.ObjectName = o.name);

UPDATE oe
SET KeepUntil = '21001231'
FROM dbo.ObjectExpiration AS oe
WHERE ObjectName IN ('ObjectExpiration','PurgeOldObjects');
