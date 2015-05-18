<cfcomponent displayname="ReadRPC" output="false" hint="
			This componented is used to get everything Read related information.  
			It is used to gather, format and return all Read related information 
			for Sequence Detail View and Detail BLAST view
			">

	<cffunction name="getORFs" access="private" returntype="query" hint="
				Gather all ORF metadata for give read/contig.
				
				A helper function for:
					getSequenceInfo()
					
				Return: A hash of all ORF names, ids, size and metadata
				">
				
		<cfargument name="readId" type="Numeric" required="true" hint="Read/contig ID"/>
		<cfargument name="server" type="String" required="true" hint="Server (database) name"/>

		<cftry>
			<cfset q = "">
	
			<!--- get orf for a given read --->
			<cfquery name="q" datasource="#server#">
				SELECT distinct s.id,
								s.name,
								s.size,
								s.header
				FROM	sequence s
					INNER JOIN
						sequence_relationship sr on sr.objectId = s.id
				WHERE	sr.subjectId = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.readId#">
					and sr.typeId = 3
					and s.deleted = 0
				ORDER BY s.id
			</cfquery>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="ReadRPC", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn q/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="gettRNA" access="private" returntype="query" hint="
				Gather all tRNAs metadata for given read/contig
				
				A helper function for:
					getSequenceInfo()
					
				Return: A hash of tRNA name, location and type
				">
				
		<cfargument name="readId" type="Numeric" required="true" hint="Read/contig ID"/>
		<cfargument name="server" type="String" required="true" hint="Server (database) name"/>

		<cftry>
			<cfset q = "">
	
			<!--- get orf for a given read --->
			<cfquery name="q" datasource="#server#">
				SELECT distinct t.num,
								t.tRNA_start,
								t.tRNA_end,
								t.anti,
								t.intron
				FROM	tRNA t
				WHERE	t.deleted = 0
					and t.sequenceId = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.readId#">
				ORDER BY t.num
			</cfquery>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="ReadRPC", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn q>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="getBlastHit" access="private" returntype="query" hint="
					Gather BLAST details of all ORFs for give read/contig
					
					A helper function for:
						getSequenceInfo
						
					Return: A hash of BLAST details
				">
				
		<cfargument name="orfId" type="Numeric" required="false" default="-1" hint="ORF ID"/>
		<cfargument name="readId" type="numeric" required="false" default="-1" hint="Read/contig ID"> 
		<cfargument name="topHit" type="Numeric" required="true" hint="Flag indication whether to retrieve all or only the top BLAST"/>
		<cfargument name="server" type="String" required="true" hint="Server (database) name"/>
		<cfargument name="database" type="String" required="true" hint="BLAST database type (SEED, KEGG, COG, ACLAME etc...)"/>
		
		<cftry>
			<cfset q=""/>
			
			<cfquery name="q" datasource="#arguments.server#" result="qrslt">
				SELECT	b.sequenceId,
						b.id,
						b.query_name,
						b.query_length,
						b.algorithm,
						b.database_name,
						b.hit_name,
						b.hit_description,
						b.qry_start,
						b.qry_end,
						b.hit_start,
						b.hit_end,
						b.percent_identity,
						b.percent_similarity,
						b.raw_score,
						b.bit_score,
						b.e_value,
						format((((b.qry_end-b.qry_start+1)/b.query_length)*100),2) as qry_coverage,
						b.subject_length,
						b.domain,
						b.kingdom,
						b.phylum,
						b.class,
						b.order,
						b.family,
						b.genus,
						b.species,
						b.organism,
						b.sys_topHit,
						b.fxn_topHit,
						sr.objectId
				FROM	blastp b
					<cfif arguments.readId gt -1>
						right join 
							sequence_relationship sr on b.sequenceId = sr.objectId
					</cfif>
				WHERE	<cfif arguments.readId gt -1>
							sr.subjectId = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.readId#">
							and sr.typeId=3 
						<cfelse>
					 		b.sequenceId = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.id#"/>
						 </cfif>
					<cfif arguments.topHit>
						and	b.sys_topHit = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.topHit#"/>
					</cfif>
					<cfif len(arguments.database)>
						and b.database_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.database)#"/>
					</cfif>
					and b.e_value <= 0.001
					and b.deleted = 0
				ORDER BY b.query_name, b.sequenceId, b.database_name desc 
			</cfquery>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="ReadRPC", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn q>
			</cffinally>
		</cftry>
		
	</cffunction>
	
	<cffunction name="getEnvironmentDetail" access="private" returntype="Struct" hint="
				Gather environmental metadata related to give prefix (a unique library identifier, which is the same for ORF and read/contigs)
				
				A helper function for:
					getSequenceInfo()
					
				Return: A hash of environmental metadata
				">
				
		<cfargument name="prefix" type="string" required="true" hint="A unique library identifier, which is the same for ORF and read/contigs">
		
		<cftry>
			<cfset struct = structNew()/>
			
			<cfquery name="q" datasource="#request.mainDSN#">
				SELECT	seq_type,
						lib_type,
						na_type,
						genesis,
						sphere,
						ecosystem,
						phys_subst,
						lib_name
				FROM	mgol_library
				WHERE	lib_prefix = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.prefix#">
					and deleted = 0
			</cfquery>
			
			<cfif q.recordcount>
				<cfset struct = CreateObject("component", request.cfc & ".Utility").QueryToStruct(q, 1)/>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="ReadRPC", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn struct/>
			</cffinally>
		</cftry>
	</cffunction> 

	<!---<cffunction name="getBlastImage" access="private" returntype="String">
		<cfargument name="qry" required="true" type="Query" />
		<cfargument name="tqry" required="true" type="any" />
		<cfargument name="sname" required="true" type="String" />
		<cfargument name="readId" required="true" type="Numeric" />
		<cfargument name="server" required="true" type="String" />
		
		<cfset img = "">
		<cfset count = 0>

		<cftry>
			<!--- set file names --->
			<cfset tabFileName = sname & "_orf.txt">
			<cfset imgFileName = sname & "_orf.gif">
			
			<cfscript>
				myfile = FileOpen("#request.blastImgFilePath#/txt/#tabFileName#","write");
			</cfscript>
				
			<!--- Get true size of the read. --->
			<cfquery name="rsize" datasource="#arguments.server#">
				SELECT	s.size
				FROM	sequence s
				WHERE	s.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.readId#"/>
				LIMIT 1
			</cfquery>
			
			<!--- insert first line as read info. --->			
			<cfloop query="rsize">
				<cfset str = "READLINE" & #chr(9)# & trim(sname) & #chr(9)#>
				<cfset str = str & "INFO" & #chr(9)#>
				<cfset str = str & "0" & #chr(9)# & rsize.size & #chr(9)# & "-0" & 
							#chr(9)# & "0" & #chr(9)# & "1" & #chr(9)# & rsize.size & 
							#chr(9)# & "0" & #chr(9)# & "0" & #chr(9)# & "0" & #chr(9)# & "0">
				
				<cfscript>
					//FileWriteLine(myfile, str & request.linefeed);
					FileWriteLine(myfile, str);
				</cfscript>
			</cfloop>

			<cfif not FileExists("#request.blastImgFilePath#/img")>
				<cfset count = 1>

				<!--- get orf info in the blast imager. --->
					
				<cfoutput query="qry">
					<cfif len(sname) gt 11>
						<cfset sname = LEFT(sname,8) & "..."/>
					</cfif>
					<cfset blastImager = "ORF" & #chr(9)# & trim(sname) & #chr(9)#>
					<cfset blastImager = blastImager & "ORF_" & (count) & #chr(9)#>

					<cfset orftype = 0>
					<cfset orf_info_struct = structNew()/>
					<cfloop list="#qry.header#" index="item" delimiters=" " >
						<cfset data = listToArray(item,"=")/>
						<cfset orf_info_struct[data[1]] = data[2]/>
					</cfloop>
					
					<cfif Find("incomplete",orf_info_struct['type'],0)>
						<cfset orftype = "3">
					<cfelseif Find("complete",orf_info_struct['type'],0)>
						<cfset orftype = "0">
					<cfelseif Find("lack_stop",orf_info_struct['type'],0)>
						<cfset orftype = "1">
					<cfelseif Find("lack_start",orf_info_struct['type'],0)>
						<cfset orftype = "2">
					</cfif>

					<cfset blastImager = blastImager & orftype & #chr(9)# &
										 orf_info_struct['stop']-orf_info_struct['start'] & #chr(9)# &
										 orf_info_struct['strand'] & (abs(orf_info_struct['start']-orf_info_struct['frame']-1)%3) & 
										 #chr(9)# & 0 & #chr(9)# &
										 orf_info_struct['start'] & #chr(9)# &
										 orf_info_struct['stop'] & #chr(9)# &
										 0 & #chr(9)# & 0 & #chr(9)# &
										 NumberFormat(Round(orf_info_struct['score']), "__") & #chr(9)# & 0>
					
					<cfscript>
						FileWriteLine(myfile, blastImager);
					</cfscript>					
					<cfset count = count + 1>
				</cfoutput>
				
				<!--- get trna info --->
				<cfif isQuery(tqry) and tqry.recordcount gt 0>
					<cfoutput query="tqry">
						<cfif len(sname) gt 11>
							<cfset sname = LEFT(sname,8) & "..."/>
						</cfif>
						<cfset trna_line = "READ" & #chr(9)# & trim(sname) & #chr(9)# & 
											tqry.anti & #chr(9)# & 
											0 & #chr(9)# & 
											abs(tqry.tRNA_end-tqry.tRNA_start) & #chr(9)# &
											0 & #chr(9)# & 
											0 & #chr(9)# & 
											tqry.tRNA_start & #chr(9)# & 
											tqry.tRNA_end & #chr(9)# & 
											0 & #chr(9)# & 
											0 & #chr(9)# &
											0 & #chr(9)# & 0/>
						<cfscript>
							FileWriteLine(myfile, trna_line);
						</cfscript>	
					</cfoutput>					 
				</cfif>
				
				<cfscript>
					FileClose(myfile);
				</cfscript>
				
				<cfexecute 	name="#request.blastImgFilePath#/wrapper.sh"
			                arguments="#request.blastImgFilePath#/txt/#tabFileName#"
			                outputFile="#request.blastImgFilePath#/img/#imgFileName#"
			                timeout="10">
				</cfexecute>				
			</cfif>
				
			<cfset img= "#request.rootHostPath#/blastImager/img/#imgFileName#">
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="ReadRPC", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn img>
			</cffinally>
		</cftry>
	</cffunction>--->

	<cffunction name="getACLAMEInfo" access="private" returntype="struct" hint="
				Get ACLAME functional information for a given accession number.
				
				Return:  An array of hash of ACLAME
				">
				
		<cfargument name="acc" type="string" required="true" hint="Accession number"/>
		
		<cfset st= StructNew()/>
		
		<cfset idx = iif(Find(";",arguments.acc,0),Find(";",arguments.acc,0)-1,len(arguments.acc))/>
		<cfset local.acc = Left(arguments.acc,idx) />
				
		<cftry>			
			<cfquery name="aq" datasource="#request.lookupDSN#">
				SELECT	a.id,
						a.realacc,
						a.desc,
						a.mge_name,
						a.mge_type,
						a.mge_genome_org,
						a.mge_genometype,
						a.mge_host_organism
				FROM	aclame a
				WHERE	a.realacc = <cfqueryparam cfsqltype="cf_sql_varchar" value="#local.acc#"/>
				ORDER By a.id
				LIMIT 1
			</cfquery>
			
			<cfset st = CreateObject("component", request.cfc & ".Utility").QueryToStruct(query=aq,row=1)/>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="ReadRPC", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn st/>
	</cffunction>

	<cffunction name="getSequenceInfo" access="remote" returntype="Struct" hint="
				Get detail seqeunce information of a given read/contig.
				This function will gather all ORFs, tRNA and ORF BLAST details related to a read/contig 
				
				Called directly from Flex sequence detail view
				
				Return: A hash of all ORF, tRNA and ORF BLAST details.
				">
				
		<cfargument name="orfId" type="numeric" required="true" hint="ORF ID"/>
		<cfargument name="readId" type="numeric" required="true" hint="Read ID"/>
		<cfargument name="environment" type="string" required="true" hint="Environment name"/>
		
		<!--- 	get details about a read and return a detail struct
				struct includes following fields
					id
					name
					basepair
					size
					number of ORFs
					number of tRNA
					taxonomy table
					blastImager 
		--->
		
		<cftry>
			<cfset _serverObject = CreateObject("component",  request.cfc & ".Utility").getServerName(arguments.environment) />
			<cfset _server = _serverObject['server']/>
			
			<!--- if orfId is passed then use orfId --->
			<cfset local.id = arguments.readId />
			<cfif arguments.orfId gt 0>
				<cfset local.id = arguments.orfId />
			</cfif>
			
			<cfset object = StructNew()/>
			<cfset object['ENVIRONMENT'] = arguments.environment />
			<cfset object['LIBRARYID'] = _serverObject['library'] />
			
			<cfquery name="qry" datasource="#_server#" >
				SELECT	s.id,
						s.name,
						s.basepair,
						s.size
				FROM	sequence s
					INNER JOIN
						sequence_relationship sr on sr.subjectId = s.id
				WHERE	sr.objectId = <cfqueryparam cfsqltype="cf_sql_bigint" value="#local.id#" null="false">
					<cfif arguments.orfId gt 0>
						and sr.typeId = 3
					<cfelse>
						and sr.typeId = 1
					</cfif>
					and s.deleted = 0
			</cfquery>
			
			<cfscript>
				if (qry.recordCount) {
					object = CreateObject("component", request.cfc & ".Utility").QueryToStruct(qry, 1);

					orfQry = getORFs(readId=qry['id'][1], server=_server);
					tQry = gettRNA(readId=qry['id'][1], server=_server);

					
					// create orf array of struct for blastImager and to create 
					// empty orf viewstack.
					orf_arr = ArrayNew(1);
					
					for (var i=1; i<=orfQry.recordcount; i++){
						orf_st = StructNew();
						orf_st['ID'] = orfQry['id'][i];
						orf_st['NAME'] = orfQry['name'][i];
						orf_st['SIZE'] = orfQry['size'][i];
						
						structappend(orf_st, CreateObject("component", request.cfc & ".Utility").SeqHeaderToStruct(orfQry['header'][i]));
						arrayappend(orf_arr,orf_st);
					}
					
					// create trna array of struct for blast imager
					trna_arr = ArrayNew(1);
					for (var i=1; i<= tQry.recordcount; i++) {
						trna_st = structNew();
						trna_st['NAME'] = object['NAME'];
						if (tQry['trna_start'][i] gt tQry['trna_end'][i]) {
							trna_st['START'] = tQry['trna_end'][i];
							trna_st['STOP'] = tQry['trna_start'][i];
							trna_st['STRAND'] = "-";
						} else {
							trna_st['START'] = tQry['trna_start'][i];
							trna_st['STOP'] = tQry['trna_end'][i];
							trna_st['STRAND'] = "+";
						}
						
						trna_st['ANTI'] = tQry['anti'][i];
						trna_st['INTRON'] = tQry['INTRON'][i];
						
						arrayappend(trna_arr, trna_st);
					}
					
					
					object['ORF'] = orf_arr;
					object['TRNA'] = trna_arr;
					
					object['TRNA_COUNT'] = tQry.recordcount;
					object['ORF_COUNT'] = orfQry.recordcount;
					
					//required for blast imager
					object['START'] = 1;
					object['STOP'] = object['SIZE'];
					object['STRAND'] = "+"; //dummy value
					object['FRAME'] = "0"; //dummy value
					object['TYPE'] = "complete"; //dummy value

					// list of db's for top blast result table.
					db_list = "UNIREF100P,ACLAME,SEED,KEGG,COG,METAGENOMES";
					orf_env_detail = arrayNew(1);
					
					for (var i=1; i<=listLen(db_list); i++) {
						orf_blast_details = getBlastHit(readId=qry['id'][1], topHit=1, server=_server, database=listGetAt(db_list, i));

						orf_blast_struct = StructNew();
						if (orf_blast_details.recordcount) {
							orf_blast_struct = CreateObject("component", request.cfc & ".Utility").QueryToStruct(orf_blast_details);
							object[listGetAt(db_list, i)] = orf_blast_struct;
								
							if (listGetAt(db_list,i) eq "METAGENOMES") {
								for (var j=1; j<=orf_blast_details.recordcount; j++) {
									orf_env_struct = getEnvironmentDetail(left(orf_blast_details['hit_name'][j], 3));
									orf_env_struct['QUERY_NAME'] = orf_blast_details['query_name'][j];
									arrayappend(orf_env_detail, orf_env_struct);
								}
								object['ORF_ENV_DETAIL'] = orf_env_detail;
							}
						}
					}
				}
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="ReadRPC", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn object/>
			</cffinally>
		</cftry>		
	</cffunction>

</cfcomponent>