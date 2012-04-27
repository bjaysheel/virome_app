<cfcomponent output="false">

	<cffunction name="getLibrary" access="remote" returntype="query">
		<cfargument name="id" default="-1" type="Numeric">
		<cfargument name="libraryIdList" default="" type="string">
		<cfargument name="publish" default="-1" type="Numeric" >
		<cfargument name="environment" default="" type="String">
		<!---<cfargument name="privateOnly" default="False" type="boolean">--->
				
		<cfset q="">
		<cftry>
			<cfquery name="q" datasource="#application.mainDSN#">
				SELECT	l.id,
						l.name,
						l.description,
						l.environment,
						l.prefix,
						l.server,
						l.publish,
						l.groupId,
						l.project,
						ls.citation,
						ls.citation_pdf,
						ls.seq_type,
						ls.lib_type,
						ls.na_type,
						ls.geog_place_name,
						ls.country,
						ls.amplification,
						ls.filter_lower_um,
						ls.filter_upper_um,
						ls.sample_date,
						ls.lat_deg,
						ls.lon_deg,
						ls.lat_hem,
						ls.lon_hem,
						ls.country
				FROM	library l
					INNER JOIN
						lib_summary ls on l.id = ls.libraryId
				WHERE	l.deleted = 0
					<cfif arguments.id gt -1>
						and l.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
					</cfif>
					<cfif arguments.publish gt -1>
						and l.publish = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.publish#">
					</cfif>
					<cfif len(arguments.libraryIdList) gt 0>
						and l.id in (#arguments.libraryIdList#)
						and l.publish = 0
					</cfif>
					<cfif len(arguments.environment)>
						and l.environment = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.environment#">
					</cfif>
				order by l.publish desc, l.environment, l.description asc
			</cfquery>
			<cfreturn q />
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETLIBRARY", 
							#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		<cfreturn q>
	</cffunction>

	<cffunction name="getSizeGC" access="private" returntype="Query">
		<cfargument name="libraryId" type="numeric" required="true">
		<cfargument name="server" type="string" required="true">
		<cfargument name="type" type="string" required="true">
		<cfargument name="orf" type="numeric" default="1">
		
		<cfset q=""/>
		<cftry>
			<cfquery name="q" datasource="#arguments.server#">
				SELECT	(<cfif arguments.type eq "gc">
							gc
						<cfelseif arguments.type eq "orf">
							size*3
						<cfelse>
							size
						</cfif>) as hval
				FROM	sequence
				WHERE	orf = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.orf#"/>
					and rRNA = 0
					and libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>
				ORDER BY hval desc
			</cfquery>
			<cfreturn q/>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETSIZEGC", 
							#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>		
		</cftry>
		
		<cfreturn q/>
	</cffunction>
		
	<cffunction name="getEnvironment" access="private" returntype="query">
		<cfargument name="libraryIdList" type="string" default=""/>
		<cfset q = "" />
		
		<cftry>
			<cfquery name="q" datasource="#application.mainDSN#">
				SELECT 	distinct environment
				FROM	library
				WHERE	deleted = 0
					<cfif len(arguments.libraryIdList)>
						and id in (#arguments.libraryIdList#)
					</cfif>
			</cfquery>
			
			<cfreturn q />

			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETENVIRONMENT", 
							#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>

		<cfreturn q>
	</cffunction>
	
	<cffunction name="jsonHelper" access="private" returntype="void" hint="create JSON object and write to file" >
		<cfargument name="struct" type="Struct" required="true">
		<cfargument name="filename" type="String" required="true">
		
		<cftry>
			<cfscript>
				djson = StructNew();
				djson = arguments.struct;
				
				if (FileExists(#arguments.filename#)){
					data = FileRead(#arguments.filename#);
					
					if(len(data)){
						djson = deserializeJSON(data);
						StructAppend(djson,arguments.struct);
					}
				}
				
				myfile = FileOpen(#arguments.filename#,"write","UTF-8");
				sjson = SerializeJSON(djson);
				FileWriteLine(myfile,sjson);
				FileClose(myfile);
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / JSONHELPER", 
							#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="getTaxAtLevel" access="private" returntype="void">
		<cfargument name="libraryId" type="Numeric" required="true" />
		<cfargument name="server" type="String" required="true" />
		<cfargument name="environment" type="String" default="" />
		<cfargument name="filename" type="string" default=""/>

		<cfset objarr = ArrayNew(1)>
		
		<cftry>
			<cfquery name="qry" datasource="#arguments.server#">
				SELECT	lineage,
						libraryId
				FROM	statistics
				WHERE	deleted = 0 
					and	libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>		
			</cfquery>
			<cfset str = ""/>
			
			<cfif qry.recordcount>
				<!--- parse the lineage from statistics table and create a struct --->
				<cfloop list="#qry.lineage#" index="level" delimiters=";">
						<cfset tmp = ListToArray(level,":")/>
						<cfset obj = StructNew()>
						<cfset StructInsert(obj,"type",#iif(len(tmp[1]), "tmp[1]", """Unclassified""")#)>
						<cfset StructInsert(obj,"count",tmp[2])>
						<cfset StructInsert(obj,"library",arguments.libraryId)>
						<cfset StructInsert(obj,"environment",arguments.environment)>
						<cfset StructInsert(Obj,"database","UNIREF100P")>
						<cfset ArrayAppend(objarr,obj)>
				</cfloop>
			
				<cfscript>
					struct = structnew();
					StructInsert(struct,"DOMAIN",objarr);
					
					jsonHelper(struct,arguments.filename);
				</cfscript>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETTAXDOMAIN", 
							#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="setReadObject" access="private" returntype="void" hint="create read JSON object">
		<cfargument name="libraryId" type="numeric" required="true">
		<cfargument name="server" type="string" required="true" >
		<cfargument name="environment" type="string" required="true" >
		<cfargument name="filename" type="string" required="true">
		
		<cftry>
			<cfquery name="qry" datasource="#arguments.server#">
				SELECT	read_cnt,
						read_mb
				FROM	statistics
				WHERE	deleted = 0 
					and	libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>		
			</cfquery>
			
			<cfscript>
				if (qry.RecordCount){
					obj = StructNew();
					objarr = ArrayNew(1);
					
					StructInsert(obj,"type","read");
					StructInsert(obj,"count",qry.read_cnt);
					StructInsert(obj,"mbp",qry.read_mb);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					
					ArrayAppend(objarr,obj);
					
					struct = structnew();
					StructInsert(struct,"READ",objarr);
					
					jsonHelper(struct,arguments.filename);	
				}
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / SETREADOBJECT", 
								#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="setORFTypeObject" access="private" returntype="void" hint="create ORF type JSON object">
		<cfargument name="libraryId" type="numeric" required="true">
		<cfargument name="server" type="string" required="true" >
		<cfargument name="environment" type="string" required="true" >
		<cfargument name="filename" type="string" required="true">
		
		<cftry>
			<cfquery name="qry" datasource="#arguments.server#">
				SELECT	complete_cnt, complete_mb,
						incomplete_cnt, incomplete_mb,
						lackstart_cnt, lackstart_mb,
						lackstop_cnt, lackstop_mb,
						libraryId
				FROM	statistics
				WHERE	deleted = 0 
					and	libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>		
			</cfquery>
			
			<cfscript>
				if (qry.RecordCount){
					obj = StructNew();
					objarr = ArrayNew(1);
					
					StructInsert(obj,"type","complete");
					StructInsert(obj,"count",qry.complete_cnt);
					StructInsert(obj,"mbp",qry.complete_mb);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","lack both ends");
					StructInsert(obj,"count",qry.incomplete_cnt);
					StructInsert(obj,"mbp",qry.incomplete_mb);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","lack start");
					StructInsert(obj,"count",qry.lackstart_cnt);
					StructInsert(obj,"mbp",qry.lackstart_mb);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","lack stop");
					StructInsert(obj,"count",qry.lackstop_cnt);
					StructInsert(obj,"mbp",qry.lackstop_mb);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					ArrayAppend(objarr,obj);
					
					struct = StructNew();
					StructInsert(struct,"ORFTYPE",objarr);
					
					jsonHelper(struct,arguments.filename);	
				}
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / SETREADOBJECT", 
								#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="setVIROMECatObject" access="private" returntype="void" hint="create ORF type JSON object">
		<cfargument name="libraryId" type="numeric" required="true">
		<cfargument name="server" type="string" required="true" >
		<cfargument name="environment" type="string" required="true" >
		<cfargument name="filename" type="string" required="true">
		
		<cftry>
			<cfquery name="qry" datasource="#arguments.server#">
				SELECT	tRNA_cnt, tRNA_id, 
						rRNA_cnt, rRNA_id,
						orfan_cnt, orfan_id,
						topviral_cnt, topviral_id,
						allviral_cnt, allviral_id,
						topmicrobial_cnt, topmicrobial_id,
						allmicrobial_cnt, allmicrobial_id,
						fxn_cnt, fxn_id,
						unassignfxn_cnt, unassignfxn_id,
						libraryId
				FROM	statistics
				WHERE	deleted = 0 
					and	libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>		
			</cfquery>
			
			<cfscript>
				if (qry.RecordCount){
					obj = StructNew();
					objarr = ArrayNew(1);
					
					StructInsert(obj,"type","tRNA");
					StructInsert(obj,"count",qry.tRNA_cnt);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					ArrayAppend(objarr,obj);
										
					obj=StructNew();
					StructInsert(obj,"type","rRNA");
					StructInsert(obj,"count",qry.rRNA_cnt);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","ORFans");
					StructInsert(obj,"count",qry.orfan_cnt);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","Top viral hit");
					StructInsert(obj,"count",qry.topviral_cnt);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					StructInsert(obj,"database","METAGENOMES");
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","Only viral hit");
					StructInsert(obj,"count",qry.allviral_cnt);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					StructInsert(Obj,"database","METAGENOMES");
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","Top microbial hit");
					StructInsert(obj,"count",qry.topmicrobial_cnt);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					StructInsert(Obj,"database","METAGENOMES");
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","Only microbial hit");
					StructInsert(obj,"count",qry.allmicrobial_cnt);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					StructInsert(Obj,"database","METAGENOMES");
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","Functional protein");
					StructInsert(obj,"count",qry.fxn_cnt);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					StructInsert(Obj,"database","UNIREF100P");
					ArrayAppend(objarr,obj);
					
					obj=StructNew();
					StructInsert(obj,"type","Unassigned protein");
					StructInsert(obj,"count",qry.unassignfxn_cnt);
					StructInsert(obj,"library",arguments.libraryId);
					StructInsert(obj,"environment",arguments.environment);
					StructInsert(Obj,"database","UNIREF100P");
					ArrayAppend(objarr,obj);

					struct = StructNew();
					StructInsert(struct,"VIRCAT",objarr);
					
					jsonHelper(struct,arguments.filename);	
				}
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / SETREADOBJECT", 
								#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="getStatistics" access="private" returntype="struct">
		<cfargument name="id" type="Numeric" required="true" />
		<cfargument name="server" type="String" required="true" />
		<cfargument name="environment" type="String" default=""/>
		
		<cfset stat_struct = StructNew()>
		<cfset local.filename = "LIBRARY_STAT_" & arguments.id & ".json"/>
		
		<cftry>
			<!--- get directory listing to see if .tab file is available --->
			<cfdirectory name="fList" action="list" directory="#application.xDocsFilePath#" filter="#local.filename#"/>
			
			<cfif NOT FileExists(application.xDocsFilePath&"/"&#local.filename#)>
				<cfscript>
					setReadObject(libraryId=arguments.id,server=arguments.server,environment=arguments.environment,filename=application.xDocsFilePath&"/"&#local.filename#);
					
					setORFTypeObject(libraryId=arguments.id,server=arguments.server,environment=arguments.environment,filename=application.xDocsFilePath&"/"&#local.filename#);
					
					setVIROMECatObject(libraryId=arguments.id,server=arguments.server,environment=arguments.environment,filename=application.xDocsFilePath&"/"&#local.filename#);
					
					getTaxAtLevel(libraryId=arguments.id,server=arguments.server,environment=arguments.environment,filename=application.xDocsFilePath&"/"&#local.filename#);
				</cfscript>
			</cfif>
			
			<cfscript>
				//check if there was any data for a given lib.
				if (not FileExists(application.xDocsFilePath&"/"&#local.filename#)){
					writelog(text="return empty",type="information",file="virome.log");
					return stat_struct;
				}

				data = FileRead(application.xDocsFilePath&"/"&#local.filename#);
				
				if(not isNull(data))
					stat_struct = deserializeJSON(data);
				
				return stat_struct;
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETSTATISTICS", 
								#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn stat_struct>
	</cffunction>

	<cffunction name="serverOverviewHelper" access="private" returntype="Struct">
		<cfargument name="environment" type="string" required="true">
		<cfargument name="libraryId" type="numeric" required="true">
		
		<cfset local.struct = StructNew()/>
		<cftry>
			<cfset serverObj = CreateObject("component", application.cfc & ".Utility").getServerName(environment=arguments.environment)/>
			<cfset _server=serverObj.server/>
			
			<!--- q of q get read counts --->
			<cfquery name="rq" datasource="#_server#">
				SELECT	COUNT(s.id) as rcount,
						SUM(s.size) as rsize
				FROM 	sequence s
				WHERE	deleted = 0
					and	s.orf=0 
					and s.rRNA=0 
					and s.libraryId=<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>
			</cfquery>
			<!--- add read counts into struct --->
			<cfset StructInsert(local.struct,"reads",iif(isNumeric(rq.rcount),"#rq.rcount#","0"))/>
			<cfset StructInsert(local.struct,"rsize",iif(isNumeric(rq.rsize),"#rq.rsize#","0"))/>	
				
			<!--- q of q get orf counts --->
			<cfquery name="oq" datasource="#_server#">
				SELECT	COUNT(s.id) as ocount,
						SUM(s.size) as osize
				FROM 	sequence s
				WHERE	deleted = 0
					and	s.orf=1
					and s.rRNA=0 
					and s.libraryId=<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>
			</cfquery>
			<!--- add orf counts into struct --->
			<cfset StructInsert(local.struct,"orfs",iif(isNumeric(oq.ocount),"#oq.ocount#","0"))/>
			<cfset StructInsert(local.struct,"osize",iif(isNumeric(oq.osize),"#oq.osize#","0"))/>	
					
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / SERVEROVERVIEWHELPER", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn local.struct/>
	</cffunction>
	
	<cffunction name="getMeanSTD" access="private" returntype="Struct" 
		hint="Get mean and std for a given library">
		<cfargument name="libraryId" type="numeric" required="true"/>
		<cfargument name="server" type="string" required="true"/>
		<cfargument name="orf" type="numeric" required="true"/>
	
		<cfset lstr = structnew()/>
		<cftry>
			<cfquery name="q" datasource="#arguments.server#">
				SELECT	avg(size) as mean,
						stddev(size) as sdev
				FROM	sequence
				WHERE	libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>
					and orf = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.orf#"/>
					and rRNA=0
			</cfquery>
			
			<cfif q.recordcount>
				<cfset StructInsert(lstr,"MEAN",#q.mean#)/>
				<cfset StructInsert(lstr,"STDEV",#q.sdev#)/>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETMEANSTD", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn lstr/>
	</cffunction>
	
	<cffunction name="getLibraryInfo" access="remote" returntype="Struct">
		<cfargument name="environment" type="string" required="true"/>
		<cfargument name="libraryIdList" type="string" required="true"/>
		<cfargument name="publish" type="numeric" required="true" default="1"/>
		
		<cfset struct = StructNew()>
		<cftry>
			<cfset summary = StructNew()>
			<cfset detail = StructNew()>
			<cfset arr = ArrayNew(1)>
			<cfset lib = getLibrary(environment=arguments.environment,libraryIdList=arguments.libraryIdList,publish=arguments.publish)>

			<cfif isQuery(lib)>
				<cfloop query="lib">
					<cfset StructInsert(summary,"LIBID",lib.id)>
					<cfset StructInsert(summary,"LIBNAME",lib.name)>
					<cfset StructInsert(summary,"DESCRIPTION",lib.description)>
					<cfset StructInsert(summary,"PREFIX",lib.prefix)>
					<cfset StructInsert(summary,"SERVER",lib.server)>
					<cfset StructInsert(summary,"PUBLISH",lib.publish)>
					<cfset StructInsert(summary,"PROJECT",lib.project)>
					<cfset StructInsert(summary,"CITATION",lib.citation)>
					<cfset StructInsert(summary,"LINK",lib.citation_pdf)>
					<cfset StructInsert(summary,"NA_TYPE",lib.na_type)>
					<cfset StructInsert(summary,"ENVIRONMENT",arguments.environment)>
					
					<cfset detail = getStatistics(id=lib.id,server=lib.server,environment=arguments.environment)>
					<cfset StructInsert(summary,"DETAIL",detail)>

					<cfset ArrayAppend(arr,summary)>
					<cfset summary = StructNew()>
					<cfset detail = StructNew()>
				</cfloop>

				<cfset StructInsert(struct,"environment",arguments.environment)>
				<cfset StructInsert(struct,"children",arr)>
			</cfif>

			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETLIBRARYINFO", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>

		<cfreturn struct>
	</cffunction>

	<cffunction name="getEnvironmentObject" access="remote" returntype="Array">
		<cfargument name="libraryIdList" type="string" default=""/>
	
		<cfset e = getEnvironment(libraryIdList=arguments.libraryIdList) />
		<cfset struct = StructNew()>
		<cfset array = ArrayNew(1)>
		
		<cfset StructInsert(struct,"label","Select One")>
		<cfset StructInsert(struct,"data","-1")>
		<cfset ArrayAppend(array,struct)>

		<cfloop query="e">
			<cfscript>
				struct = StructNew();
				structInsert(struct, "label", "#UCase(q.environment)#");
				structInsert(struct, "data", "#UCase(q.environment)#");
				ArrayAppend(array, struct);
			</cfscript>
		</cfloop>
		
		<cfreturn array />
	</cffunction>

	<cffunction name="getLibraryObject" access="remote" returntype="Array">
		<cfargument name="environment" type="string" required="true">
		<cfargument name="libraryIdList" type="string" required="true"/>
		
		<cfset libList = "">
		<cfset struct = StructNew()>
		<cfset array = ArrayNew(1)>

		<cfset StructInsert(struct, "label", "Select One")>
		<cfset StructInsert(struct, "data", "-1")>
		<cfset ArrayAppend(array, struct)>
		
		<cfset pub_lib = getLibrary(environment=arguments.environment,publish=1)>
		<cfloop query="pub_lib">
			<cfscript>
				struct = StructNew();
				structInsert(struct, "label", "Public: " & #UCase(pub_lib.name)#);
				structInsert(struct, "data", "#pub_lib.id#");
				ArrayAppend(array, struct);
			</cfscript>
		</cfloop>
		
		<cfif len(libraryIdList) gt 0>
			<cfset pri_lib = getLibrary(environment=arguments.environment,libraryIdList=arguments.libraryIdList,publish=0)>
			<cfloop query="pri_lib">
				<cfscript>
					struct = StructNew();
					structInsert(struct, "label", "Private: " & #UCase(pri_lib.name)#);
					structInsert(struct, "data", "#pri_lib.id#");
					ArrayAppend(array, struct);
				</cfscript>
			</cfloop>
		</cfif>
		
		<cfreturn array />
	</cffunction>
	
	<cffunction name="getBLASTDBObject" access="remote" returntype="Array">
		<cfset struct = StructNew()/>
		<cfset arr = ArrayNew(1)/>
		
		<cftry>
			<cfset lib = getLibrary(publish=1)/>
			
			<cfoutput query="lib" group="environment">
				<cfset struct = StructNew()/>
				<cfset struct['label'] = UCase(lib.environment) & " ENVIRONMENT"/>
				<cfset struct['data'] = UCase(REReplace(lib.environment,"_| ","-","ALL"))/>
				<cfset ArrayAppend(arr,struct)/>
				<cfoutput group="description">
					<cfset struct = StructNew()/>
					<cfset struct['label'] = "     "&UCase(lib.name)/>
					<cfset struct['data'] = UCase(lib.name)/>
					<cfset ArrayAppend(arr,struct)/>
				</cfoutput>
			</cfoutput>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETBLASTOBJECT", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn arr/>
	</cffunction>
	
	<cffunction name="getGeneralObject" access="remote" returntype="Struct" >
		<cfargument name="obj" type="Struct" required="true" />
		
		<cfset summary=StructNew()>
		<cftry>
			<cfset lib=getLibrary(id=arguments.obj.LIBRARY)/>
			
			<cfloop query="lib">
				<cfset StructInsert(summary,"LIBID",lib.id)>
				<cfset StructInsert(summary,"PROJECT",lib.project)>
				<cfset StructInsert(summary,"ENVIRONMENT",arguments.obj.ENVIRONMENT)>
				<cfset StructInsert(summary,"DESCRIPTION",lib.description)>
				<cfset StructInsert(summary,"LIBNAME",lib.name)>
				<cfset StructInsert(summary,"PREFIX",lib.prefix)>
				<cfset StructInsert(summary,"SERVER",lib.server)>
				<cfset StructInsert(summary,"PUBLISH",lib.publish)>
				<cfset StructInsert(summary,"LIBTYPE",lib.lib_type)>
				<cfset StructInsert(summary,"CITATION",lib.citation)>
				<cfset StructInsert(summary,"LINK",lib.citation_pdf)>
				<cfset StructInsert(summary,"SAMPLEDATE",lib.sample_date)>
				<cfset StructInsert(summary,"LOCATION",lib.geog_place_name)>
				<cfset StructInsert(summary,"COUNTRY",lib.country)>
				<cfset StructInsert(summary,"LAT",lib.lat_deg)>
				<cfset StructInsert(summary,"LATHEM",lib.lat_hem)>
				<cfset StructInsert(summary,"LON",lib.lon_deg)>
				<cfset StructInsert(summary,"LONHEM",lib.lon_hem)>
				<cfset StructInsert(summary,"SEQTYPE",lib.seq_type)>
				<cfset StructInsert(summary,"AMPLIFICATION", lib.amplification)>
				<cfset StructInsert(summary,"FILTER_LOWER", lib.filter_lower_um)>
				<cfset StructInsert(summary,"FILTER_UPPER", lib.filter_upper_um)>
				
				<cfset detail = getStatistics(id=arguments.obj.LIBRARY,server=lib.server,environment=arguments.obj.ENVIRONMENT)>
				<cfset StructInsert(summary,"DETAIL",detail)>
				
				<cfset rmean = getMeanSTD(libraryId=arguments.obj.LIBRARY,server=lib.server,orf=0)/>
				<cfset omean = getMeanSTD(libraryId=arguments.obj.LIBRARY,server=lib.server,orf=1)/>
				
				<cfset StructInsert(summary,"RMEAN",rmean.MEAN)/>
				<cfset StructInsert(summary,"RSTDEV",rmean.STDEV)/>
				<cfset StructInsert(summary,"OMEAN",omean.MEAN)/>
				<cfset StructInsert(summary,"OSTDEV",omean.STDEV)/>
			</cfloop>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETGENERALOBJECT", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		<cfreturn summary/>
	</cffunction>
	
	<cffunction name="getHistogram" access="remote" returntype="xml">
		<cfargument name="libraryId" type="numeric" required="true" />
		<cfargument name="server" type="string" required="true"/>
		<cfargument name="type" type="string" required="true"/>
		
		<cfset k = 10/>
		<cfset filename = UCASE(arguments.type) & "_HISTOGRAM_" & arguments.libraryId & ".xml"/>
		<cfset xroot = XMLNew()>
		<cfset xroot.xmlRoot = XMLElemNew(xroot,"root")>
		<cfset root = xroot.xmlRoot>
		
		<cftry>
			<!--- if file does not exist create a new one--->		
			<cfif not fileExists(application.xDocsFilePath&"/"&filename)>
				
				<!---  get size or gc --->
				<cfset qry = getSizeGC(libraryId=arguments.libraryId,server=arguments.server,type=arguments.type,orf=iif(arguments.type eq "orf",1,0))/>
			
				<!--- calculate total number of bins --->
				<cfif arguments.type neq "gc">
					<cfset k = 30/>
					<cfset max = qry["hval"][1]/>
					<cfset min = qry["hval"][qry.recordcount]/>
					<cfset bin = round((max-min)/k)/>
				<cfelse>
					<cfset k = 21/>
					<cfset bin = 5/>
					<cfset max = 100/>
					<cfset min = 0/>
				</cfif>				
	
				<!--- set range of bins, and init temp array --->
				<cfset range_list = min/>
				<cfset t.arr = ArrayNew(1)/>
				<cfloop from="1" to="#k#" index="idx">
					<cfset range_list = listprepend(range_list,min+(bin*idx))/>
					<cfset t.arr[idx] = 0/>
				</cfloop>

				<!--- populate frequence count for each bin --->
				<cfloop query="qry">
				 	<cfloop list="#range_list#" index="idx">
				 		<cfif qry.hval gte idx>
							<cfset cnt = abs(ListFindNoCase(range_list,idx)-k)+1/>
							<cfset t.arr[cnt] += 1/>
							<cfbreak/>
						</cfif>
					</cfloop>
				</cfloop>

				<!--- reverse list in asc order --->
				<cfset rev_list=""/>
				<cfloop list="#range_list#" index="idx">
					<cfset rev_list = listprepend(rev_list,idx)/>
				</cfloop>

				<!--- create key value pair each bin --->
				<cfloop from="1" to="#ArrayLen(t.arr)#" index="idx">
					<cfscript>
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						cat = root.xmlChildren[ArrayLen(root.xmlChildren)];
						cat.XmlAttributes.label = ListGetAt(rev_list,idx).toString();
						cat.XmlAttributes.value = t.arr[idx];
					</cfscript>
				</cfloop>
				
				<!--- write to file as well --->
				<cfscript>
					fileWrite("#application.xDocsFilePath#/#filename#","#xroot#");
					return xroot;
				</cfscript>
				
			<cfelse>
				<cfscript>
					xroot = fileRead("#application.xDocsFilePath#/#filename#");
					return xroot;
				</cfscript>				
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETHISTOGRAM", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn xroot/>
	</cffunction>
	
	<cffunction name="getServerOverview" access="remote" returntype="Array">
		<cfargument name="userId" type="numeric" required="true" hint="set to view private libraries for give user"/>
		<cfargument name="libraryIdList" type="string" required="true" hint="set to view private libraries"/>
		<cfargument name="privateOnly" type="boolean" required="true" default="false"/>
			
		<cfset local.arr = ArrayNew(1)/>
		
		<cftry>
			<!--- set public/private filename --->
			<cfset filename = "SERVEROVERVIEW_PUBLIC.json"/>
			<cfif arguments.userId gt 0>
				<cfset filename = "SERVEROVERVIEW_PRIVATE_" & arguments.userId & ".json"/>
			</cfif>
			
			<cfif not fileExists(application.xDocsFilePath&"/"&filename)>
				<!--- get environment --->				
				<cfset lib = getLibrary(libraryIdList=arguments.libraryIdList, publish=iif(arguments.privateOnly,"""0""","""1""") )/>
				<cfset str = ""/>
				
				<!--- for each environment get simple library stats --->
				<cfoutput query="lib" group="environment">
					<cfscript>
						rcount = 0; rsize = 0; ocount = 0; osize = 0; //rncount = 0; rnsize = 0;
						count = 0;
						tStruct = StructNew();
					</cfscript>
					
					<cfoutput>
						<cfset obj = serverOverviewHelper(environment=lib.environment,libraryId=lib.id)/>
						<cfset rcount += obj.reads/>
						<cfset rsize += obj.rsize/>
						<cfset ocount += obj.orfs/>
						<cfset osize += obj.osize/>
						<!---<cfset rncount += obj.rRNA/>
						<cfset rnsize += obj.rnsize/>--->
						<cfset count += 1/>
					</cfoutput>
					
					<cfset StructInsert(tStruct,"ENVIRONMENT",#lib.environment#)/>
					<cfset StructInsert(tStruct,"LIBCOUNT",count)/>
					<cfset StructInsert(tStruct,"READS",rcount)/>
					<cfset StructInsert(tStruct,"R_SIZE",rsize)/>
					<cfset StructInsert(tStruct,"ORFS",ocount)/>
					<cfset StructInsert(tStruct,"O_SIZE",osize)/>
					
					<cfset ArrayAppend(local.arr,tStruct)/>
				</cfoutput>
				
				<cfscript>
					tStruct = StructNew();
					StructInsert(tStruct,"ServerOverview",local.arr);
					
					jsonHelper(tStruct,application.xDocsFilePath&"/"&filename);
					
					return local.arr;
				</cfscript>
			</cfif>
			
			<cfscript>
				data = FileRead(application.xDocsFilePath&"/"&#filename#);
				ov_struct = StructNew();
								
				if(not isNull(data))
					ov_struct = deserializeJSON(data);
				
				return ov_struct['ServerOverview'];
			</cfscript>
						
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETSERVEROVERVIEW", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn local.arr/>
	</cffunction>
	
	<!--- functions for virome submission ---->
		
	<cffunction name="edit_library" access="remote" returntype="Struct" >
		<cfargument name="obj" type="struct" required="true" >
		
		<cfset struct= StructNew()>
		<cfset struct['MSG'] = "failed"/>
		<cfset struct['ERROR'] = ""/>
		
		<cftry>
			<cfset srv = getServerName(arguments.obj.environment)/>
			
			<cfquery name="q" datasource="#application.mainDSN#" >
				UPDATE library
				SET	name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.name#">,
					description = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.description#">,
					environment = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.environment#" >,
					project = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.project#">,
					seqMethod = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.seqMethod#">,
					publish = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.publish#" >,
					server = <cfqueryparam cfsqltype="cf_sql_varchar" value="#srv#" >
				WHERE	prefix = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.prefix#">
					and	name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.old_name#">
			</cfquery>
			
			<cfset struct['MSG'] = "Library <b>#arguments.obj.name#</b> modified successfully."/>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / EDIT_LIBRARY", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
				<cfset struct['ERROR'] = cfcatch.message/>
			</cfcatch>
		</cftry>
		
		<cfreturn struct/>
	</cffunction>
	
	<cffunction name="add_library" access="remote" returntype="struct" >
		<cfargument name="obj" type="struct" required="true" >
		
		<cfset struct= StructNew()>
		<cfset struct['MSG'] = "failed"/>
		<cfset struct['ERROR'] = ""/>
		
		<cfset prefix = arguments.obj.prefix/>
		<cfif prefix eq "">
			<cfset prefix = getPrefix()/>
		</cfif>
			
		<cfset struct['PREFIX'] = prefix/>	
		
		<cftry>
			<cfset srv = getServerName(arguments.obj.environment)/>
			<cfset groupId = getGroupId(arguments.obj.user)/>
			
			<cfquery name="q" datasource="#application.mainDSN#">
				INSERT INTO library(name,prefix,description,environment,project,publish,user,seqMethod,progress,groupId,server,deleted)
				VALUES	(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.name#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#prefix#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.description#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.environment#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.project#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.publish#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.user#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.seqMethod#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="standby">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#groupId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#srv#">,
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#arguments.obj.deleted#">
						)
			</cfquery>
			
			<cfset struct['MSG'] = "Library <b>#arguments.obj.name#</b> added successfully."/>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / ADD_LIBRARY", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
				<cfset struct['ERROR'] = cfcatch.message/>
			</cfcatch>
		</cftry>
		
		<cfreturn struct/>
	</cffunction>
		
	<cffunction name="delete_library" access="remote" returntype="Struct" >
		<cfargument name="obj" type="struct" required="true" >
		
		<cfset struct= StructNew()>
		<cfset struct['MSG'] = "failed"/>
		<cfset struct['ERROR'] = ""/>
		
		<cftry>
			<cfquery name="q" datasource="#application.mainDSN#" >
				UPDATE 	library
				SET		deleted = <cfqueryparam cfsqltype="cf_sql_tinyint" value="1">
				WHERE	prefix = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.prefix#">
					and	name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.old_name#">
			</cfquery>
			
			<cfset struct['MSG'] = "Library <b>#arguments.obj.name#</b> deleted successfully."/>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / DELETE_LIBRARY", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
				<cfset struct['ERROR'] = cfcatch.Message/>
			</cfcatch>
		</cftry>
		
		<cfreturn struct/>
	</cffunction>
	
	<cffunction name="getServerName" access="private" returntype="string">
		<cfargument name="environment" type="string" required="true" >
		
		<cfswitch expression="#lcase(arguments.environment)#">
			<cfcase value="extreme"> <cfreturn "thalia"> </cfcase>
			<cfcase value="solid substrate"> <cfreturn "thalia"> </cfcase>
			<cfcase value="organismal substrate"> <cfreturn "calliope"> </cfcase>
			<cfcase value="sediment"> <cfreturn "calliope"> </cfcase>
			<cfcase value="soil"> <cfreturn "polyhymnia"> </cfcase>
			<cfcase value="water"> <cfreturn "terpsichore"> </cfcase>			
			<cfdefaultcase> <cfreturn "calliope"> </cfdefaultcase>
		</cfswitch>
	</cffunction>
	 
	<cffunction name="getGroupId" access="private" returntype="Numeric">
		<cfargument name="username" type="string" required="true">
		<cfset groupId = -1>
		
		<cftry>
			<cfquery name="q" datasource="#application.mainDSN#">
				SELECT	id
				FROM	groups
				WHERE	name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#">
			</cfquery>
			
			<cfloop query="q">
				<cfset groupId = q.id/>	
			</cfloop>
				
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETGROUPID", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
				<cfset struct['ERROR'] = cfcatch.Message/>
			</cfcatch>
		</cftry>
		
		<cfreturn groupId>
	</cffunction> 
	
	<cffunction name="getPrefix" access="private" returntype="String">
		<cfset prefix = ""/>
		<cfset stop = false/>
		
		<cftry>
			<cfloop condition="stop eq false">
				<cfset prefix = ucase(createPrefix())/>
				
				<cfquery name="q" datasource="#application.mainDSN#">
					SELECT	id
					FROM	library
					WHERE	prefix = '#prefix#'	
				</cfquery>
				
				<cfif (q.recordcount eq 0) and (len(prefix) eq 3)>
					<cfset stop = true/>
				</cfif>
			</cfloop>
			
			<cfcatch type="any">
				<cfset CreateObject("component", application.cfc & ".Utility").ReportError("LIBRARY.CFC / GETPREFIX",
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>

		<cfreturn prefix/>
	</cffunction>
	
	<cffunction name="createPrefix" access="private" returntype="String">
		<cfset str = ""/>
		<cfloop index="i" from="1" to="3" step="1">
			<cfset a = randrange(48,122)/>
			
			<cfif (#a# gt 57 and #a# lt 65) or (#a# gt 90 and #a# lt 97)>
			<cfelse>
				<cfset str &= #chr(a)#>
			</cfif>
		</cfloop>
		
		<cfreturn str/>
	</cffunction>
	 
</cfcomponent>