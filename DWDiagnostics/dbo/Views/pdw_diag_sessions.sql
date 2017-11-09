
			CREATE VIEW [dbo].[pdw_diag_sessions] AS
			SELECT 
				[session_name] as [name],
				CAST([definition] AS NVARCHAR(4000)) as xml_data,
				[is_enabled] as [is_active],
				[host_address],
				-1 as [principal_id],
				CAST(NULL AS int) as [database_id]
			FROM [dbo].[pdw_diagnostics_sessions] (NOLOCK)