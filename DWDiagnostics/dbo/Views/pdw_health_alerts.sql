CREATE VIEW [dbo].[pdw_health_alerts] AS
							SELECT [CustomContext.ComponentId] as [alert_id]
								, [CustomContext.ParentId] as [component_id]
								, [CustomContext.ComponentName] as [alert_name]
								, [CustomContext.AlertState] as [state]
								, [CustomContext.AlertSeverity] as [severity]
								, [CustomContext.AlertType] as [type]
								, [CustomContext.Description] as [description]
								, [CustomContext.AlertThresholdCondition] as [condition]
								, CAST([CustomContext.Status] AS nvarchar(32))as [status]
								, [CustomContext.AlertThresholdConditionValue] as [condition_value]
							FROM [dbo].[pdw_health_components_data] 
							WHERE [CustomContext.ComponentType] = 'DeviceAlertElement'