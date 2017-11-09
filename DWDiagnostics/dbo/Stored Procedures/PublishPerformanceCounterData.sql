
CREATE PROCEDURE [dbo].[PublishPerformanceCounterData] 
    @PerformanceCounterDataBatch AS PerformanceCounterData READONLY
AS
BEGIN

DECLARE @SummaryOfChanges TABLE(Change NVARCHAR(255));

MERGE [pdw_performance_data] AS target
USING(SELECT DISTINCT [MachineName],
        [CustomContext.Node.Id],
        [CustomContext.CounterValue],
        [CustomContext.CounterName],
        [CustomContext.CounterCategory],
        [CustomContext.InstanceName],
        [DateTimePublished],
        [Builtin_DateTimeEntryCreated],
        [Builtin_RowId],
        [Builtin_HasData]
        FROM @PerformanceCounterDataBatch) AS source([MachineName],
            [CustomContext.Node.Id],
            [CustomContext.CounterValue],
            [CustomContext.CounterName],
            [CustomContext.CounterCategory],
            [CustomContext.InstanceName],
            [DateTimePublished],
            [Builtin_DateTimeEntryCreated],
            [Builtin_RowId],
            [Builtin_HasData])
ON(target.[Builtin_RowId] = source.[Builtin_RowId] collate Latin1_General_100_CI_AS_KS_WS)         
    WHEN MATCHED THEN 
        UPDATE SET 
            [CustomContext.CounterValue] = source.[CustomContext.CounterValue],
            [DateTimePublished] = source.[DateTimePublished]
    WHEN NOT MATCHED THEN    
        INSERT ([MachineName],
            [CustomContext.Node.Id],
            [CustomContext.CounterValue],
            [CustomContext.CounterName],
            [CustomContext.CounterCategory],
            [CustomContext.InstanceName],
            [DateTimePublished],
            [Builtin_DateTimeEntryCreated],
            [Builtin_RowId],
            [Builtin_HasData])
        VALUES (source.[MachineName],
            source.[CustomContext.Node.Id],
            source.[CustomContext.CounterValue],
            source.[CustomContext.CounterName],
            source.[CustomContext.CounterCategory],
            source.[CustomContext.InstanceName],
            source.[DateTimePublished],
            source.[Builtin_DateTimeEntryCreated],
            source.[Builtin_RowId],
            source.[Builtin_HasData])
        OUTPUT $action INTO @SummaryOfChanges;

    SELECT * FROM @SummaryOfChanges;

END
