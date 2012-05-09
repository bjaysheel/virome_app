<cfcomponent output="false">

	<cffunction name="getORFs" access="private" returntype="query">
		<cfargument name="readId" type="Numeric" required="true"/>
		<cfargument name="server" type="String" required="true"/>
		<cfset q = "">

		<cftry>
			<!--- get orf for a given read --->
			<cfquery name="q" datasource="#server#">
				SELECT distinct s.id,
								s.name,
								s.basepair,
								s.size,
								s.header
				FROM	sequence s
					INNER JOIN
						sequence_relationship sr on sr.objectId=s.id
				WHERE	sr.subjectId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.readId#">
					and sr.typeId = 3
					and s.deleted = 0
				ORDER BY s.id
			</cfquery>

			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("SEQUENCE.CFC - GETORFS", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>

		<cfreturn q>
	</cffunction>

	<cffunction name="gettRNA" access="private" returntype="query" hint="get tRNAs for a given read">
		<cfargument name="readId" type="Numeric" required="true"/>
		<cfargument name="server" type="String" required="true"/>
		<cfset q = "">

		<cftry>
			<!--- get orf for a given read --->
			<cfquery name="q" datasource="#server#">
				SELECT distinct t.num,
								t.tRNA_start,
								t.tRNA_end,
								t.anti,
								t.intron
				FROM	tRNA t
				WHERE	t.deleted = 0
					and t.sequenceId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.readId#">
				ORDER BY t.num
			</cfquery>

			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("SEQUENCE.CFC - GETTRNA", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>

		<cfreturn q>
	</cffunction>

	<cffunction name="getBlastHit" access="private" returntype="query">
		<cfargument name="id" type="Numeric" required="true" />
		<cfargument name="topHit" type="Numeric" required="true" />
		<cfargument name="server" type="String" required="true" />
		<cfargument name="database" type="String" required="true"/>
		
		<cfset q=""/>
		<cftry>
			<cfquery name="q" datasource="#arguments.server#">
				SELECT	b.sequenceId,
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
						b.id,
						b.sys_topHit,
						b.fxn_topHit,
						s.size
				FROM	blastp b
					INNER JOIN
						sequence s on b.sequenceId = s.id
				WHERE	b.deleted = 0
					and b.e_value <= 0.001
					<cfif arguments.topHit>
						and	b.sys_topHit = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.topHit#"/>
					</cfif>
					<cfif len(arguments.database)>
						and b.database_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.database#"/>
					</cfif>
					and b.sequenceId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#"/>
				ORDER BY b.fxn_topHit desc, b.sys_topHit desc, b.sequenceId, b.database_name desc 
			</cfquery>

			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("SEQUENCE.CFC - GETDBDETAIL", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>

		<cfreturn q>
	</cffunction>
	
	<cffunction name="splitBlastResult" access="private" returntype="any" 
		hint="Split blast query result into hsp and tax ">
		<cfargument name="qry" type="Query" required="true" />
		<cfargument name="idx" type="Numeric" required="false" default="0"/>
		<cfargument name="server" type="String" required="true" />
		<cfargument name="environment" type="String" required="true"/>
		
		<cfset array=ArrayNew(1)/>

		<cftry>
			<cfscript>
				if (arguments.idx){
					fromIndex = idx;
					toIndex = idx;
				} else {
					fromIndex = 1;
					toIndex = qry.recordCount;
				}
				
				for (rowIndex=fromIndex; rowIndex lte toIndex; rowIndex=rowIndex+1){
					local.tax = StructNew();
					local.hsp = StructNew();
					local.bstruct = StructNew();
					
					_hitdesc = q['hit_description'][rowIndex];
					//remove metagenome reformat correct value should be in blast table
					/*if ((len(q['hit_description'][rowIndex]) < 1) and 
						(qry["database_name"][rowIndex] eq "METAGENOMES"))
							_hitdesc = CreateObject("component",  application.cfc & ".Utility").getMetaHitDesc(hitName=qry["hit_name"][rowIndex]);
					*/
					
					// get hsp values
					StructInsert(local.hsp,"EVALUE",qry["e_value"][rowIndex]);
					StructInsert(local.hsp,"BITSCORE",qry["bit_score"][rowIndex]);
					StructInsert(local.hsp,"IDENTITY",qry["percent_identity"][rowIndex]);
					StructInsert(local.hsp,"SIMILARITY",qry["percent_similarity"][rowIndex]);
					StructInsert(local.hsp,"HITNAME",qry["hit_name"][rowIndex]);
					StructInsert(local.hsp,"QUERYNAME",qry["query_name"][rowIndex]);
					StructInsert(local.hsp,"HITDESCRIPTION",_hitdesc);
					StructInsert(local.hsp,"HITSTART",qry["hit_start"][rowIndex]);
					StructInsert(local.hsp,"HITEND",qry["hit_end"][rowIndex]);
					StructInsert(local.hsp,"QUERYSTART",qry["qry_start"][rowIndex]);
					StructInsert(local.hsp,"QUERYEND",qry["qry_end"][rowIndex]);
					StructInsert(local.hsp,"SUBJECTLENGTH",qry["subject_length"][rowIndex]);
					StructInsert(local.hsp,"SIZE",qry["size"][rowIndex]);
					StructInsert(local.hsp,"QRYSTART",qry["qry_start"][rowIndex]);
					StructInsert(local.hsp,"QRYEND",qry["qry_end"][rowIndex]);
					StructInsert(local.hsp,"DATABASENAME",qry["database_name"][rowIndex]);
					StructInsert(local.hsp,"ALGORITHM",qry["algorithm"][rowIndex]);
					StructInsert(local.hsp,"SEQUENCEID",qry["sequenceId"][rowIndex]);
					StructInsert(local.hsp,"ENVIRONMENT",arguments.environment);
					
					local.bstruct['hsp']=local.hsp;
					ArrayAppend(array,local.bstruct);
				}
				
				if (arguments.idx)
					return array[1];
				else return array;
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("SEQUENCE.CFC - GETDBDETAIL", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="getBlastImage" access="private" returntype="String">
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
				myfile = FileOpen("#application.blastImgFilePath#/txt/#tabFileName#","write");
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
					//FileWriteLine(myfile, str & application.linefeed);
					FileWriteLine(myfile, str);
				</cfscript>
			</cfloop>

			<cfif not FileExists("#application.blastImgFilePath#/img")>
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
					<cfloop list="qry.header" index="item" delimiters=" " >
						<cfset data = listToArray(item,"=")/>
						<cfset orf_info_struct[data[1]] = data[2]/>
					</cfloop>
					
					<cfif Find("incomplete",orf_info_strct['type'],0)>
						<cfset orftype = "3">
					<cfelseif Find("complete",orf_info_strct['type'],0)>
						<cfset orftype = "0">
					<cfelseif Find("lack_stop",orf_info_strct['type'],0)>
						<cfset orftype = "1">
					<cfelseif Find("lack_start",orf_info_strct['type'],0)>
						<cfset orftype = "2">
					</cfif>

					<cfset blastImager = blastImager & orftype & #chr(9)# &
										 orf_info_strct['end']-orf_info_strct['start'] & #chr(9)# &
										 orf_info_strct['strand'] & (abs(orf_info_strct['start']-orf_info_strct['frame']-1)%3) & 
										 #chr(9)# & 0 & #chr(9)# &
										 orf_info_strct['start'] & #chr(9)# &
										 orf_info_strct['end'] & #chr(9)# &
										 0 & #chr(9)# & 0 & #chr(9)# &
										 NumberFormat(Round(orf_info_strct['score']), "__") & #chr(9)# & 0>
					
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
				
				<cfexecute 	name="#application.blastImgFilePath#/wrapper.sh"
			                arguments="#application.blastImgFilePath#/txt/#tabFileName#"
			                outputFile="#application.blastImgFilePath#/img/#imgFileName#"
			                timeout="10">
				</cfexecute>				
			</cfif>
				
			<cfset img= "#application.rootHostPath#/blastImager/img/#imgFileName#">
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("READRPC.CFC - GETBLASTIMAGE", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn img>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="getACLAMEInfo" access="private" returntype="struct">
		<cfargument name="acc" type="string" required="true"/>
		
		<cfset st= StructNew()/>
		
		<cfset idx = iif(Find(";",arguments.acc,0),Find(";",arguments.acc,0)-1,len(arguments.acc))/>
		<cfset local.acc = Left(arguments.acc,idx) />
				
		<cftry>			
			<cfquery name="aq" datasource="#application.lookupDSN#">
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
			
			<cfset st = CreateObject("component", application.cfc & ".Utility").QueryToStruct(query=aq,row=1)/>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("READRPC.CFC - GETACLAMEINFO", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn st/>
	</cffunction>

	<cffunction name="getSequenceInfo" access="remote" returntype="Struct">
		<cfargument name="id" type="Numeric" required="true"/>
		<cfargument name="name" type="String" required="true"/>
		<cfargument name="environment" type="String" required="true"/>

		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.environment) />
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cfset struc = StructNew()>
		<cfset _readId = 0>
		
		<cftry>
			<!--- id passed in will always be sequence Id of an orf, so first
			get the read information of the given orf --->
			<cfquery name="rq" datasource="#_server#">
				SELECT	s.id,
						s.name,
						s.basepair,
						s.size,
						o.readId
				FROM	orf o
					INNER JOIN
						sequence s on o.readId=s.id
				WHERE	o.seqId = <cfqueryparam cfsqltype="CF_SQL_NUMERIC" value="#arguments.id#" null="false">
			</cfquery>
			
			<!--- if there is an orf value, then there will alway be a read,
			so no need to check if query returned anything rows. 
			IF RQ IS EMPTY THEN THERE IS A DISCREPANCY IN THE DATABASE --->
			<cfset rStruct = structnew()/>
			<cfoutput query="rq" maxrows="1">
				<cfscript>
					_readId = rq.readId;
					
					StructInsert(rStruct,"ID",rq.id);
					StructInsert(rStruct,"NAME",rq.name);
					StructInsert(rStruct,"BASEPAIR",rq.basepair);
					StructInsert(rStruct,"SIZE",rq.size);
				</cfscript>
			</cfoutput>

			<cfscript>
				struct = StructNew();

				//get ORF's
				orfQuery = getORFs(readId=_readId,server=_server);
				orfArray = CreateObject("component", application.cfc & ".Utility").QueryToStruct(orfQuery);
				
				StructInsert(struct,"read",rStruct);
				StructInsert(struct,"orf",orfArray);
				//return the structure.
				return struct;
			</cfscript>

			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("READRPC.CFC - GETSEQUENCEINFO", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="getORFSummary" access="remote" retuntype="Struct">
		<cfargument name="id" type="Numeric" required="true" />
		<cfargument name="environment" type="String" required="true"/>
		<cfargument name="database" type="String" required="false" default=""/>
		<cfargument name="topHit" type="Numeric" required="false" default="0"/>
		
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.environment) />
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cfset struct = StructNew()>
		<cftry>
			<cfset orfQry = getORFs(readId=arguments.id,server=_server)/>
			<cfset tQry = gettRNA(readId=arguments.id,server=_server)/>
			
			<cfif orfQry.recordcount>
				<!---  add image of orfs over original seq.--->
				<cfset idx = REFind("_\d+_\d+_\d+$",orfQry.name,0,"false")/>
				<cfset img = getBlastImage(qry=orfQry,tqry=tQry,sname=Left(orfQry.name,idx-1),readId=arguments.id,server=_server)/>
				<cfset StructInsert(struct,"IMAGE",img)/>
			</cfif>
			
			<!--- loop through all orfs for a given read --->
			<cfloop query="orfQry">
			<cfset arr = ArrayNew(1)>
				<cfset blast = getBlastHit(id=orfQry.id,topHit=arguments.topHit,server=_server,database=arguments.database)/>
				
				<!--- loop over all top blast hits for a given orf --->
				<cfif IsQuery(blast)>
					<cfloop query="blast">
						<!--- check  if database struct already exist--->
						<cfset splt = splitBlastResult(qry=blast,idx=blast.currentRow,server=_server,environment=arguments.environment) />
						<cfif not StructIsEmpty(struct) and StructKeyExists(struct,blast.database_name)>
							<cfset arr = struct[blast.database_name]/>
							<cfset ArrayAppend(arr,splt['hsp'])/>
							<cfset Structupdate(struct,blast.database_name,arr)/>	
						<cfelse>
							<cfset arr = ArrayNew(1)>
							<cfset ArrayAppend(arr,splt['hsp'])/>
							<cfset StructInsert(struct,blast.database_name,arr)/>
						</cfif>
					</cfloop>
				</cfif>
			</cfloop>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("READRPC.CFC - GETORFSUMMARY", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn struct/>
	</cffunction>

	<cffunction name="getTaxonomicInfo" access="remote" returntype="Struct">
		<cfargument name="id" type="Numeric" required="true" />
		<cfargument name="environment" type="String" required="true"/>

		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.environment) />
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cfset struct = StructNew()>
		<cftry>
			<cfset orfQry = getORFs(readId=arguments.id,server=_server)/>
			<cfset taxArray = ArrayNew(1)/>
			<cfset aclArray = ArrayNew(1)/>
			
			<cfloop query="orfQry">
				<cfset local.qry = getBlastHit(id=orfQry.id,topHit=1,fxnHit=0,server=_server,database="")/>
				
				<cfloop query="local.qry">
					<cfscript>
						if (local.qry.database_name eq 'UNIREF100P'){
							local.tax = StructNew();
							StructInsert(local.tax,"DOMAIN",local.qry.domain);
							StructInsert(local.tax,"KINGDOM",local.qry.kingdom);
							StructInsert(local.tax,"PHYLUM",local.qry.phylum);
							StructInsert(local.tax,"CLASS",local.qry.class);
							StructInsert(local.tax,"ORDER",local.qry.order);
							StructInsert(local.tax,"FAMILY",local.qry.family);
							StructInsert(local.tax,"GENUS",local.qry.genus);
							StructInsert(local.tax,"SPECIES",local.qry.species);
							StructInsert(local.tax,"ORGANISM",local.qry.organism);
							StructInsert(local.tax,"QUERYNAME",local.qry.query_name);
							StructInsert(local.tax,"SEQUENCEID",local.qry.sequenceId);
							
							ArrayAppend(taxArray,local.tax);
						}
						
						if (local.qry.database_name eq 'ACLAME'){
							astruct = getACLAMEInfo(acc=local.qry.hit_name);
							
							if (NOT StructIsEmpty(astruct)){
								str = "";
								orfNum = Left(reverse(local.qry.query_name),Find("_",reverse(local.qry.query_name))-1);
								if (astruct["MGE_TYPE"] eq "plasmid"){
									str = "ORF_#orfNum#  was homologus (eval: #local.qry.e_value#) to #astruct["realacc"]# #astruct["desc"]# ";
									str = str & "from #astruct["mge_host_organism"]# plasmid #astruct["mge_name"]#.";
								}
								else {
									str = "ORF_" & orfNum &  "was homologus (eval: #local.qry.e_value#) to #astruct["realacc"]# #astruct["desc"]# in a ";
									str	= str &	"#astruct["mge_genome_org"]# #astruct["mge_genometype"]# virus (#astruct["mge_name"]#) ";
									str = str & "infecting host #astruct["mge_host_organism"]#.";
								}
								ArrayAppend(aclArray,str);
							}
						}
					</cfscript>
				</cfloop>
			</cfloop>
			
			<cfset StructInsert(struct,"TAXONOMY",taxArray)/>
			<cfset StructInsert(struct,"ACLAME",aclArray)/>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("READRPC.CFC - GETTAXONOMICINFO", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn struct/>
	</cffunction>
</cfcomponent>