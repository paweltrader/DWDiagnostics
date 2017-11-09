CREATE VIEW [dbo].[pdw_health_components] AS
SELECT [CustomContext.ComponentId] as [component_id]
	, [CustomContext.ParentId] as [group_id]
	, [CustomContext.ComponentName] as [component_name]
FROM [dbo].[pdw_health_components_data] 
WHERE [CustomContext.ComponentType] = 'DeviceElement' OR  [CustomContext.ComponentType] = 'ApplicationComponentElement'
