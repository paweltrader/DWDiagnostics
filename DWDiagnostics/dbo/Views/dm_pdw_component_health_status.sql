CREATE VIEW [dbo].[dm_pdw_component_health_status] AS
				SELECT 
					  [CustomContext.Node.Id] as [pdw_node_id],
					  [CustomContext.ComponentId] as [component_id],
					  [CustomContext.ParentId] as [group_id],
					  [CustomContext.InstanceId] as [component_instance_id],
					  [CustomContext.DetailId] as [property_id],
					  CAST([CustomContext.DetailValue] AS NVARCHAR(32)) as [property_value],
					  [DateTimePublished] as [update_time]
				FROM [dbo].[pdw_component_health_data] (NOLOCK)
				WHERE [Builtin_HasData] = 1