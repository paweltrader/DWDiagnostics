CREATE TABLE [dbo].[pdw_loader_run_stages_data] (
    [CustomContext.Run_Id]             INT            NOT NULL,
    [CustomContext.Stage]              NVARCHAR (30)  NULL,
    [CustomContext.Request_Id]         NVARCHAR (255) NULL,
    [CustomContext.Status]             NVARCHAR (16)  NULL,
    [CustomContext.Start_Time]         DATETIME       NULL,
    [CustomContext.End_Time]           DATETIME       NULL,
    [CustomContext.Total_Elapsed_time] INT            NULL,
    [Builtin_DateTimeEntryCreated]     DATETIME2 (7)  NOT NULL,
    [Builtin_RowId]                    NVARCHAR (255) NOT NULL,
    [Builtin_HasData]                  BIT            NOT NULL,
    CONSTRAINT [PK_pdw_loader_backup_run_stages_data] PRIMARY KEY CLUSTERED ([Builtin_RowId] ASC) WITH (ALLOW_PAGE_LOCKS = OFF)
);


GO
CREATE NONCLUSTERED INDEX [IX_pdw_loader_run_stages_data]
    ON [dbo].[pdw_loader_run_stages_data]([Builtin_DateTimeEntryCreated] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);

