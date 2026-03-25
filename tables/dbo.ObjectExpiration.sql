CREATE TABLE dbo.ObjectExpiration 
(
	ObjectId    int,
	ObjectName  sysname,
	ObjectType  char(2) COLLATE Latin1_General_CI_AS_KS_WS,
	CreatedAt   datetime2(0) NOT NULL
		CONSTRAINT DF_ObjectExpiration_CreatedAt DEFAULT (SYSUTCDATETIME()),
	CreatedBy	nvarchar(128),
	KeepUntil   datetime2(0)
		CONSTRAINT DF_ObjectExpiration_KeepUntil DEFAULT (DATEADD(DAY,90,SYSUTCDATETIME())),
	DroppedAt   datetime2(0),
	CONSTRAINT PK_Keeplist PRIMARY KEY CLUSTERED (ObjectId) WITH (DATA_COMPRESSION = PAGE),
	INDEX IX_ObjectExpiration_KeepUntil NONCLUSTERED (KeepUntil) WHERE DroppedAt IS NULL WITH (DATA_COMPRESSION = PAGE),
    INDEX IX_ObjectExpiration_DroppedAt NONCLUSTERED (DroppedAt) WITH (DATA_COMPRESSION = PAGE)
);
GO
