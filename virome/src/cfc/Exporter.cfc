<cfcomponent output="true">

	<cffunction name="export" returntype="any" access="remote" hint="export images,csv and/or multifasta files">
		<cfargument name="fileObject" type="struct" required="true" />
		<cfargument name="genInfoObject" type="struct" required="true" />
		<cfargument name="bin" type="binary" required="true"/>
		<cfargument name="content" type="string" required="true" />
		
		<cfset uniqueId = createuuid()/>
		<cfset dir = lcase(application.tmpFilePath & "/" & uniqueId) />
		<cfset zip = lcase(uniqueId & ".zip")/>
		<cfset localFilePath = application.tmpFilePath & "/" & zip/> 
		<cfset webFilePath = application.roothostpath & "/tmp/#zip#"/>
			
		<cftry>
			<cfdirectory action="create" directory="#dir#" mode="777"/>
			<cfset fname = "" />
			
			<cfif NOT structisempty(arguments.genInfoObject)>
				<!--- append environment --->
				<cfif isdefined("arguments.genInfoObject.ENVIRONMENT") and len(arguments.genInfoObject.ENVIRONMENT) gt 0>
					<cfset fname &= arguments.genInfoObject.ENVIRONMENT & "_"/>
				</cfif>
				
				<!--- append library name --->
				<cfif arguments.genInfoObject.LIBRARY gt -1>
					<cfset fname &= createobject("component", application.cfc & ".Library").getLibrary(id=arguments.genInfoObject.LIBRARY).name & "_"/>
				</cfif>
				
				<!--- append database --->
				<cfif len(arguments.genInfoObject.BLASTDB) gt 0>
					<cfset fname &= arguments.genInfoObject.BLASTDB & "_"/>
				</cfif>
				
				<!--- append virome cat --->
				<cfif len(arguments.genInfoObject.VIRCAT) gt 0>
					<cfset fname &= arguments.genInfoObject.VIRCAT & "_"/>
				</cfif>
				
				<!--- append orf type --->
				<cfif len(arguments.genInfoObject.ORFTYPE) gt 0>
					<cfset fname &= arguments.genInfoObject.ORFTYPE & "_"/>
				</cfif>
				
				<cfset fname = lcase(rereplace(fname," +","_","all"))/>
				<cfset fname = lcase(rereplace(fname,"_$","","one" ))/>
			</cfif>
			 
			<!--- download db search result grid as csv file ---> 
			<cfif arguments.fileObject.csv>
				<cfset name = dir & "/search_rslt" & "_" & fname & ".csv"/>
				<cfset exportCSV(name,content)/>
			</cfif>
			
			<!--- download db search result orfs --->
			<cfif arguments.fileObject.peptide>
				<cfset name = dir & "/search_rslt" & "_" & fname & "_orf_pep.fasta"/>
				<cfset exportSearchRslt(name,arguments.genInfoObject,"false","false")/>
			</cfif>
			
			<!--- download db search results original reads --->
			<cfif arguments.fileObject.read>
				<cfset name = dir & "/search_rslt" & "_" & fname & "_reads.fasta"/>
				<cfset exportSearchRslt(name,arguments.genInfoObject,"true","false")/>
			</cfif>
			
			<!--- download db search result orfs as nucleotides --->
			<cfif arguments.fileObject.nucleotide>
				<cfset name = dir & "/search_rslt" & "_" & fname & "_orf_nuc.fasta"/>
				<cfset exportSearchRslt(name,arguments.genInfoObject,"true","true")/>
			</cfif>
			
			<!--- download image --->
			<cfif arguments.fileObject.image>
				<cfset name = dir & "/virome_piechart.png"/>
				<cfset saveImage(name,arguments.bin)/>
			</cfif>
			
			<!--- download library reads --->
			<cfif arguments.fileObject.libRead>
				<cfset name = dir & "/" & fname & "_reads.fasta"/>
				<cfset exportSeq(name,arguments.genInfoObject,"true","false")/>
			</cfif>
			
			<!--- download library orfs as peptides --->
			<cfif arguments.fileObject.libPeptide>
				<cfset name = dir & "/" & fname & "_orf_pep.fasta"/>
				<cfset exportSeq(name,arguments.genInfoObject,"false","false")/>
			</cfif>
			
			<!--- download library orfs as nucleotides --->
			<cfif arguments.fileObject.libNucleotide>
				<cfset name = dir & "/" & fname & "_orf_nuc.fasta"/>
				<cfset exportSeq(name,arguments.genInfoObject,"true","true")/>
			</cfif>
			
			<cfzip action="zip" source="#dir#" file="#localFilePath#" overwrite="yes" prefix="#uniqueId#"/>
		
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORT", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn "#webFilePath#"/>
	</cffunction>


	<cffunction name="exportCSV" access="private" returntype="any" >
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
							#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="exportSearchRslt" access="private" returntype="Any">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="obj" type="Struct" required="true" />
		<cfargument name="read" type="boolean" default="false"/>
		<cfargument name="orf_nuc" type="boolean" default="false"/>
		
		<cfset partialQuery = CreateObject("component",  application.cfc & ".SearchRPC").partialSearchQuery(obj=arguments.obj,read=arguments.read)/>
		
		<cfif partialQuery eq "">
			<cfreturn "false"/>
		</cfif>
		
		<!--- get server from either sequence name using prefix or from environment --->
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cftry>
			<cfquery name="qry" datasource="#_server#">
				SELECT	distinct
						<cfif arguments.read>
							r.id as sequenceId,
							r.libraryId,
							r.basepair,
							r.name,
							o.seq_name,
							o.start,
							o.end
						<cfelse>
							s.id as sequenceId,
							s.libraryId,
							s.basepair,
							s.name
						</cfif>
				 
				 #PreserveSingleQuotes(partialQuery)#
				 
				ORDER BY s.id, b.database_name desc, b.e_value asc
			</cfquery>
			
			<cfscript>
				myfile = FileOpen("#arguments.filename#","write","UTF-8");
			</cfscript>
			
			<cfloop query="qry">
				<cfset seq_desc = CreateObject("component",  application.cfc & ".Utility").getMGOLDescription(qry.name)/>
				<cfset sequence = qry.basepair/>
				<cfif arguments.orf_nuc>
					<cfset sequence = mid(sequence,qry.start,(qry.end-qry.start))/>
					<cfset qry.name = qry.seq_name/>
				</cfif>
				
				<cfscript>
					FileWriteLine(myfile,">#qry.name# #seq_desc# #application.NL#");
					FileWriteLine(myfile,"#formatSequence(sequence)#");
				</cfscript>
			</cfloop>
			
			<cfscript>
				FileClose(myfile);
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPROTFSA", 
						#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction> 
	
	<cffunction name="exportSeq" access="private" returntype="any">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="obj" type="Struct" required="true" />
		<cfargument name="read" type="boolean" default="false"/>
		<cfargument name="orf_nuc" type="boolean" default="false"/>
		
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
							s.name
						<cfif arguments.orf_nuc>
							,o.start
							,o.end
							,o.seq_name
						</cfif>
				FROM 	sequence s 
					<cfif arguments.orf_nuc>
						right join orf o on o.readId = s.id
					</cfif>
				WHERE	s.deleted=0
					and s.rRNA=0
					and s.libraryId = #arguments.obj.library#
					<cfif not arguments.read>
						and s.orf = 1
					<cfelse>
						and s.orf = 0	
					</cfif>	
				ORDER BY s.id
			</cfquery>
			
			<!--- this function is called for one library only so just get description for library once. --->
			<cfset seq_desc = CreateObject("component",  application.cfc & ".Utility").getMGOLDescription(qry.name[1])/>
			
			<cfscript>
				myfile = FileOpen("#arguments.filename#","write","UTF-8");
			</cfscript>
			
			<cfloop query="qry">
				<cfset sequence = qry.basepair/>
				<cfif arguments.orf_nuc>
					<cfset sequence = mid(sequence,qry.start,(qry.end-qry.start))/>
					<cfset qry.name = qry.seq_name/>
				</cfif>
				
				<cfscript>
					FileWriteLine(myfile,">#qry.name# #seq_desc# #application.NL#");
					FileWriteLine(myfile,"#formatSequence(sequence)#");
				</cfscript>
			</cfloop>
			
			<cfscript>
				FileClose(myfile);
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - EXPORTSEQ", 
						#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="saveImage" access="remote" output="false" returntype="any">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="data" type="binary" required="true" />
		
		<cftry>
			<cfscript>
				fileWrite("#arguments.filename#","#arguments.data#");
			</cfscript>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - SAVEIMAGE", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="savePDF" access="remote" output="false" returntype="any">
		<cfargument name="filename" type="string" required="true"/>
		<cfargument name="data" type="binary" required="true" />

		<cftry>
			<cfscript>
				fileWrite("#arguments.filename#","#arguments.data#");
			</cfscript>
			
			<cfdocument format="PDF" filename="#application.chartFilePath#/#_filename#.pdf" overwrite="yes">
				This is a generated PDF containing image data from Flex.
				<br><br>
				<img src="#application.chartFilePath#/#_filename#.png" >
				Enjoy!
			</cfdocument>
	
			<cfscript>
				fileDelete("#application.chartFilePath#/#_filename#.png");
			</cfscript>
		
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - SAVEPDF", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn "#application.rootHostPath#/charts/#_filename#.pdf">
	</cffunction>
	
	<cffunction name="formatSequence" access="private" returntype="string">
		<cfargument name="sequence" type="string" required="true"/>
		<cfset NL = CreateObject("java", "java.lang.System").getProperty("line.separator")>
		
		<cfset str = ''/>
		
		<cftry>
			<cfloop index="idx" from="1" to="#len(sequence)#" step="80">
				<cfset str &= mid(sequence,idx,80) & application.NL/>
			</cfloop>
		
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - FORMATSEQUENCE", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
		</cftry>
		
		<cfreturn str/>
		
	</cffunction>
		
</cfcomponent>