<cfcomponent displayname="SearchRPC" output="true" hint="
			This componented is used to get everything Search related information.
			It is used to Search entire VIROME database (min req. Environment name).
			All search results are stored to be recalled later.
			">

	<cffunction name="getORFSeqIdFromRead" access="remote" returntype="String" hint="
				Get all ORF ids related to a given read/contig

				A helper function for:
					retrieveSequenceId_B()
					partialSearchQuery()

				Return: A comma seperated list of IDs
				">

		<cfargument name="readId" type="string" required="true" hint="Read ID"/>
		<cfargument name="server" type="String" required="true" hint="Server (database) name"/>

		<cftry>
			<cfset ids = ""/>

			<cfquery name="read2orf" datasource="#arguments.server#">
				SELECT 	sr.objectId
				FROM	sequence_relationship sr
				WHERE	sr.subjectId in (#arguments.readId#)
					and sr.typeId = 3
			</cfquery>

			<cfif read2orf.RecordCount>
				<cfset ids = VALUELIST(read2orf.objectId)/>
			</cfif>

			<cfcatch>
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="SearchRPC",
																						function_name=getFunctionCalledName(),
																						args=arguments,
																						msg=cfcatch.Message,
																						detail=cfcatch.Detail,
																						tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn ids/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="retrieveSequenceId_A" access="remote" returntype="String" hint="
				In order to return search results as fast as possible, sequence IDs
				of various categories that make up a give chart are stored in an XML document
				The list of ID per category (eg: VIROME functional category, top viral, top microbial ...)
				will not change unless library is re-run through VIROME pipeline.
				Instead of performing complex logic at  run-time to identify seqeunce IDs they are
				stored by VIROME pipeline taking advantage of computing power behind VIROME pipeline running
				on large cluster

				IDs are then stored in temprary indexed table to improve search performance

				A helper furnction for:
					partialSearchResult()

				Return: A temprary table name
				">

		<cfargument name="tag" type="string" required="true" hint="XML unique TAG index ID"/>
		<cfargument name="file" type="string" required="true" hint="ID file name"/>
		<cfargument name="server" type="String" required="true" hint="Server (database) name"/>

		<cftry>
			<cfset tbl_name = ""/>

			<cffile action="read" file="#request.xDocsFilePath#/#arguments.file#" variable="idXDoc"/>

			<cfset xdoc = xmlparse(idXDoc)/>

			<cfset searchXML = xmlSearch(xdoc,'/root/'&arguments.tag)/>
			<cfif isArray(searchXML) and isXMLNode(searchXML[1])>

				<cfset tbl_name = "tmp_" & DateFormat(now(),"mmddyy") & "" & TimeFormat(now(),"hhmmss")/>
				<cfset values = searchXML[1].XmlAttributes.IDLIST/>
				<cfset values = rereplace(values,",","),(","all" )/>
				<cfset values = "("&values&")"/>

				<cftransaction>
					<cfquery name="dtmp" datasource="#arguments.server#">
						DROP TEMPORARY TABLE IF EXISTS #tbl_name#
					</cfquery>

					<cfquery name="ctmp" datasource="#arguments.server#">
						CREATE TEMPORARY TABLE #tbl_name# (id bigint(19) UNIQUE)
					</cfquery>

					<cfquery name="itmp" datasource="#arguments.server#" >
						INSERT INTO #tbl_name# (id) VALUES #values#
					</cfquery>
				</cftransaction>
			</cfif>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="SearchRPC",
																						function_name=getFunctionCalledName(),
																						args=arguments,
																						msg=cfcatch.Message,
																						detail=cfcatch.Detail,
																						tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn tbl_name/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="retrieveSequenceId_B" access="remote" returntype="string" hint="
				In order to return search results as fast as possible, sequence IDs
				of various categories that make up a give chart are stored in an flat file (old method)
				Instead of performing complex logic at  run-time to identify seqeunce IDs they are
				stored by VIROME pipeline taking advantage of computing power behind VIROME pipeline running
				on large cluster

				IDs are then stored in temprary indexed table to improve search performance

				A helper furnction for:
					partialSearchResult()

				Return: A temporary table name
				">

		<cfargument name="str" type="String" required="true" hint="VIROME category name"/>
		<cfargument name="server" type="String" required="true" hint="Server (database) name"/>
		<cfargument name="library" type="String" required="true" hint="Library ID"/>

		<cftry>
			<cfset idExistsStruct = structNew()/>
			<cfset idList=''/>
			<cfset tbl_name = ""/>

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
						filename = #getFileFromPath(s.file)#; //hack for older verion where full path is stored in db.
						ids = FileRead(request.idFilePath & "/" & filename);
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
				<cfset tbl_name = "tmp_" & DateFormat(now(),"mmddyy") & "" & TimeFormat(now(),"hhmmssl")/>
				<cfset values = listsort(idList,"text","asc")/>
				<cfset values = rereplace(values,",","),(","all" )/>
				<cfset values = "("&values&")"/>

				<cftransaction>
					<cfquery name="dtmp" datasource="#arguments.server#">
						DROP TEMPORARY TABLE IF EXISTS #tbl_name#
					</cfquery>

					<cfquery name="ctmp" datasource="#arguments.server#">
						CREATE TEMPORARY TABLE #tbl_name# (id bigint(19) UNIQUE)
					</cfquery>

					<cfquery name="itmp" datasource="#arguments.server#">
						INSERT INTO #tbl_name# (id) VALUES #values#
					</cfquery>
				</cftransaction>
			</cfif>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="SearchRPC",
																						function_name=getFunctionCalledName(),
																						args=arguments,
																						msg=cfcatch.Message,
																						detail=cfcatch.Detail,
																						tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn tbl_name/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="partialSearchQuery" access="remote" returntype="String" description="
				Create a comman where clause query to be shared by various function.  Helper function
				to reduce duplication and easy of maintanence an already complex search query.

				A helper function for:
					getSearchCount() [DEPRICATED],
					getSearchResult()

				Return: A SQL string formated for where clause
				">

		<cfargument name="obj" type="struct" required="true" hint="A hash of all search parameters requested by end user">
		<cfargument name="typeId" type="numeric" default="-1" required="false" hint="Flag indicating read/contig or ORF id"/>

		<cfset _libraryId = ""/>
		<cfset database_list = ""/>
		<cfset database_name = ""/>
		<cfset seq_tmp_tbl = ""/>
		<cfset queryStr = ""/>

		<cftry>
			<!--- get server from either sequence name using prefix or from environment --->
			<cfset _serverObject = CreateObject("component",  request.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
			<cfset _server = _serverObject['server']/>
			<cfset _environment = _serverObject['environment']/>

			<!--- error checking if _server is empty return error and stop --->
			<cfif NOT len(_server)>
				<cfset CreateObject("component",  request.cfc & ".Utility").reportServerError(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
				<cfthrow type="INCORRECT_ENV_SEQ" />
			</cfif>

			<!--- set _libraryId info --->
			<cfif (isDefined("arguments.obj.LIBRARY") and (arguments.obj.LIBRARY gt -1))>
				<cfset _libraryId = #arguments.obj.LIBRARY# />
			<cfelse>
				<cfset _libraryId = CreateObject("component",  request.cfc & ".Utility").getLibraryList(_environment)/>
			</cfif>

			<!--- get seqeunce ids from idFiles --->
			<cfif len(arguments.obj.TAG) and len(arguments.obj.IDFILE)>
				<cfset seq_tmp_tbl = retrieveSequenceId_A(tag=arguments.obj.TAG,file=arguments.obj.IDFILE,server=_server)/>
			<!--- get sequence ids from stats flat files --->
			<cfelseif isDefined("arguments.obj.ORFTYPE") and len(arguments.obj.ORFTYPE)>
				<cfset seq_tmp_tbl = retrieveSequenceId_B(str=arguments.obj.ORFTYPE & "_id",server=_server,library=_libraryId)/>
				<!--- if value retuned from retrieveSequenceId_B is empty, assume that there are no seq in orftype return empty array now no need to proceed--->
				<cfif len(seq_tmp_tbl) eq 0>
					<cfthrow type="EMPTY_CATEGORY" />
				</cfif>
			<!--- get sequence ids from stats flat files --->
			<cfelseif isDefined("arguments.obj.VIRCAT") and len(arguments.obj.VIRCAT)>
				<cfif len(seq_tmp_tbl) eq 0>
					<!--- if value retuned from retrieveSequenceId_B is empty, assume that there are no seq in vircat return empty array now no need to proceed--->
					<cfset seq_tmp_tbl = retrieveSequenceId_B(str=arguments.obj.VIRCAT & "_id",server=_server,library=_libraryId)/>
					<cfif len(seq_tmp_tbl) eq 0>
						<cfthrow type="EMPTY_CATEGORY" />
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

				// get reads or orf nucleotides from orf amino acid records.
				if (arguments.typeId eq 3){
					queryStr &=	" INNER JOIN sequence_relationship sr on sr.objectId = s.id";
					queryStr &= " INNER JOIN sequence r on sr.subjectId = r.id";
				}

				if (arguments.typeId eq 4){
					queryStr &=	" INNER JOIN sequence_relationship sr on sr.subjectId = s.id";
					queryStr &= " INNER JOIN sequence r on sr.objectId = r.id";
				}

				if (len(seq_tmp_tbl)){
					queryStr &= " INNER JOIN #seq_tmp_tbl# st on s.id = st.id";
				}

				//where conditons
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
					queryStr &= " and b.#lcase(arguments.obj.INTAXONOMY)# like '%#arguments.obj.TAXONOMY#%'";
				}

				if (isDefined("arguments.obj.VIRCAT") and len(arguments.obj.VIRCAT) and (arguments.obj.VIRCAT eq 'fxn')){
					queryStr &= " and b.fxn_topHit=1";
				} else {
					queryStr &= " and b.sys_topHit=1";
				}

				// get reads or orf nucleotide from orf amino acid records.
				if (arguments.typeId gt -1){
					queryStr &= " and sr.typeId = #arguments.typeId#";
				}

				queryStr &= " and b.e_value <= #arguments.obj.EVALUE#";
			</cfscript>

			<cfcatch type="any">
				<cfset queryStr = ""/>

				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="SearchRPC",
																						function_name=getFunctionCalledName(),
																						args=arguments,
																						msg=cfcatch.Message,
																						detail=cfcatch.Detail,
																						tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn queryStr/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="prepareRS" access="remote" returntype="struct" hint="
				Generate a result set to be retunred to serach view.  This is the essential function in performaing
				all VRIOME searches.  Based on the input provided a SQL query is constructed and executed.
				All the results are then stored in a JSON object on the file system to be used later when
				recalled using Bookmarks.

				This function called directly from Flex Search view.

				Return: A hash of BLAST results
				">
		<cfargument name="obj" type="Struct" required="true" />

		<cftry>
			<cfset struct = StructNew()/>
			<cfset struct['MSG'] = "EMPTY"/>
			<cfset struct['USERID'] = ""/>
			<cfset struct['JOBNAME'] = ""/>
			<cfset struct['JOBALIAS'] = ""/>
			<cfset struct['DATECREATED'] = ""/>
			<cfset struct['SEARCHPARAM'] = ""/>
			<cfset struct['RCD_COUNT'] = 0/>

			<cfset _arr = ArrayNew(1)/>
			<cfset partialQuery = partialSearchQuery(arguments.obj)/>
			<cfif partialQuery eq "">
				<cfreturn struct>
			</cfif>

			<!--- get server from either sequence name using prefix or from environment --->
			<cfset _serverObject = CreateObject("component",  request.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
			<cfset _server = _serverObject['server']/>
			<cfset _environment = _serverObject['environment']/>

			<cfquery name="srch_qry" datasource="#_server#" result="srch_qry_rslt">
				SELECT	distinct
						s.id as sequenceId,
						s.libraryId,
						b.id as blastId,

						s.name,
						s.size,
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

						b.domain,
						b.kingdom,
						b.phylum,
						b.class,
						b.order,
						b.family,
						b.genus,
						b.species,
						b.organism,

						'#_environment#' as environment

				#PreserveSingleQuotes(partialQuery)#

				ORDER BY s.id, b.database_name desc, b.e_value asc
			</cfquery>

			<cflog file="virome.search" type="information" text="#PreserveSingleQuotes(partialQuery)#" />
			<cflog file="virome.search" type="information" text="#srch_qry_rslt.sql#" />

			<cfif srch_qry.RecordCount>
				<cfset _arr = CreateObject("component",  request.cfc & ".Utility").QueryToStruct(srch_qry)>

				<cfscript>
					jobId = createuuid();
					dir = lcase(request.searchFilePath & "/" & jobId);

					if ((isDefined("arguments.obj.USERNAME")) and len(arguments.obj.USERNAME)){
						dir = lcase(request.searchFilePath & "/" & arguments.obj.USERNAME);
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
						lib = CreateObject("component",  request.cfc & ".Library").getLibrary(id=arguments.obj.LIBRARY);
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
					<cfset CreateObject("component", request.cfc & ".Bookmark").add(arguments.obj,fname,srch_qry.RecordCount)/>
				</cfif>
			</cfif>

			<cfcatch type="any">
				<cfset struct['MSG'] = "FAILED"/>

				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="SearchRPC",
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

	<cffunction name="getSearchRSLT" access="remote" returntype="Array" hint="
				When a search result is asked to be recalled from Bookmarks getSearchRSLT is used.
				Using Bookmark id, search for respective JSON file and the convert it into an array
				of hash that can be understood by Flex.

				This function is directly called by Flex Search view

				Return: A array of hash
				">
		<cfargument name="obj" type="struct" required="true">

		<cftry>
			<cfscript>
				arr = ArrayNew(1);
				data = "";
				jobId = arguments.obj.USERID;

				// is userid passed in is not a unique id created for
				// non logged in user it will always be numeric int value
				// becuase user id comes from db.  convet it to username
				// to get correct folder name.
				if (isNumeric(jobId)){
					uStruct = StructNew();
					uStruct['USERID'] = jobId;
					userObj = CreateObject("component", request.cfc & ".User").GetUser(uStruct);

					jobId = userObj['USERNAME'];
				}

				fname = lcase(request.searchFilePath & "/" & jobId & "/" & arguments.obj.JOBNAME);
				myfile = FileOpen(fname,"read","UTF-8");

				while(NOT FileIsEOF(myfile)) {
					data = FileReadLine(myfile);
				}
				FileClose(myfile);

				arr = deserializeJSON(data);
			</cfscript>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="SearchRPC",
																						function_name=getFunctionCalledName(),
																						args=arguments,
																						msg=cfcatch.Message,
																						detail=cfcatch.Detail,
																						tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn arr/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="getBlastSearch" access="remote" returntype="String" hint="
				Provides a interface to BLAST your sequence of interest against all public
				and respective private libraries withing VIROME.  This function creates a
				BLAST request and passes it to specialised BLAST server.

				Due to asynchronous nature of BLAST search, we do not have a way to identify when
				the job has completed. For this reason this function will busy wait for 5min
				for BLAST result to return a result. (AJAX options not yet explored from within CF)

				Due to computational limitation only one sequence can be submitted for BLAST at this time.

				Once results are available, parse the HTML file and link subject IDs back to sequence detail
				view within VIROME.

				This function is called directly by Flex Search view

				Return: A well formatted BLAST report.
				">

		<cfargument name="obj" type="Struct" required="true">

		<cftry>
			<cfset contentStr = ""/>
			<cfset SEQUENCE = arguments.obj.SEQUENCE />

			<!--- remove all but first seq. --->
			<cfset idx = Find(">", arguments.obj.SEQUENCE, 3)>
			<cfif idx>
				<cfset SEQUENCE = Left(arguments.obj.SEQUENCE, idx-1)>
			</cfif>

			<!--- set default parameters for blast option --->
			<cfset wordSize = 3>
			<cfif comparenocase(#arguments.obj.PROGRAM#, "blastn") eq 0>
				<cfset wordSize = 11>
			</cfif>

			<cfset gapCost = "">
			<cfif (comparenocase(#arguments.obj.PROGRAM#, "tblastx") neq 0) && (comparenocase(#arguments.obj.PROGRAM#, "blastn") eq 0)>
				<cfset gapCost = "Existence: 5, Extension: 2" >
			<cfelseif (comparenocase(#arguments.obj.PROGRAM#, "tblastx") neq 0) && (comparenocase(#arguments.obj.PROGRAM#, "blastn") neq 0)>
				<cfset gapCost = "Existence: 11, Extension: 1" >
			</cfif>

			<cfset matrix = "BLOSUM62" >
			<cfif comparenocase(#arguments.obj.PROGRAM#, "blastn") eq 0>
				<cfset matrix = "" >
			</cfif>

			<cfset filter = "T">
			<cfif comparenocase(#arguments.obj.PROGRAM#, "blastp") eq 0>
				<cfset filter = "">
			</cfif>

			<!--- add prefix of pep or orf to subject database select --->
			<cfset db_list = ""/>
			<cfloop list="#arguments.obj.DATABASE#" index="db" delimiters="," >
				<cfif comparenocase(#arguments.obj.PROGRAM#, "blastp") eq 0>
					<cfset db_list &= db & "_pep" & ","/>
				<cfelse>
					 <cfset db_list &= db & "_orf" & ","/>
				</cfif>
			</cfloop>

			<cfset db_list = ReReplace(db_list, ",$", "", "one")/>
			<cfset arguments.obj.DATABASE = db_list/>

			<cfhttp url="http://viroblast.dbi.udel.edu/viromeblast/blastresult.php" method="post" result="response">
				<cfhttpparam type="formfield" name="blast_flag" value="1">
				<cfhttpparam type="formfield" name="blastpath" value="/share/opt/blast+/bin">
				<cfhttpparam type="formfield" name="searchType" value="advanced">
				<cfhttpparam type="formfield" name="outFmt" value="0" >

				<cfhttpparam type="formfield" name="wordSize" value="#wordSize#" >
				<cfhttpparam type="formfield" name="gapCost" value="#gapCost#" >
				<cfhttpparam type="formfield" name="matrix" value="#matrix#" >
				<cfhttpparam type="formfield" name="filter" value="#filter#" >

				<cfhttpparam type="formfield" name="program" value="#arguments.obj.PROGRAM#">
				<cfhttpparam type="formfield" name="patientIDarray[]" value="#arguments.obj.DATABASE#">
				<cfhttpparam type="formfield" name="expect" value="#arguments.obj.EXPECT#">
				<cfhttpparam type="formfield" name="targetSeqs" value="#arguments.obj.DESCRIPTION#">
				<cfhttpparam type="formfield" name="querySeq" value="#SEQUENCE#">
			</cfhttp>

			<cfscript>
				// once a blast job is submitted reponse is sent back
				// confirm blast job was send successfully
				if (compareNoCase(response.statusCode, "200 OK") eq 0) {
					// now that the blast job was submitted successfully
					// extract job id.
					jobString = REMatchNoCase("jobid=(\d+)", response.fileContent);
					jobId = ReReplaceNoCase(jobString[1], "jobid=", "", "all");

					// send a request to see if blast job is complete
					// and an html file has been written.
					httpService = new http();
					httpService.setCharset("utf-8");
		    		httpService.setUrl("http://viroblast.dbi.udel.edu/viromeblast/data/#jobId#.blast1.html");
					result = httpService.send().getPrefix();

					// it may take some time to create html job based on the
					// size of the seq submitted.
					// keep check for at least 5 min.
					count = 0;

					while (compareNoCase(result.statusCode, "200 OK") neq 0) {
						sleep(1000);
						result = httpService.send().getPrefix();
						count++;

						if (count gt 300) {
							break;
						}
					}

					// if html page is created successfully parse the file, else print error msg.
					if (compareNoCase(result.statusCode, "200 OK") neq 0) {
						contentStr = "Error running BLAST against give sequence.  Please contact administrator for details";
					} else {
						// once we have the raw html data lets reformat it.
						contentStr = result.fileContent;

						// find all this description line
						// e.g: ><a name = BCRJP.418B.600-18_1_350_1BCRJP.418B.600-18_1_350_1></a> BCRJP.418B.600-18_1_350_1 on BCRJP.418B.600-18_1_350_1 ...
						// need to replace string up to "... on SEQUENCE_NAME"
						// with a link that can be using with in flex.
						m = ReMatch("<a name\s*=\s*[[:graph:]]+></a>\s*[[:graph:]]+ on ([[:graph:]]+)", contentStr);

						for(i=1; i<=arraylen(m); i++){
							// each match result will be of format
							// <a name = BCRJP.418B.600-18_1_350_1BCRJP.418B.600-18_1_350_1></a> BCRJP.418B.600-18_1_350_1 on BCRJP.418B.600-18_1_350_1
							// from this string only extract the last sequence name

							// to get just the last sequence name,
							// reverse the string, substring up to the first space, and reverse it back
							// trim any space around the name.
							str = reverse(trim(m[i]));

							sequence_name = trim(reverse(left(str, find(" ", str, 1))));

							// get sequence info from the database, will need this info to create flex link button for sequence detail page.
							l = CreateObject("component",  request.cfc & ".SearchRPC").getSeqInfo(sequence_name);
							link = "[" & l & "]" & #sequence_name# & "[\\" & l &"]";

							// replace match string with new link that flex can parse
							contentStr = ReReplaceNoCase(contentStr, m[i], link, "one");
						}

						// remove all html tags.
						contentStr = ReReplaceNoCase(contentStr, "<[^>]*>", "", "all");
					}
				}
			</cfscript>

			<cfcatch type="any">
				<cfset contentStr = "Error running BLAST against give sequence.  Please contact administrator for details"/>

				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="SearchRPC",
																						function_name=getFunctionCalledName(),
																						args=arguments,
																						msg=cfcatch.Message,
																						detail=cfcatch.Detail,
																						tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn contentStr>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="getSeqInfo" access="remote" returntype="String" hint="
				Get sequence ID for a give sequence name

				A helper function for:
					getBlastSearch()

				Return: A string, underscore separated with sequence ID and environment name
				">
		<cfargument name="sequence_name" type="String" required="true">

		<cftry>
			<cfset _serverObject = CreateObject("component",  request.cfc & ".Utility").getServerName(sequence_name=sequence_name)/>
			<cfset _server = _serverObject['server']/>
			<cfset _environment = _serverObject['environment']/>
			<cfset retVal = "0_null">

			<cfquery name="q" datasource="#_server#">
				SELECT	id
				FROM	sequence
				WHERE 	name = '#arguments.sequence_name#'
			</cfquery>

			<cfif q.recordcount gt 0>
				<cfset retVal = q.id & "_" & _environment>
			</cfif>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="SearchRPC",
																						function_name=getFunctionCalledName(),
																						args=arguments,
																						msg=cfcatch.Message,
																						detail=cfcatch.Detail,
																						tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn retVal>
			</cffinally>
		</cftry>
	</cffunction>

</cfcomponent>
