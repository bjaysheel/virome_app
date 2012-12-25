<cfcomponent output="true">

	<cffunction name="export" returntype="any" access="remote" hint="export images,csv and/or multifasta files">
		<cfargument name="fileObject" type="struct" required="true" />
		<cfargument name="genInfoObject" type="struct" required="true" />
		<cfargument name="bin" type="binary" required="true"/>
		<cfargument name="content" type="string" required="true" />
		<cfargument name="biom" type="struct" required="true" />
		
		<cftry>
			<cfscript>
				uniqueId = createuuid();
				
				fname = "";
				
				// check to see if environment and/or library info is passed
				// if so set filename based on env and librar info				
				if (not structIsEmpty(arguments.genInfoObject)){
					if (isDefined("arguments.genInfoObject.ENVIRONMENT") and len(arguments.genInfoObject.ENVIRONMENT) gt 0) {
						fname &= arguments.genInfoObject.ENVIRONMENT & "_";
						
						// override uniqueId with human readable name
						uniqueId = arguments.genInfoObject.ENVIRONMENT & "_";
					}
						
										
					//append library name
					if (arguments.genInfoObject.LIBRARY gt -1) {
						lib_name = createobject("component", request.cfc & ".Library").getLibrary(id=arguments.genInfoObject.LIBRARY).name;
						
						fname &= lib_name & "_";
						
						// override uniqueId with human readable name
						uniqueId &= lib_name & "_" & dateformat(now(), "mmddyy") & "" & timeformat(now(), "hhmmssL");
					}
					
					//append database
					if (len(arguments.genInfoObject.BLASTDB) gt 0)
						fname &= arguments.genInfoObject.BLASTDB & "_";
					
					//append virome cat
					if (len(arguments.genInfoObject.VIRCAT) gt 0)
						fname &= arguments.genInfoObject.VIRCAT & "_";
					
					//append orf type
					if (len(arguments.genInfoObject.ORFTYPE) gt 0)
						fname &= arguments.genInfoObject.ORFTYPE & "_";
					
					fname = lcase(rereplace(fname," +","_","all"));
					fname = lcase(rereplace(fname,"_$","","one" )); 
				}
				
				// if BIOM download is requested it is independent of other downloads
				// it does not include environment info and will have more than one
				// libraryId, use generic file/folder output name.
				if (not StructIsEmpty(arguments.biom)){
					uniqueId = "VIROME_BIOM_" & dateformat(now(), "mmddyy") & "" & timeformat(now(), "hhmmssL");
				}
				
				// set dir name where files are stored
				dir = lcase(request.tmpFilePath & "/" & uniqueId);
				zip = lcase(uniqueId & ".zip");
				localFilePath = request.tmpFilePath & "/" & zip;
				webFilePath = request.roothostpath & "/tmp/" & zip;
				
				DirectoryCreate(#dir#);
				
				
				// download biom files
				if (not StructIsEmpty(arguments.biom)){
					exportBIOM(dir, arguments.biom);
				}
				
				//download db search result grid as csv file 
				if (arguments.fileObject.csv){
					if (FindNoCase("trna no.",content,0))
						name = dir & "/tRNA" & "_" & fname & ".csv";
					else 
						name = dir & "/search_rslt" & "_" & fname & ".csv";
						
					exportCSV(name, content);
				}
				
				//download db search result orfs
				if (arguments.fileObject.peptide){
					name = dir & "/search_rslt" & "_" & fname & "_orf_pep.fasta";
					exportSearchRslt(name, arguments.genInfoObject);
				}
				
				//download db search results original reads
				if (arguments.fileObject.read){
					name = dir & "/search_rslt" & "_" & fname & "_reads.fasta";
					exportSearchRslt(name, arguments.genInfoObject, 3 );
				}
				
				//download db search result orfs as nucleotides
				if (arguments.fileObject.nucleotide){
					name = dir & "/search_rslt" & "_" & fname & "_orf_nuc.fasta";
					exportSearchRslt(name ,arguments.genInfoObject, 4);
				}
				
				//download image
				if (arguments.fileObject.image){
					name = dir & "/virome_piechart.png";
					saveImage(name, arguments.bin);
				}
				
				//download library reads
				if (arguments.fileObject.libRead){
					name = dir & "/" & fname & "_reads.fasta";
					exportSeq(filename=name, obj=arguments.genInfoObject, typeId=1);
				}
				
				//download library rRNA
				if (arguments.fileObject.librRNA){
					name = dir & "/" & fname & "_rRNA.fasta";
					exportSeq(filename=name, obj=arguments.genInfoObject, typeId=2);
				}
				
				//download library tRNA
				if (arguments.fileObject.libtRNA){
					name = dir & "/" & fname & "_tRNA.fasta";
					exporttRNASeq(filename=name, obj=arguments.genInfoObject);
				}
				
				//download library orfs as peptides
				if (arguments.fileObject.libPeptide){
					name = dir & "/" & fname & "_orf_pep.fasta";
					exportSeq(filename=name, obj=arguments.genInfoObject, typeId=3);
				}
				
				//download library orfs as nucleotides
				if (arguments.fileObject.libNucleotide){
					name = dir & "/" & fname & "_orf_nuc.fasta";
					exportSeq(filename=name, obj=arguments.genInfoObject, typeId=4);
				}
			</cfscript>
			
			<cfzip action="zip" source="#dir#" file="#localFilePath#" overwrite="yes" prefix="#uniqueId#"/>
		
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORT", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn "#webFilePath#"/>	
			</cffinally>
		</cftry>
	</cffunction>


	<cffunction name="exportCSV" access="private" returntype="void" >
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="content" type="String" required="true"/>
		
		<cftry>
			
			<cfscript>
				myfile = FileOpen("#arguments.filename#","write","UTF-8");
				FileWriteLine(myfile,"#arguments.content#");
				FileClose(myfile);
			</cfscript>
			 
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORTCSV", 
							cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="exportSearchRslt" access="private" returntype="void">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="obj" type="Struct" required="true" />
		<cfargument name="typeId" type="numeric" default="-1" required="false" />
		
		<cfset partialQuery = CreateObject("component",  request.cfc & ".SearchRPC").partialSearchQuery(obj=arguments.obj, typeId=arguments.typeId)/>
		
		<cfif partialQuery eq "">
			<cfreturn "false"/>
		</cfif>
		
		<!--- get server from either sequence name using prefix or from environment --->
		<cfset _serverObject = CreateObject("component",  request.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT, arguments.obj.SEQUENCE)/>
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cftry>
			<cfquery name="qry" datasource="#_server#" result="exportSearchRsltQuery">
				SELECT	distinct
						<cfif arguments.typeId gt 0>
							r.id as sequenceId,
							r.libraryId,
							r.basepair,
							r.name,
							r.header
						<cfelse>
							s.id as sequenceId,
							s.libraryId,
							s.basepair,
							s.name,
							s.header
						</cfif>
				 
				 #PreserveSingleQuotes(partialQuery)#
				 
				ORDER BY s.id, b.database_name desc, b.e_value asc
			</cfquery>
			
			<cfscript>
				myfile = FileOpen("#arguments.filename#","write","UTF-8");
				
				prev = "";
				seq_desc = "";
				
				for (i=1; i lte qry.recordcount; i++){
					if (left(qry["name"][i], 3) neq prev){
						seq_desc = createObject("component", request.cfc & ".Utility").getMGOLDescription(qry["name"][i]);
						prev = left(qry["name"][i],3);
					}
					
					header = ">" & qry["name"][i] & " " & seq_desc;
					if (len(qry["header"][i])){
						header &= " [" & qry["header"][i] & "]";	
					}
					
					FileWriteLine(myfile, header);
					fileWriteLine(myfile, formatSequence(qry["basepair"][i]));					
				}
				
				FileClose(myfile);
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPROTFSA", 
						cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<!--- --->
			</cffinally>
		</cftry>
	</cffunction> 
	
	<cffunction name="exportSeq" access="private" returntype="void">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="obj" type="Struct" required="true" />
		<cfargument name="typeId" type="numeric" default="1"/>
		
		<!--- get server from either sequence name using prefix or from environment --->
		<cfset _serverObject = CreateObject("component",  request.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cftry>
			
			<!--- typeId=1 => get reads (nuc) 
				  typeId=2 => get orfs (peptide)
				  typeId=3 => get rRNA (nuc)
				  typeId=4 => get orfs (nuc) --->
			<cfquery name="qry" datasource="#_server#">
				SELECT	distinct
							s.id as sequenceId,
							s.libraryId,
							s.basepair,
							s.name,
							s.header
				FROM 	sequence s 
					inner join
						sequence_relationship sr on sr.objectId = s.id
				WHERE	s.deleted=0
					and s.libraryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.library#">
					and sr.typeId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.typeId#">	
				ORDER BY s.id
			</cfquery>
			
			<!--- this function is called for one library only so just get description for library once. --->
			<cfset seq_desc = CreateObject("component",  request.cfc & ".Utility").getMGOLDescription(qry.name[1])/>
			
			<cfscript>
				myfile = FileOpen("#arguments.filename#","write","UTF-8");
				
				for (i=1; i lte qry.recordcount; i++){					
					header = ">" & qry["name"][i] & " " & seq_desc;
					if (len(qry["header"][i])){
						header &= " [" & qry["header"][i] & "]";	
					}
					
					FileWriteLine(myfile, header);
					fileWriteLine(myfile, formatSequence(qry["basepair"][i]));					
				}
				
				FileClose(myfile);
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORTSEQ", 
						cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="exporttRNASeq" access="private" returntype="void">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="obj" type="Struct" required="true" />
		
		<!--- get server from either sequence name using prefix or from environment --->
		<cfset _serverObject = CreateObject("component",  request.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cftry>
			<cfquery name="qry" datasource="#_server#">
				SELECT	distinct
							s.id as sequenceId,
							s.libraryId,
							s.basepair,
							s.name,
							t.id,
							t.num,
							t.tRNA_start,
							t.tRNA_end,
							t.anti,
							t.intron,
							t.score
				FROM 	sequence s 
					INNER JOIN
						tRNA t ON t.sequenceId = s.id
				WHERE	s.libraryId = #arguments.obj.library#
					and s.deleted = 0
				ORDER BY s.id, t.num
			</cfquery>
			
			<!--- this function is called for one library only so just get description for library once. --->
			<cfset seq_desc = CreateObject("component",  request.cfc & ".Utility").getMGOLDescription(qry.name[1])/>
			
			<cfscript>
				myfile = FileOpen("#arguments.filename#","write","UTF-8");
			</cfscript>
			
			<cfoutput query="qry" group="sequenceId">
				<cfset sequence = qry.basepair/>
				<cfset tRNA = ""/>
				
				<cfoutput group="id">
					<cfset tRNA &= "[num=#qry.num# start=#qry.tRNA_start# end=#qry.tRNA_end# anti=#qry.anti# intron=#qry.intron# score=#qry.score#] " />	
				</cfoutput>
				
				<cfscript>
					FileWriteLine(myfile, ">#qry.name# #seq_desc# #tRNA#");
					FileWriteLine(myfile, #formatSequence(sequence)#);
				</cfscript>
			</cfoutput>
			
			<cfscript>
				FileClose(myfile);
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORTTRNASEQ", 
						cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="exportBIOM" access="private" output="false" returntype="void">
		<cfargument name="dir" type="string" required="true">
		<cfargument name="object" type="struct" required="true">
		
		<cftry>
			<cfloop list="#arguments.object.xtype#" index="idx" delimiters="," >
				<cfset local_struct = structNew()/>
				<cfset local_struct['lineage'] = structNew()/>
				<cfset local_struct['counts'] = structNew()/>
								
				<cfloop list="#arguments.object.libraryIdList#" index="id" >					
					<cfset xmlfile = request.xDocsFilePath & "/" & ucase(idx) & "_XMLDOC_" & id & ".xml" />
					<cfset myDoc = xmlParse(xmlfile) />
				
					<cfset theRootElement = myDoc.XmlRoot>
					<cfset local_struct = flatternXML(theRootElement, "", local_struct, #id#)/>
				</cfloop>
				
				<cfset local_dir = arguments.dir & "/" & lcase(idx) />				
				<cfset directorycreate(local_dir)/>
				
				<cfset writeBIOMTab(local_struct, arguments.object.libraryIdList, local_dir, idx)/>
				
				<cfset writeBIOMJSON(local_struct, arguments.object.libraryIdList, local_dir, idx)/>
				
				<cfset writeBIOMMapping(arguments.object.libraryIdList, local_dir)/>
			</cfloop>
			
			<cfcatch type="any" >
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORTBIOM", 
						cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="flatternXML" access="private" returntype="struct">
		<cfargument name="node" type="xml" required="true">
		<cfargument name="str" type="string" required="true">
		<cfargument name="object" type="struct" required="true" >
		<cfargument name="libraryId" type="numeric" required="true">
		
		<cfscript>
			//set name and prefix, of the current node
			var t_name = "NONE";
			var t_value = 0;
			var updateStr = arguments.str;
			
			if (arguments.node.XmlName eq "root"){
				t_name = """ROOT""";
			} else {
				if (structKeyExists(arguments.node.XmlAttributes, "NAME")) {
					var prefix = arguments.node.XmlName;
					
					// if parsing seed, keeg, cog or aclame the tag name is 
					// function_X and prefix will always be F, set it to F
					// followed by function level no.
					if (findnocase("function_", prefix)){
						prefix = rereplacenocase(prefix, "function_", "", "one");
						prefix = "F" & prefix;
					} else {
						prefix = left(arguments.node.XmlName, 1);
					}
					
					t_name = """" & prefix & "_" & arguments.node.XmlAttributes['NAME'] & """";
				}


				if (structKeyExists(arguments.node.XmlAttributes, "VALUE"))
					t_value = arguments.node.XmlAttributes['VALUE'];
			}
			
	
			if (len(arguments.str))
				updateStr &= ", " & t_name;
			else
				updateStr = t_name;
	
	
			//recursion end condition
			if (arraylen(arguments.node.XmlChildren) eq 0) {
				var hash_key = hash(updateStr, "MD5");
				
				if (not structKeyExists(arguments.object['lineage'], hash_key)) {
					arguments.object['lineage'][hash_key] = updateStr;
					arguments.object['counts'][hash_key][arguments.libraryId] = t_value;
				} else {
					if (structKeyExists(arguments.object['counts'], hash_key) and structKeyExists(arguments.object['counts'][hash_key], libraryId))
						writeoutput("duplicate lineage: " & arguments.str & "<br/>");
					else
						arguments.object['counts'][hash_key][arguments.libraryId] = t_value;
				}
				
				return(arguments.object);
			}
		
			for(var j=1; j lte arraylen(arguments.node.XmlChildren); j=j+1) {
				arguments.lineage = flatternXML(arguments.node.XmlChildren[j], updateStr, arguments.object, arguments.libraryId);
			}
			
			return(arguments.object);	
		</cfscript>
		
	</cffunction>
	
	<cffunction name="getRawAndNormalizedCounts" access="private" returntype="Array">
		<cfargument name="libIdList" type="string" required="true"/>
		
		<cftry>
			<cfset var max = 0>
			<cfset var RNArray = ArrayNew(1)/>
			
			<cfquery name="q" datasource="#request.mainDSN#" >
				SELECT	l.libraryId, l.lib_name, l.orfs
				FROM	lib_summary l
				WHERE	l.libraryId in (#arguments.libIdList#)
				ORDER BY l.libraryId
			</cfquery>
			
			<cfset RNArray = CreateObject("component",  request.cfc & ".Utility").QueryToStruct(q)/>
			
			<cfloop query="q">
				<cfif max lt q.orfs>
					<cfset max = q.orfs>
				</cfif>
			</cfloop>				
		
			<cfloop from="1" to="#arrayLen(RNArray)#" index="p" >
				<cfset structInsert(RNArray[p], "normal", (max/RNArray[p]['orfs']))/>
			</cfloop>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - GETRAWANDNORMALIZEDCOUNTS", 
										cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn RNArray/>
			</cffinally>
			
		</cftry>		
	</cffunction>
	
	
	<cffunction name="writeBIOMTab" access="private" returntype="void">
		<cfargument name="object" type="struct" required="true">
		<cfargument name="libIdList" type="string" required="true">
		<cfargument name="dir" type="string" required="true">
		<cfargument name="xType" type="string" required="true">
		
		<cftry>
			
			<cfset RNcounts = getRawAndNormalizedCounts(libIdList)/>
			
			<cfscript>
				//open file to write
				var raw_out = FileOpen(arguments.dir & "/#arguments.xType#.raw.tab", "append", "UTF-8");
				var nor_out = FileOpen(arguments.dir & "/#arguments.xType#.normalized.tab", "append", "UTF-8");
				
				//create header for the file
				var header = "##ID#chr(9)#";
				for(var i=1; i lte arrayLen(RNcounts); i++){
					header &= RNcounts[i]['lib_name'] & "#chr(9)#";
				}
				header &= "taxonomy#request.linefeed#";
						
				filewrite(raw_out, header);
				filewrite(nor_out, header);
				
				
				//loop over each lineage hash_key
				var counter = 1;
				var sortedkeys = structSort(arguments.object['lineage'], "textnocase", "asc");
				
				for(var z=1; z lte arrayLen(sortedkeys); z++) {
					var key = sortedkeys[z];
					var raw_str = "#counter##chr(9)#";
					var nor_str = "#counter##chr(9)#";
					
					//check if lineage exist in library
					for(var i=1; i lte arrayLen(RNcounts); i++){
						if (structKeyExists(arguments.object['counts'][key], RNcounts[i]['libraryId'])) {
							var raw = arguments.object['counts'][key][RNcounts[i]['libraryId']];
							var nor = numberformat(raw * RNcounts[i]['normal'], ".99"); 
							
							raw_str &= raw & "#chr(9)#";
							nor_str &= nor & "#chr(9)#";
							
						} else { 
							raw_str &= "0#chr(9)#";
							nor_str &= "0#chr(9)#";
						}
					}
					raw_str &= arguments.object['lineage'][key] & "#request.linefeed#";
					nor_str &= arguments.object['lineage'][key] & "#request.linefeed#";
					
					filewrite(raw_out, raw_str);
					filewrite(nor_out, nor_str);
					
					// increment id counter
					counter++;
				}
			
				FileClose(raw_out);
				FileClose(nor_out);
				
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - WRITEBIOMTAB", 
										cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="writeBIOMJSON" access="private" returntype="void">
		<cfargument name="object" type="struct" required="true">
		<cfargument name="libIdList" type="string" required="true">
		<cfargument name="dir" type="string" required="true">
		<cfargument name="xType" type="string" required="true">
		
		<cftry>
			<cfset RNcounts = getRawAndNormalizedCounts(libIdList)/>

			<cfscript>
				//open file to write
				var raw_out = FileOpen(arguments.dir & "/#arguments.xType#.raw.biom", "append", "UTF-8");
				var nor_out = FileOpen(arguments.dir & "/#arguments.xType#.normalized.biom", "append", "UTF-8");
						
				//start biom JSON object
				var columns = "";
				var raw_str = "";
				var nor_str = "";
					
				var metadata = "{""rows"": [#request.linefeed##chr(9)#";
				
				filewrite(raw_out, metadata);
				filewrite(nor_out, metadata);
				
				//loop over each lineage hash_key
				var counter = 1;
				var sortedkeys = structsort(arguments.object['lineage'], "textnocase", "asc");
				
				for(var z=1; z lte arrayLen(sortedkeys); z++) {
					var key = sortedkeys[z];
					
					metadata = "";
					if (z gt 1){
						metadata = ",";
					}
					
					metadata &= "{""id"": ""#counter#"", ";
					metadata &= "#request.linefeed##chr(9)#";
					
					metadata &= "  ""metadata"": {""taxonomy"": [#request.linefeed##chr(9)##chr(9)#";
					
					metadata &= arguments.object['lineage'][key] & "]}} #request.linefeed##chr(9)# ";
					
					filewrite(raw_out, metadata);
					filewrite(nor_out, metadata);
					
					raw_str &= "[";
					nor_str &= "[";
					columns = "";
					
					// keep data/counts for each metadata.
					for(var i=1; i lte arrayLen(RNcounts); i++){
						if (structKeyExists(arguments.object['counts'][key], RNcounts[i]['libraryId'])) {
							var raw = arguments.object['counts'][key][RNcounts[i]['libraryId']];
							var nor = numberformat(raw * RNcounts[i]['normal'], ".99"); 
							
							raw_str &= raw & ",";
							nor_str &= nor & ",";
							
						} else { 
							raw_str &= "0,";
							nor_str &= "0,";
						}
						
						columns &= "#chr(9)#{""id"": ""#RNcounts[i]['lib_name']#"", ""metadata"": null}, #request.linefeed# ";
					}
					
					// remove the last , from data, and add closing ],
					raw_str = rereplace(raw_str, ",$", "], #request.linefeed##chr(9)# ", "one");
					nor_str = rereplace(nor_str, ",$", "], #request.linefeed##chr(9)# ", "one");
					
					// increment id counter
					counter++;
				}
				
				
				// close metadata,
				metadata = "], #request.linefeed#";
				metadata &= """data"": [#request.linefeed##chr(9)#";
			
				filewrite(raw_out, metadata);
				filewrite(nor_out, metadata);
				
				// close last data value, and then close data block.
				raw_str = rereplace(raw_str, "], #request.linefeed##chr(9)# $", "]], #request.linefeed#", "one");
				nor_str = rereplace(nor_str, "], #request.linefeed##chr(9)# $", "]], #request.linefeed#", "one");
				
				filewrite(raw_out, raw_str);
				filewrite(nor_out, nor_str);
			
				//add columns
				columns = rereplace(columns, ", #request.linefeed# $", "", "one");
				
				metadata = " ""columns"": [#request.linefeed##columns#], #request.linefeed#";
				filewrite(raw_out, metadata);
				filewrite(nor_out, metadata);
				
				// end biom file
				metadata = " ""format"": ""Biological Observation Matrix 1.0.0"", #request.linefeed#";		
				metadata &= " ""generated_by"": ""BIOM-Format 1.0.0c"", #request.linefeed#";
				metadata &= " ""matrix_type"": ""dense"", #request.linefeed#";
				metadata &= " ""shape"": [""#counter-1#"", ""#listLen(libIdList)#""], #request.linefeed#";
				metadata &= " ""format_url"": ""http://biom-format.org"", #request.linefeed#";
				metadata &= " ""date"": ""2012-12-05T10:31:00.106530"", #request.linefeed#";
				metadata &= " ""type"": ""Taxon table"", #request.linefeed#";
				metadata &= " ""id"": null, ""matrix_element_type"": ""float""}";
				
				filewrite(raw_out, metadata);
				filewrite(nor_out, metadata);
			
				FileClose(raw_out);
				FileClose(nor_out);
				
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - WRITEBIOMJSON", 
										cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	
	</cffunction>
	
	<cffunction name="writeBIOMMapping" access="private" returntype="void" >
		<cfargument name="libIdList" type="string" required="true"/>
		<cfargument name="dir" type="string" required="true"/>
		
		<cftry>
			<cfquery name="q" datasource="#request.mainDSN#" >
				SELECT	libraryId, lib_name, lib_prefix, lib_type, 
						na_type, geog_place_name, country, region, 
						lat_deg, lon_deg, lat_hem, lon_hem
				FROM	lib_summary
				WHERE	libraryId in (#arguments.libIdList#)
				ORDER BY libraryId
			</cfquery>
			
			<cfscript>
				var summary = CreateObject("component", request.cfc & ".Utility").QueryToStructure(theQuery=q, primaryKey="libraryId");
				var map = FileOpen(arguments.dir & "/mapping.txt", "write", "UTF-8");
				
				filewrite(map, "##SampleId#chr(9)#Description#request.linefeed#");
				
				for(var i=1; i lte listlen(arguments.libIdList); i++){
					var str = summary[listGetAt(arguments.libIdList, i)]['lib_name'] & "#chr(9)#" & summary[listGetAt(arguments.libIdList, i)]['lib_name'];
					str &= " " & summary[listGetAt(arguments.libIdList, i)]['lib_prefix'] & " " & summary[listGetAt(arguments.libIdList, i)]['na_type'];
					str &= request.linefeed;
					
					fileWrite(map, str); 	
				}
				
				fileClose(map);
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - WRITEBIOMMAPPING", 
										cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry> 
		
	</cffunction>
	
	<cffunction name="saveImage" access="remote" output="false" returntype="void">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="data" type="binary" required="true" />
		
		<cftry>
			<cfscript>
				fileWrite("#arguments.filename#","#arguments.data#");
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - SAVEIMAGE", 
									cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="savePDF" access="remote" output="false" returntype="any">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="data" type="binary" required="true" />

		<cftry>
			<cfscript>
				FileWrite("#arguments.filename#","#arguments.data#");
			</cfscript>
			
			<cfdocument format="PDF" filename="#request.chartFilePath#/#_filename#.pdf" overwrite="yes">
				This is a generated PDF containing image data from Flex.
				<br><br>
				<img src="#request.chartFilePath#/#_filename#.png" >
				Enjoy!
			</cfdocument>
	
			<cfscript>
				FileDelete("#request.chartFilePath#/#_filename#.png");
			</cfscript>
		
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - SAVEPDF", 
									cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn "#request.rootHostPath#/charts/#_filename#.pdf">
	</cffunction>
	
	<cffunction name="formatSequence" access="private" returntype="string">
		<cfargument name="sequence" type="string" required="true"/>
		
		<cftry>
			<cfset str = ''/>
			
			<cfloop index="idx" from="1" to="#len(sequence)#" step="80">
				<cfset str &= mid(sequence,idx,80) & request.linefeed/>
			</cfloop>
			
			<cfset str = left(str,len(str)-1) />
		
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("EXPORTER.CFC - FORMATSEQUENCE", 
									cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn str/>
			</cffinally>
		</cftry>
	</cffunction>
		
</cfcomponent>