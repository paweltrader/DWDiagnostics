						
CREATE PROCEDURE [dbo].[UpgradeDWDiagnostics]
	-- Parameters
	@StoredVer INT, -- Currently stored version in the version_history table
	@DatabaseName NVARCHAR(MAX) -- Name of the Database to modify.  It is important to keep this generic to accommodate both setup and Backup/Restore
	AS
	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;
	
		-- Constants
			
		-- Work Variables
		DECLARE @ErrorMessage NVARCHAR(MAX);
		DECLARE @Sql NVARCHAR(MAX);
		
		------------------------------------------------------------------------------------------
		-- Validate All Input Parameters test
		------------------------------------------------------------------------------------------
	
		-- Make sure the database exists.
		PRINT N'Database name is: ' + @DatabaseName;
		
		if DB_ID(@DatabaseName) IS NULL
		BEGIN
			SET @ErrorMessage = N'ERROR: Database "' + @DatabaseName + N'" does not exist.' 
			raiserror(@ErrorMessage,16,1);
			return -1;
		END
	
		-- IMPORTANT!!! Specify the changes required for execution during Madison upgrade.
		-- For every NON-rerunnable change that is added, the @CurrentScriptVer value 
		-- needs to match the version number specified in the condition below.
		-- This will guarantee that the change is only executed once.
		--
		-- For example, if making a change after version 1 is released, roll @CurrentScriptVer = 2 and 
		-- ADD another IF block, "IF (@StoredVer < 2) BEGIN ... statements ... END"
		-- On error, use raiserror to return the error back to the caller.
		IF (@StoredVer < 3)
		BEGIN
			-- Specify NON-rerunnable changes here; i.e. the changes that should be executed only once, 
			-- when this particular version of the script is executed
			-- or when a fresh install is being executed

			--****************************************************************************************
			--BEGIN     Alter DWDiagnostics  [dbo].[dm_pdw_component_health_status] view         BEGIN
			--****************************************************************************************
			--Has to be wrapped in the sp_executesql since CREATE VIEW can only be the first statement
			--in the batch.
			EXEC sp_executesql N'ALTER VIEW [dbo].[dm_pdw_component_health_status] AS
				SELECT 
					  [CustomContext.Node.Id] as [pdw_node_id],
					  [CustomContext.ComponentId] as [component_id],
					  [CustomContext.ParentId] as [group_id],
					  [CustomContext.InstanceId] as [component_instance_id],
					  [CustomContext.DetailId] as [property_id],
					  CAST([CustomContext.DetailValue] AS NVARCHAR(32)) as [property_value],
					  [DateTimePublished] as [update_time]
				FROM [dbo].[pdw_component_health_data] (NOLOCK)
				WHERE [Builtin_HasData] = 1'; 
			--****************************************************************************************
			--END      Alter DWDiagnostics  [dbo].[dm_pdw_component_health_status] view            END
			--****************************************************************************************
			
			DROP TABLE [dbo].[pdw_errors];
			
			CREATE TABLE [dbo].[pdw_errors](
				[MachineName] [nvarchar](255) NOT NULL,
				[CurrentNode.Id] [int] NOT NULL,
				[CurrentNode.Type] [nvarchar](32) NOT NULL,
				[FullName] [nvarchar](255) NOT NULL,
				[ThreadId] [int] NOT NULL,
				[ProcessId] [int] NOT NULL,
				[ModuleName] [nvarchar](255) NOT NULL,
				[ErrorId] [nvarchar](36) NOT NULL,
				[Session.SessionId] [nvarchar](32) NULL,
				[Query.QueryId] [nvarchar](32) NULL,
				[CustomContext.SPID] [int] NULL,
				[Message] [nvarchar](max) NULL,
				[DateTimePublished] [datetime2](7) NOT NULL,
				[Builtin_DateTimeEntryCreated] [datetime2](7) NOT NULL,
				[Builtin_RowId] [uniqueidentifier] NOT NULL,
				[Builtin_HasData] [bit] NOT NULL,
			 CONSTRAINT [PK_pdw_errors] PRIMARY KEY CLUSTERED 
			(
				[Builtin_RowId] ASC
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]
			) ON [PRIMARY]


			--Preallocate rows for the errors ring buffer
			INSERT INTO [dbo].[pdw_errors] 
				SELECT TOP 10000 'N', 0, 'N', 'N', 0, 0, 'N', '00000000-0000-0000-0000-000000000000', NULL, NULL, NULL, NULL, getdate(), SYSDATETIME(), newid(), 0 FROM [dbo].[pdw_population_template]

			--***** Object:  Index [IX_pdw_errors]    Script Date: 11/25/2009 11:37:20 *****
			CREATE NONCLUSTERED INDEX [IX_pdw_errors] ON [dbo].[pdw_errors] 
			(
				[Builtin_DateTimeEntryCreated] ASC
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]

		END
		
		IF (@StoredVer < 7)
		BEGIN
		
			EXEC sp_executesql N'CREATE VIEW [dbo].[dm_pdw_component_health_active_alerts] AS
				SELECT
					alerts.pdw_node_id, 
					alerts.component_id, 
					alerts.component_instance_id, 
					alerts.alert_id, 
					alerts.alert_instance_id, 
					alerts.current_value, 
					alerts.previous_value, 
					alerts.create_time
				FROM (
						SELECT
							all_errors.pdw_node_id, 
							all_errors.component_id, 
							all_errors.component_instance_id, 
							all_errors.alert_id, 
							all_errors.alert_instance_id, 
							all_errors.current_value, 
							all_errors.previous_value, 
							all_errors.create_time, 
							all_errors.[alert_type]
						FROM (
								 SELECT
									DMA.pdw_node_id, 
									DMA.component_id, 
									DMA.component_instance_id, 
									DMA.alert_id, 
									DMA.alert_instance_id, 
									DMA.current_value, 
									DMA.previous_value, 
									DMA.create_time, 
									A.severity, 
									A.[type] AS [alert_type], 
									RANK() OVER (PARTITION BY DMA.component_id, DMA.pdw_node_id
									ORDER BY DMA.create_time DESC) [Rank]
								FROM dbo.dm_pdw_component_health_alerts AS DMA 
								JOIN dbo.pdw_health_alerts AS A 
									ON A.alert_id = DMA.alert_id 
									AND A.component_id = DMA.component_id
							) all_errors
						WHERE 
							all_errors.severity IN (''Error'', ''Warning'') 
							AND all_errors.[Rank] = 1
					) alerts 
				JOIN dbo.dm_pdw_component_health_status S 
					ON S.pdw_node_id = alerts.pdw_node_id 
					AND S.component_id = alerts.component_id 
					AND S.component_instance_id = alerts.component_instance_id 
				JOIN [dbo].[pdw_health_component_properties] p 
					ON S.property_id = p.property_id 
					AND S.component_id = p.component_id 
					AND p.property_name = ''Status''
				WHERE 
					alerts.create_time <= S.update_time 
					AND ((alerts.alert_type = ''StatusChange'' AND S.property_value = alerts.current_value) 
							OR (alerts.alert_type = ''Threshold''))'
		END		
		
		--As part of the Alert Decription changes we are introducing in R2, we need to extend Description length
		IF (@StoredVer < 10)
		BEGIN
			SET @Sql = 'IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[pdw_health_components_data]''))
						DROP TABLE [dbo].[pdw_health_components_data]';
			EXECUTE(@Sql);
	
			SET @Sql = 'CREATE TABLE [dbo].[pdw_health_components_data](
							[CustomContext.ComponentId] [int] NOT NULL,
							[CustomContext.ParentId] [int] NOT NULL,
							[CustomContext.ComponentName] [nvarchar](255) NOT NULL,
							[CustomContext.ComponentType] [nvarchar](255) NOT NULL,
							[CustomContext.Description] [nvarchar](4000) NULL,
							[CustomContext.AlertType] [nvarchar](32) NOT NULL,
							[CustomContext.AlertState] [nvarchar](32) NOT NULL,
							[CustomContext.AlertSeverity] [nvarchar](32) NOT NULL,
							[CustomContext.AlertThresholdCondition] [nvarchar](255) NULL,
							[CustomContext.AlertThresholdConditionValue] [bit] NULL,
							[CustomContext.Status] [nvarchar](255) NULL,
							[CustomContext.ComponentWmiNamespace] [nvarchar](255) NULL,
							[CustomContext.ComponentWmiClass] [nvarchar](255) NULL,
							[CustomContext.LogicalName] [nvarchar](255) NOT NULL,
							[CustomContext.PhysicalName] [nvarchar](255) NOT NULL,
							[CustomContext.IsKeyProperty] [bit] NOT NULL,
							[Builtin_DateTimeEntryCreated] [datetime2](7) NOT NULL,
							[Builtin_RowId] [nvarchar](255) NOT NULL,
							[Builtin_HasData] [bit] NOT NULL,
						 CONSTRAINT [PK_pdw_health_components_data] PRIMARY KEY CLUSTERED 
						(
							[Builtin_RowId] ASC
						)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]
						) ON [PRIMARY]';
			EXECUTE(@Sql);
			
			SET @Sql = 'IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[pdw_health_alerts]'') AND type in (N''V''))
						DROP VIEW [dbo].[pdw_health_alerts]';
			EXECUTE(@Sql);
	
			SET @Sql = 'CREATE VIEW [dbo].[pdw_health_alerts] AS
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
							WHERE [CustomContext.ComponentType] = ''DeviceAlertElement''';
			EXECUTE(@Sql);
			
		END
		
		IF (@StoredVer < 13)
		BEGIN
		
			DROP TABLE [dbo].[pdw_component_health_data];
		
			CREATE TABLE [dbo].[pdw_component_health_data](
				[CustomContext.SourceName] [nvarchar](128) NOT NULL,
				[CustomContext.CurrentNode.Id] [int] NOT NULL,
				[CustomContext.Node.Id] [int] NOT NULL,
				[CustomContext.ComponentId] [int] NOT NULL,
				[CustomContext.ParentId] [int] NOT NULL,
				[CustomContext.InstanceId] [nvarchar](255) NOT NULL,
				[CustomContext.DetailId] [int] NOT NULL,
				[CustomContext.DetailValue] [nvarchar](255) NULL,
				[DateTimePublished] [datetime2](7) NOT NULL,
				[Builtin_DateTimeEntryCreated] [datetime2](7) NOT NULL,
				[Builtin_RowId] [nvarchar](255) NOT NULL,
				[Builtin_HasData] [bit] NOT NULL,
			 CONSTRAINT [PK_pdw_component_health_data] PRIMARY KEY CLUSTERED 
			(
				[CustomContext.SourceName]  ASC,
				[CustomContext.CurrentNode.Id] ASC,
				[Builtin_RowId] ASC
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]
			) ON [PRIMARY]

			CREATE NONCLUSTERED INDEX [IX_pdw_component_health_data] ON [dbo].[pdw_component_health_data] 
			(
				[Builtin_DateTimeEntryCreated] ASC
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]

		
			EXEC sp_executesql N'ALTER VIEW [dbo].[dm_pdw_component_health_active_alerts] AS
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
							 ) all_errors
					  WHERE     
							 all_errors.severity IN (''Error'', ''Warning'') 
							 AND all_errors.[Rank] = 1
					  ) alerts 
				JOIN dbo.dm_pdw_component_health_status S 
					  ON S.pdw_node_id = alerts.pdw_node_id 
							 AND S.component_id = alerts.component_id 
							 AND S.component_instance_id = alerts.component_instance_id 
				JOIN [dbo].[pdw_health_component_properties] p 
					  ON S.property_id = p.property_id 
							 AND S.component_id = p.component_id 
							 AND p.property_name = ''Status''
				WHERE     
					  alerts.create_time <= S.update_time 
					  AND ((alerts.alert_type = ''StatusChange'' AND S.property_value = alerts.current_value) 
							 OR (alerts.alert_type = ''Threshold''))'
		END
		
		IF (@StoredVer < 14)
		BEGIN
			DELETE FROM [dbo].[pdw_health_components_data]			
		END
		

		IF (@StoredVer < 17)
		BEGIN
			--Change QueryId from nvarchar(32) to to nvarchar(36) because loader uses a GUID for this value	
			IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pdw_errors]') AND type in (N'U'))
				DROP TABLE [dbo].[pdw_errors];
			
			CREATE TABLE [dbo].[pdw_errors](
				[MachineName] [nvarchar](255) NOT NULL,
				[CurrentNode.Id] [int] NOT NULL,
				[CurrentNode.Type] [nvarchar](32) NOT NULL,
				[FullName] [nvarchar](255) NOT NULL,
				[ThreadId] [int] NOT NULL,
				[ProcessId] [int] NOT NULL,
				[ModuleName] [nvarchar](255) NOT NULL,
				[ErrorId] [nvarchar](36) NOT NULL,
				[Session.SessionId] [nvarchar](32) NULL,
				[Query.QueryId] [nvarchar](36) NULL,
				[CustomContext.SPID] [int] NULL,
				[Message] [nvarchar](max) NULL,
				[DateTimePublished] [datetime2](7) NOT NULL,
				[Builtin_DateTimeEntryCreated] [datetime2](7) NOT NULL,
				[Builtin_RowId] [uniqueidentifier] NOT NULL,
				[Builtin_HasData] [bit] NOT NULL,
			 CONSTRAINT [PK_pdw_errors] PRIMARY KEY CLUSTERED 
			(
				[Builtin_RowId] ASC
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]
			) ON [PRIMARY]


			--Preallocate rows for the errors ring buffer
			INSERT INTO [dbo].[pdw_errors] 
				SELECT TOP 10000 'N', 0, 'N', 'N', 0, 0, 'N', '00000000-0000-0000-0000-000000000000', NULL, NULL, NULL, NULL, getdate(), SYSDATETIME(), newid(), 0 FROM [dbo].[pdw_population_template]

			--***** Object:  Index [IX_pdw_errors]    Script Date: 11/25/2009 11:37:20 *****
			CREATE NONCLUSTERED INDEX [IX_pdw_errors] ON [dbo].[pdw_errors] 
			(
				[Builtin_DateTimeEntryCreated] ASC
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]

		END
		
		IF (@StoredVer < 22)
		BEGIN
			SET @Sql = 'IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[pdw_health_components_data]''))
						DROP TABLE [dbo].[pdw_health_components_data]';
			EXECUTE(@Sql);
	
			SET @Sql = 'CREATE TABLE [dbo].[pdw_health_components_data](
							[CustomContext.ComponentId] [int] NOT NULL,
							[CustomContext.ParentId] [int] NOT NULL,
							[CustomContext.ComponentName] [nvarchar](255) NOT NULL,
							[CustomContext.ComponentType] [nvarchar](255) NOT NULL,
							[CustomContext.Description] [nvarchar](4000) NULL,
							[CustomContext.AlertType] [nvarchar](32) NOT NULL,
							[CustomContext.AlertState] [nvarchar](32) NOT NULL,
							[CustomContext.AlertSeverity] [nvarchar](32) NOT NULL,
							[CustomContext.AlertThresholdCondition] [nvarchar](255) NULL,
							[CustomContext.AlertThresholdConditionValue] [bit] NULL,
							[CustomContext.Status] [nvarchar](255) NULL,
							[CustomContext.ComponentWmiNamespace] [nvarchar](255) NULL,
							[CustomContext.ComponentWmiClass] [nvarchar](MAX) NULL,
							[CustomContext.LogicalName] [nvarchar](255) NOT NULL,
							[CustomContext.PhysicalName] [nvarchar](255) NOT NULL,
							[CustomContext.IsKeyProperty] [bit] NOT NULL,
							[Builtin_DateTimeEntryCreated] [datetime2](7) NOT NULL,
							[Builtin_RowId] [nvarchar](255) NOT NULL,
							[Builtin_HasData] [bit] NOT NULL,
						 CONSTRAINT [PK_pdw_health_components_data] PRIMARY KEY CLUSTERED 
						(
							[Builtin_RowId] ASC
						)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]
						) ON [PRIMARY]';
			EXECUTE(@Sql);
			
		END		
		
		IF (@StoredVer < 26)
		BEGIN
			EXEC sp_executesql N'ALTER VIEW [dbo].[dm_pdw_component_health_active_alerts] AS
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
							all_errors.severity IN (''Error'', ''Warning'') 
							AND all_errors.[Rank] = 1
							) alerts 
						JOIN dbo.dm_pdw_component_health_status S 
							ON S.pdw_node_id = alerts.pdw_node_id 
							AND S.component_id = alerts.component_id 
							AND S.component_instance_id = alerts.component_instance_id 
						JOIN [dbo].[pdw_health_component_properties] p 
							ON S.property_id = p.property_id 
							AND S.component_id = p.component_id 
							AND p.property_name = ''Status''
						WHERE 
							alerts.create_time <= S.update_time 
							  AND ((alerts.alert_type = ''StatusChange'' AND S.property_value = alerts.current_value) 
									 OR (alerts.alert_type = ''Threshold''))'
		END
		
		--Adding new column to be able to distinguish monitoring sources by 
		--their owning cluster and a new table that will hold information about
		--source/cluster associations that should be synchornized when updating monitoring data.
		IF (@StoredVer < 31)
		BEGIN
	
			SET @Sql = 'DELETE FROM [dbo].[pdw_component_health_data]';
			EXECUTE(@Sql);
	
			SET @Sql = 'ALTER TABLE [dbo].[pdw_component_health_data]
						ADD [CustomContext.ClusterId] [nvarchar](255) NOT NULL';
			EXECUTE(@Sql);
			
			SET @Sql = 'CREATE TABLE [dbo].[pdw_component_health_data_lock](
						[CustomContext.SourceName] [nvarchar](255) NOT NULL,
						[CustomContext.ClusterId] [nvarchar](255) NOT NULL)';

			EXECUTE(@Sql);

			DECLARE @clusterCount INT, @clusterCountText VARCHAR(2), @monitorSourceName NVARCHAR(32);
			SET @monitorSourceName = N'Failover Cluster Health Monitor';
			SET @clusterCount = 1;
			
			DELETE FROM [dbo].[pdw_component_health_data_lock];
			
			--Pre-populate compute cluster names (up to 10 clusters)
			--associated with the Failover Cluster Health Monitor. 
			--This way we let the Health Agent know that any failover cluster
			--monitoring should be synchronized such that only one Agent is allowed to update 
			--data at any given time.
			WHILE @clusterCount < 11
			BEGIN
				SET @clusterCountText = CAST(@clusterCount AS NVARCHAR(10))

				IF @clusterCount < 10 
					SET @clusterCountText = '0' + @clusterCountText
					
				INSERT INTO [dbo].[pdw_component_health_data_lock]
				VALUES(@monitorSourceName, UPPER(DEFAULT_DOMAIN() + N'-WFOCMP' + @clusterCountText))
			
				SET @clusterCount = @clusterCount + 1;
			END
					
			--Pre-populate control cluster name			
			--associated with the Failover Cluster Health Monitor. 
			--This way we let the Health Agent know that any failover cluster
			--monitoring should be synchronized such that only one Agent is allowed to update 
			--data at any given time.
			INSERT INTO [dbo].[pdw_component_health_data_lock]
			VALUES(@monitorSourceName, UPPER(DEFAULT_DOMAIN() + N'-WFOCTL01'))
			
			SET @Sql = 'DROP PROCEDURE [dbo].[PublishHealthStatusData]';
			EXECUTE(@Sql);
			
			SET @Sql = 'DROP TYPE [dbo].[HealthStatusData]';
			EXECUTE(@Sql);
			
			SET @Sql = 'CREATE TYPE [dbo].[HealthStatusData] AS TABLE(
				[CustomContext.SourceName] [nvarchar](255) NOT NULL,
				[CustomContext.CurrentNode.Id] [int] NOT NULL,
				[CustomContext.Node.Id] [int] NOT NULL,
				[CustomContext.ComponentId] [int] NOT NULL,
				[CustomContext.ParentId] [int] NOT NULL,
				[CustomContext.InstanceId] [nvarchar](255) NOT NULL,
				[CustomContext.DetailId] [int] NOT NULL,
				[CustomContext.DetailValue] [nvarchar](255) NULL,
				[DateTimePublished] [datetime2](7) NOT NULL,
				[Builtin_DateTimeEntryCreated] [datetime2](7) NOT NULL,
				[Builtin_RowId] [nvarchar](255) NOT NULL,
				[Builtin_HasData] [bit] NOT NULL,
				[CustomContext.ClusterId] [nvarchar](255) NOT NULL
			)';
			EXECUTE(@Sql);
			
			SET @Sql = 'CREATE PROCEDURE [dbo].[PublishHealthStatusData] 
				@HealthStatusDataBatch AS HealthStatusData READONLY,
				@PdwNodeId AS INT,
				@SourceName AS nvarchar(255),
				@ClusterId AS nvarchar(255) = NULL -- Unique id of the cluster this particular monitoring source belongs to.
			AS
			BEGIN

				DECLARE @SummaryOfChanges TABLE(Change NVARCHAR(255));
				DECLARE @ReadpastCount INT

				--If the particular source and cluster pair exists in the synchronization
				--table, perform the synchronized cleanup logic in the transaction
				--which ensures that only one source at a time updates the data.
				--This prevents duplicates and orphaned data since we delete everything
				--for the source in the particular cluster.
				IF EXISTS(SELECT [CustomContext.SourceName] 
							FROM [pdw_component_health_data_lock] (NOLOCK)
							WHERE [CustomContext.SourceName] = @SourceName
							AND [CustomContext.ClusterId] = @ClusterId)
				BEGIN
					--Lock the rows for the duration of the transaction. This ensures that other agent processes
					--will return 0 rows until this transaction is completed.
					SELECT @ReadpastCount = count([CustomContext.SourceName]) 
					FROM [pdw_component_health_data_lock] WITH (ROWLOCK, READPAST, UPDLOCK)
					WHERE [CustomContext.SourceName] = @SourceName 
					AND [CustomContext.ClusterId] = @ClusterId;

					--This count is greater than 0 only if the lock
					--was acquired successfully
					IF (@ReadpastCount > 0)
					BEGIN
						--Delete all data produced from this source in the 
						--particular cluster (e.g. wipe out all the failover cluster monitoring
						--data for a particular cluster)
						DELETE FROM [pdw_component_health_data] 
						WHERE [CustomContext.SourceName] = @SourceName
						AND [CustomContext.ClusterId] = @ClusterId;
					END
					ELSE RETURN;
				END

				MERGE [pdw_component_health_data] AS target
				USING(SELECT DISTINCT 
						[CustomContext.SourceName],
						[CustomContext.ClusterId],
						[CustomContext.CurrentNode.Id],
						[CustomContext.Node.Id],
						[CustomContext.ComponentId],
						[CustomContext.ParentId],
						[CustomContext.InstanceId],
						[CustomContext.DetailId],
						[CustomContext.DetailValue],
						[DateTimePublished],
						[Builtin_DateTimeEntryCreated],
						[Builtin_RowId],
						[Builtin_HasData]
						FROM @HealthStatusDataBatch) AS source(
							[CustomContext.SourceName],
							[CustomContext.ClusterId],
							[CustomContext.CurrentNode.Id],
							[CustomContext.Node.Id],
							[CustomContext.ComponentId],
							[CustomContext.ParentId],
							[CustomContext.InstanceId],
							[CustomContext.DetailId],
							[CustomContext.DetailValue],
							[DateTimePublished],
							[Builtin_DateTimeEntryCreated],
							[Builtin_RowId],
							[Builtin_HasData])
				ON(target.[Builtin_RowId] = source.[Builtin_RowId]) 		
					WHEN MATCHED THEN 
						UPDATE SET 
							[CustomContext.DetailValue] = source.[CustomContext.DetailValue],
							[DateTimePublished] = source.[DateTimePublished]
					WHEN NOT MATCHED BY TARGET THEN	
						INSERT (
							[CustomContext.SourceName],
							[CustomContext.ClusterId],
							[CustomContext.CurrentNode.Id],
							[CustomContext.Node.Id],
							[CustomContext.ComponentId],
							[CustomContext.ParentId],
							[CustomContext.InstanceId],
							[CustomContext.DetailId],
							[CustomContext.DetailValue],
							[DateTimePublished],
							[Builtin_DateTimeEntryCreated],
							[Builtin_RowId],
							[Builtin_HasData])
						VALUES (
							source.[CustomContext.SourceName],
							source.[CustomContext.ClusterId],
							source.[CustomContext.CurrentNode.Id],
							source.[CustomContext.Node.Id],
							source.[CustomContext.ComponentId],
							source.[CustomContext.ParentId],
							source.[CustomContext.InstanceId],
							source.[CustomContext.DetailId],
							source.[CustomContext.DetailValue],
							source.[DateTimePublished],
							source.[Builtin_DateTimeEntryCreated],
							source.[Builtin_RowId],
							source.[Builtin_HasData])
					WHEN NOT MATCHED BY SOURCE AND target.[CustomContext.CurrentNode.Id] = @PdwNodeId AND target.[CustomContext.SourceName] = @SourceName THEN
						DELETE			
					OUTPUT $action INTO @SummaryOfChanges;

				SELECT * FROM @SummaryOfChanges;
			END';
			EXECUTE(@Sql);
				
			-- Grant EXEC to DWDiagnostics stored procedure and user type.
			GRANT EXEC ON dbo.PublishHealthStatusData TO [NT AUTHORITY\NETWORK SERVICE]
			GRANT EXEC ON dbo.PublishHealthStatusData TO [BEDNARSKIPAUL3\PdwComputeNodeAccess]

			GRANT EXEC ON TYPE::[dbo].[HealthStatusData] TO [NT AUTHORITY\NETWORK SERVICE]
			GRANT EXEC ON TYPE::[dbo].[HealthStatusData] TO [BEDNARSKIPAUL3\PdwComputeNodeAccess]	
		END		

		-- With the move to KatmaiCU3 which has the system views in the catalog combined with the move to 
		-- the SQL Server security model, the schema of pdw_diag_sessions has changed to expose the principal_id
		-- instead of the owner_id.  The view definition change captures the new schema.
		IF (@StoredVer < 40)
		BEGIN
			EXEC sp_executesql N'ALTER VIEW [dbo].[pdw_diag_sessions] AS
									SELECT 
										[session_name] as [name],
										CAST([definition] AS NVARCHAR(4000)) as xml_data,
										[is_enabled] as [is_active],
										[host_address],
										SUSER_ID([owner_id]) as [principal_id],
										CAST(NULL AS int) as [database_id]
									FROM [dbo].[pdw_diagnostics_sessions] (NOLOCK);'
		
			EXEC sp_executesql N'
			
			IF  EXISTS (SELECT object_id FROM sys.objects WHERE object_id = OBJECT_ID(N''dbo.pdw_loader_backup_runs_data'') AND type in (N''U''))
			BEGIN
				IF NOT EXISTS (SELECT object_id FROM sys.columns WHERE object_id = OBJECT_ID(N''dbo.pdw_loader_backup_runs_data'') AND name = N''CustomContext.PrincipalId'')
				BEGIN
					-- If the table already exists, we need to add the CustomContext.PrincipalId column to the table.
					ALTER TABLE [dbo].[pdw_loader_backup_runs_data] ADD [CustomContext.PrincipalId] [int] null;
				END
			END
				
			ELSE
			BEGIN
		
				CREATE TABLE [dbo].[pdw_loader_backup_runs_data] (
					[CustomContext.Run_Id] [int] not null,
					[CustomContext.Name] [nvarchar](255) null,
					[CustomContext.Submit_Time] [datetime] null,
					[CustomContext.StartTime] [datetime] null,
					[CustomContext.End_Time] [datetime] null,
					[CustomContext.Total_Elapsed_Time] [int] null,
					[CustomContext.Operation_Type] [nvarchar](16) null,
					[CustomContext.Mode] [nvarchar](16) null,
					[CustomContext.Database] [nvarchar](255) null,
					[CustomContext.Table] [nvarchar](255) null,
					[CustomContext.PrincipalId] int null,
					[CustomContext.Session_Id] [nvarchar](255) null,
					[CustomContext.Request_Id] [nvarchar](255) null,
					[CustomContext.Status] [nvarchar](16) null,
					[CustomContext.Progress] [int] null,
					[CustomContext.Command] [nvarchar](4000) null,
					[CustomContext.Rows_Processed] [bigint] null,
					[CustomContext.Rows_Rejected] [bigint] null,
					[CustomContext.Rows_Inserted] [bigint] null,	
					[Builtin_DateTimeEntryCreated] [datetime2](7) NOT NULL,
					[Builtin_RowId] [nvarchar](255) NOT NULL,
					[Builtin_HasData] [bit] NOT NULL,
				 CONSTRAINT [PK_pdw_loader_backup_runs_data] PRIMARY KEY CLUSTERED 
				(
					[Builtin_RowId] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]
				) ON [PRIMARY]
				
			END
			
			-- Create the index if it does not exist already
			IF NOT EXISTS (SELECT object_id FROM sys.indexes WHERE object_id = OBJECT_ID(N''dbo.pdw_loader_backup_runs_data'') AND name = N''IX_pdw_loader_backup_runs_data'')
			BEGIN
			
				CREATE NONCLUSTERED INDEX [IX_pdw_loader_backup_runs_data] ON [dbo].[pdw_loader_backup_runs_data] 
				(
					  [Builtin_DateTimeEntryCreated] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [PRIMARY]
			
			END';
			
			EXEC sp_executesql N'
			
			UPDATE [dbo].[pdw_loader_backup_runs_data]
			SET [CustomContext.PrincipalId] = ( SELECT principal_id FROM sys.server_principals WHERE name COLLATE Latin1_General_100_CI_AS_KS_WS = [CustomContext.User] COLLATE Latin1_General_100_CI_AS_KS_WS)
			WHERE EXISTS 
				( SELECT name FROM sys.server_principals WHERE name COLLATE Latin1_General_100_CI_AS_KS_WS = [CustomContext.User] COLLATE Latin1_General_100_CI_AS_KS_WS)
				
			UPDATE [dbo].[pdw_loader_backup_runs_data]
			SET [CustomContext.PrincipalId] = -1
			WHERE NOT EXISTS
				( SELECT name FROM sys.server_principals WHERE name COLLATE Latin1_General_100_CI_AS_KS_WS = [CustomContext.User] COLLATE Latin1_General_100_CI_AS_KS_WS)
			
			-- VSTS 870821:
			-- Check to see if the column [CustomContext.User] exists. Drop the column if it exists becasue we are deprecating this column in AU3
			IF EXISTS (SELECT object_id FROM sys.columns WHERE object_id = OBJECT_ID(N''dbo.pdw_loader_backup_runs_data'') AND name = N''CustomContext.User'')
			BEGIN
				ALTER TABLE [dbo].[pdw_loader_backup_runs_data]  DROP COLUMN [CustomContext.User];
			END';
			
		END
		
		-- VSTS 854490:  This change updates the value that is stored in the diagnostics session metadata.  Prior to
		-- this change, it stored the actual name of the login.  After this change, the value will be -1, as this column
		-- is now deprecated.
		IF (@StoredVer < 52)
		BEGIN
			update [DWDiagnostics].[dbo].[pdw_diagnostics_sessions] set [owner_id] = null;
						  
			exec sp_executesql N'
			ALTER VIEW [dbo].[pdw_diag_sessions] AS
			SELECT 
				[session_name] as [name],
				CAST([definition] AS NVARCHAR(4000)) as xml_data,
				[is_enabled] as [is_active],
				[host_address],
				-1 as [principal_id],
				CAST(NULL AS int) as [database_id]
			FROM [dbo].[pdw_diagnostics_sessions] (NOLOCK)';
		END

		-- Specify rerunnable changes here; 
		-- these changes can be executed during every upgrade, not just once
		
		IF (@StoredVer < 56)
		BEGIN
			exec sp_executesql N'
				ALTER VIEW [dbo].[dm_pdw_component_health_active_alerts] AS
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
					all_errors.severity IN (''Error'', ''Warning'') 
					AND all_errors.[Rank] = 1
					) alerts 
				JOIN dbo.dm_pdw_component_health_status S 
					ON S.pdw_node_id = alerts.pdw_node_id 
					AND S.component_id = alerts.component_id 
					AND S.component_instance_id = alerts.component_instance_id 
				JOIN [dbo].[pdw_health_component_properties] p 
					ON S.property_id = p.property_id 
					AND S.component_id = p.component_id 
					AND p.property_name = ''Status''
				WHERE 
					alerts.create_time <= S.update_time 
					  AND ((alerts.alert_type = ''StatusChange'' AND S.property_value = alerts.current_value) 
							 OR (alerts.alert_type = ''Threshold''))
				UNION
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
					all_errors.severity IN (''Error'', ''Warning'') 
					AND all_errors.[Rank] = 1
					) alerts 
				WHERE alerts.alert_id IN (100001, 100002)';
		END
		
		IF (@StoredVer < 58)
		BEGIN
			exec sp_executesql N'
				ALTER VIEW [dbo].[dm_pdw_component_health_active_alerts] AS
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
					all_errors.severity IN (''Error'', ''Warning'') 
					AND all_errors.[Rank] = 1
					) alerts 
				JOIN dbo.dm_pdw_component_health_status S 
					ON S.pdw_node_id = alerts.pdw_node_id 
					AND S.component_id = alerts.component_id 
					AND S.component_instance_id = alerts.component_instance_id 
				JOIN [dbo].[pdw_health_component_properties] p 
					ON S.property_id = p.property_id 
					AND S.component_id = p.component_id 
					AND p.property_name = ''Status''
				WHERE 
					alerts.create_time <= S.update_time 
					  AND ((alerts.alert_type = ''StatusChange'' AND S.property_value = alerts.current_value) 
							 OR (alerts.alert_type = ''Threshold''))';
		END

		IF (@StoredVer < 80)
		BEGIN
			-- VSTS: 979949 - Health alerts are cached and not updated for 2-3 polling intervals
			exec sp_executesql N'
				ALTER VIEW [dbo].[dm_pdw_component_health_active_alerts] AS
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
					all_errors.severity IN (''Error'', ''Warning'') 
					AND all_errors.[Rank] = 1
					) alerts 
				JOIN dbo.dm_pdw_component_health_status S 
					ON S.pdw_node_id = alerts.pdw_node_id 
					AND S.component_id = alerts.component_id 
					AND S.component_instance_id = alerts.component_instance_id 
				JOIN [dbo].[pdw_health_component_properties] p 
					ON S.property_id = p.property_id 
					AND S.component_id = p.component_id 
					AND p.property_name = ''Status''
				WHERE 
					DATEADD(ms, -DATEPART(ms, alerts.create_time), alerts.create_time) <= DATEADD(ms, -DATEPART(ms, S.update_time), S.update_time) 
						AND ((alerts.alert_type = ''StatusChange'' AND S.property_value = alerts.current_value) 
							OR (alerts.alert_type = ''Threshold''))';
		END
		
	END
