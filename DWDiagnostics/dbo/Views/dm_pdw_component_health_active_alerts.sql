
				CREATE VIEW [dbo].[dm_pdw_component_health_active_alerts] AS
				SELECT 
					alerts.pdw_node_id, alerts.component_id, alerts.component_instance_id, 
					alerts.alert_id, alerts.alert_instance_id, alerts.current_value, alerts.previous_value, 
					alerts.create_time
				FROM (
					SELECT 
						all_errors.pdw_node_id, all_errors.component_id, all_errors.component_instance_id, 
						all_errors.alert_id, all_errors.alert_instance_id, all_errors.current_value, 
						all_errors.previous_value, all_errors.create_time, all_errors.[alert_type]
					FROM (
						SELECT 
							DMA.pdw_node_id, DMA.component_id, DMA.component_instance_id, DMA.alert_id, 
							DMA.alert_instance_id, DMA.current_value, DMA.previous_value, DMA.create_time, 
							A.severity, A.[type] AS [alert_type], 
							RANK() OVER (PARTITION BY DMA.pdw_node_id, DMA.component_id, 
							DMA.component_instance_id, A.[type]
							ORDER BY DMA.create_time DESC) [Rank]
						FROM dbo.dm_pdw_component_health_alerts AS DMA 
						JOIN dbo.pdw_health_alerts AS A 
							ON A.alert_id = DMA.alert_id AND A.component_id = DMA.component_id
						WHERE DMA.component_id NOT IN (199080100,199080200,199080300)
						UNION
						SELECT 
							DMA.pdw_node_id, DMA.component_id, DMA.component_instance_id, DMA.alert_id, 
							DMA.alert_instance_id, DMA.current_value, DMA.previous_value, DMA.create_time, 
							A.severity, A.[type] AS [alert_type], 
							RANK() OVER (PARTITION BY DMA.component_id, 
							DMA.component_instance_id, A.[type]
							ORDER BY DMA.create_time DESC) [Rank]
						FROM dbo.dm_pdw_component_health_alerts AS DMA 
						JOIN dbo.pdw_health_alerts AS A 
						ON A.alert_id = DMA.alert_id AND A.component_id = DMA.component_id
						WHERE DMA.component_id IN (199080100,199080200,199080300)	
					) all_errors
					WHERE 
					all_errors.severity IN ('Error', 'Warning') 
					AND all_errors.[Rank] = 1
					) alerts 
				JOIN dbo.dm_pdw_component_health_status S 
					ON S.pdw_node_id = alerts.pdw_node_id 
					AND S.component_id = alerts.component_id 
					AND S.component_instance_id = alerts.component_instance_id 
				JOIN [dbo].[pdw_health_component_properties] p 
					ON S.property_id = p.property_id 
					AND S.component_id = p.component_id 
					AND p.property_name = 'Status'
				WHERE 
					DATEADD(ms, -DATEPART(ms, alerts.create_time), alerts.create_time) <= DATEADD(ms, -DATEPART(ms, S.update_time), S.update_time) 
						AND ((alerts.alert_type = 'StatusChange' AND S.property_value = alerts.current_value) 
							OR (alerts.alert_type = 'Threshold'))