<cfcomponent displayname="Bookmark" output="false">
	
	<cffunction name="get" access="remote" returntype="Array">
		<cfargument name="userId" type="numeric" required="true" >
		
		<cfset arr = ArrayNew(1)>
		<cftry>
			<cfquery name="q" datasource="#request.mainDSN#" >
				SELECT 	id,
						userId,
						jobName,
						jobAlias,
						rcd_count,
						searchParam,
						dateCreated
				FROM	bookmark
				WHERE	deleted=0
					and userId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userId#">
				ORDER BY dateCreated desc
			</cfquery>

			<cfset arr = createObject("component", request.cfc & ".Utility").QueryToStruct(q)/>
			
			<cfloop from="1" to="#ArrayLen(arr)#" step="1" index="idx">
				<cfif len(arr[idx]['SEARCHPARAM'])>
					<cfset arr[idx]['SEARCHPARAM'] = deserializeJSON(ToString(arr[idx]['SEARCHPARAM']))/>
				</cfif>
			</cfloop>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("BOOKMARK.CFC - GET", 
						cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn arr />
			</cffinally>
		</cftry> 
		
		
	</cffunction>
	
	<cffunction name="add" access="remote" returntype="void">
		<cfargument name="obj" type="struct" required="true" />
		<cfargument name="jname" type="string" required="true"  />
		<cfargument name="count" type="numeric" required="true" />
		
		<cftry>
			<cfquery name="q" datasource="#request.mainDSN#">
				INSERT	bookmark(userId,jobName,jobAlias,searchParam,rcd_count,dateCreated)
				VALUES	(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.USERID#">,
						 <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.jname#">,
						 <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.ALIAS#">,
						 <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON(arguments.obj)#">,
						 <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.count#">, 
						 #createODBCDateTime(now())# )
			</cfquery>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("BOOKMARK.CFC - ADD", 
						cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>			
		</cftry>
		
	</cffunction>
	 
</cfcomponent>