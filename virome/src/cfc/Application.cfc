<cfcomponent output="false">

	<cfset this.name = "VIROME">
	<cfset this.sessionmanagement = true>
	<cfset this.applicationtimeout="#createtimespan(0,10,0,0)#">
	<cfset this.sessiontimeout="#createtimespan(0,2,0,0)#">

	<cffunction name="OnApplicationStart" output="false" returntype="void">
		<cfscript>
			
		</cfscript>
	</cffunction>
	
	
	<cffunction name="onSessionStart" output="false" returntype="void" >
		<cfscript>
			
		</cfscript>
	</cffunction>
	
	
	<cffunction name="onRequestStart" output="false" returntype="void" >
		<cfscript>
			//DSN variables.
			request.mainDSN = "virome";
			request.lookupDSN = "uniref_lookup";
	
			request.seed = "SEED";
			request.kegg = "KEGG";
			request.cog = "COG"; 
			request.aclame = "ACLAME";
			request.uniref = "UNIREF100P";
			request.metagenome = "METAGENOMES";
			
			//email to/from adr
			request.reportFrom = "kingquattro@gmail.com";
			request.reportErrorTo = "bjaysheel@gmail.com";
			request.reportLibrarySubmissionTo = "virome@dbi.udel.edu";
	
			//path variables
			rawPath = ExpandPath('./');
			if (FindNoCase('htdocs', rawPath) gt 0){
				baseIndex1 = FindNoCase('htdocs', rawPath);
				baseIndex2 = FindNoCase('/', rawPath, baseIndex1);
				rawPath = Left(rawPath, baseIndex2-1);
			} else if(FindNoCase('Library', rawPath) gt 0){
				baseIndex1 = FindNoCase('virome', rawPath);
				
				if (baseIndex1 eq 0)
					baseIndex1 = FindNoCase('devel', rawPath);
				
				baseIndex2 = FindNoCase('/', rawPath, baseIndex1);
				rawPath = Left(rawPath, baseIndex2-1);
			}
	
			//production env (igs)
			request.rootHostPath = "http://#CGI.HTTP_HOST#";
			request.cfc = "cfc";
			request.tracker_id = "UA-17366023-3";
			request.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBSbYlangC20ZDSoh64UTIAj25byVxR5sDFWZVaM--7wrItXxIschFS8zQ";
			
			//development env (virome.udel)
			if (FindNoCase(".udel.edu",CGI.HTTP_HOST)) {
				request.rootHostPath = "http://#CGI.HTTP_HOST#/devel";
				request.cfc = "devel.cfc";
				request.tracker_id = "UA-17366023-1";
				request.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBQdVYN3EdDtLl4NNMD6gXWS-vWfShSIOaNRaBtOSCFyLDNZFjJvdmzQig";
			} else if (FindNoCase('localhost',CGI.HTTP_HOST)) {
				//request.rootHostPath = "http://#CGI.HTTP_HOST#/VIROME";
				request.rootHostPath = "http://localhost.virome/";
				request.cfc = "cfc";
				request.tracker_id = "UA-17366023-1";
				request.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBQdVYN3EdDtLl4NNMD6gXWS-vWfShSIOaNRaBtOSCFyLDNZFjJvdmzQig";
			}
	
			request.hostEndPoint = "http://#CGI.HTTP_HOST#/flex2gateway/";
			request.webCFCPath = "#request.rootHostPath#/#request.cfc#";
		
			request.rootFilePath = "#rawPath#";
			request.chartFilePath = "#request.rootFilePath#/charts";
			request.blastImgFilePath = "#request.rootFilePath#/blastImager";
			request.idFilePath = "#request.rootFilePath#/idFiles";
			request.xDocsFilePath = "#request.rootFilePath#/xDocs";
			request.tmpFilePath = "#request.rootFilePath#/tmp";
			request.searchFilePath = "#request.rootFilePath#/search";
			
			if (FindNoCase("Mac", CGI.HTTP_USER_AGENT) or FindNoCase("Linux", CGI.HTTP_USER_AGENT))
				request.linefeed = #chr(10)#;
			else
				request.linefeed = #chr(13)#&#chr(10)#;
				
		</cfscript>
	</cffunction>
	
	<cffunction name="OnRequest" output="false" returntype="void" >
		
	</cffunction>
</cfcomponent>