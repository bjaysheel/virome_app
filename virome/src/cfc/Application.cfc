<cfcomponent output="false">

	<cfset this.name = "VIROME">
	<cfset this.sessionmanagement = true>
	<cfset this.applicationtimeout="#createtimespan(0,10,0,0)#">
	<cfset this.sessiontimeout="#createtimespan(0,2,0,0)#">

	<cffunction name="OnApplicationStart" output="true" returntype="void">
		<!--- DSN variables. --->
		<cfset application.mainDSN = "virome">
		<cfset application.lookupDSN = "uniref_lookup">

		<cfset application.seed = "SEED">
		<cfset application.kegg = "KEGG">
		<cfset application.cog = "COG">
		<cfset application.aclame = "ACLAME">
		<cfset application.uniref = "UNIREF100P">
		<cfset application.metagenome = "METAGENOMES">

		<!--- path variables --->
		<cfset rawPath = #ExpandPath('./')#>
		<cfif FindNoCase('htdocs', rawPath) gt 0>
			<cfset baseIndex1 = FindNoCase('htdocs',rawPath)>
			<cfset baseIndex2 = FindNoCase('/',rawPath,baseIndex1)>
			<cfset rawPath = Left(rawPath,baseIndex2-1)>
		<cfelseif FindNoCase('Library', rawPath) gt 0>
			<cfset baseIndex1 = FindNoCase('virome',rawPath)>
			<cfset baseIndex2 = FindNoCase('/',rawPath,baseIndex1)>
			<cfset rawPath = Left(rawPath,baseIndex2-1)>
		</cfif>

		<!--- production env (igs) --->
		<cfset application.rootHostPath = "http://#CGI.HTTP_HOST#">
		<cfset application.cfc = "cfc"/>
		<cfset application.tracker_id = "UA-17366023-3"/>
		<cfset application.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBSbYlangC20ZDSoh64UTIAj25byVxR5sDFWZVaM--7wrItXxIschFS8zQ"/>
		
		<!--- development env (virome.udel) --->
		<cfif (FindNoCase('.udel.edu',CGI.HTTP_HOST) gt 0) or (FindNoCase('localhost',CGI.HTTP_HOST) gt 0)>
			<cfset application.rootHostPath = "http://#CGI.HTTP_HOST#/VIROME">
			<cfset application.cfc = "VIROME.cfc"/>
			<cfset application.tracker_id = "UA-17366023-1"/>
			<cfset application.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBQdVYN3EdDtLl4NNMD6gXWS-vWfShSIOaNRaBtOSCFyLDNZFjJvdmzQig"/>
		</cfif>

		<cfset application.hostEndPoint = "http://#CGI.HTTP_HOST#/flex2gateway">
		<cfset application.webCFCPath = "#application.rootHostPath#/#application.cfc#">
	
		<cfset application.rootFilePath = "#rawPath#">
		<cfset application.chartFilePath = "#application.rootFilePath#/charts">
		<cfset application.blastImgFilePath = "#application.rootFilePath#/blastImager">
		<cfset application.idFilePath = "#application.rootFilePath#/idFiles">
		<cfset application.xDocsFilePath = "#application.rootFilePath#/xDocs">
		<cfset application.tmpFilePath = "#application.rootFilePath#/tmp">
		<cfset application.searchFilePath = "#application.rootFilePath#/search">
		
		<cfif CGI.HTTP_USER_AGENT contains "Mac">
			<cfset application.NL = "#chr(13)#">
		<cfelseif CGI.HTTP_USER_AGENT contains "Linux">
			<cfset application.NL = "#chr(13)#">
		<cfelse>
			<cfset application.NL = "#chr(13)##chr(10)#">
		</cfif>
	</cffunction>
</cfcomponent>