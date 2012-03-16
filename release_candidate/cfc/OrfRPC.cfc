<cfcomponent output="false">
	
	<cffunction name="getBlastHit" access="remote" returntype="Query">
		<cfargument name="id" type="Numeric" required="true"/>
		<cfargument name="server" type="String" required="true"/>
		<cfargument name="database" type="String" required="false" default=""/>
		<cfargument name="topHit" type="Numeric" required="false" default="-1"/>
		<cfargument name="fxnHit" type="numeric" required="false" default="-1"/>
		
		<cfset q="">
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
						b.blast_frame,
						b.raw_score,
						b.bit_score,
						b.e_value,
						b.subject_length,
						<cfif len(arguments.database) and findnocase("metagenomes",arguments.database)>
							m.genesis,
							m.sphere,
							m.ecosystem,
						<cfelse>
							b.domain,
							b.kingdom,
							b.phylum,
							b.class,
							b.order,
							b.family,
							b.genus,
							b.species,
							b.organism,
						</cfif>
						b.id,
						s.size,
						b.sys_topHit,
						b.fxn_topHit
				FROM	
					blastp b
					INNER JOIN
						sequence s on b.sequenceId = s.id
					<!--- if metagenomes hits join mgol_lib in same db --->
					<cfif len(arguments.database) and findnocase("metagenomes",arguments.database)>
						INNER JOIN
						mgol_library m on m.lib_prefix = substring(b.hit_name,1,3)
					</cfif>
				WHERE	b.deleted = 0
					and b.e_value <= 0.001
					<cfif arguments.topHit gt -1>
						and	b.sys_topHit = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.topHit#"/>
					</cfif>
					<cfif arguments.fxnHit gt -1>
						and b.fxn_topHit = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.fxnHit#"/>
					</cfif>
					<cfif len(arguments.database)>
						and b.database_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.database#"/>
					<cfelse>
						and b.database_name not like 'NOHIT'
					</cfif>
					and b.sequenceId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#"/>
				ORDER BY b.sequenceId, b.database_name desc, b.e_value
			</cfquery>
						
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - GETBLASTHIT", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn q>
	</cffunction>

	<cffunction name="getBlastImage" access="private" returntype="string">
		<cfargument name="qry" required="true" type="query" />
		<cfargument name="sname" required="true" type="string">
		
		<cfset img = "">
		<cfset count = 0>

		<cftry>
			<cfset tabFileName = sname & ".txt">
			<cfset imgFileName = sname & ".gif">

			<cfdirectory action="list" filter="#imgFileName#" directory="#application.blastImgFilePath#/img" name="imgList">

			<cfif imgList.recordCount eq 0>
				<cfset blastImager = "">
				<cfscript>
					myfile = FileOpen("#application.blastImgFilePath#/txt/#tabFileName#","write");
				</cfscript>
				
				<cfoutput query="qry">
					<cfif len(sname) gt 11>
						<cfset sname = LEFT(sname,8) & "...">
					</cfif>
					<cfset hitId= qry.database_name>
					
	            	<cfset blastImager = "READ   " & trim(sname) & "	">
					<cfset blastImager = blastImager & hitId & "	">
	                <cfset blastImager = blastImager & qry.percent_identity & "	" &
	                                    abs(qry.qry_start-qry.qry_end+1) & "	" &
										qry.blast_frame & "	" &
										0 & "	" &
										qry.qry_start & "	" &
										qry.qry_end & "	" &
										qry.hit_start & "	" &
										qry.hit_end & "	" &
										qry.e_value & "	" &
										qry.bit_score>

					<cfscript>
						FileWriteLine(myfile,"#blastImager# #chr(13)##chr(10)#");
					</cfscript>					
			    </cfoutput>
				
				<cfscript>
					fileClose(myfile);
				</cfscript>
				
				<cfexecute 	name="#application.blastImgFilePath#/wrapper.sh"
			                arguments="#application.blastImgFilePath#/txt/#tabFileName#"
			                outputFile="#application.blastImgFilePath#/img/#imgFileName#"
			                timeout="10">
				</cfexecute>
				
			</cfif>
			
			<cfset img="#application.rootHostPath#/blastImager/img/#imgFileName#">
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("SEQUENCE.CFC - GETBLASTIMAGE", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>

		<cfreturn img>
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
					toIndex = arguments.qry.recordCount;
				}
				
				for (rowIndex=fromIndex; rowIndex lte toIndex; rowIndex=rowIndex+1){
					local.hsp = StructNew();
					local.bstruct = StructNew();
					local.fxn = StructNew();
					
					_hitdesc = arguments.qry['hit_description'][rowIndex];
					//remove metagenome reformat correct value should be in blast table
					/*
					if ((len(arguments.qry['hit_description'][rowIndex]) < 1) and 
						(arguments.qry["database_name"][rowIndex] eq application.metagenome))
							_hitdesc = CreateObject("component",  application.cfc & ".Utility").getMetaHitDesc(hitName=arguments.qry["hit_name"][rowIndex]);
					*/
					
					// get hsp values
					StructInsert(local.hsp,"EVALUE",arguments.qry["e_value"][rowIndex]);
					StructInsert(local.hsp,"BITSCORE",arguments.qry["bit_score"][rowIndex]);
					StructInsert(local.hsp,"IDENTITY",arguments.qry["percent_identity"][rowIndex]);
					StructInsert(local.hsp,"SIMILARITY",arguments.qry["percent_similarity"][rowIndex]);
					StructInsert(local.hsp,"HITNAME",arguments.qry["hit_name"][rowIndex]);
					StructInsert(local.hsp,"QUERYNAME",arguments.qry["query_name"][rowIndex]);
					StructInsert(local.hsp,"HITDESCRIPTION",_hitdesc);
					StructInsert(local.hsp,"HITSTART",arguments.qry["hit_start"][rowIndex]);
					StructInsert(local.hsp,"HITEND",arguments.qry["hit_end"][rowIndex]);
					StructInsert(local.hsp,"QUERYSTART",arguments.qry["qry_start"][rowIndex]);
					StructInsert(local.hsp,"QUERYEND",arguments.qry["qry_end"][rowIndex]);
					StructInsert(local.hsp,"SUBJECTLENGTH",arguments.qry["subject_length"][rowIndex]);
					StructInsert(local.hsp,"SIZE",arguments.qry["size"][rowIndex]);
					StructInsert(local.hsp,"QRYSTART",arguments.qry["qry_start"][rowIndex]);
					StructInsert(local.hsp,"QRYEND",arguments.qry["qry_end"][rowIndex]);
					StructInsert(local.hsp,"DATABASENAME",arguments.qry["database_name"][rowIndex]);
					StructInsert(local.hsp,"ALGORITHM",arguments.qry["algorithm"][rowIndex]);
					StructInsert(local.hsp,"SEQUENCEID",arguments.qry["sequenceId"][rowIndex]);
					StructInsert(local.hsp,"ENVIRONMENT",arguments.environment);
					
					//get seed function information
					if (arguments.qry["database_name"][rowIndex] eq application.seed){
						local.fxn = getSEEDFXN(id=arguments.qry["sequenceId"][rowIndex],server=arguments.server);
					}
					// get cog function information
					else if (arguments.qry["database_name"][rowIndex] eq application.cog){
						local.fxn = getCOGFXN(id=arguments.qry["sequenceId"][rowIndex],server=arguments.server);
					}
					// get kegg function information
					else if (arguments.qry["database_name"][rowIndex] eq application.kegg){
						local.fxn = getKEGGFXN(id=arguments.qry["sequenceId"][rowIndex],server=arguments.server);
					}
					// get uniref function information
					else if (arguments.qry["database_name"][rowIndex] eq application.uniref){
						local.fxn = getGOFxn(id=arguments.qry["sequenceId"][rowIndex],server=arguments.server);
					}
					
					local.bstruct['hsp']=local.hsp;
					local.bstruct['fxn']=local.fxn;
					
					/*
					if (isDefined(local.fxn['EVALUE']) and len(local.fxn['EVALUE'])){
						local.bstruct['fxn']=local.fxn;
					}
					*/
					ArrayAppend(array,local.bstruct);
				}
				
				if (arguments.idx)
					return array[1];
				else return array;
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - SPLITBLASTRESULT", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="blastStructHelper" access="private" returntype="Struct">
		<cfargument name="qry" type="query" required="true">
		
		<cfset bstr = StructNew()/>
		
		<cfset StructInsert(bstr,"EVALUE",qry.e_value)/>
		<cfset StructInsert(bstr,"BITSCORE",qry.bit_score)/>
		<cfset StructInsert(bstr,"IDENTITY",qry.percent_identity)/>
		<cfset StructInsert(bstr,"SIMILARITY",qry.percent_similarity)/>
		<cfset StructInsert(bstr,"HITNAME",qry.hit_name)/>
		<cfset StructInsert(bstr,"QUERYNAME",qry.query_name)/>
		<cfset StructInsert(bstr,"HITDESCRIPTION",qry.hit_description)/>
		<cfset StructInsert(bstr,"HITSTART",qry.hit_start)/>
		<cfset StructInsert(bstr,"HITEND",qry.hit_end)/>
		<cfset StructInsert(bstr,"QUERYSTART",qry.qry_start)/>
		<cfset StructInsert(bstr,"QUERYEND",qry.qry_end)/>
		<cfset StructInsert(bstr,"SUBJECTLENGTH",qry.subject_length)/>
		<cfset StructInsert(bstr,"SIZE",qry.size)/>
		<cfset StructInsert(bstr,"QRYSTART",qry.qry_start)/>
		<cfset StructInsert(bstr,"QRYEND",qry.qry_end)/>
		<cfset StructInsert(bstr,"DATABASENAME",qry.database_name)/>
		<cfset StructInsert(bstr,"ALGORITHM",qry.algorithm)/>
		<cfset StructInsert(bstr,"SEQUENCEID",qry.sequenceId)/>
		
		<cfreturn bstr/>
	</cffunction>
	
	<cffunction name="getSEEDFxn" access="private" returntype="Struct">
		<cfargument name="id" type="numeric" required="true"/>
		<cfargument name="server" type="string" required="true"/>
		
		<cfset fxn_struct = StructNew()/>
		<cfset farray = ArrayNew(1)/>
		
		<cftry>
			<!--- get functional hit for seed database --->
			<cfset fxnHit = getBlastHit(id=arguments.id,server=arguments.server,database=application.seed,fxnHit=1)/>
			
			<!--- if functional seed hit exist get seed annotation --->
			<cfif fxnHit.recordcount>
				<!--- add seed blast hit info to struct. --->
				<cfset fxn_struct = blastStructHelper(qry=fxnHit)/>
						
				<!--- check if multiple hit names. --->
				<cfset idx = iif(Find(";",fxnHit.hit_name,0),Find(";",fxnHit.hit_name,0)-1,len(fxnHit.hit_name))/>
				<cfset acc = Left(fxnHit.hit_name,idx) />
				
				<cfquery name="fx" datasource="#application.lookupDSN#">
					SELECT 	s.fxn1,
							s.fxn2,
							s.subsystem,
							s.organism,
							s.desc
					FROM	seed s
					WHERE	s.realacc = <cfqueryparam cfsqltype="cf_sql_varchar" value="#acc#"/>
				</cfquery>
				
				<cfloop query="fx">
					<cfset fxnstr = StructNew()/>
										
					<cfset StructInsert(fxnstr,"FXN1",fx.fxn1)/>
					<cfset StructInsert(fxnstr,"FXN2",fx.fxn2)/>
					<cfset StructInsert(fxnstr,"SUBSYSTEM",fx.subsystem)/>
					<cfset StructInsert(fxnstr,"DESC",fx.desc)/>
					<cfset StructInsert(fxnstr,"ORGANISM",fx.organism)/>
					<cfset ArrayAppend(farray,fxnstr)/>					
				</cfloop>
				
				<cfset StructInsert(fxn_struct,"FXNANNO",farray)/>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - GETSEEDFXN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn fxn_struct/>
	</cffunction>

	<cffunction name="getKEGGFxn" access="private" returntype="Struct">
		<cfargument name="id" type="numeric" required="true"/>
		<cfargument name="server" type="string" required="true"/>
		
		<cfset fxn_struct = StructNew()/>
		<cfset farray = ArrayNew(1)/>
		
		<cftry>
			<!--- get functional hit for seed database --->
			<cfset fxnHit = getBlastHit(id=arguments.id,server=arguments.server,database=application.kegg,fxnHit=1)/>
			
			<!--- if functional seed hit exist get seed annotation --->
			<cfif fxnHit.recordcount>
				<!--- add seed blast hit info to struct. --->
				<cfset fxn_struct = blastStructHelper(qry=fxnHit)/>
			
				<!--- check if multiple hit names. --->
				<cfset idx = iif(Find(";",fxnHit.hit_name,0),Find(";",fxnHit.hit_name,0)-1,len(fxnHit.hit_name))/>
				<cfset acc = Left(fxnHit.hit_name,idx) />
				
				<cfquery name="q" datasource="#application.lookupDSN#">
					SELECT 	k.fxn1,
							k.fxn2,
							k.fxn3,
							k.ec_no
					FROM	kegg k
					WHERE	k.realacc = <cfqueryparam cfsqltype="cf_sql_varchar" value="#acc#"/>
				</cfquery>
				
				<cfloop query="q">
					<cfset fxnstr = StructNew()/>
					<cfset StructInsert(fxnstr,"FXN1",q.fxn1)/>
					<cfset StructInsert(fxnstr,"FXN2",q.fxn2)/>
					<cfset StructInsert(fxnstr,"FXN3",q.fxn3)/>
					<cfset StructInsert(fxnstr,"ECNO",q.ec_no)/>
					<cfset ArrayAppend(farray,fxnstr)/>
				</cfloop>
				
				<cfset StructInsert(fxn_struct,"FXNANNO",farray)/>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - GETKEGGFXN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn fxn_struct/>
	</cffunction>

	<cffunction name="getCOGFxn" access="private" returntype="Struct">
		<cfargument name="id" type="numeric" required="true"/>
		<cfargument name="server" type="string" required="true"/>
		
		<cfset fxn_struct = StructNew()/>
		<cfset farray = ArrayNew(1)/>
		
		<cftry>
			<!--- get functional hit for seed database --->
			<cfset fxnHit = getBlastHit(id=arguments.id,server=arguments.server,database=application.cog,fxnHit=1)/>
			
			<!--- if functional seed hit exist get seed annotation --->
			<cfif fxnHit.recordcount>
				<!--- add seed blast hit info to struct. --->
				<cfset fxn_struct = blastStructHelper(qry=fxnHit)/>
						
				<!--- check if multiple hit names. --->
				<cfset idx = iif(Find(";",fxnHit.hit_name,0),Find(";",fxnHit.hit_name,0)-1,len(fxnHit.hit_name))/>
				<cfset acc = Left(fxnHit.hit_name,idx) />
				
				<cfquery name="q" datasource="#application.lookupDSN#">
					SELECT 	c.fxn1,
							c.fxn2,
							c.fxn3
					FROM	cog c
					WHERE	c.realacc = <cfqueryparam cfsqltype="cf_sql_varchar" value="#acc#"/>
				</cfquery>
				
				<cfloop query="q">
					<cfset fxnstr = StructNew()/>
					<cfset StructInsert(fxnstr,"FXN1",q.fxn1)/>
					<cfset StructInsert(fxnstr,"FXN2",q.fxn2)/>
					<cfset StructInsert(fxnstr,"FXN3",q.fxn3)/>
					<cfset ArrayAppend(farray,fxnstr)/>
				</cfloop>
				
				<cfset StructInsert(fxn_struct,"FXNANNO",farray)/>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - GETCOGFXN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn fxn_struct/>
	</cffunction>

	<cffunction name="getACLAMEFxn" access="private" returntype="Struct">
		<cfargument name="id" type="string" required="true"/>
		
		<cfset struct = StructNew()>
		
		<cftry>
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - GETACLAMEFXN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn struct/>
	</cffunction>

	<cffunction name="getGOFxn" access="private" returntype="Struct">
		<cfargument name="id" type="numeric" required="true"/>
		<cfargument name="server" type="string" required="true"/>
		
		<cfset fxn_struct = StructNew()>
		<cfset farray = ArrayNew(1)/>
		
		<cftry>
			<!--- get functional hit for go database --->
			<cfset fxnHit = getBlastHit(id=arguments.id,server=arguments.server,database=application.uniref,fxnHit=1)/>
			
			<!--- if functional seed hit exist get seed annotation --->
			<cfif fxnHit.recordcount>
				<!--- add go blast hit info to struct. --->
				<cfset fxn_struct = blastStructHelper(qry=fxnHit)/>
						
				<!--- check if multiple hit names. --->
				<cfset idx = iif(Find(";",fxnHit.hit_name,0),Find(";",fxnHit.hit_name,0)-1,len(fxnHit.hit_name))/>
				<cfset acc = Left(fxnHit.hit_name,idx) />
				
				<cflog file="virome" text="#acc#" type="information">
				
				<cfquery name="q" datasource="#application.lookupDSN#">
					SELECT 	s.acc_chain,
							s.desc_chain
					FROM	goslim s 
						inner join 
							goslimfxn sf on s.acc = sf.go_num
					WHERE	sf.realacc = <cfqueryparam cfsqltype="cf_sql_varchar" value="#acc#"/>
				</cfquery>
				
				<cfloop query="q">
					<cfset fxnstr = StructNew()/>
					<cfset q.acc_chain = Replace(q.acc_chain,";","[br/]","All")/>
					<cfset q.acc_chain = Replace(q.acc_chain,"<","&lt; ","All")/>
					<cfset q.acc_chain = Replace(q.acc_chain,"[br/]","<br/>","All")/>
					
					<cfset q.desc_chain = Replace(q.desc_chain,";","[br/]","All")/>
					<cfset q.desc_chain = Replace(q.desc_chain,"<","&lt; ","All")/>
					<cfset q.desc_chain = Replace(q.desc_chain,"[br/]","<br/>","All")/>
					
					<!--- remove last occurance of &lt; --->
					<cfset q.acc_chain = REReplace(q.acc_chain, "(.*)&lt; ","\1")/>
					<cfset q.desc_chain = REReplace(q.desc_chain, "(.*)&lt; ","\1")/>
					
					<cfset StructInsert(fxnstr,"GOSLIM_ACC",q.acc_chain)/>
					<cfset StructInsert(fxnstr,"GOSLIM_DESC",q.desc_chain)/>
					<cfset arrayAppend(farray,fxnstr)/>
				</cfloop>
				
				<cfset StructInsert(fxn_struct,"FXNANNO",farray)/>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - GETGOFXN", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn fxn_struct/>
	</cffunction>

	<cffunction name="getSequenceInfo" access="remote" returntype="Struct">
		<cfargument name="id" type="Numeric" required="true"/>
		<cfargument name="name" type="String" required="true"/>
		<cfargument name="environment" type="String" required="true"/>
		<cfargument name="tabIndex" type="Numeric" required="true"/>

		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.environment) />
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cfset struc = StructNew()>
		<cfset _readId = 0>
		
		<cftry>
			<!--- id passed in will always be sequence Id of an orf, so first
			get the read information of the given orf --->
			<cfquery name="q" datasource="#_server#">
				SELECT distinct s.id,
								s.name,
								s.basepair,
								s.size,
								o.strand,
								o.frame,
								o.score,
								o.type,
								o.start,
								o.end,
								o.model
				FROM	sequence s
					INNER JOIN
						orf o on s.id = o.seqId
				WHERE	s.deleted = 0
					and o.deleted = 0
					and o.seqId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				ORDER BY o.seqId
			</cfquery>
			
			<!--- if there is an orf value, then there will alway be a read,
			so no need to check if query returned anything rows. 
			IF RQ IS EMPTY THEN THERE IS A DISCREPANCY IN THE DATABASE --->
			<cfoutput query="q" maxrows="1">
				<cfscript>
					oStruct = StructNew();
					StructInsert(oStruct,"ID",q.id);
					StructInsert(oStruct,"NAME",q.name);
					StructInsert(oStruct,"BASEPAIR",q.basepair);
					StructInsert(oStruct,"SIZE",q.size);
					StructInsert(oStruct,"STRAND",q.strand);
					StructInsert(oStruct,"FRAME",q.frame);
					StructInsert(oStruct,"SCORE",q.score);
					StructInsert(oStruct,"TYPE",q.type);
					StructInsert(oStruct,"START",q.start);
					StructInsert(oStruct,"END",q.end);
					StructInsert(oStruct,"MODEL",q.model);
					StructInsert(oStruct,"TABINDEX",arguments.tabIndex);
										
					return oStruct;					
				</cfscript>
			</cfoutput>

			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - GETSEQUENCEINFO", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="orfBlastHit" access="remote" returntype="Struct">
		<cfargument name="id" type="Numeric" required="true" />
		<cfargument name="environment" type="String" required="true" />
		<cfargument name="tabindex" type="Numeric" requried="true" />
		<cfargument name="database" type="String" required="false" default=""/>
		<cfargument name="topHit" type="Numeric" required="false" default="1"/>
				
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.environment) />
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cfset local.struct = StructNew()>
		<cfset local.struct['TABINDEX']=arguments.tabindex/>
		
		<cftry>
			<cfset arr = ArrayNew(1)>
			<cfset blast=getBlastHit(id=arguments.id,topHit=arguments.topHit,server=_server,database=arguments.database)/>
			
			<cfif IsQuery(blast) and blast.recordCount>
				<cfset img = getBlastImage(qry=blast,sname=blast.query_name)/>
				<cfif (NOT StructKeyExists(local.struct,"IMAGE"))>
					<cfset StructInsert(local.struct,"IMAGE",img)/>
				</cfif>
			
				<cfloop query="blast">
					<cfset splt = splitBlastResult(qry=blast,idx=blast.currentRow,server=_server,environment=arguments.environment) />
					
					<!--- when adding hsp for the first time or only time for a given database --->
					<cfset arr = ArrayNew(1)>
					<cfset ArrayAppend(arr,splt)/>
					<cfset StructInsert(local.struct,blast.database_name,arr)/>
				</cfloop>
			</cfif>

			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - GETORFINFO", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>

		<cfreturn local.struct>
	</cffunction>
	
	<cffunction name="orfBlastDetails" access="remote" returntype="Array">
		<cfargument name="id" type="Numeric" required="true" />
		<cfargument name="environment" type="String" required="true" />
		<cfargument name="database" type="String" required="false" default=""/>
		
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.environment) />
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cfset local.arr = ArrayNew(1)>
		<cftry>
			<cfset blast=getBlastHit(id=arguments.id,server=_server,database=arguments.database)/>
			
			<cfset local.arr = CreateObject("component", application.cfc & ".Utility").QueryToStruct(Query=blast)/>
			
			<cfloop from="1" to="#ArrayLen(local.arr)#" index="idx">
				<!--- remove metagenome description reformat correct value should be in blast table --->
				<!---<cfif (database eq "METAGENOMES")>
					<cfset _hitdesc = CreateObject("component",  application.cfc & ".Utility").getMetaHitDesc(hitName=local.arr[idx].hit_name)/>
					<cfset StructUpdate(local.arr[idx], "HIT_DESCRIPTION", "#_hitdesc#")/>
				</cfif>--->
				
				<!--- filename --->
				<cfset tabFileName = local.arr[idx].query_name&"_mini.txt">
				<cfset imgFileName = local.arr[idx].query_name&"_mini.gif">
				
				<!--- create file for mini blast image --->
				<cfset local.str = local.arr[idx].PERCENT_IDENTITY & "     " & 
									local.arr[idx].QRY_START & "     " & 
									local.arr[idx].QRY_END & "     " & 
									1 & "     " & 
									local.arr[idx].SUBJECT_LENGTH & "     " & 
									local.arr[idx].E_VALUE & "     " & 
									local.arr[idx].BIT_SCORE/>
							
				<cfscript>
					myfile = FileOpen("#application.blastImgFilePath#/txt/#tabFileName#","write","UTF-8");
					FileWriteLine(myfile,"#local.str##application.NL#");
					FileClose(myfile);
				</cfscript>
				
				<!---<cffile action="write" mode="755" file="#application.blastImgFilePath#/txt/#tabFileName#" output="#local.str#" addnewline="true">--->
				
				<cfset imgData = "">

				<cfexecute 	name="#application.blastImgFilePath#/mini_wrapper.sh"
			                arguments="#application.blastImgFilePath#/txt/#tabFileName#"
			                outputFile="#application.blastImgFilePath#/img/#imgFileName#"
			                timeout="10">
				</cfexecute>
						
				<cfset StructInsert(local.arr[idx], "IMAGE", "#application.rootHostPath#/blastImager/img/#imgFileName#")/>
			</cfloop>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - ORFBLASTDETAILS", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn local.arr/>
	</cffunction>

	<cffunction name="heatMap" access="remote" returntype="Struct">
		<cfargument name="id" type="Numeric" required="true" />
		<cfargument name="environment" type="String" required="true" />
		<cfargument name="tabindex" type="Numeric" requried="true" />
		
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.environment)/>
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cfset struct = StructNew()>
		<cfset struct['TABINDEX']=arguments.tabindex/>
		
		<cftry>
			<cfset blast=getBlastHit(id=arguments.id,topHit=-1,server=_server)/>
			<cfset range = ArrayNew(1)/>
			<cfset emin = 1000>
			<cfset emax = 0>
			<cfset cmin = 10000>
			<cfset cmax = -1>
			<cfset temp = 0>
			
			<cfif IsQuery(blast)>
				<cfoutput query="blast" group="sequenceId">
					<cfoutput group="database_name">
						<cfset arr = ArrayNew(1)/>
						<cfset cnt = 1>
						<cfoutput>
							<cfscript>
								//remove metagenome description reformat correct value should be in blast table
								/*
								if (blast.database_name eq "METAGENOMES")
									_hitdesc = CreateObject("component",  application.cfc & ".Utility").getMetaHitDesc(hitName=blast.hit_name);
								*/
								 _hitdesc = blast.hit_description;

								if (emin gt blast.e_value)
									emin = blast.e_value;
								if (emax lt blast.e_value)
									emax = blast.e_value;
								
								temp = (abs(blast.qry_start-blast.qry_end+1)/blast.size)*100;; 
								
								if (cmin gt temp)
									cmin = temp;
								if (cmax lt temp)
									cmax = temp;
									
								if (cnt <= 10){
									clr = StructNew();
									
									// temp value for color.
									clr['COLOR'] = 0;
									clr['HITDESCRIPTION'] = _hitdesc;
									clr['ENVIRONMENT'] = arguments.environment;
									clr['BLASTID'] = blast.id;
									clr['SEQUENCEID'] = blast.sequenceId;
									clr['DATABASE'] = blast.database_name;
									clr['EVALUE'] = blast.e_value;
									clr['QCOVER'] = temp;
									clr['EMIN'] = 0;
									clr['EMAX'] = 0;
									clr['CMIN'] = 0;
									clr['CMAX'] = 0;
									// add more info to struct.
									ArrayAppend(arr,clr);
									cnt = cnt +1;
								}
							</cfscript>
						</cfoutput> <!--- all hits per db --->
						<cfset StructInsert(struct,blast.database_name,arr)>
					</cfoutput> <!--- all db --->
				</cfoutput> <!--- all blast --->
				
				<!--- update color values --->
				<cfloop collection="#struct#" item="idx">
					<cfif idx neq "TABINDEX">
						<cfset arr = StructFind(struct,idx)>
						<cfloop from="1" to="#ArrayLen(arr)#" index="i">
							<cfset arr[i]['COLOR'] = createobject("component", application.cfc & ".Utility")
									.ECToHexColor(arr[i]['EVALUE'],arr[i]['QCOVER'],emin,emax,cmin,cmax) />
							<cfset arr[i]['EMIN'] = emin/>
							<cfset arr[i]['EMAX'] = emax/>
							<cfset arr[i]['CMIN'] = cmin/>
							<cfset arr[i]['CMAX'] = cmax/>
						</cfloop>
						<cfset StructUpdate(struct,idx,arr)/>
					</cfif>
				</cfloop>
				
			</cfif>

			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").
					reporterror("ORFRPC.CFC - HEATMAP", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>

		<cfreturn struct>
	</cffunction>	
</cfcomponent>