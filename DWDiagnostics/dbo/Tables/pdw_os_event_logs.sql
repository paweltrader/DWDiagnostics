CREATE TABLE [dbo].[pdw_os_event_logs] (
    [MachineName]                  NVARCHAR (255)   NOT NULL,
    [CurrentNode.Id]               INT              NOT NULL,
    [CurrentNode.Type]             NVARCHAR (32)    NOT NULL,
    [CustomContext.LogName]        NVARCHAR (255)   NOT NULL,
    [CustomContext.SourceName]     NVARCHAR (255)   NOT NULL,
    [CustomContext.EntryId]        NVARCHAR (255)   NOT NULL,
    [CustomContext.EntryType]      NVARCHAR (255)   NOT NULL,
    [CustomContext.TimeGeneated]   DATETIME2 (7)    NOT NULL,
    [CustomContext.TimeWritten]    DATETIME2 (7)    NOT NULL,
    [Message]                      NVARCHAR (MAX)   NULL,
    [Builtin_DateTimeEntryCreated] DATETIME2 (7)    NOT NULL,
    [Builtin_RowId]                UNIQUEIDENTIFIER NOT NULL,
    [Builtin_HasData]              BIT              NOT NULL,
    CONSTRAINT [PK_pdw_os_event_logs] PRIMARY KEY CLUSTERED ([Builtin_RowId] ASC) WITH (ALLOW_PAGE_LOCKS = OFF)
);


GO
CREATE NONCLUSTERED INDEX [IX_pdw_os_event_logs]
    ON [dbo].[pdw_os_event_logs]([Builtin_DateTimeEntryCreated] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);

