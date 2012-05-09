<cfapplication name="VIROME" applicationtimeout="#createtimespan(0,2,0,0)#" 
	sessiontimeout="#createtimespan(0,2,0,0)#" sessionmanagement="true" />

<cfscript>
	//DSN variables.
	application.mainDSN = "virome";
	application.lookupDSN = "uniref_lookup";

	application.seed = "SEED";
	application.kegg = "KEGG";
	application.cog = "COG";
	application.aclame = "ACLAME";
	application.uniref = "UNIREF100P";
	application.metagenome = "METAGENOMES";
	
	//email to/from adr
	reportFrom = "@EMAIL_FROM_ERROR_REPORT@";
	reportErrorTo = "@EMAIL_TO_ERROR_REPORT@";
	reportLibrarySubmissionTo = "virome@dbi.udel.edu";

	//path variables
	rawPath = ExpandPath('./');
	if (FindNoCase('htdocs', rawPath) gt 0){
		baseIndex1 = FindNoCase('htdocs',rawPath);
		baseIndex2 = FindNoCase('/',rawPath,baseIndex1);
		rawPath = Left(rawPath,baseIndex2-1);
	} else if(FindNoCase('Library', rawPath) gt 0){
		baseIndex1 = FindNoCase('virome',rawPath);
		baseIndex2 = FindNoCase('/',rawPath,baseIndex1);
		rawPath = Left(rawPath,baseIndex2-1);
	}

	//production env (igs)
	application.rootHostPath = "http://#CGI.HTTP_HOST#";
	application.cfc = "cfc";
	application.tracker_id = "UA-17366023-3";
	application.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBSbYlangC20ZDSoh64UTIAj25byVxR5sDFWZVaM--7wrItXxIschFS8zQ";
	
	//development env (virome.udel)
	if ((FindNoCase('.udel.edu',CGI.HTTP_HOST) gt 0) or (FindNoCase('localhost',CGI.HTTP_HOST) gt 0)){
		application.rootHostPath = "http://#CGI.HTTP_HOST#/VIROME";
		application.cfc = "VIROME.cfc";
		application.tracker_id = "UA-17366023-1";
		application.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBQdVYN3EdDtLl4NNMD6gXWS-vWfShSIOaNRaBtOSCFyLDNZFjJvdmzQig";
	}

	application.hostEndPoint = "http://#CGI.HTTP_HOST#/flex2gateway/";
	application.webCFCPath = "#application.rootHostPath#/#application.cfc#";

	application.rootFilePath = "#rawPath#";
	application.chartFilePath = "#application.rootFilePath#/charts";
	application.blastImgFilePath = "#application.rootFilePath#/blastImager";
	application.idFilePath = "#application.rootFilePath#/idFiles";
	application.xDocsFilePath = "#application.rootFilePath#/xDocs";
	application.tmpFilePath = "#application.rootFilePath#/tmp";
	application.searchFilePath = "#application.rootFilePath#/search";
	
	if (FindNoCase("Mac", CGI.HTTP_USER_AGENT) or FindNoCase("Linux", CGI.HTTP_USER_AGENT))
		application.linefeed = #chr(10)#;
	else
		application.linefeed = #chr(13)#&#chr(10)#;
</cfscript>