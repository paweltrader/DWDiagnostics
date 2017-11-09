CREATE VIEW [dbo].[pdw_health_component_status_mappings] AS
SELECT [CustomContext.ComponentId] as [property_id]
	, [CustomContext.ParentId] as [component_id]
	, [CustomContext.PhysicalName] as [physical_name]
	, [CustomContext.Status] as [logical_name]
FROM [dbo].[pdw_health_components_data] 
WHERE [CustomContext.ComponentType] = 'DeviceStatusMappingElement'
