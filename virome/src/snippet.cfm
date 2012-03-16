<cfsetting showdebugoutput="true"/> 

<cfoutput>
	<cfscript>
		obj = StructNew();
		obj['ENVIRONMENT']="ORGANISMAL SUBSTRATE";
		obj['EVALUE']=0.001;
		obj['LIBRARY']=31;
		obj['BLASTDB']="ACLAME";
		obj['SEQUENCE']="";
		obj['SEQUENCEID']="";
		obj['READID']="";
		obj['ORFTYPE']="";
		obj['VIRCAT']="fxn";
		obj['INTERM']="";
		obj['TERM']="";
		obj['ACCESSION']="";
		obj['INACC']="";
		obj['TAXONOMY']="";
		obj['INTAX']="";
		obj['TAG']="TAG_2";
		obj['IDFILE']="ACLAME_IDDOC_31.xml";
		
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
	<!---<cfset rt_value = CreateObject("component", application.cfc & ".SearchRPC").getSearchRSLT(obj,0,10)/>--->
	<!---<cfdump var="#rt_value#">--->
		
	<cfscript>
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
	<cfdump var="#value#">
	
	<!-- git test -->
</cfoutput>
