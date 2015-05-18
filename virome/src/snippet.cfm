<cfsetting showdebugoutput="true"/> 

<cfoutput>
	<cfscript>
		obj = StructNew();
		obj['ENVIRONMENT']="ORGANISMAL SUBSTRATE";
		obj['EVALUE']=0.001;
		obj['LIBRARY']=31;
		obj['BLASTDB']="";
		obj['SEQUENCE']="HUFHumanFecesSDVir_065_1_687_1";
		obj['SEQUENCEID']="";
		obj['READID']="";
		obj['ORFTYPE']="";
		obj['VIRCAT']="";
		obj['INTERM']="";
		obj['TERM']="";
		obj['ACCESSION']="";
		obj['INACC']="";
		obj['TAXONOMY']="";
		obj['INTAX']="";
		obj['TAG']="";
		obj['IDFILE']="";
		obj['USERNAME']="bjaysheel";
		obj['USERID'] = 3;
		obj['ALIAS'] = "bare test";
		obj['JOBNAME'] = "bare test";
		
		file = structnew();
		file['peptide'] = "false";
		file['nucleotide'] = "true";
		file['image']  = "false";
		file['read'] = "true";
		file['csv'] = "true";
	</cfscript>
	
	<cfset value = CreateObject("component", request.cfc & ".Library").getBLASTDBObject("3")/>
	<cfdump var="#value#">
	
	
	<cfset list = "water"/>
	[#listFirst(list, " ")#]
</cfoutput>
