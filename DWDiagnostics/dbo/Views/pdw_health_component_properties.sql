CREATE VIEW [dbo].[pdw_health_component_properties] AS
SELECT [CustomContext.ComponentId] as [property_id]
	, [CustomContext.ParentId] as [component_id]
	, [CustomContext.ComponentName] as [property_name]
	, [CustomContext.PhysicalName] as [physical_name]
	, [CustomContext.IsKeyProperty] as [is_key]
FROM [dbo].[pdw_health_components_data] 
WHERE [CustomContext.ComponentType] = 'DeviceDataElement'
