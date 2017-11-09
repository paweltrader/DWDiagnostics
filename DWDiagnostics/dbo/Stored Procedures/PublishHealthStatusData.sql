CREATE PROCEDURE [dbo].[PublishHealthStatusData] 
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
			END