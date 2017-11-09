CREATE TYPE [dbo].[PerformanceCounterData] AS TABLE (
    [MachineName]                   NVARCHAR (255) NOT NULL,
    [CustomContext.Node.Id]         INT            NOT NULL,
    [CustomContext.CounterValue]    FLOAT (53)     NOT NULL,
    [CustomContext.CounterName]     NVARCHAR (255) NOT NULL,
    [CustomContext.CounterCategory] NVARCHAR (255) NOT NULL,
    [CustomContext.InstanceName]    NVARCHAR (255) NULL,
    [DateTimePublished]             DATETIME2 (7)  NOT NULL,
    [Builtin_DateTimeEntryCreated]  DATETIME2 (7)  NOT NULL,
    [Builtin_RowId]                 NVARCHAR (255) NOT NULL,
    [Builtin_HasData]               BIT            NOT NULL);

