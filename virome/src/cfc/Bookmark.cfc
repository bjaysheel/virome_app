<cfcomponent displayname="Bookmark" output="false" hint="
			This componented is used to get everything Bookmark related information.  
			It is used to gather, format and return all information for Bookmarks
			">
	
	<cffunction name="get" access="remote" returntype="Array" hint="
				Get all Bookmarks that are available for a give user.
				
				Return: An array of all bookmarks for a give user. Empty array if non exists.
				">
				
		<cfargument name="userId" type="numeric" required="true" hint="User ID">
		
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
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="Bookmark", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn arr />
			</cffinally>
		</cftry> 
		
		
	</cffunction>
	
	<cffunction name="add" access="remote" returntype="void" hint="
				Add all Bookmarks to the database.  
				A crude way of keeping history of all searches performed against VIROME database.
				
				Return: NA
				">
				
		<cfargument name="obj" type="struct" required="true" hint="A hash with user ID and bookmark alias name"/>
		<cfargument name="jname" type="string" required="true"  hint="Bookmark name"/>
		<cfargument name="count" type="numeric" required="true" hint="Number of rows/search results" />
		
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
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="Bookmark", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>			
		</cftry>
		
	</cffunction>
	 
</cfcomponent>