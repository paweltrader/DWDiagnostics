CREATE TABLE [dbo].[pdw_component_alerts_data] (
    [CustomContext.Node.Id]             INT              NOT NULL,
    [CustomContext.InstanceId]          NVARCHAR (255)   NOT NULL,
    [CustomContext.ComponentInstanceId] NVARCHAR (255)   NOT NULL,
    [CustomContext.AlertId]             INT              NOT NULL,
    [CustomContext.ParentId]            INT              NOT NULL,
    [CustomContext.CurrentValue]        NVARCHAR (255)   NULL,
    [CustomContext.PreviousValue]       NVARCHAR (255)   NULL,
    [DateTimePublished]                 DATETIME2 (7)    NOT NULL,
    [Builtin_DateTimeEntryCreated]      DATETIME2 (7)    NOT NULL,
    [Builtin_RowId]                     UNIQUEIDENTIFIER NOT NULL,
    [Builtin_HasData]                   BIT              NOT NULL,
    CONSTRAINT [PK_pdw_component_alerts_data] PRIMARY KEY CLUSTERED ([Builtin_RowId] ASC) WITH (ALLOW_PAGE_LOCKS = OFF)
);


GO
CREATE NONCLUSTERED INDEX [IX_pdw_component_alerts_data]
    ON [dbo].[pdw_component_alerts_data]([Builtin_DateTimeEntryCreated] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);

