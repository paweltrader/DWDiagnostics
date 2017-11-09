CREATE VIEW [dbo].[pdw_health_component_groups] AS
SELECT [CustomContext.ComponentId] as [group_id]
	, [CustomContext.ComponentName] as [group_name]
FROM [dbo].[pdw_health_components_data] 
WHERE [CustomContext.ComponentType] = 'ComponentElement'
