CREATE TYPE [dbo].[HealthStatusData] AS TABLE (
    [CustomContext.SourceName]     NVARCHAR (255) NOT NULL,
    [CustomContext.CurrentNode.Id] INT            NOT NULL,
    [CustomContext.Node.Id]        INT            NOT NULL,
    [CustomContext.ComponentId]    INT            NOT NULL,
    [CustomContext.ParentId]       INT            NOT NULL,
    [CustomContext.InstanceId]     NVARCHAR (255) NOT NULL,
    [CustomContext.DetailId]       INT            NOT NULL,
    [CustomContext.DetailValue]    NVARCHAR (255) NULL,
    [DateTimePublished]            DATETIME2 (7)  NOT NULL,
    [Builtin_DateTimeEntryCreated] DATETIME2 (7)  NOT NULL,
    [Builtin_RowId]                NVARCHAR (255) NOT NULL,
    [Builtin_HasData]              BIT            NOT NULL,
    [CustomContext.ClusterId]      NVARCHAR (255) NOT NULL);

