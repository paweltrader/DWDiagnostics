CREATE TABLE [dbo].[pdw_health_components_data] (
    [CustomContext.ComponentId]                  INT             NOT NULL,
    [CustomContext.ParentId]                     INT             NOT NULL,
    [CustomContext.ComponentName]                NVARCHAR (255)  NOT NULL,
    [CustomContext.ComponentType]                NVARCHAR (255)  NOT NULL,
    [CustomContext.Description]                  NVARCHAR (4000) NULL,
    [CustomContext.AlertType]                    NVARCHAR (32)   NOT NULL,
    [CustomContext.AlertState]                   NVARCHAR (32)   NOT NULL,
    [CustomContext.AlertSeverity]                NVARCHAR (32)   NOT NULL,
    [CustomContext.AlertThresholdCondition]      NVARCHAR (255)  NULL,
    [CustomContext.AlertThresholdConditionValue] BIT             NULL,
    [CustomContext.Status]                       NVARCHAR (255)  NULL,
    [CustomContext.ComponentWmiNamespace]        NVARCHAR (255)  NULL,
    [CustomContext.ComponentWmiClass]            NVARCHAR (MAX)  NULL,
    [CustomContext.LogicalName]                  NVARCHAR (255)  NOT NULL,
    [CustomContext.PhysicalName]                 NVARCHAR (255)  NOT NULL,
    [CustomContext.IsKeyProperty]                BIT             NOT NULL,
    [Builtin_DateTimeEntryCreated]               DATETIME2 (7)   NOT NULL,
    [Builtin_RowId]                              NVARCHAR (255)  NOT NULL,
    [Builtin_HasData]                            BIT             NOT NULL,
    CONSTRAINT [PK_pdw_health_components_data] PRIMARY KEY CLUSTERED ([Builtin_RowId] ASC) WITH (ALLOW_PAGE_LOCKS = OFF)
);

