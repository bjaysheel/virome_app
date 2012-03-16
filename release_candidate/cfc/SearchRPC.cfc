<cfcomponent displayname="SearchDB" output="true">

	<cffunction name="getORFSeqIdFromRead" access="remote" returntype="String" hint="Get ORF sequenceId when ReadIds are passed">
		<cfargument name="readId" type="string" required="true"/>
		<cfargument name="server" type="String" required="true"/>
		
		<cfset ids = ""/>
		<cftry>
			<cfquery name="orf2read" datasource="#arguments.server#">
				SELECT 	seqId
				FROM	orf
				WHERE	readId in (#arguments.readId#)
			</cfquery>
			
			<cfset ids = VALUELIST(orf2read.seqId)/>
			
			<cfcatch>
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("SEARCH.CFC - GETORFSEQIDFROMREAD", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn ids/>
	</cffunction>
	
	<cffunction name="retrieveSequenceId_A" access="remote" returntype="String" hint="Get sequenceId for idfile xdoc">
		<cfargument name="tag" type="string" required="true"/>
		<cfargument name="file" type="string" required="true"/>
		<cfargument name="server" type="String" required="true"/>
		
		<cftry>
			<cffile action="read" file="#application.xDocsFilePath#/#arguments.file#" variable="idXDoc"/>
			
			<cfset xdoc = xmlparse(idXDoc)/>
			
			<cfset searchXML = xmlSearch(xdoc,'/root/'&arguments.tag)/>
			<cfif isArray(searchXML) and isXMLNode(searchXML[1])>
				
				<cfset tbl_name = "tmp_" & DateFormat(now(),"mmddyy") & "" & TimeFormat(now(),"hhmmss")/>
				<cfset values = searchXML[1].XmlAttributes.IDLIST/>
				<cfset values = rereplace(values,",","),(","all" )/>
				<cfset values = "("&values&")"/>
					
				<cftransaction>
					<cfquery name="ctmp" datasource="#arguments.server#">
						CREATE TEMPORARY TABLE #tbl_name# (id int(8) UNIQUE)
					</cfquery>
					
					<cfquery name="itmp" datasource="#arguments.server#" >
						INSERT INTO #tbl_name# (id) VALUES #values#
					</cfquery>					
				</cftransaction>
				
				<cfreturn tbl_name/>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("SEARCH.CFC - RETRIEVESEQUENCEID_A", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn ''/>
	</cffunction>
	
	<cffunction name="retrieveSequenceId_B" access="remote" returntype="any" hint="Get sequenceIds for vircats">
		<cfargument name="str" type="String" required="true" />
		<cfargument name="server" type="String" required="true"/>
		<cfargument name="library" type="String" required="true"/>
		
		<cftry>	
			<cfset idExistsStruct = structNew()/>
			<cfset idList=''/>
			
			<cfloop list="#arguments.library#" index="idx">
				<cfquery name="s" datasource="#arguments.server#">
					SELECT	#arguments.str# as file
					FROM	statistics
					WHERE	libraryId = #idx#
					and 	deleted=0
				</cfquery>
				
				<cfset ids = ""/>
				<cfif s.recordCount>
					<cfscript>
						ids = FileOpen(application.idFilePath & "/" & s.file);
					</cfscript>
				</cfif>

				<!--- if filtering tRNA get all orfs that belong to readIds in var=>ids --->
				<cfif #arguments.str# eq 'tRNA_id'>
					<cfset ids = getORFSeqIdFromRead(ids,arguments.server)/>
				</cfif>
				
				<!--- if ids are available append it to the list, make sure not duplicate ids exist --->
				<cfif len(ids)>
					<cfloop list="#ids#" index="id_idx">
						<cfif NOT StructKeyExists(idExistsStruct,id_idx)>
							<cfset idExistsStruct[id_idx] = true/>
							<cfset idList=listAppend(idList,id_idx)/>
						</cfif>
					</cfloop>
				</cfif>
			</cfloop>
			
			<cfif len(idList)>
				<cfset tbl_name = "tmp_" & DateFormat(now(),"mmddyy") & "" & TimeFormat(now(),"hhmmss")/>
				<cfset values = listsort(idList,"text","asc")/>
				<cfset values = rereplace(values,",","),(","all" )/>
				<cfset values = "("&values&")"/>
					
				<cftransaction>
					<cfquery name="ctmp" datasource="#arguments.server#">
						CREATE TEMPORARY TABLE #tbl_name# (id int(8) UNIQUE)
					</cfquery>
					
					<cfquery name="itmp" datasource="#arguments.server#" >
						INSERT INTO #tbl_name# (id) VALUES #values#
					</cfquery>					
				</cftransaction>
				
				<cfreturn tbl_name/>
			<cfelse>
				<cfreturn ''/>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("SEARCH.CFC - RETRIEVESEQUENCEID_B", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="partialSearchQuery" access="public" returntype="String" description="create comman query string used for getSearchCount, and getSearchResult">
		<cfargument name="obj" type="struct" required="true" >
		<cfargument name="read" type="boolean" default="false"/>
		 
		<cfset _libraryId = ""/>
		<cfset database_list = ""/>
		<cfset database_name = ""/>
		<cfset seq_tmp_tbl = ""/>
		<cfset queryStr = ""/>
		
		<cftry>
			<!--- get server from either sequence name using prefix or from environment --->
			<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
			<cfset _server = _serverObject['server']/>
			<cfset _environment = _serverObject['environment']/>
			
			<!--- error checking if _server is empty return error and stop --->
			<cfif NOT len(_server)>
				<cfset CreateObject("component",  application.cfc & ".Utility").reportServerError(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
				<!---<cfthrow type="INCORRECT_ENV_SEQ" />--->
				<cfreturn ""/>
			</cfif>
			
			<!--- set _libraryId info --->
			<cfif (isDefined("arguments.obj.LIBRARY") and (arguments.obj.LIBRARY gt -1))>
				<cfset _libraryId = #arguments.obj.LIBRARY# />
			<cfelse>
				<cfset _libraryId = CreateObject("component",  application.cfc & ".Utility").getLibraryList(_environment)/>
			</cfif>
			
			<!--- get seqeunce ids from idFiles --->
			<cfif len(arguments.obj.TAG) and len(arguments.obj.IDFILE)>
				<cfset seq_tmp_tbl = retrieveSequenceId_A(tag=arguments.obj.TAG,file=arguments.obj.IDFILE,server=_server)/>
			<!--- get sequence ids from stats flat files --->
			<cfelseif isDefined("arguments.obj.ORFTYPE") and len(arguments.obj.ORFTYPE)>
				<cfset seq_tmp_tbl = retrieveSequenceId_B(str=arguments.obj.ORFTYPE & "_id",server=_server,library=_libraryId)/>
				<!--- if value retuned from retrieveSequenceId_B is empty, assume that there are no seq in orftype return empty array now no need to proceed--->
				<cfif not len(seq_tmp_tbl)>
					<!---<cfthrow type="EMPTY_CATEGORY" />--->
					<cfreturn ""/>
				</cfif>
			<!--- get sequence ids from stats flat files --->				
			<cfelseif isDefined("arguments.obj.VIRCAT") and len(arguments.obj.VIRCAT)>
				<cfif not len(seq_tmp_tbl)>
					<!--- if value retuned from retrieveSequenceId_B is empty, assume that there are no seq in vircat return empty array now no need to proceed--->
					<cfset seq_tmp_tbl = retrieveSequenceId_B(str=arguments.obj.VIRCAT & "_id",server=_server,library=_libraryId)/>
					<cfif not len(seq_tmp_tbl)>
						<!---<cfthrow type="EMPTY_CATEGORY" />--->
						<cfreturn ""/>
					</cfif>	
				</cfif>
			</cfif>	
			
			<!--- get orfs belonging to given read. --->
			<cfif isDefined("arguments.obj.READID") and len(arguments.obj.READID)>
				<cfset arguments.obj.SEQUENCEID = getORFSeqIdFromRead(arguments.obj.READID,_server) & "," & arguments.obj.SEQUENCEID/>
				<cfset arguments.obj.SEQUENCEID = REReplace(arguments.obj.SEQUENCEID,",$","","one")/>
			</cfif>
			
			<!--- set database str --->
			<cfif isDefined("arguments.obj.BLASTDB") and len(arguments.obj.BLASTDB)>
				<cfset database_name = "b.database_name = '#arguments.obj.BLASTDB#'"/>
			<cfelseif (isDefined("arguments.obj.VIRCAT") and len(arguments.obj.VIRCAT)) and ((arguments.obj.VIRCAT eq 'fxn') or (arguments.obj.VIRCAT eq 'unassignfxn'))>
				<cfset database_list = "(b1.database_name <> 'NOHIT') and (b1.database_name <> 'METAGENOMES')"/>
			<cfelseif (isDefined("arguments.obj.ORFTYPE") and len(arguments.obj.ORFTYPE))>
				<cfset database_list = "(b1.database_name = 'UNIREF100P') or (b1.database_name = 'METAGENOMES')"/>
			<cfelseif NOT ((isDefined("arguments.obj.BLASTDB") and len(arguments.obj.BLASTDB)))>		
				<cfset database_list = "(b1.database_name = 'UNIREF100P') or (b1.database_name = 'METAGENOMES') or (b1.database_name = 'NOHIT')"/>
			</cfif>
			
			<cfscript>
				if (len(database_list)) {
					queryStr &=	" FROM (SELECT b1.sequenceId, MAX(b1.db_ranking_code) AS db_ranking_code";
					querystr &= " FROM 	blastp b1 INNER JOIN sequence s1 ON s1.id=b1.sequenceId"; 
					queryStr &= " WHERE b1.e_value <= #arguments.obj.EVALUE#";
								 		 
						 	if (IsNumeric(_libraryId)) {
						 		queryStr &= " and s1.libraryId = #_libraryId#";
						 	} else {
						 		queryStr &= " and s1.libraryId in (#_libraryId#)";
							}
						
							if (isDefined("arguments.obj.VIRCAT") and len(arguments.obj.VIRCAT) and (arguments.obj.VIRCAT eq 'fxn')) {
								queryStr &= " and b1.fxn_topHit=1";
							} else {
								queryStr &= " and b1.sys_topHit=1";
							}
							
							queryStr &= " and (#database_list#)";										
							queryStr &= " GROUP BY b1.sequenceId) p2"; 
								 
					queryStr &= " INNER JOIN blastp b on p2.sequenceId = b.sequenceId";
				} else {
					queryStr = " FROM blastp b";
				}
				
				queryStr &= " INNER JOIN sequence s on b.sequenceId = s.id";
				
				if (arguments.read){
					queryStr &=	" INNER JOIN orf o on o.seqId = s.id";
					queryStr &= " INNER JOIN sequence r on r.id = o.readId";
				}
				
				if (len(seq_tmp_tbl)){
					queryStr &= " INNER JOIN #seq_tmp_tbl# st on s.id = st.id";
				}
				
				queryStr &= " WHERE	s.deleted = 0";
				queryStr &= " and b.deleted = 0"; 
				
				if (len(database_list)){
					queryStr &= " and b.db_ranking_code = p2.db_ranking_code";
				} else {
					queryStr &= " and #database_name#";
				}
				
				if (isNumeric(_libraryId)){
					queryStr &= " and s.libraryId = #_libraryId#"; 
				} else {
					queryStr &= " and s.libraryId in (#_libraryId#)";	
				}
							
				if (isDefined("arguments.obj.SEQUENCE") and len(arguments.obj.SEQUENCE)){
					queryStr &= " and s.name like '#arguments.obj.SEQUENCE#%'";
				}
							
				if (isDefined("arguments.obj.ACCESSION") and len(arguments.obj.ACCESSION)){
					queryStr &= " and b.hit_name like '#arguments.obj.ACCESSION#%'";
				}
						
				if (isDefined("arguments.obj.TERM") and len(arguments.obj.TERM)){
					queryStr &= " and b.hit_description like '%#arguments.obj.TERM#%'";
				}
				
				if (isDefined("arguments.obj.TAXONOMY") and len (arguments.obj.TAXONOMY) and 
					isDefined("arguments.obj.INTAXONOMY") and len(arguments.obj.INTAXONOMY)){
					queryStr &= " and b.#arguments.obj.INTAXONOMY# like '%#arguments.obj.TAXONOMY#%'";		
				}
				
				if (isDefined("arguments.obj.VIRCAT") and len(arguments.obj.VIRCAT) and (arguments.obj.VIRCAT eq 'fxn')){
					queryStr &= " and b.fxn_topHit=1";
				} else {
					queryStr &= " and b.sys_topHit=1";
				}
				
				queryStr &= " and b.e_value <= #arguments.obj.EVALUE#";
			</cfscript>
		
			<cfcatch type="any">
				<cfset queryStr = ""/>
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("SEARCH.CFC - PARTIALSEARCHQUERY", 
						#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>		
		</cftry>
		
		<cfreturn queryStr/>
	</cffunction>

	<cffunction name="prepareRS" access="remote" returntype="struct">
		<cfargument name="obj" type="Struct" required="true" />
		
		<cfset struct = StructNew()/>
		<cfset struct['MSG'] = "FAILED"/>
		<cfset struct['USERID'] = ""/>
		<cfset struct['JOBNAME'] = ""/>
		<cfset struct['JOBALIAS'] = ""/>
		<cfset struct['DATECREATED'] = ""/>
		<cfset struct['SEARCHPARAM'] = ""/>
		<cfset struct['RCD_COUNT'] = 0/>
		
		<cfset _arr = ArrayNew(1)/>
		<cfset partialQuery = partialSearchQuery(arguments.obj)/>
		
		<cfif partialQuery eq "">
			<!---<cfthrow type="EMPTY_PARTIAL_QUERY" >--->
			<!---<cfreturn _arr/>--->
			<cfreturn struct>
		</cfif>

		<!--- get server from either sequence name using prefix or from environment --->
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>

		<cftry>
			<cfquery name="srch_qry" datasource="#_server#">
				SELECT	distinct
						s.id as sequenceId,
						s.name,
						s.size,
						s.libraryId,
						b.id as blastId,
						b.query_length,
						b.algorithm,
						b.database_name,
						b.hit_name,
						b.hit_description,
						b.qry_start,
						b.qry_end,
						b.hit_start,
						b.hit_end,
						b.percent_similarity,
						b.percent_identity,
						b.raw_score,
						b.bit_score,
						b.subject_length,
						b.e_value,
						b.sys_topHit,
						b.user_topHit,
						'#_environment#' as environment
				
				#PreserveSingleQuotes(partialQuery)#
				
				ORDER BY s.id, b.database_name desc, b.e_value asc
			</cfquery>
				
			<cfif srch_qry.RecordCount>
				<cfset _arr = CreateObject("component",  application.cfc & ".Utility").QueryToStruct(srch_qry)>	

				<cfscript>	
					jobId = application.SessionId;
					dir = lcase(application.searchFilePath & "/" & jobId);

					if ((isDefined("arguments.obj.USERNAME")) and len(arguments.obj.USERNAME)){
						dir = lcase(application.searchFilePath & "/" & arguments.obj.USERNAME);
						jobId = arguments.obj.USERID;
					}
				</cfscript>
					
				<cfif (not DirectoryExists(dir))>
					<cfdirectory action="create" directory="#dir#">
				</cfif> 

				<cfscript>
					//if (not DirectoryExists(dir))
					//	DirectoryCreate(dir);
					
					fname = _environment;
					if (isDefined("arguments.obj.LIBRARY") and (arguments.obj.LIBRARY gt -1)){
						lib = CreateObject("component",  application.cfc & ".Library").getLibrary(id=arguments.obj.LIBRARY);
						fname &= "_" & lib.name;
						fname = ReReplaceNoCase(fname,"\s+","_","all");
					} 
					fname &= "_#DateFormat(now(),"mmddyy")##TimeFormat(now(),"hhmmss")#.txt";
					
					myfile = FileOpen(lcase(dir &"/"& fname), "write", "UTF-8");					
					FileWriteLine(myfile,SerializeJSON(_arr));
					FileClose(myfile);
					
					struct['MSG'] = "Success";
					struct['USERID'] = jobId;
					struct['JOBNAME'] = fname;
					struct['JOBALIAS'] = arguments.obj.ALIAS;
					struct['SEARCHPARAM'] = arguments.obj;
					struct['DATECREATED'] = createODBCDateTime(now());
					struct['RCD_COUNT'] = srch_qry.RecordCount;
				</cfscript>
				
				<cfif isDefined("arguments.obj.USERID") and (arguments.obj.USERID gt 0)>
					<cfset CreateObject("component", application.cfc & ".Bookmark").add(arguments.obj,fname,srch_qry.RecordCount)/>	
				</cfif>
				
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("SEARCH.CFC - PREPARERS", 
						#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn struct/>
	</cffunction>
	
	<cffunction name="getSearchRSLT" access="remote" returntype="Array">
		<cfargument name="obj" type="struct" required="true">
		
		<cfset arr = ArrayNew(1)>
		<cfset jobId = arguments.obj.USERID/>
		
		<cfif REFind("^VIROME_",jobId) eq 0>
			<cfset uStruct = StructNew()/>
			<cfset uStruct['USERID'] = jobId/>
			<cfset userObj = CreateObject("component", application.cfc & ".User").GetUser(uStruct)/>
			<cfset jobId = userObj['USERNAME']/>
		</cfif>
		
		<cftry>
			<cfscript>
					fname = lcase(application.searchFilePath & "/" & jobId & "/" & arguments.obj.JOBNAME); 
					myfile = FileOpen(fname,"read","UTF-8");
					
					while(NOT FileIsEOF(myfile)) {
						data = FileReadLine(myfile);
					}
					FileClose(myfile);
					
					arr = deserializeJSON(data);
					
					return arr;
				</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("SEARCH.CFC - GETSEARCHRSLT", 
						#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>			
		</cftry> 
		
		<cfreturn arr/>
	</cffunction>

	<cffunction name="getBlastSearch" access="remote" returntype="String">
		
		<cfargument name="obj" type="Struct" required="true">

		<cftry>
			<!--- remove all but first seq. --->
			<cfset idx = Find(">",arguments.obj.SEQUENCE,3)>
			<cfif idx>
				<cfset SEQUENCE = Left(arguments.obj.SEQUENCE,idx-1)>
				<cfset SEQUENCE = REReplace(arguments.obj.SEQUENCE," ", "","ALL")>
				<cfset SEQUENCE = REReplace(arguments.obj.SEQUENCE,"#chr(10)#", "","ALL")>
				<cfset SEQUENCE = REReplace(arguments.obj.SEQUENCE,"#chr(13)#", "","ALL")>
			<cfelse>
				<cfset SEQUENCE = REReplace(arguments.obj.SEQUENCE,">","","ALL")/>
			</cfif>

			<!--- setup blast url --->
			<cfset str="http://128.175.253.180/blast/blast_cs.cgi?PROGRAM=#arguments.obj.PROGRAM#&DATALIB=#arguments.obj.DATABASE#&INPUT_TYPE=Sequence+in+FASTA+format&SEQUENCE=#SEQUENCE#&EXPECT=#arguments.obj.EXPECT#&ALIGNMENT_VIEW=0&DESCRIPTIONS=#arguments.obj.DESCRIPTION#">

			<!--- set http request --->
			<cfhttp url="#str#" method="get" result="response"/>

			<!--- save response to local var --->
			<cfset contentStr = response.FileContent>

			<!--- remove top section of response --->
			<cfset contentStr = REReplaceNoCase(contentStr,"<!--.*-->","","all")>
			<cfset contentStr = ReReplaceNoCase(contentStr,"</Body>.*","","all")>
			<cfset contentStr = REReplaceNoCase(contentStr,"^.*<b>Database","<b>Database","all")>
			<cfset contentStr = REReplaceNoCase(contentStr,"<b>|</b>|<BR>|<PRE>|</PRE>|<HR>|<form>|</form>|</a>|</font>|<h3>|</h3>","","all")>
			<cfset contentStr = ReReplaceNoCase(contentStr,"<a href = ##\d+>","","all")>
			<cfset contentStr = ReReplaceNoCase(contentStr,"<a name = \d+>","","all")>
			<cfset contentStr = ReReplaceNoCase(contentStr,"<font color=red>","","all")>
			
			<cfset tstr = contentStr/>
			<cfset idx = Find(">",tstr,0)>

			<cfloop condition="idx gt 0">
				<cfset count=Find(" ",tstr,idx)-idx>
				<cfset name=mid(tstr,idx+1,count-1)>
				<cfset ret = getSeqInfo(name)>
				<cfset link = "[#ret#]" & name &"[/#ret#]">
				<cfset contentStr = REReplaceNoCase(contentStr,name,link,"all")>
				<cfset idx = Find(">",tstr,idx+count)>
			</cfloop>

			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("SEARCH.CFC - GETBLASTSEARCH", 
								#cfcatch.Message#,#cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>

		<cfreturn contentStr>

	</cffunction>

	<cffunction name="getSeqInfo" access="private" returntype="String">
		<cfargument name="sequence_name" type="String" required="true">		
		
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName("",sequence_name)/>
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		<cfset retVal = "0_null">
		
		<cftry>
			<cfquery name="q" datasource="#_server#">
				SELECT	id
				FROM	sequence
				WHERE 	name = '#arguments.sequence_name#'
			</cfquery>

			<cfif q.recordcount gt 0>
				<cfset retVal = q.id &"_"& _server>
			</cfif>
	
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("SEARCH.CFC - GETSEQUINFO - #arguments.sequence_name#", 
								#cfcatch.Message#,#cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>

		<cfreturn retVal>

	</cffunction>
</cfcomponent>