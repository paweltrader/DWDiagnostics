CREATE TABLE [dbo].[pdw_loader_backup_runs_data] (
    [CustomContext.Run_Id]             INT             NOT NULL,
    [CustomContext.Name]               NVARCHAR (255)  NULL,
    [CustomContext.Submit_Time]        DATETIME        NULL,
    [CustomContext.StartTime]          DATETIME        NULL,
    [CustomContext.End_Time]           DATETIME        NULL,
    [CustomContext.Total_Elapsed_Time] INT             NULL,
    [CustomContext.Operation_Type]     NVARCHAR (16)   NULL,
    [CustomContext.Mode]               NVARCHAR (16)   NULL,
    [CustomContext.Database]           NVARCHAR (255)  NULL,
    [CustomContext.Table]              NVARCHAR (255)  NULL,
    [CustomContext.Session_Id]         NVARCHAR (255)  NULL,
    [CustomContext.Request_Id]         NVARCHAR (255)  NULL,
    [CustomContext.Status]             NVARCHAR (16)   NULL,
    [CustomContext.Progress]           INT             NULL,
    [CustomContext.Command]            NVARCHAR (4000) NULL,
    [CustomContext.Rows_Processed]     BIGINT          NULL,
    [CustomContext.Rows_Rejected]      BIGINT          NULL,
    [CustomContext.Rows_Inserted]      BIGINT          NULL,
    [Builtin_DateTimeEntryCreated]     DATETIME2 (7)   NOT NULL,
    [Builtin_RowId]                    NVARCHAR (255)  NOT NULL,
    [Builtin_HasData]                  BIT             NOT NULL,
    [CustomContext.PrincipalId]        INT             NULL,
    CONSTRAINT [PK_pdw_loader_backup_runs_data] PRIMARY KEY CLUSTERED ([Builtin_RowId] ASC) WITH (ALLOW_PAGE_LOCKS = OFF)
);


GO
CREATE NONCLUSTERED INDEX [IX_pdw_loader_backup_runs_data]
    ON [dbo].[pdw_loader_backup_runs_data]([Builtin_DateTimeEntryCreated] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);

