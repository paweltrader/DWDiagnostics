
CREATE VIEW [dbo].[dm_pdw_os_performance_counters] AS
SELECT
      [MachineName] as [machine_name],
	  [CustomContext.Node.Id] as [pdw_node_id],
      [CustomContext.CounterName] as [counter_name],
      [CustomContext.CounterCategory] as [counter_category],
      [CustomContext.InstanceName]  as [instance_name],
      [CustomContext.CounterValue] as [counter_value],
      [DateTimePublished] as [last_update_time]
FROM [dbo].[pdw_performance_data] (NOLOCK)
WHERE [Builtin_HasData] = 1   
