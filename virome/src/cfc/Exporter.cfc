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
				<cfset exportSeq(filename=name,obj=arguments.genInfoObject,r=false,o=false)/>
			</cfif>
			
			<!--- download library rRNA --->
			<cfif arguments.fileObject.librRNA>
				<cfset name = dir & "/" & fname & "_rRNA.fasta"/>
				<cfset exportSeq(filename=name,obj=arguments.genInfoObject,r=true,o=false)/>
			</cfif>
			
			<!--- download library tRNA --->
			<cfif arguments.fileObject.libtRNA>
				<cfset name = dir & "/" & fname & "_rRNA.fasta"/>
				<cfset exporttRNASeq(filename=name,obj=arguments.genInfoObject)/>
			</cfif>
			
			<!--- download library orfs as peptides --->
			<cfif arguments.fileObject.libPeptide>
				<cfset name = dir & "/" & fname & "_orf_pep.fasta"/>
				<cfset exportSeq(filename=name,obj=arguments.genInfoObject,r=false,o=true)/>
			</cfif>
			
			<!--- download library orfs as nucleotides --->
			<cfif arguments.fileObject.libNucleotide>
				<cfset name = dir & "/" & fname & "_orf_nuc.fasta"/>
				<cfset exportSeq(filename=name,obj=arguments.genInfoObject,r=true,o=true)/>
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
							o.end,
							o.strand,
							o.type,
							s.basepair as peptide
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
					<cfset sequence = extractORF(sequence, qry.start, qry.end, qry.strand, qry.type) />
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
		<cfargument name="r" type="boolean" default="false"/>
		<cfargument name="o" type="boolean" default="false"/>
		
		<!--- get server from either sequence name using prefix or from environment --->
		<cfset _serverObject = CreateObject("component",  application.cfc & ".Utility").getServerName(arguments.obj.ENVIRONMENT,arguments.obj.SEQUENCE)/>
		<cfset _server = _serverObject['server']/>
		<cfset _environment = _serverObject['environment']/>
		
		<cftry>
			
			<!--- r=0 and o=0 => get reads (nuc) 
				  r=0 and o=1 => get orfs (peptide)
				  r=1 and o=0 => get rRNA (nuc)
				  r=1 and o=1 => get orfs (nuc) --->
			<cfquery name="qry" datasource="#_server#">
				SELECT	distinct
							s.id as sequenceId,
							s.libraryId,
							s.basepair,
							s.name
						<cfif arguments.o and arguments.r>
							,o.start
							,o.end
							,o.seq_name
							,o.strand
							,o.type
						</cfif>
				FROM 	sequence s 
					<cfif arguments.o and arguments.r>
						right join orf o on o.readId = s.id
					</cfif>
				WHERE	s.deleted=0
					and s.libraryId = #arguments.obj.library#
					
					<cfif (arguments.r) and (not arguments.o)>
						and s.rRNA=1
					<cfelse>
						and s.rRNA=0
					</cfif>
					
					<cfif (arguments.o) and (not arguments.r)>
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
				
				<cfif arguments.o and arguments.r>
					<cfset sequence = extractORF(sequence, qry.start, qry.end, qry.strand, qry.type) />
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
	
	<cffunction name="exporttRNASeq" access="private" returntype="any">
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
					and s.rRNA = 0
					and s.orf = 0
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
					FileWriteLine(myfile,">#qry.name# #seq_desc# #tRNA# #application.NL#");
					FileWriteLine(myfile,"#formatSequence(sequence)#");
				</cfscript>
			</cfoutput>
			
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
	
	<cffunction name="extractORF" access="private" returntype="String">
		<cfargument name="seqeunce" type="string" required="true"/>
		<cfargument name="start" type="numeric" required="true" />
		<cfargument name="end" type="numeric" required="true" />
		<cfargument name="strand" type="string" required="true" />
		<cfargument name="type" type="string" required="true" />
		
		<cftry>
	 		<cfset arguments.sequence = mid(arguments.sequence,arguments.start,(arguments.end-arguments.start)+1)/>
			
			<cfif arguments.strand eq "-">
				<cfset arguments.sequence = CreateObject("component",  application.cfc & ".Utility").reverseComplement(arguments.sequence)/>
			</cfif>
			
			<!--- if missing start codon then make nucleotide sequence a multiple of 3
				  i.e remove 1 or 2 bases from the start of sequence --->
			<cfif lcase(arguments.type) eq 'lack start'>
				<cfif len(arguments.sequence)%3 eq 2>
					<cfset arguments.sequence = right(arguments.seqeunce, len(arguments.seqeunce)-2) />
				<cfelseif len(arguments.sequence)%3 eq 1>
					<cfset arguments.sequence = right(arguments.seqeunce, len(arguments.seqeunce)-1) />
				</cfif>
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  application.cfc & ".Utility").reporterror("EXPORTER.CFC - EXTRACTORF", 
									#cfcatch.Message#, #cfcatch.Detail#, #cfcatch.tagcontext#)>
			</cfcatch>
			
			<cffinally>
				<cfreturn arguments.sequence/>
			</cffinally>
		</cftry>
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