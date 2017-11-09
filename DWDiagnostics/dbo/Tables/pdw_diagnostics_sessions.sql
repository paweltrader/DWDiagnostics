CREATE TABLE [dbo].[pdw_diagnostics_sessions] (
    [session_name] NVARCHAR (255) NOT NULL,
    [definition]   NVARCHAR (MAX) NOT NULL,
    [host_address] NVARCHAR (255) NOT NULL,
    [owner_id]     NVARCHAR (255) NULL,
    [table_name]   NVARCHAR (255) NOT NULL,
    [is_enabled]   BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([session_name] ASC)
);

