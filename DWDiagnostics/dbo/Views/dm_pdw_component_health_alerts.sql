CREATE VIEW [dbo].[dm_pdw_component_health_alerts] AS
SELECT 	
		  [CustomContext.Node.Id] as [pdw_node_id],
          [CustomContext.ParentId] as [component_id],
          [CustomContext.ComponentInstanceId] as [component_instance_id],
          [CustomContext.AlertId] as [alert_id],
          [CustomContext.InstanceId] as [alert_instance_id],
          [CustomContext.CurrentValue]  as [current_value],
          [CustomContext.PreviousValue]  as [previous_value],
          [DateTimePublished] as [create_time]
FROM [dbo].[pdw_component_alerts_data] (NOLOCK)
WHERE [Builtin_HasData] = 1       
