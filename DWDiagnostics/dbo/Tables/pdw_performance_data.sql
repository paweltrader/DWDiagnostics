CREATE TABLE [dbo].[pdw_performance_data] (
    [MachineName]                   NVARCHAR (255) NOT NULL,
    [CustomContext.Node.Id]         INT            NOT NULL,
    [CustomContext.CounterValue]    FLOAT (53)     NOT NULL,
    [CustomContext.CounterName]     NVARCHAR (255) NOT NULL,
    [CustomContext.CounterCategory] NVARCHAR (255) NOT NULL,
    [CustomContext.InstanceName]    NVARCHAR (255) NULL,
    [DateTimePublished]             DATETIME2 (7)  NOT NULL,
    [Builtin_DateTimeEntryCreated]  DATETIME2 (7)  NOT NULL,
    [Builtin_RowId]                 NVARCHAR (255) NOT NULL,
    [Builtin_HasData]               BIT            NOT NULL,
    CONSTRAINT [PK_pdw_performance_data] PRIMARY KEY CLUSTERED ([Builtin_RowId] ASC) WITH (ALLOW_PAGE_LOCKS = OFF)
);


GO
CREATE NONCLUSTERED INDEX [IX_pdw_performance_data]
    ON [dbo].[pdw_performance_data]([Builtin_DateTimeEntryCreated] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);

