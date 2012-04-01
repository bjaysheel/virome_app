<cfsetting showdebugoutput="true"/> 

<cfoutput>
	<cfscript>
		obj = StructNew();
		obj['ENVIRONMENT']="";
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
	
	<cfset domList = ""/>
	<cfset objarr = ArrayNew(1)/>
	
	<!---<cfset rt_value = CreateObject("component",  application.cfc & ".Exporter").export(file,obj,binarydecode('',"Base64"),'')/>--->
	<cfset rt_value = CreateObject("component", application.cfc & ".SearchRPC").prepareRS(obj)/>
	<!---<cfdump var="#rt_value#">--->
		
	<!---<cfscript>
		sobj = StructNew();
		sobj['name'] = "test2";
		sobj['description'] = "test 2";
		sobj['project'] = "test 2";
		sobj['environment'] = "water";
		sobj['seqMethod'] = "sanger";
		sobj['publish'] = "0";
		sobj['user'] = "zeah";
	</cfscript>
	
	<cfdump var="#sobj#"/>
	
	<cfset value = CreateObject("component", application.cfc & ".Library").add_library(sobj)/>
	<cfdump var="#value#">--->
	
	<!-- git test2 -->
</cfoutput>
