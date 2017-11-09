CREATE TABLE [dbo].[pdw_loader_backup_run_details_data] (
    [CustomContext.Run_Id]             INT            NOT NULL,
    [CustomContext.Pdw_Node_Id]        INT            NOT NULL,
    [CustomContext.Status]             NVARCHAR (16)  NULL,
    [CustomContext.Start_Time]         DATETIME       NULL,
    [CustomContext.End_Time]           DATETIME       NULL,
    [CustomContext.Total_Elapsed_time] INT            NULL,
    [CustomContext.Progress]           INT            NULL,
    [Builtin_DateTimeEntryCreated]     DATETIME2 (7)  NOT NULL,
    [Builtin_RowId]                    NVARCHAR (255) NOT NULL,
    [Builtin_HasData]                  BIT            NOT NULL,
    CONSTRAINT [PK_pdw_loader_backup_run_details_data] PRIMARY KEY CLUSTERED ([Builtin_RowId] ASC) WITH (ALLOW_PAGE_LOCKS = OFF)
);


GO
CREATE NONCLUSTERED INDEX [IX_pdw_loader_backup_run_details_data]
    ON [dbo].[pdw_loader_backup_run_details_data]([Builtin_DateTimeEntryCreated] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);

