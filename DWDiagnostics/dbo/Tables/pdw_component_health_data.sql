CREATE TABLE [dbo].[pdw_component_health_data] (
    [CustomContext.SourceName]     NVARCHAR (128) NOT NULL,
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
    [CustomContext.ClusterId]      NVARCHAR (255) NOT NULL,
    CONSTRAINT [PK_pdw_component_health_data] PRIMARY KEY CLUSTERED ([CustomContext.SourceName] ASC, [CustomContext.CurrentNode.Id] ASC, [Builtin_RowId] ASC) WITH (ALLOW_PAGE_LOCKS = OFF)
);


GO
CREATE NONCLUSTERED INDEX [IX_pdw_component_health_data]
    ON [dbo].[pdw_component_health_data]([Builtin_DateTimeEntryCreated] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);

