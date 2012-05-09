<cfcomponent output="false">
	
	<cffunction name="getLibrary" access="private" returntype="Query" 
		hint="Get all libraries">
		
		<cfargument name="libraryIdList" type="string" required="false" default=""/>
		
		<cftry>
			<cfquery name="q" datasource="#application.mainDSN#">
				SELECT 	l.id,
						l.name,
						l.prefix,
						l.environment,
						l.server,
						l.publish,
						l.groupId
				FROM	library l
				WHERE	l.deleted = 0
					<cfif len(arguments.libraryIdList) gt 0>
						and l.id in (#arguments.libraryIdList#)
						and l.publish = 0
					<cfelse>
						and l.publish = 1
					</cfif>
				ORDER BY l.environment, l.id, l.server 
			</cfquery>
			
			<cfreturn q>
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETLIBRARY", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="getAccList" access="private" returntype="Query" 
		hint="Get all accession numbers (hit_name) for given library and database.">
		<cfargument name="libraryId" type="numeric" required="true"/>
		<cfargument name="server" type="string" required="true"/>
		<cfargument name="database" type="string" required="true"/>
		
		<cfset q="">
		<cftry>
			<cfquery name="q" datasource="#arguments.server#">
				SELECT	distinct (b.sequenceId), b.hit_name
				FROM	blastp b
					INNER JOIN
						sequence s on s.id=b.sequenceId
				WHERE	s.id = b.sequenceId
					and b.fxn_topHit=1
					and b.database_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.database#"/>
					and s.libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>
				ORDER BY b.sequenceId, b.hit_name
			</cfquery>		
			<cfreturn q/>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETACCLIST", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		<cfreturn q/> 
	</cffunction>
	
	<cffunction name="getFxnalDbQuery" access="private" returntype="Query"
		hint="Get ACLAME functional information for a given ACLAME accession">
		<cfargument name="acc" type="string" required="true">
		<cfargument name="database" type="string" required="true">
		
		<cfset q="">
		
		<cfset createobject("component", application.cfc & ".Utility").PrintLog(acc)/>
		<cftry>
			<cfquery name="q" datasource="#application.lookupDSN#">
				SELECT 	distinct db.realacc,
						if(length(db.fxn1),db.fxn1,'UNKNOWN') as fxn1,
						if(length(db.fxn2),db.fxn2,'UNKNOWN') as fxn2,
						<cfif arguments.database eq 'seed'>
							if(length(db.subsystem),db.subsystem,'UNKNOWN') as fxn3
						<cfelse>
							if(length(db.fxn3),db.fxn3,'UNKNOWN') as fxn3
						</cfif>
						<cfif (arguments.database eq 'aclamefxn') or (arguments.database eq 'gofxn')>
							,if(length(db.fxn4),db.fxn4,'UNKNOWN') as fxn4
							,if(length(db.fxn5),db.fxn5,'UNKNOWN') as fxn5
							,if(length(db.fxn6),db.fxn6,'UNKNOWN') as fxn6
							,if(length(db.fxn7),db.fxn7,'UNKNOWN') as fxn7
							,if(length(db.fxn8),db.fxn8,'UNKNOWN') as fxn8
							,if(length(db.fxn9),db.fxn9,'UNKNOWN') as fxn9
							,if(length(db.fxn10),db.fxn10,'UNKNOWN') as fxn10
							,if(length(db.fxn11),db.fxn11,'UNKNOWN') as fxn11
							,if(length(db.fxn12),db.fxn12,'UNKNOWN') as fxn12
						</cfif>
				FROM	#lcase(arguments.database)# db
				WHERE	db.realacc in (#preserveSingleQuotes(arguments.acc)#)
				ORDER BY fxn1, fxn2, fxn3 
					<cfif (arguments.database eq 'aclamefxn') or (arguments.database eq 'gofxn')>
						 ,fxn4 ,fxn5 ,fxn6 ,fxn7 ,fxn8 ,fxn9 ,fxn10 ,fxn11 ,fxn12
					</cfif>
			</cfquery>
			<cfreturn q/>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETFXNALDBQUERY", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		<cfreturn q/>
	</cffunction>
	
	<cffunction name="getBlastHits" access="private" returntype="Query"
		hint="Get id's of sequences who has blast records">
		<cfargument name="server" type="String" required="true"/>
		<cfargument name="library" type="numeric" required="true"/>
		<cfargument name="database" type="string" default=""/>
		<cfargument name="topHit" type="numeric" default="-1"/>
		<cfargument name="fxnHit" type="numeric" default="-1"/>
		
		<cfset q="">
		<cftry>
			<cfquery name="q" datasource="#arguments.server#">
				SELECT 	DISTINCT(b.sequenceId)
				FROM 	blastp b 
					RIGHT JOIN 
						sequence s ON b.sequenceId = s.id
				WHERE 	s.deleted=0
				 	and b.deleted=0
					and b.e_value < 0.001
					<cfif len(arguments.database)>
						and b.database_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.database#"/>
					</cfif>
					<cfif topHit gt -1>
						and b.sys_topHit = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.topHit#"/>
					</cfif>
					<cfif fxnHit gt -1>
						and b.fxn_topHit = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.fxnHit#"/>
					</cfif>
					and s.libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.library#"/>
				ORDER BY b.sequenceId
			</cfquery>
			<cfreturn q/>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETBLASTHITS", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn q>
	</cffunction>
	
	<cffunction name="gettRNAHelper" access="private" returntype="query">
		<cfargument name="libraryId" type="numeric" required="true"/>
		<cfargument name="server" type="String" required="true"/>
		<cfargument name="sortby" type="string" default="anti"/>
		
		<cfset q=""/>
		<cftry>
			<cfquery name="q" datasource="#arguments.server#">
				SELECT	t.num,
						t.tRNA_start,
						t.tRNA_end,
						t.anti,
						t.intron,
						t.score,
						s.name,
						s.id
				FROM	tRNA t
					INNER JOIN
						sequence s on s.id = t.sequenceId
				WHERE	t.deleted=0
					and	s.deleted=0
					and s.libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#"/>
				<cfif arguments.sortby eq "id">
					ORDER BY s.id, t.anti
				<cfelse>
					ORDER BY t.anti
				</cfif>
			</cfquery>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETTRNAHELPER", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn q/>
	</cffunction>
	
	<cffunction name="getTaxonomyHelper" access="private" returntype="Query"
		hint="get all taxonomic information for all top blast hits for a given library">
		<cfargument name="libraryId" type="numeric" required="true"/>
		<cfargument name="server" type="string" required="true"/>
		
		<cfset q=""/>
		<cftry>
			<cfquery name="q" datasource="#arguments.server#">
				SELECT	b.domain,
						b.kingdom,
						b.phylum,
						b.class,
						b.order,
						b.family,
						b.genus,
						b.species,
						b.organism,
						b.sequenceId
				FROM	blastp b 
					RIGHT JOIN
						sequence s on b.sequenceId=s.id
				WHERE	b.deleted=0
					and s.deleted=0
					and b.sys_topHit=1
					and b.e_value <= 0.001
					and b.database_name = 'UNIREF100P'
					and s.libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.libraryId#" />
				ORDER BY b.domain,b.kingdom,b.phylum,b.class,b.order,b.family,b.genus,b.species
			</cfquery>
			<cfreturn q/>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETTAXONOMYHELPER", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn q/>
	</cffunction>
	
	<cffunction name="getStatistics" access="private" returntype="Query"
		hint="Get Statistics for given library">		
		<cfargument name="server" type="String" requried="true"/>
		<cfargument name="library" type="Numeric" required="true"/>

		<cfset q="">
		<cftry>
			<cfquery name="q" datasource="#arguments.server#">
				SELECT	s.read_cnt,
						s.read_mb,
						s.complete_cnt,
						s.complete_mb,
						s.complete_id,
						s.incomplete_cnt,
						s.incomplete_mb,
						s.incomplete_id,
						s.lackstop_cnt,
						s.lackstop_mb,
						s.lackstop_id,
						s.lackstart_cnt,
						s.lackstart_mb,
			 			s.lackstart_id,
						s.archaea_cnt,
						s.archaea_mb,
						s.archaea_id,
						s.bacteria_cnt,
						s.bacteria_mb,
						s.bacteria_id,
						s.phage_cnt,
						s.phage_mb,
						s.phage_id,
						s.tRNA_cnt,
						s.tRNA_id,
						s.rRNA_cnt,
						s.rRNA_id,
						s.orfan_cnt,
						s.orfan_id,
						s.allviral_cnt,
						s.allviral_id,
						s.topviral_cnt,
						s.topviral_id,
						s.allmicrobial_cnt,
						s.allmicrobial_id,
						s.topmicrobial_cnt,
						s.topmicrobial_id,
						s.fxn_cnt,
						s.fxn_id,
						s.unassignfxn_cnt,
						s.unassignfxn_id,
						s.libraryId
				FROM	statistics s
				WHERE	s.deleted = 0
					and s.libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.library#"/>						
			</cfquery>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETSTATISTICS", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		<cfreturn q/>
	</cffunction>
	
	<cffunction name="ORFOverview" access="private" returntype="xml" 
		hint="get overview of all orf per env, and virome cat" >
	
		<cfargument name="userId" type="Numeric" required="false" default="-1"/>
		<cfargument name="libraryIdList" type="string" required="false" default=""/>
		
		<cfset xroot = XMLNew()>
		<cfset xroot.xmlRoot = XMLElemNew(xroot,"root")>
		<cfset root = xroot.xmlRoot>
		<cfset root.XmlAttributes.CHILDREN = "ENVIRONMENT"/>
		<cfset root.XmlAttributes.DIRECT = "Browse"/>
		
		<cftry>
			<!--- get all librarires --->
			<cfset libs = getLibrary(libraryIdList=arguments.libraryIdList)>
			
			<!--- loop over each env. --->
			<cfoutput query="libs" group="environment">
				<!--- loop over each lib in an environment --->
				<cfscript>
					//create a struct for each library
					struct = StructNew();
					struct['ORFAN'] = 0;
					struct['VIRALONLY'] = 0;
					struct['MICROONLY'] = 0;
					struct['TOPVIRAL'] = 0;
					struct['TOPMICRO'] = 0;
					struct['FXN'] = 0;
					struct['UNASSIGNFXN'] = 0;
					struct['TRNA'] = 0;
					struct['RRNA'] = 0;
					struct['TOTAL'] = 0;
				</cfscript>
				
				<cfoutput group="id">
					<!--- for each library get statistics --->
					<cfset stat = getStatistics(server=libs.server,library=libs.id)/>
					<cfif IsQuery(stat) and stat.recordCount>
						<cfloop query="stat">
							<cfscript>
								struct['ORFAN'] = struct['ORFAN'] + stat.orfan_cnt;
								struct['VIRALONLY'] = struct['VIRALONLY'] + stat.allviral_cnt;
								struct['MICROONLY'] = struct['MICROONLY'] + stat.allmicrobial_cnt;
								struct['TOPVIRAL'] = struct['TOPVIRAL'] + stat.topviral_cnt;
								struct['TOPMICRO'] = struct['TOPMICRO'] + stat.topmicrobial_cnt;
								struct['FXN'] = struct['FXN'] + stat.fxn_cnt;
								struct['UNASSIGNFXN'] = struct['UNASSIGNFXN'] + stat.unassignfxn_cnt;
								struct['TRNA'] = struct['TRNA'] + stat.tRNA_cnt;
								struct['RRNA'] = struct['RRNA'] + stat.rRNA_cnt;
								struct['TOTAL'] = struct['TOTAL'] + stat.orfan_cnt + stat.allviral_cnt +
												  stat.topviral_cnt + stat.fxn_cnt + stat.unassignfxn_cnt +
												  stat.tRNA_cnt + stat.rRNA_cnt + stat.allmicrobial_cnt + stat.topmicrobial_cnt;
							</cfscript>
						</cfloop>						
					</cfif>
				</cfoutput> <!--- end each library --->
				
				<!--- create xml object --->
				<cfscript>
					ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"ENVIRONMENT"));
					env_node = root.xmlChildren[ArrayLen(root.xmlChildren)];
					env_node.XmlAttributes.name = UCASE(libs.environment);
					env_node.XmlAttributes.label = UCase(libs.environment);
					env_node.XmlAttributes.value = #iif((struct['TOTAL'] gt 0),"log10(struct['TOTAL'])","struct['TOTAL']")#;
					
					// add orfan node
					ArrayAppend(env_node.xmlChildren, XmlElemNew(xroot,"CATEGORY"));
					orfan_node = env_node.xmlChildren[ArrayLen(env_node.xmlChildren)];
					orfan_node.XmlAttributes.label = "ORFANS";
					orfan_node.XmlAttributes.value = struct['ORFAN'];
					
					// add viral only node
					ArrayAppend(env_node.xmlChildren, XmlElemNew(xroot,"CATEGORY"));
					vironly_node = env_node.xmlChildren[ArrayLen(env_node.xmlChildren)];
					vironly_node.XmlAttributes.label = "VIRAL ONLY";
					vironly_node.XmlAttributes.value = struct['VIRALONLY'];
				
					// add top viral node
					ArrayAppend(env_node.xmlChildren, XmlElemNew(xroot,"CATEGORY"));
					topvir_node = env_node.xmlChildren[ArrayLen(env_node.xmlChildren)];
					topvir_node.XmlAttributes.label = "Top Viral";
					topvir_node.XmlAttributes.value = struct['TOPVIRAL'];
					
					// add micorbial only node
					ArrayAppend(env_node.xmlChildren, XmlElemNew(xroot,"CATEGORY"));
					mircoonly_node = env_node.xmlChildren[ArrayLen(env_node.xmlChildren)];
					mircoonly_node.XmlAttributes.label = "MICROBIAL ONLY";
					mircoonly_node.XmlAttributes.value = struct['MICROONLY'];
					
					// add top micorbial node
					ArrayAppend(env_node.xmlChildren, XmlElemNew(xroot,"CATEGORY"));
					topmicro_node = env_node.xmlChildren[ArrayLen(env_node.xmlChildren)];
					topmicro_node.XmlAttributes.label = "TOP MICROBIAL";
					topmicro_node.XmlAttributes.value = struct['TOPMICRO'];
					
					// add fxn node
					ArrayAppend(env_node.xmlChildren, XmlElemNew(xroot,"CATEGORY"));
					fxn_node = env_node.xmlChildren[ArrayLen(env_node.xmlChildren)];
					fxn_node.XmlAttributes.label = "FUNCTIONAL";
					fxn_node.XmlAttributes.value = struct['FXN'];
					
					// add unassigned fxn node
					ArrayAppend(env_node.xmlChildren, XmlElemNew(xroot,"CATEGORY"));
					unfxn_node = env_node.xmlChildren[ArrayLen(env_node.xmlChildren)];
					unfxn_node.XmlAttributes.label = "UNASSIGN FUNCTION";
					unfxn_node.XmlAttributes.value = struct['UNASSIGNFXN'];
					
					// add trna node
					ArrayAppend(env_node.xmlChildren, XmlElemNew(xroot,"CATEGORY"));
					trna_node = env_node.xmlChildren[ArrayLen(env_node.xmlChildren)];
					trna_node.XmlAttributes.label = "tRNA";
					trna_node.XmlAttributes.value = struct['TRNA'];
					
					// add rrna node
					ArrayAppend(env_node.xmlChildren, XmlElemNew(xroot,"CATEGORY"));
					rrna_node = env_node.xmlChildren[ArrayLen(env_node.xmlChildren)];
					rrna_node.XmlAttributes.label = "rRNA";
					rrna_node.XmlAttributes.value = struct['RRNA'];
				</cfscript>
			</cfoutput> <!--- end environment --->
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - ORFOVERVIEW", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn xroot/>
	</cffunction>
	
	<cffunction name="properMySQLList" access="private" returntype="string"
		hint="Create a proper list where each element is surrounded by single quote, and delimted by comma 
			  for MySQL where statement">
			  
		<cfargument name="aList" type="string" required="true" hint="original list of items"/>
		<cfargument name="cList" type="string" required="true" hint="update list to return"/>
		
		<cftry>
			<cfloop list="#aList#" index="vl">
				<!--- only list itme is itself a list delimited my semi-colon only take first item
						eg: acc1;acc2;acc3 --->
				<cfset pos = Find(";",vl,0)>
				<cfif pos gt 0>
					<cfset vl = mid(vl,1,pos-1)/>
				</cfif>
				
				<cfif len(cList)>
					<cfset cList &= ",'" & vl & "'"/>
				<cfelse>
					<cfset cList = "'" & vl & "'"/>
				</cfif>
			</cfloop>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETACLAMEBREAKDOWN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn cList/>
	</cffunction>
		
	<cffunction name="CreateFXNStruct" access="private" returntype="struct"
		hint="Create complex array of struct for deep fxnl tree">
		
		<cfargument name="arr" type="array" required="true" hint="array object in which to add/update struct"/>
		<cfargument name="fxn" type="string" required="true" hint="fxnl string to add/update"/>
		<cfargument name="sequenceId" type="numeric" required="true" hint="seqID associated with fxn"/>
		<cfargument name="nextFxn" type="string" required="true" hint="empty struct name that might follow"/>
		
		<cftry>
			<cfscript>
				//flag to see if fxn exist
				keyFound = false;
				
				//loop through array of struct
				for (i=1; i<=Arraylen(arguments.arr); i++){
					//if fxn already exist update struct values
					if (StructKeyExists(arguments.arr[i],lcase(trim(fxn)))){
						//update fxn1 values
						StructUpdate(arguments.arr[i],'value',arguments.arr[i]['value']+1);
						StructUpdate(arguments.arr[i],'idList',arguments.arr[i]['idList']&","&merge.sequenceId);
						keyFound = true;
						idx = i;
					}
				}
				//if fxn does not exist create new struct and add to array
				if (not keyFound){
					sfxn1 = structNew();
					structInsert(sfxn1,lcase(trim(fxn)),lcase(trim(fxn)));
					structInsert(sfxn1,'value',1);
					structInsert(sfxn1,'idList',merge.sequenceId);
					structInsert(sfxn1,nextFxn,ArrayNew(1));
					ArrayAppend(arguments.arr,sfxn1);
					idx = arraylen(arguments.arr);
				}
				//return index of struct updated/added
				//and up-to date array of struct.
				s = structnew();
				s.keyidx = idx;
				s.arr = arguments.arr;
				return s;
			</cfscript>
		
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETACLAMEBREAKDOWN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="RecursiveXMLDoc" access="private" returntype="Any" 
		hint="recursively create entire xml document from complex array of struct passed">
		
		<cfargument name="xroot" type="xml" required="true" hint="xml document object">
		<cfargument name="xnode" type="any" required="true" hint="xml node to add">
		<cfargument name="fxn_no" type="numeric" required="true" hint="which function to add">
		<cfargument name="arr" type="array" required="true" hint="complex array of struct object">
		<cfargument name="upto" type="numeric" required="true" hint="recurse upto this number">
		<cfargument name="tagCount" type="numeric" default="1" hint="keep count of total number tags">
		<cfargument name="idFName" type="string" required="true" hint="idFName where idTags will be stored">
		
		<cftry>
			<!--- stop condition --->
			<cfif upto lt 1>
				<!---ending recursion, not doing anything with return value, make sure return value is not numeric--->
				<cfreturn xnode/>
			<cfelse>
				<!--- loop through arry of struct to add each element onto xml node --->
				<cfloop from="1" to="#ArrayLen(arr)#" index="i">
					<!--- create new xml node and add it as a child to XNODE --->
					<cfscript>
						ArrayAppend(xnode.xmlChildren,XmlElemNew(xroot,"FUNCTION_"&#fxn_no#));
						newNode = xnode.xmlChildren[ArrayLen(xnode.xmlChildren)];
						
						keyToStruct = structkeyarray(arr[i]);
						//get name and label of the function.
						for (p=1; p<=arrayLen(keyToStruct); p++){
							if (not ((REFindNoCase('idList',keyToStruct[p])) or (REFindNoCase('value',keyToStruct[p])) or (REFindNoCase('fxn.*',keyToStruct[p])))){
								newNode.XmlAttributes.name = UCASE(keyToStruct[p]);
								newNode.XmlAttributes.label = UCase(keyToStruct[p]);
							}
						}
					
						newNode.XmlAttributes.value = arr[i]['value'];
						newNode.XmlAttributes.tag = "TAG_" & ++arguments.tagCount;
						newNode.XmlAttributes.idFName = arguments.idFName;
						//newNode.XmlAttributes.idList = arr[i]['idList'];
						//arguments.tagCount+=1;
						
						f = "fxn"&fxn_no+1;
						
						//add children of this node
						t_return = RecursiveXMLDoc(xroot=arguments.xroot,xnode=newNode,fxn_no=arguments.fxn_no+1,arr=arguments.arr[i][f],upto=arguments.upto-1,tagCount=arguments.tagCount,idFName=arguments.idFName);
					    if (isstruct(t_return))
							arguments.tagCount = t_return['count'];
					</cfscript>
				</cfloop>
				<!--- return complete xml doc --->
				<cfset tstruct = StructNew()/>
				<cfset tstruct['count'] = arguments.tagCount++/>
				<cfset tstruct['doc'] = xroot/>
				<cfreturn tstruct/>
			</cfif>
		
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - RECURSIVEXMLDOC", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="RecursiveIDXMLDoc" access="private" returntype="Any" 
		hint="recursively create entire xml document from complex array of struct passed">
		
		<cfargument name="xroot" type="xml" required="true" hint="xml document object">
		<cfargument name="xnode" type="any" required="true" hint="xml node to add">
		<cfargument name="fxn_no" type="numeric" required="true" hint="which function to add">
		<cfargument name="arr" type="array" required="true" hint="complex array of struct object">
		<cfargument name="upto" type="numeric" required="true" hint="recurse upto this number">
		<cfargument name="tagCount" type="numeric" default="1" hint="keep count of total number tags">
		
		<cftry>
			<!--- stop condition --->
			<cfif upto lt 1>
				<!---ending recursion, not doing anything with return value, make sure return value is not numeric--->
				<cfreturn xnode/>
			<cfelse>
				<!--- loop through arry of struct to add each element onto xml node --->
				<cfloop from="1" to="#ArrayLen(arr)#" index="i">
					<!--- create new xml node and add it as a child to XNODE --->
					<cfscript>
						ArrayAppend(xnode.xmlChildren,XmlElemNew(xroot,"TAG_" & ++arguments.tagCount));
						newNode = xnode.xmlChildren[ArrayLen(xnode.xmlChildren)];
						newNode.XmlAttributes.idList = arr[i]['idList'];
						
						//arguments.tagCount+=1;
						
						//next node
						f = "fxn"&fxn_no+1;
						
						//add children of root.  Not nesting xml elements here to make search of tags easier.
						t_return = RecursiveIDXMLDoc(xroot=arguments.xroot,xnode=arguments.xnode,fxn_no=arguments.fxn_no+1,arr=arguments.arr[i][f],upto=arguments.upto-1,tagCount=arguments.tagCount);
						if (isstruct(t_return))
							arguments.tagCount = t_return['count'];
					</cfscript>
				</cfloop>
				<!--- return complete xml doc --->
				<cfset tstruct = StructNew()/>
				<cfset tstruct['count'] = arguments.tagCount++/>
				<cfset tstruct['doc'] = xroot/>
				<cfreturn tstruct/>
			</cfif>
		
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - RECURSIVEIDXMLDOC", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="getAllFxnalDbBreakdown" access="private" returntype="xml"
		hint="Get functional breakdown for a given library">
		<cfargument name="library" type="numeric" required="true"/>
		<cfargument name="environment" type="string" required="true"/>
		
		<cfset xroot = XMLNew()>
		<cfset xroot.xmlRoot = XMLElemNew(xroot,"root")>
		<cfset root = xroot.xmlRoot>
		
		<cftry>
			<cfset serverObj=CreateObject("component", application.cfc & ".Utility").getServerName(environment=arguments.environment)/>
			
			<!--- get seed counts --->
			<cfset aclame_qry = getBlastHits(server=serverObj.server,library=arguments.library,database="ACLAME",fxnHit=1)/>
			<cfset cog_qry = getBlastHits(server=serverObj.server,library=arguments.library,database="COG",fxnHit=1)/>
			<cfset kegg_qry = getBlastHits(server=serverObj.server,library=arguments.library,database="KEGG",fxnHit=1)/>
			<cfset seed_qry = getBlastHits(server=serverObj.server,library=arguments.library,database="SEED",fxnHit=1)/>
			<cfset uniref_qry = getBlastHits(server=serverObj.server,library=arguments.library,database="UNIREF100P",fxnHit=1)/>
			
			<cfset aclame_id = valuelist(aclame_qry.sequenceId)/>
			<cfset cog_id = valuelist(cog_qry.sequenceId)/>
			<cfset kegg_id = valuelist(kegg_qry.sequenceId)/>
			<cfset seed_id = valuelist(seed_qry.sequenceId)/>
			<cfset uniref_id = valuelist(uniref_qry.sequenceId)/>
			
			<cfset aclame_cnt = listlen(aclame_id,",")/>
			<cfset cog_cnt = listlen(cog_id,",")/>
			<cfset kegg_cnt = listlen(kegg_id,",")/>
			<cfset seed_cnt = listlen(seed_id,",")/>
			<cfset uniref_cnt = listlen(uniref_id,",")/>
			
			<cfscript>
				ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
				acl = root.xmlChildren[ArrayLen(root.xmlChildren)];
				acl.XmlAttributes.label = "ACLAME";
				acl.XmlAttributes.value = aclame_cnt;
				acl.XmlAttributes.idList = #iif(len(aclame_id), "aclame_id", """NULL""")#;

				ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
				cog = root.xmlChildren[ArrayLen(root.xmlChildren)];
				cog.XmlAttributes.label = "COG";
				cog.XmlAttributes.value = cog_cnt;
				cog.XmlAttributes.idList = #iif(len(cog_id), "cog_id", """NULL""")#;

				ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
				goc = root.xmlChildren[ArrayLen(root.xmlChildren)];
				goc.XmlAttributes.label = "GO";
				goc.XmlAttributes.value = uniref_cnt;
				goc.XmlAttributes.idList = #iif(len(uniref_id), "uniref_id", """NULL""")#;

				ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
				keg = root.xmlChildren[ArrayLen(root.xmlChildren)];
				keg.XmlAttributes.label = "KEGG";
				keg.XmlAttributes.value = kegg_cnt;
				keg.XmlAttributes.idList = #iif(len(kegg_id), "kegg_id", """NULL""")#;

				ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
				sed = root.xmlChildren[ArrayLen(root.xmlChildren)];
				sed.XmlAttributes.label = "SEED";
				sed.XmlAttributes.value = seed_cnt;
				sed.XmlAttributes.idList = #iif(len(seed_id), "seed_id", """NULL""")#;
			</cfscript>
			
			<cfreturn xroot/>
		
		 	<cfcatch type="any">
		 		<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETALLFXNALDBBREAKDOWN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
		 	</cfcatch>			
		</cftry>
		
		<cfreturn xroot/>
	</cffunction>
	
	<cffunction name="getFxnalDbBreakdown" access="private" returntype="struct"
		hint="Get ACLAME/GO functional summary for a give database.">
		<cfargument name="libraryId" type="numeric" required="true"/>
		<cfargument name="environment" type="string" required="true"/>
		<cfargument name="database" type="string" required="true"/>
		<cfargument name="idFName" type="String" required="true" />
		
		<!--- create new xml object --->
		<cfset xroot = XMLNew()>
		<cfset xroot.xmlRoot = XMLElemNew(xroot,"root")>
		<cfset root = xroot.xmlRoot>
		
		
		<cfset idXRoot = XMLNew()>
		<cfset idXRoot.xmlRoot = XMLElemNew(idXRoot,"root")>
		<cfset idRoot = idXRoot.xmlRoot>
		
		<cftry>
			<!--- get server name --->
			<cfset serverObj=CreateObject("component", application.cfc & ".Utility").getServerName(environment=arguments.environment)/>
			
			<!--- get all sequenceIds and hit_names where database is aclame, and is top fxnl hit --->
			<cfset accQuery = getAccList(libraryId=arguments.libraryId,server=serverObj.server,database=UCASE(arguments.database))/>
			
			<!--- convert query to struct --->
			<cfset accStruct = CreateObject("component", application.cfc & ".Utility").QueryToStructure(accQuery,'sequenceId')/>
			
			<!--- get list of hit names --->
			<cfset aList = valuelist(accQuery.hit_name)/>
			
			<!--- check if library has requested db hits. --->
			<cfif len(aList)>			
				<!--- create proper list of accessions for sql query --->
				<cfset cList = properMySQLList(aList,'')/>
				
				<!--- get all fxn info for hit names from respective table --->
				<cfset fxn_table = arguments.database/>
				<cfif arguments.database eq 'aclame'>
					<cfset fxn_table = 'aclamefxn'/>
				<cfelseif arguments.database eq 'uniref100p'>
					<cfset fxn_table = 'gofxn'/>
				</cfif>
				<cfset fxn = getFxnalDbQuery(acc=cList,database=fxn_table)/>
				
				<!--- create new query object that holds all fxn info and its associated sequences --->
				<cfset merge = QueryNew(fxn.columnList)/>
				<cfset QueryAddColumn(merge, "SequenceId", ArrayNew(1))/>
						
				<!--- merge sequence id with fxn list --->
				<cfset LOCAL.Columns = ListToArray( fxn.ColumnList ) />
				<cfset currentRowCount = 1/>
				
				<cfloop query="fxn">
					<cfset t_arr = StructFindValue(accStruct,trim(fxn.realacc),"all")/>
					<cfloop from="1" to="#arrayLen(t_arr)#" index="idx" step="1">
						<cfset queryaddrow(merge,1)>
						<cfloop index="LOCAL.Column" from="1" to="#ArrayLen(LOCAL.Columns)#" step="1">
							<cfset LOCAL.ColumnName = LOCAL.Columns[ LOCAL.Column ] />
							<cfset merge[ LOCAL.ColumnName ][ merge.RecordCount ] = fxn[ LOCAL.ColumnName ][ fxn.CurrentRow ] />
						</cfloop>
					
						<cfset merge["SequenceId"][merge.RecordCount] = t_arr[idx].owner.sequenceId/>
					</cfloop>
				</cfloop>
				
				<!--- start of complex array of struct --->	
				<cfset arr = ArrayNew(1)/>
				
				<!--- loop through query per each group and create complex array of struct --->	
				<cfoutput query="merge" group="fxn1">
					<cfoutput>
						<!--- create struct of all fxn1 items --->
						<cfscript>
							s = CreateFXNStruct(arr,merge.fxn1,merge.sequenceId,'fxn2');
							keyIndex1 = s.keyidx;
							arr = s.arr;
						</cfscript>
					</cfoutput>
					<cfoutput group="fxn2">
						<cfoutput>
							<!--- create struct of all fxn2 items --->
							<cfscript>
								fxn2_arr = arr[keyIndex1].fxn2;
								s = CreateFXNStruct(fxn2_arr,merge.fxn2,merge.sequenceId,'fxn3');
								keyIndex2 = s.keyidx;
								fxn2_arr = s.arr;
								
								structUpdate(arr[keyIndex1],'fxn2',fxn2_arr);
							</cfscript>
						</cfoutput>
						<cfoutput group="fxn3">
							<cfoutput>
								<!--- create struct of all fxn3 items --->
								<cfscript>
									fxn3_arr = arr[keyIndex1].fxn2[keyIndex2].fxn3;
									s = CreateFXNStruct(fxn3_arr,merge.fxn3,merge.sequenceId,'fxn4');
									keyIndex3 = s.keyidx;
									fxn3_arr = s.arr;
									
									structUpdate(arr[keyIndex1].fxn2[keyIndex2],'fxn3',fxn3_arr);			
								</cfscript>
							</cfoutput>
							
							<!--- if aclame or go/uniref100p include fxn4..6 --->
							<cfif (arguments.database eq 'aclame') or (arguments.database eq 'uniref100p')>
							
								<cfoutput group="fxn4">
									<cfoutput>
										<!--- create struct of all fxn4 items --->
										<cfscript>
											fxn4_arr = arr[keyIndex1].fxn2[keyIndex2].fxn3[keyIndex3].fxn4;
											s = CreateFXNStruct(fxn4_arr,merge.fxn4,merge.sequenceId,'fxn5');
											keyIndex4 = s.keyidx;
											fxn4_arr = s.arr;
											
											structUpdate(arr[keyIndex1].fxn2[keyIndex2].fxn3[keyIndex3],'fxn4',fxn4_arr);			
										</cfscript>
									</cfoutput>
									<cfoutput group="fxn5">
										<cfoutput>
											<!--- create struct of all fxn5 items --->
											<cfscript>
												fxn5_arr = arr[keyIndex1].fxn2[keyIndex2].fxn3[keyIndex3].fxn4[keyIndex4].fxn5;
												s = CreateFXNStruct(fxn5_arr,merge.fxn5,merge.sequenceId,'fxn6');
												keyIndex5 = s.keyidx;
												fxn5_arr = s.arr;
												
												structUpdate(arr[keyIndex1].fxn2[keyIndex2].fxn3[keyIndex3].fxn4[keyIndex4],'fxn5',fxn5_arr);			
											</cfscript>
										</cfoutput>
										<cfoutput group="fxn6">
											<cfoutput>
												<!--- create struct of all fxn6 items --->
												<cfscript>
													fxn6_arr = arr[keyIndex1].fxn2[keyIndex2].fxn3[keyIndex3].fxn4[keyIndex4].fxn5[keyIndex5].fxn6;
													s = CreateFXNStruct(fxn6_arr,merge.fxn6,merge.sequenceId,'fxn7');
													keyIndex6 = s.keyidx;
													fxn6_arr = s.arr;
													
													structUpdate(arr[keyIndex1].fxn2[keyIndex2].fxn3[keyIndex3].fxn4[keyIndex4].fxn5[keyIndex5],'fxn6',fxn6_arr);			
												</cfscript>
											</cfoutput>
										</cfoutput> <!--- end fxn6 --->
									</cfoutput> <!--- end fxn5 --->
								</cfoutput> <!--- end fxn4 --->
								
							</cfif> <!--- check to see if aclame or go db fxn was called --->
							
						</cfoutput> <!--- end fxn3 --->
					</cfoutput> <!--- end fxn2 --->
				</cfoutput> <!--- end fxn1 --->
				
				<cfif (arguments.database eq 'aclame') or (arguments.database eq 'uniref100p')>
					<cfset xroot = RecursiveXMLDoc(xroot=xroot,xnode=root,fxn_no=1,arr=arr,upto=6,tagCount=0,idFName=arguments.idFName)/>
					<cfset idXRoot = RecursiveIDXMLDoc(xroot=idXRoot,xnode=idRoot,fxn_no=1,arr=arr,upto=6,tagCount=0)/>
				<cfelse>
					<cfset xroot = RecursiveXMLDoc(xroot=xroot,xnode=root,fxn_no=1,arr=arr,upto=3,tagCount=1,idFName=arguments.idFName)/>
					<cfset idXRoot = RecursiveIDXMLDoc(xroot=idXRoot,xnode=idRoot,fxn_no=1,arr=arr,upto=3,tagCount=1)/>
				</cfif>
				
				<cfset xStruct = StructNew()/>
				<cfset xStruct['xroot'] = xroot['doc']/>
				<cfset xStruct['idroot'] = idXRoot['doc']/>
				
			</cfif> <!--- end check if library have db hits --->
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETFXNALDBBREAKDOWN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn xStruct/>
	</cffunction>
	
	<cffunction name="getTaxonomyBreakDown" access="private" returntype="struct"
		hint="get taxonomy break down for a given library">
		<cfargument name="libraryId" type="numeric" required="true" />
		<cfargument name="environment" type="string" required="true" />
		<cfargument name="idFName" type="string" required="true"/>
		
		<cfset xroot = XMLNew()>
		<cfset xroot.xmlRoot = XMLElemNew(xroot,"root")>
		<cfset root = xroot.xmlRoot>
		
		<cfset idXRoot = XMLNew()>
		<cfset idXRoot.xmlRoot = XMLElemNew(idXRoot,"root")>
		<cfset idRoot = idXRoot.xmlRoot>
		
		<cftry>
			<cfset serverObj=CreateObject("component", application.cfc & ".Utility").getServerName(environment=arguments.environment)/>
			<cfset tq = getTaxonomyHelper(libraryId=arguments.libraryId,server=serverObj.server)/>
			
			<cfset dprev="null"/>
			<cfset dcurr=""/>
			<cfset tagCount = 1/>
			
			<cfoutput query="tq" group="domain">
				<cfset dcurr = tq.domain/>
				<cfif dprev neq dcurr>
					<cfset dprev=dcurr>
					<!--- domain --->
					<cfset dcount = 0>
					<cfset dList = "">
					<cfoutput>
						<cfscript>
							dcount += 1;
							if (len(dList))
								dList &= "," & tq.sequenceId;
							else dList = tq.sequenceId;
						</cfscript>					
					</cfoutput>
					
					<cfscript>
						if (NOT (len(tq.domain)))
							tq.domain = "UNKNOWN DOMAIN";
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"DOMAIN"));
						dnode = root.xmlChildren[ArrayLen(root.xmlChildren)];
	
						dnode.XmlAttributes.name = tq.domain;
						dnode.XmlAttributes.label = tq.domain;
						dnode.XmlAttributes.value = dcount;
						dnode.XmlAttributes.tag = "TAG_"&tagCount;
						dnode.XmlAttributes.idFName = arguments.idFName;
						//dnode.XmlAttributes.idList = dList;
						
						//id xml nodes
						ArrayAppend(idRoot.xmlChildren,XmlElemNew(idXRoot,"TAG_"&tagCount));
						idNode = idRoot.xmlChildren[ArrayLen(idRoot.xmlChildren)];
						idNode.XmlAttributes.idList = dList;
						
						tagCount++;
					</cfscript>
				</cfif>	
					
				<!--- kindom --->
				<cfset kprev="null"/>
				<cfset kcurr=""/>
				<cfoutput group="kingdom">
					<cfset kcurr = tq.kingdom/>
			
					<cfif kprev neq kcurr>
						<cfset kprev=kcurr/>
						<cfset kcount = 0/>
						<cfset kList = ""/>
						<cfoutput>
							<cfscript>
								kcount +=1;
								if (len(kList))
									kList &= "," & tq.sequenceId;
								else kList = tq.sequenceId;
							</cfscript>
						</cfoutput>
						<cfscript>
							if (NOT (len(tq.kingdom)))
								tq.kingdom = "UNKNOWN KINGDOM";
							ArrayAppend(dnode.xmlChildren,XmlElemNew(xroot,"KINGDOM"));
							knode = dnode.xmlChildren[ArrayLen(dnode.xmlChildren)];
		
							knode.XmlAttributes.name = tq.kingdom;
							knode.XmlAttributes.label = tq.kingdom;
							knode.XmlAttributes.value = kcount;
							knode.XmlAttributes.tag = "TAG_"&tagCount;
							knode.XmlAttributes.idFName = arguments.idFName;
							//knode.XmlAttributes.idList = kList;
							
							//id xml nodes
							ArrayAppend(idRoot.xmlChildren,XmlElemNew(idXRoot,"TAG_"&tagCount));
							idNode = idRoot.xmlChildren[ArrayLen(idRoot.xmlChildren)];
							idNode.XmlAttributes.idList = kList;
							
							tagCount++;
						</cfscript>
					</cfif>
					
					<!--- phylum --->
					<cfset pprev="null"/>
					<cfset pcurr=""/>
					<cfoutput group="phylum">
						<cfset pcurr = tq.phylum/>
						
						<cfif pprev neq pcurr>
							<cfset pprev=pcurr/>
							<cfset pcount = 0/>
							<cfset pList = ""/>
							<cfoutput>
								<cfscript>
									pcount +=1;
									if (len(pList))
										pList &= "," & tq.sequenceId;
									else pList = tq.sequenceId;
								</cfscript>
							</cfoutput>
							<cfscript>
								if (NOT (len(tq.phylum)))
									tq.phylum = "UNKNOWN PHYLUM";
								ArrayAppend(knode.xmlChildren,XmlElemNew(xroot,"PHYLUM"));
								pnode = knode.xmlChildren[ArrayLen(knode.xmlChildren)];
			
								pnode.XmlAttributes.name = tq.phylum;
								pnode.XmlAttributes.label = tq.phylum;
								pnode.XmlAttributes.value = pcount;
								pnode.XmlAttributes.tag = "TAG_"&tagCount;
								pnode.XmlAttributes.idFName = arguments.idFName;
								//pnode.XmlAttributes.idList = pList;
								
								//id xml nodes
								ArrayAppend(idRoot.xmlChildren,XmlElemNew(idXRoot,"TAG_"&tagCount));
								idNode = idRoot.xmlChildren[ArrayLen(idRoot.xmlChildren)];
								idNode.XmlAttributes.idList = pList;
								
								tagCount++;
							</cfscript>
						</cfif>
						
						<!--- class --->
						<cfset cprev="null"/>
						<cfset ccurr=""/>
						<cfoutput group="class">
							<cfset ccurr = tq.class/>
							
							<cfif cprev neq ccurr>
								<cfset cprev=ccurr/>
								<cfset ccount=0/>
								<cfset cList = ""/>
								<cfoutput>
									<cfscript>
										ccount +=1;
										if (len(cList))
											cList &= "," & tq.sequenceId;
										else cList = tq.sequenceId;
									</cfscript>
								</cfoutput>
								<cfscript>
									if (NOT (len(tq.class)))
										tq.class = "UNKNOWN CLASS";
									ArrayAppend(pnode.xmlChildren,XmlElemNew(xroot,"CLASS"));
									cnode = pnode.xmlChildren[ArrayLen(pnode.xmlChildren)];
				
									cnode.XmlAttributes.name = tq.class;
									cnode.XmlAttributes.label = tq.class;
									cnode.XmlAttributes.value = ccount;
									cnode.XmlAttributes.tag = "TAG_"&tagCount;
									cnode.XmlAttributes.idFName = arguments.idFName;
									//cnode.XmlAttributes.idList = cList;
									
									//id xml nodes
									ArrayAppend(idRoot.xmlChildren,XmlElemNew(idXRoot,"TAG_"&tagCount));
									idNode = idRoot.xmlChildren[ArrayLen(idRoot.xmlChildren)];
									idNode.XmlAttributes.idList = cList;
									
									tagCount++;
								</cfscript>
							</cfif>
							
							<!--- order --->
							<cfset oprev="null"/>
							<cfset ocurr=""/>
							<cfoutput group="order">
								<cfset ocurr = tq.order/>
								
								<cfif oprev neq ocurr>
									<cfset oprev=ocurr/>
									<cfset ocount=0/>
									<cfset oList = ""/>
									<cfoutput>
										<cfscript>
											ocount +=1;
											if (len(oList))
												oList &= "," & tq.sequenceId;
											else oList = tq.sequenceId;
										</cfscript>
									</cfoutput>
									<cfscript>
										if (NOT (len(tq.order)))
											tq.order = "UNKNOWN ORDER";
										ArrayAppend(cnode.xmlChildren,XmlElemNew(xroot,"ORDER"));
										onode = cnode.xmlChildren[ArrayLen(cnode.xmlChildren)];
					
										onode.XmlAttributes.name = tq.order;
										onode.XmlAttributes.label = tq.order;
										onode.XmlAttributes.value = ocount;
										onode.XmlAttributes.tag = "TAG_"&tagCount;
										onode.XmlAttributes.idFName = arguments.idFName;
										//onode.XmlAttributes.idList = oList;
										
										//id xml nodes
										ArrayAppend(idRoot.xmlChildren,XmlElemNew(idXRoot,"TAG_"&tagCount));
										idNode = idRoot.xmlChildren[ArrayLen(idRoot.xmlChildren)];
										idNode.XmlAttributes.idList = oList;
										
										tagCount++;
									</cfscript>
								</cfif>
								
								<!--- family --->
								<cfset fprev="null"/>
								<cfset fcurr=""/>
								<cfoutput group="family">
									<cfset fcurr = tq.family/>
									
									<cfif fprev neq fcurr>
										<cfset fprev=fcurr/>
										<cfset fcount=0/>
										<cfset fList = ""/>
										<cfoutput>
											<cfscript>
												fcount +=1;
												if (len(fList))
													fList &= "," & tq.sequenceId;
												else fList = tq.sequenceId;
											</cfscript>
										</cfoutput>
										<cfscript>
											if (NOT (len(tq.family)))
												tq.family = "UNKNOWN FAMILY";
											ArrayAppend(onode.xmlChildren,XmlElemNew(xroot,"FAMILY"));
											fnode = onode.xmlChildren[ArrayLen(onode.xmlChildren)];
						
											fnode.XmlAttributes.name = tq.family;
											fnode.XmlAttributes.label = tq.family;
											fnode.XmlAttributes.value = fcount;
											fnode.XmlAttributes.tag = "TAG_"&tagCount;
											fnode.XmlAttributes.idFName = arguments.idFName;
											//fnode.XmlAttributes.idList = fList;
											
											//id xml nodes
											ArrayAppend(idRoot.xmlChildren,XmlElemNew(idXRoot,"TAG_"&tagCount));
											idNode = idRoot.xmlChildren[ArrayLen(idRoot.xmlChildren)];
											idNode.XmlAttributes.idList = fList;
											
											tagCount++;
										</cfscript>
									</cfif>
									
									<!--- genus --->
									<cfset gprev="null"/>
									<cfset gcurr=""/>
									<cfoutput group="genus">
										<cfset gcurr = tq.genus/>
										
										<cfif gprev neq gcurr>
											<cfset gprev=gcurr/>
											<cfset gcount=0/>
											<cfset gList = ""/>
											<cfoutput>
												<cfscript>
													gcount +=1;
													if (len(gList))
														gList &= "," & tq.sequenceId;
													else gList = tq.sequenceId;
												</cfscript>
											</cfoutput>
											<cfscript>
												if (NOT (len(tq.genus)))
													tq.genus = "UNKNOWN GENUS";
												ArrayAppend(fnode.xmlChildren,XmlElemNew(xroot,"GENUS"));
												gnode = fnode.xmlChildren[ArrayLen(fnode.xmlChildren)];
							
												gnode.XmlAttributes.name = tq.genus;
												gnode.XmlAttributes.label = tq.genus;
												gnode.XmlAttributes.value = gcount;
												gnode.XmlAttributes.tag = "TAG_"&tagCount;
												gnode.XmlAttributes.idFName = arguments.idFName;
												//gnode.XmlAttributes.idList = gList;
												
												//id xml nodes
												ArrayAppend(idRoot.xmlChildren,XmlElemNew(idXRoot,"TAG_"&tagCount));
												idNode = idRoot.xmlChildren[ArrayLen(idRoot.xmlChildren)];
												idNode.XmlAttributes.idList = gList;
												
												tagCount++;
											</cfscript>
										</cfif>
										
										<!--- species --->
										<cfset sprev="null"/>
										<cfset scurr=""/>
										<cfoutput group="species">
											<cfset scurr = tq.species/>
											
											<cfif sprev neq scurr>
												<cfset sprev=scurr/>
												<cfset scount=0/>
												<cfset sList = ""/>
												<cfoutput>
													<cfscript>
														scount +=1;
														if (len(sList))
															sList &= "," & tq.sequenceId;
														else sList = tq.sequenceId;
													</cfscript>
												</cfoutput>
												<cfscript>
													if (NOT (len(tq.species)))
														tq.species = "UNKNOWN SPECIES";
													ArrayAppend(gnode.xmlChildren,XmlElemNew(xroot,"SPECIES"));
													snode = gnode.xmlChildren[ArrayLen(gnode.xmlChildren)];
								
													snode.XmlAttributes.name = tq.species;
													snode.XmlAttributes.label = tq.species;
													snode.XmlAttributes.value = scount;
													snode.XmlAttributes.tag = "TAG_"&tagCount;
													snode.XmlAttributes.idFName = arguments.idFName;
													//snode.XmlAttributes.idList = sList;
													
													//id xml nodes
													ArrayAppend(idRoot.xmlChildren,XmlElemNew(idXRoot,"TAG_"&tagCount));
													idNode = idRoot.xmlChildren[ArrayLen(idRoot.xmlChildren)];
													idNode.XmlAttributes.idList = sList;
													
													tagCount++;
												</cfscript>
											</cfif>
											
											<!--- orgranism --->
											<cfset orprev="null"/>
											<cfset orcurr=""/>
											<cfoutput group="organism">
												<cfset orcurr = tq.organism/>
												
												<cfif orprev neq orcurr>
													<cfset orprev=orcurr/>
													<cfset orcount=0/>
													<cfset orList = ""/>
													<cfoutput>
														<cfscript>
															orcount +=1;
															if (len(orList))
																orList &= "," & tq.sequenceId;
															else orList = tq.sequenceId;
														</cfscript>
													</cfoutput>
													<cfscript>
														if (NOT (len(tq.organism)))
															tq.organism = "UNKNOWN ORGANISM";
														ArrayAppend(snode.xmlChildren,XmlElemNew(xroot,"ORGANISM"));
														ornode = snode.xmlChildren[ArrayLen(snode.xmlChildren)];
									
														ornode.XmlAttributes.name = tq.organism;
														ornode.XmlAttributes.label = tq.organism;
														ornode.XmlAttributes.value = orcount;
														ornode.XmlAttributes.tag = "TAG_"&tagCount;
														ornode.XmlAttributes.idFName = arguments.idFName;
														//knode.XmlAttributes.idList = orList;
														
														//id xml nodes
														ArrayAppend(idRoot.xmlChildren,XmlElemNew(idXRoot,"TAG_"&tagCount));
														idNode = idRoot.xmlChildren[ArrayLen(idRoot.xmlChildren)];
														idNode.XmlAttributes.idList = orList;
														
														tagCount++;
													</cfscript>
												</cfif>
											</cfoutput><!--- end output loop for organism --->
										</cfoutput><!--- end output loop for species --->
									</cfoutput><!--- end output loop for genus --->
								</cfoutput><!--- end output loop for family --->
							</cfoutput><!--- end output loop for order --->
						</cfoutput><!--- end output loop for class --->
					</cfoutput><!--- end ouptut loop for phylum --->
				</cfoutput><!--- end output loop for kindom --->				
			</cfoutput><!--- end output loop for domain --->
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETTAXONOMYBREAKDOWN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfset xStruct = StructNew()/>
		<cfset xStruct['xroot'] = xroot/>
		<cfset xStruct['idRoot'] = idXRoot/>
		
		<cfreturn xStruct/>
	</cffunction>

	<cffunction name="getEnvironment" access="private" returntype="xml">
		<cfargument name="libraryId" type="numeric" required="true"/>
		<cfargument name="type" type="string" required="true"/>
		
		<cfset xdoc = ""/>
		
		<cftry>
			<cfset filename = UCASE(type) & "_XMLDOC_" & arguments.libraryId & ".xml"/>
			<cffile action="read" file="#application.xDocsFilePath#/#filename#" variable="stats"/>
			
			<cfset xdoc = XMLPARSE(stats)/>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETENVIRONMENT", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn xdoc/>
	</cffunction>

	<cffunction name="getVIROMEClass" access="remote" returntype="Struct"
		hint="Get VIROME classification summary for a given library">
		<cfargument name="libId" type="numeric" required="true"/>
		<cfargument name="environment" type="string" required="true"/>
				
		<cfset globalStruct = StructNew()/>
		<cfset xroot = XMLNew()>
		<cfset xroot.xmlRoot = XMLElemNew(xroot,"root")>
		<cfset root = xroot.xmlRoot>
		<cfset vfilename = "VIRClass_XMLDOC_"&arguments.libId&".xml"/>
		<cfset dbfilename = "DBBreakdown_XMLDOC_"&arguments.libId&".xml"/>

		 <cftry>
			 <cfdirectory action="list" name="fList" directory="#application.xDocsFilePath#" filter="#vfilename#"/>
	
			<cfif fList.recordcount eq 0>
			
			 	<cfset serverObj=CreateObject("component", application.cfc & ".Utility").getServerName(environment=arguments.environment)/>
			 	<cfset qry=getStatistics(server=serverObj.server,library=libId)/>
				
				<!--- update query ids --->
				<cffile action="read" file="#application.idFilePath#/fxnIdList_#arguments.libId#.txt" variable="qry.fxn_id"/>
				<cffile action="read" file="#application.idFilePath#/unClassIdList_#arguments.libId#.txt" variable="qry.unassignfxn_id"/>
				<cffile action="read" file="#application.idFilePath#/orfanList_#arguments.libId#.txt" variable="qry.orfan_id"/>
				
				<cfoutput query="qry">
					<cfset uniref_id = ValueList(qry.fxn_id)/>
					
					<cfscript>
						local.arr = ArrayNew(1);
						uniref_cnt = 0;					
						str = "";
						total = qry.tRNA_cnt + qry.rRNA_cnt + qry.fxn_cnt + 
								qry.unassignfxn_cnt + qry.topviral_cnt + qry.allviral_cnt +
								qry.topmicrobial_cnt + qry.allmicrobial_cnt + qry.orfan_cnt;
						//tRNA
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "tRNA";
						node.XmlAttributes.cat = "tRNA";
						node.XmlAttributes.value = ceiling((qry.tRNA_cnt/total)*100);
						//node.XmlAttributes.idList = #iif(len(qry.tRNA_id), "qry.tRNA_id", """NULL""")#;

						//rRNA
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "rRNA";
						node.XmlAttributes.cat = "rRNA";
						node.XmlAttributes.value = ceiling((qry.rRNA_cnt/total)*100);
						//node.XmlAttributes.idList = #iif(len(qry.rRNA_id), "qry.rRNA_id", """NULL""")#;

 						//functional
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "Possible functional protein";
						node.XmlAttributes.cat = "fxn";
						node.XmlAttributes.value = ceiling((qry.fxn_cnt/total)*100);
						//node.XmlAttributes.idList = #iif(len(qry.fxn_id), "qry.fxn_id", """NULL""")#;
						uniref_cnt += qry.fxn_cnt;

						//unfunctional
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "Unclassified protein";
						node.XmlAttributes.cat = "unassignfxn";
						node.XmlAttributes.value = ceiling((qry.unassignfxn_cnt/total)*100);
						//node.XmlAttributes.idList = #iif(len(qry.unassignfxn_id), "qry.unassignfxn_id", """NULL""")#;

						if (len(uniref_id))
							uniref_id &= "," & qry.unassignfxn_id;
						else uniref_id = qry.unassignfxn_id;
						uniref_cnt += qry.unassignfxn_cnt;
 
 						//top viral
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "Top-hit viral";
						node.XmlAttributes.cat = "topviral";
						node.XmlAttributes.value = ceiling((qry.topviral_cnt/total)*100);
						//node.XmlAttributes.idList = #iif(len(qry.topviral_id), "qry.topviral_id", """NULL""")#;

						//viral only
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "Viral only";
						node.XmlAttributes.cat = "allviral";
						node.XmlAttributes.value = ceiling((qry.allviral_cnt/total)*100);
						//node.XmlAttributes.idList = #iif(len(qry.allviral_id), "qry.allviral_id", """NULL""")#;

						//top microbial
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "Top-hit microbial";
						node.XmlAttributes.cat = "topmicrobial";
						node.XmlAttributes.value = ceiling((qry.topmicrobial_cnt/total)*100);
						//node.XmlAttributes.idList = #iif(len(qry.topmicrobial_id), "qry.topmicrobial_id", """NULL""")#;

						//microbial only
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "Microbial only";
						node.XmlAttributes.cat = "allmicrobial";
						node.XmlAttributes.value = ceiling((qry.allmicrobial_cnt/total)*100);
						//node.XmlAttributes.idList = #iif(len(qry.topmicrobial_id), "qry.topmicrobial_id", """NULL""")#;

						//orfan
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "ORFan";
						node.XmlAttributes.cat = "orfan";
						node.XmlAttributes.value = ceiling((qry.orfan_cnt/total)*100);
						//node.XmlAttributes.idList = #iif(len(qry.orfan_id), "qry.orfan_id", """NULL""")#;
					</cfscript>
					<cffile action="write" file="#application.xDocsFilePath#/#vfilename#" output="#xroot#" addnewline="true" />
					<cfset StructInsert(globalStruct,"VCLASS",xroot)/>
					 
					<cfset xroot = XMLNew()>
					<cfset xroot.xmlRoot = XMLElemNew(xroot,"root")>
					<cfset root = xroot.xmlRoot>
					
					<!---get all metagenome blast results---> 
					<cfset mgolH=getBlastHits(server=serverObj.server,library=libId,database="METAGENOMES",topHit=1)/>
					<cfset metagenome_id = ValueList(mgolH.sequenceId)/>
					<cfset metagenome_cnt = ListLen(metagenome_id)/>
					
					<cfset both_id = listToArray(ValueList(mgolH.sequenceId))/>
					<!--- Remove any elements from the first list that do not exist in the second. --->
					<cfset both_id.retainAll(listToArray(uniref_id))/>
					<cfset both_id = arrayToList(both_id)/>
					<cfset both_cnt = listLen(both_id,",")/>
					 
					<!--- create struct of analysis overview --->
					<cfscript>
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "Uniref100P";
						node.XmlAttributes.value = uniref_cnt;
						node.XmlAttributes.idList = #iif(len(uniref_id), "uniref_id", """NULL""")#;

						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "Metagenome ON-Line";
						node.XmlAttributes.value = metagenome_cnt;
						node.XmlAttributes.idList = #iif(len(metagenome_cnt), "metagenome_id", """NULL""")#;

						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "Both";
						node.XmlAttributes.value = both_cnt;
						node.XmlAttributes.idList = #iif(len(both_id), "both_id", """NULL""")#;

						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						node = root.xmlChildren[ArrayLen(root.xmlChildren)];
						node.XmlAttributes.label = "No Significant Hit";
						node.XmlAttributes.value = qry.orfan_cnt;
						node.XmlAttributes.idList = #iif(len(qry.orfan_id), "qry.orfan_id", """NULL""")#;

						StructInsert(globalStruct,"ACLASS",xroot);
					</cfscript>
					<cffile action="append" file="#application.xDocsFilePath#/#dbfilename#" output="#xroot#" addnewline="true" />
				</cfoutput>
			<cfelse>
				<!--- read from file --->
				<cffile action="read" file="#application.xDocsFilePath#/#vfilename#" variable="vroot"/>
				<cfset xmlDoc = XMLParse(trim(vroot))>
				<cfset StructInsert(globalStruct,"VCLASS",xmlDoc)/>
				
				<cffile action="read" file="#application.xDocsFilePath#/#dbfilename#" variable="aroot"/>
				<cfset xmlDoc = XMLParse(trim(aroot))>
				<cfset StructInsert(globalStruct,"ACLASS",xmldoc)/>
			</cfif>
			
		 	<cfcatch type="any">
		 		<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETVIROMECLASS", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
		 	</cfcatch>
		 </cftry>
		 
		 <cfreturn globalStruct/>
	</cffunction>
	
	<cffunction name="gettRNASeq" access="remote" returntype="array"
		hint="get tRNA information for a given library">
		<cfargument name="libId" type="numeric" required="true"/>
		<cfargument name="environment" type="String" required="true"/>
				
		<cfset local.arr = ArrayNew(1)/>

		<cftry>
				<cfset serverObj=CreateObject("component", application.cfc & ".Utility").getServerName(environment=arguments.environment)/>
				<cfset qry=gettRNAHelper(libraryId=arguments.libId,server=serverObj.server,sortby="id")/>
				
				<cfset local.arr = CreateObject("component", application.cfc & ".Utility").QueryToStruct(qry)/>
						
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETTRNASEQ", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn local.arr/>
	</cffunction>
	
	<cffunction name="gettRNAStats" access="remote" returntype="xml"
		hint="get tRNA stats for a given library">
		<cfargument name="libId" type="numeric" required="true"/>
		<cfargument name="environment" type="String" required="true"/>
		
		<cfset xroot = XMLNew()>
		<cfset xroot.xmlRoot = XMLElemNew(xroot,"root")>
		<cfset root = xroot.xmlRoot>
		<cfset filename = "TRNA_FREQ_"&#libId#&".xml"/>

		<cftry>
			<cfdirectory name="xmlFileList" action="list" directory="#application.xDocsFilePath#" filter="#filename#"/>
	
			<cfif xmlFileList.recordcount eq 0>			
				<cfset serverObj=CreateObject("component", application.cfc & ".Utility").getServerName(environment=arguments.environment)/>
				<cfset qry=gettRNAHelper(libraryId=arguments.libId,server=serverObj.server)/>
				
				<cfoutput query="qry" group="anti">
					<cfset count = 0/>
					<cfset idl = ""/>
					
					<cfoutput>
						<cfset count +=1/>
						<cfset idl = listappend(idl,qry.id)/>
					</cfoutput>
					
					<cfscript>
						ArrayAppend(root.xmlChildren,XmlElemNew(xroot,"CATEGORY"));
						trna = root.xmlChildren[ArrayLen(root.xmlChildren)];
						trna.XmlAttributes.name = UCASE(qry.anti);
						trna.XmlAttributes.label = UCase(qry.anti);
						trna.XmlAttributes.value = count;
						trna.XmlAttributes.idList = idl;
					</cfscript>
				</cfoutput>
				<cffile action="write" file="#application.xDocsFilePath#/#filename#" output="#xroot#" mode="755"/>
			<cfelse>
				<cffile action="read" file="#application.xDocsFilePath#/#filename#" variable="xroot">				
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETTRNASTATS", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn xroot/>
	</cffunction>
	
	<cffunction name="getXMLDoc" access="remote" returntype="struct">
		<cfargument name="obj" type="struct" required="true"/>
		
		<cftry>
			<cfscript>
				xdoc = XMLNew();
				
				xmlFName = UCASE(arguments.obj.sType) & "_PUBLIC_XMLDOC.xml";
				idFName = UCASE(arguments.obj.sType) & "_PUBLIC_IDDOC.xml";
				
				if (arguments.obj.libraryId gt 0){
					xmlFName = UCASE(arguments.obj.sType) & "_XMLDOC_" & arguments.obj.libraryId & ".xml";
					idFName = UCASE(arguments.obj.sType) & "_IDDOC_" & arguments.obj.libraryId & ".xml";
				} else if (arguments.obj.userId gt -1){
					xmlFName = UCASE(arguments.obj.sType) & "_PRIVATE_XMLDOC_" & arguments.obj.userId & ".xml";
					idFName = UCASE(arguments.obj.sType) & "_PRIVATE_IDDOC_" & arguments.obj.userId & ".xml";
				}
				
				xStruct = StructNew();
				xStruct['msg'] = "ERROR: File " &xmlFName& " not found";
				xStruct['xdoc'] = XMLNEW();
				
				if (not FileExists("#application.xDocsFilePath#/#xmlFName#")){
					if (arguments.obj.sType eq "overview")
						xdoc = ORFOverview(userId=arguments.obj.userId,libraryIdList=arguments.obj.libraryIdList);
				
					//if xml and idlist are seperate
					if (isstruct(xdoc)){
						myfile = FileOpen("#application.xDocsFilePath#/#xmlFName#","write","UTF-8");
						FileWriteLine(myfile, xdoc['xroot']);
						FileClose(myfile);
						
						myfile = FileOpen("#application.xDocsFilePath#/#idFName#","write","UTF-8");
						FileWriteLine(myfile, xdoc['idroot']);
						FileClose(myfile);
						
						xdoc = xdoc['xroot'];
					} else {
						xStruct['msg'] = "Success";
						xStruct['xdoc'] = xdoc;
						
						myfile = FileOpen("#application.xDocsFilePath#/#xmlFName#","write","UTF-8");
						FileWriteLine(myfile, xdoc);
						FileClose(myfile);
					}
				} else {				
					xdoc = fileRead("#application.xDocsFilePath#/#xmlFName#","UTF-8");
					xStruct['msg'] = "Success";
					xStruct['xdoc'] = xdoc;
				}
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("STATISTICS.CFC - GETXMLDOC", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn xStruct/>
			</cffinally>
		</cftry>
	</cffunction>

</cfcomponent>