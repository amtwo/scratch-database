CREATE TABLE dbo.ObjectExpiration 
(
	ObjectId   int,
	ObjectName sysname,
	CreatedAt  datetime2(0) NOT NULL
		CONSTRAINT DF_ObjectExpiration_CreatedAt DEFAULT (SYSUTCDATETIME()),
	KeepUntil  datetime2(0)
		CONSTRAINT DF_ObjectExpiration_KeepUntil DEFAULT (DATEADD(DAY,90,SYSUTCDATETIME())),
	DeletedAt  datetime2(0),
	CONSTRAINT PK_Keeplist PRIMARY KEY CLUSTERED (ObjectId) WITH (DATA_COMPRESSION = PAGE),
	INDEX IX_ObjectExpiration_KeepUntil NONCLUSTERED (KeepUntil) WHERE DeletedAt IS NULL WITH (DATA_COMPRESSION = PAGE),
    INDEX IX_ObjectExpiration_DeletedAt NONCLUSTERED (DeletedAt) WITH (DATA_COMPRESSION = PAGE)
);
GO
