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
	
	<cfscript>
		fname = "test.txt";		
	</cfscript>
	#fname#<br/>
	#getFileFromPath(fname)#
		
	<cfset dna = "ATGC"/>
	<cfset dna = CreateObject("component",  application.cfc & ".Library").getHistogram(31,"local",1)/>
	#dna#
	
	<!---<cfset rt_value = CreateObject("component",  application.cfc & ".Exporter").export(file,obj,binarydecode('',"Base64"),'')/>--->
	<!---<cfset rt_value = CreateObject("component", application.cfc & ".SearchRPC").prepareRS(obj)/>--->
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
</cfoutput>


<!---<cfquery name="q" datasource="local" >
	select 	b.id, b.sequenceId, b.sys_topHit 
	from 	blastp b inner join 
			(select 	b.sequenceId, count(b.sys_topHit) as sys_count
			 from 	blastp b
			 where 	b.database_name = 'ACLAME'
				and b.sys_topHit = 1
			 group by b.sequenceId
			 having sys_count > 1) b2 on b2.sequenceId = b.sequenceId
	where 	b.database_name = 'ACLAME'
		and b.sys_topHit=1
	order by b.sequenceId, b.id
</cfquery>
<br/><br/>
<cfoutput query="q" group="sequenceId">
	#id# ----- #sequenceId# ----- #sys_topHit#<br/>
	<cfset idList = ""/>
	<cfset current = id/>
	<cfoutput>
		<cfif id neq current>
			<cfset idList = listappend(idList, id)/>
		</cfif>
	</cfoutput>
	<cfquery name="u" datasource="local" >
		update blastp set sys_topHit = 0 where id in (#idList#)
	</cfquery>
</cfoutput>

<cflog file="virome" type="information" text="update seed and aclame sys_topHit flags"/>
<cflog file="virome" type="information" text="#all_ids_updated#"/>--->