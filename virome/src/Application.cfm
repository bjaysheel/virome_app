<cfapplication name="VIROME" applicationtimeout="#createtimespan(0,2,0,0)#" 
	sessiontimeout="#createtimespan(0,2,0,0)#" sessionmanagement="true" />

	<cfscript>
		//production env (igs)
		request.cfc = "cfc";
		request.tracker_id = "UA-17366023-3";
		request.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBSbYlangC20ZDSoh64UTIAj25byVxR5sDFWZVaM--7wrItXxIschFS8zQ";
		
		//development env (virome.udel)
		if (FindNoCase('.udel.edu',CGI.HTTP_HOST) gt 0){
			request.cfc = "devel.cfc";
			request.tracker_id = "UA-17366023-1";
			request.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBQdVYN3EdDtLl4NNMD6gXWS-vWfShSIOaNRaBtOSCFyLDNZFjJvdmzQig";
		} else if (FindNoCase('localhost',CGI.HTTP_HOST) gt 0){
			request.cfc = "cfc";
			request.tracker_id = "UA-17366023-1";
			request.map_key = "ABQIAAAAp0BksRjoymo94K_lfWHZDBQdVYN3EdDtLl4NNMD6gXWS-vWfShSIOaNRaBtOSCFyLDNZFjJvdmzQig";
		}
		
		request.hostEndPoint = "http://#CGI.HTTP_HOST#/flex2gateway/";
		
		application.SessionId = Session.SessionId;
	</cfscript>