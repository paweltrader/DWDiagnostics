CREATE TABLE [dbo].[pdw_errors] (
    [MachineName]                  NVARCHAR (255)   NOT NULL,
    [CurrentNode.Id]               INT              NOT NULL,
    [CurrentNode.Type]             NVARCHAR (32)    NOT NULL,
    [FullName]                     NVARCHAR (255)   NOT NULL,
    [ThreadId]                     INT              NOT NULL,
    [ProcessId]                    INT              NOT NULL,
    [ModuleName]                   NVARCHAR (255)   NOT NULL,
    [ErrorId]                      NVARCHAR (36)    NOT NULL,
    [Session.SessionId]            NVARCHAR (32)    NULL,
    [Query.QueryId]                NVARCHAR (36)    NULL,
    [CustomContext.SPID]           INT              NULL,
    [Message]                      NVARCHAR (MAX)   NULL,
    [DateTimePublished]            DATETIME2 (7)    NOT NULL,
    [Builtin_DateTimeEntryCreated] DATETIME2 (7)    NOT NULL,
    [Builtin_RowId]                UNIQUEIDENTIFIER NOT NULL,
    [Builtin_HasData]              BIT              NOT NULL,
    CONSTRAINT [PK_pdw_errors] PRIMARY KEY CLUSTERED ([Builtin_RowId] ASC) WITH (ALLOW_PAGE_LOCKS = OFF)
);


GO
CREATE NONCLUSTERED INDEX [IX_pdw_errors]
    ON [dbo].[pdw_errors]([Builtin_DateTimeEntryCreated] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);

