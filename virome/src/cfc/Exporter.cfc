<cfcomponent output="true">

	<cffunction name="export" returntype="any" access="remote" hint="export images,csv and/or multifasta files">
		<cfargument name="fileObject" type="struct" required="true" />
		<cfargument name="genInfoObject" type="struct" required="true" />
		<cfargument name="bin" type="binary" required="true"/>
		<cfargument name="content" type="string" required="true" />
		
		<cftry>
			<cfscript>
				uniqueId = createuuid();
				dir = lcase(application.tmpFilePath & "/" & uniqueId);
				zip = lcase(uniqueId & ".zip");
				localFilePath = application.tmpFilePath & "/" & zip; 
				webFilePath = application.roothostpath & "/tmp/" & zip;		
				
				DirectoryCreate(#dir#);
				
				fname = "";
				
				if (not structIsEmpty(arguments.genInfoObject)){
					if (isDefined("arguments.genInfoObject.ENVIRONMENT") and len(arguments.genInfoObject.ENVIRONMENT) gt 0)
						fname &= arguments.genInfoObject.ENVIRONMENT & "_";
										
					//append library name
					if (arguments.genInfoObject.LIBRARY gt -1)
						fname &= createobject("component", application.cfc & ".Library").getLibrary(id=arguments.genInfoObject.LIBRARY).name & "_";
					
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
				
				//download db search result grid as csv file 
				if (arguments.fileObject.csv){
					if (FindNoCase("trna no.",content,0))
						name = dir & "/tRNA" & "_" & fname & ".csv";
					else 
						name = dir & "/search_rslt" & "_" & fname & ".csv";
					exportCSV(name,content);
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
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORT", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
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
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORTCSV", 
							cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="exportSearchRslt" access="private" returntype="void">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="obj" type="Struct" required="true" />
		<cfargument name="typeId" type="numeric" default="-1" required="false" />
		
		<cfset partialQuery = CreateObject("component",  application.cfc & ".SearchRPC").partialSearchQuery(obj=arguments.obj, typeId=arguments.typeId)/>
		
		<cfif partialQuery eq "">
			<cfreturn "false"/>
		</cfif>
		
		<!--- get server from either sequence name using prefix or from environment --->
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT, arguments.obj.SEQUENCE)/>
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
						seq_desc = createObject("component", application.cfc & ".Utility").getMGOLDescription(qry["name"][i]);
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
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPROTFSA", 
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
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
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
			<cfset seq_desc = CreateObject("component",  application.cfc & ".Utility").getMGOLDescription(qry.name[1])/>
			
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
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORTSEQ", 
						cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="exporttRNASeq" access="private" returntype="void">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="obj" type="Struct" required="true" />
		
		<!--- get server from either sequence name using prefix or from environment --->
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
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
			<cfset seq_desc = CreateObject("component",  application.cfc & ".Utility").getMGOLDescription(qry.name[1])/>
			
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
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORTTRNASEQ", 
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
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - SAVEIMAGE", 
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
			
			<cfdocument format="PDF" filename="#application.chartFilePath#/#_filename#.pdf" overwrite="yes">
				This is a generated PDF containing image data from Flex.
				<br><br>
				<img src="#application.chartFilePath#/#_filename#.png" >
				Enjoy!
			</cfdocument>
	
			<cfscript>
				FileDelete("#application.chartFilePath#/#_filename#.png");
			</cfscript>
		
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - SAVEPDF", 
									cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn "#application.rootHostPath#/charts/#_filename#.pdf">
	</cffunction>
	
	<cffunction name="formatSequence" access="private" returntype="string">
		<cfargument name="sequence" type="string" required="true"/>
		
		<cftry>
			<cfset str = ''/>
			
			<cfloop index="idx" from="1" to="#len(sequence)#" step="80">
				<cfset str &= mid(sequence,idx,80) & application.linefeed/>
			</cfloop>
			
			<cfset str = left(str,len(str)-1) />
		
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - FORMATSEQUENCE", 
									cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
			
			<cffinally>
				<cfreturn str/>
			</cffinally>
		</cftry>
	</cffunction>
		
</cfcomponent>