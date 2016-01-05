<cfcomponent displayname="Utility" output="false" hint="
			A utility/helper component used by all Coldfusion functions.
			">

	<cffunction name="getMGOLDescription" access="remote" returntype="String" hint="
				Create a detailed description of a Metagenome library information.
				
				DEPRICATED.  VIROME pipeline creates this information at analysis time 
				">
				
		<cfargument name="hitName" type="String" required="true" />
		
		<cftry>
			<cfset str="" />
			
			<!--- get metagenoems data --->
			<cfquery name="mgoldesc" datasource="#request.mainDSN#" result="qrslt">
				SELECT	ls.seqmethod,
						ls.metatype,
						ls.acidtype,
						ls.place,
						ls.country,
						ls.phys_subst,
						ls.ecosystem,
						ls.library_name
				FROM	library_metadata ls
				WHERE	ls.prefix = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(arguments.hitName,3)#" />
			</cfquery>
			
			<cfset dwel = "N/A"/>
			<cfif mgoldesc.recordcount>
				<cfset dwel = mgoldesc.phys_subst>
				
				<cfset str = "#mgoldesc.metatype# metagenome from #mgoldesc.ecosystem# #dwel#"&
						 " near #mgoldesc.place#, #mgoldesc.country# [library: #mgoldesc.library_name#]"/>	
			</cfif>
			
			<cfcatch type="any">
				<cfset reporterror(method_name="Utility",
									function_name=getFunctionCalledName(),
									args=arguments,
									msg=cfcatch.Message,
									detail=cfcatch.Detail,
									tagcontent=cfcatch.tagcontext)>																		
			</cfcatch>
			
			<cffinally>
				<cfreturn str>
			</cffinally>
		</cftry>
	</cffunction>
	
	<cffunction name="getServerName" access="public" returntype="Struct" hint="
				Get name of server/database from either environment, sequence_name
				mgol_hit or libraryId
				
				Return: A hash
				">

		<cfargument name="environment" type="string" default="-1" required="false">
		<cfargument name="sequence_name" type="string" default="" required="false">
		<cfargument name="mgol_hit" type="boolean" default="false">
		<cfargument name="libraryId" type="numeric" default="-1" required="false" >
		
		<cfset obj=StructNew()>
		<cfset obj['server'] = "">
		<cfset obj['environment'] = "">
		<cfset obj['library'] = 0>
		
		<cftry>
			<cfquery name="q" datasource="#request.mainDSN#">
				SELECT 	server, environment, id
				FROM	library
				WHERE	deleted = 0
					<cfif len(arguments.environment) and (arguments.environment neq "-1")>
						and	environment = <cfqueryparam cfsqltype="cf_sql_varchar" null="false" value="#arguments.environment#">
					<cfelseif len(arguments.sequence_name)>
						and prefix = <cfqueryparam cfsqltype="cf_sql_varchar" null="false" value="#left(arguments.sequence_name,3)#"/>
					<cfelseif arguments.libraryId neq -1>
						and id = <cfqueryparam cfsqltype="cf_sql_integer" null="false" value="#arguments.libraryId#"> 
					<cfelse>
						<!--- fail safe, if environment of seq does not find a server, nothing should be returned --->
						and environment = "NOTFOUND"
					</cfif>
				LIMIT 1
			</cfquery>
			
			<cfif q.recordcount gt 0>
				<cfset structupdate(obj,"server",q.server)/>
				<cfset structupdate(obj,"environment",q.environment)/>
				<cfset structupdate(obj,"library",q.id)/>
				<cfreturn obj>
			<cfelseif NOT arguments.mgol_hit>
				<cfset reportServerError(arguments.environment,arguments.sequence_name)>
			</cfif>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="Utility", 
																		function_name=getFunctionCalledName(), 
																		args=arguments, 
																		msg=cfcatch.Message, 
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn obj>
	</cffunction>
	
	<cffunction name="getLibraryList" access="public" returntype="String" hint="
				Return list of all libraries that belong to a given environment
				
				Return: A comma separated list of library IDs
				">

		<cfargument name="environment" type="string" default="" required="true">

		<cfset libList = "">
		
		<cftry>
			<cfquery name="q" datasource="#request.mainDSN#">
				SELECT 	id
				FROM	library
				WHERE	deleted = 0
					and	environment = <cfqueryparam cfsqltype="cf_sql_varchar" null="false" value="#arguments.environment#">
			</cfquery>

			<cfloop query="q">
				<cfif len(libList)>
					<cfset libList = libList & "," & q.id>
				<cfelse>
					<cfset libList = q.id>
				</cfif>
			</cfloop>

			<cfcatch type="any">
				<cfset reporterror("UTILITY.CFC - GETLIBRARYLIST", #cfcatch.Message#, #cfcatch.Detail#)>
			</cfcatch>
		</cftry>
		
		<cfreturn libList>
	</cffunction>
	
	<cffunction name="reporterror" access="public" returntype="Any" hint="
				Generate a detailed error report with
					error type
					error message
					location of error
					name of component
					name of function
				
				and send an email to administrator email as listed in Application.cfc
					
				Return: NA
				">
				
		<cfargument name="method_name" default="" type="string" required="true">
		<cfargument name="function_name" default="" type="string" required="true" >
		<cfargument name="args" default="" type="any" required="false" >
		<cfargument name="msg" default="" type="String" required="true">
		<cfargument name="detail" default="" type="String" required="true">
		<cfargument name="tagcontent" default="" type="Array" required="true">
		
		<cfmail to="#request.reportErrorTo#" type="html"
				from="#request.reportFrom#"
				subject="ERROR IN VIROME APPLICATION">

			This is an automatic email generated from VIROME.<br/>
			-------------------------------------------------------<br/><br/>

			There has been an error in VIROME (#CGI.HTTP_HOST#) application in <br/>

			Method: #arguments.method_name#<br/>
			Function: #arguments.function_name#<br/><br/>

			<cfif (isDefined("arguments.args") and isStruct(arguments.args))>
				Arguments passed:<br/>
				<cfdump var="#arguments.args#">
				<!---<cfloop collection="#arguments.args#" item="key" >
					#key#:     #arguments.args[key]#<br/>
				</cfloop>--->
				<br/><br/>
			</cfif>
			
			
			ERROR MESSAGE:<br/>
			#msg#<br/><br/>

			ERROR DETAILS:<br/>
			#detail#<br/><br/>
			
			TAGCONTENT:<br/>
			<cfloop array="#tagcontent#" index="idx">
			#idx.TEMPLATE#: #idx.RAW_TRACE#<br/>
			</cfloop><br/><br/>
			
			
			<cfif isDefined('cookie.VIROMEDEBUGCOOKIE')>
				USER LOGGED IN: #cookie.VIROMEDEBUGCOOKIE#<br/>
				CURRENT TIME: #now()#
			</cfif>
			<br/><br/><br/>VIROME APP
		</cfmail>
	</cffunction>
	
	<cffunction name="reportFlexError" access="remote" returntype="void" hint="
				Flex does not have a way to catch an error and report/log the message.
				This untility give an ability for end user to email a Flex run time 
				error messsage to the administrator.
				
				Return: NA				
				">
				
		<cfargument name="msg" default="" type="String" required="true">
		
		<cfmail to="#request.reportErrorTo#" type="html"
				from="#request.reportFrom#"
				subject="ERROR IN VIROME APPLICATION">

			This is an automatic email generated from VIROME.<br/>
			-------------------------------------------------------<br/><br/>

			There has been an error a FLEX error in VIROME (#CGI.HTTP_HOST#) <br/><br/>

			ERROR MESSAGE:<br/><br/>
			#arguments.msg#<br/><br/>
			
			<br/><br/>
			<cfif isDefined('cookie.VIROMEDEBUGCOOKIE')>
				USER LOGGED IN: #cookie.VIROMEDEBUGCOOKIE#<br/>
				CURRENT TIME: #now()#
			</cfif>
			<br/><br/><br/>VIROME APP
		</cfmail>		
	</cffunction>
	
	<cffunction name="reportServerError" access="public" returntype="void" hint="
				Report a very specific error when given environment or sequence information
				VIROME database can not identify a server/database
				">
				
		<cfargument name="envname" type="String">
		<cfargument name="seqname" type="String">

		<cfmail to="#request.reportErrorTo#" type="html"
				from="#request.reportFrom#"
				subject="ERROR IN VIROME APPLICATION">

			This is an automatic email generated from VIROME.<br/>
			-------------------------------------------------------<br/><br/>

			There has been an error in VIROME (#CGI.HTTP_HOST#) application in <br/>

			There has been an error finding server using environment: #envname# and/or sequence: #seqname#
			
			<br/><br/>
			USER LOGGED IN: #cookie.VIROMEDEBUGCOOKIE#<br/>
			CURRENT TIME: #now()#
			
			<br/><br/><br/>VIROME APP
		</cfmail>
	</cffunction>
	
	<cffunction name="reportLibrarySubmission" access="public" returntype="void" hint="
				When a new library is added to the database, send an email to VIROME admin
				notifying addition of new library.
				
				DEPRICATED
				
				Return: NA
				">
		<cfargument name="obj" type="struct" required="true" >
		<cfargument name="action" type="string" required="true" >
		
		<cfmail type="html" to="#request.reportLibrarySubmissionTo#" from="#request.reportLibrarySubmissionTo#" subject="Library Submission [#arguments.action#]">
			<cfif arguments.action eq "add">
				New library #arguments.obj.name# has been added by #arguments.obj.user#<br/><br/>
				
				Library summary:<br/>
					Name: 			#arguments.obj.name#<br/>
					Description: 	#arguments.obj.description#<br/>
					Environment:	#arguments.obj.environment#<br/>
					Project:		#arguments.obj.project#"<br/>
			<cfelseif arguments.action eq "edit">
				Library #arguments.obj.old_name# (#arguments.obj.prefix#) has been edited by #arguments.obj.user#<br/><br/>
				
				Library summary:<br/>
					Name: 			#arguments.obj.name#<br/>
					Description: 	#arguments.obj.description#<br/>
					Environment:	#arguments.obj.environment#<br/>
					Project:		#arguments.obj.project#"<br/>
			<cfelseif arguments.action eq "delete">
				Library #arguments.obj.old_name# (#arguments.obj.prefix#) has been deleted.<br/>
			</cfif>
			
			<br/><br/><br/>VIROME APP
		</cfmail>
	</cffunction>

	<cffunction name="PrintLog" access="public" returntype="void" hint="
				Print log to virome.log file stored in ColdFusion logs/ directory
				">

		<cfargument name="str" type="string" default="">

		<cflog type="information" file="virome" text="#str#">

	</cffunction>

	<cffunction name="QueryToStructure" access="public" returntype="Struct" hint="
				Convert a give Query (SQL result set) into a hash of hashes using
				a query column as unique identifier for hash key (usually a primary key of table/query)
				
				Return: A hash of hashes
				">

		<cfargument name="theQuery" type="Query" required="true" default="">
		<cfargument name="primaryKey" type="String" required="true" default="">

		<cfset theStructure = StructNew()>
		<cfset cols = "">
		<cfset row = 1>
		<cfset thisRow = "">
		<cfset col = 1>

		<cfscript>
			/**
			 * Converts a query object into a structure of structures accessible by its primary key.
			 *
			 * @param theQuery 	 The query you want to convert to a structure of structures.
			 * @param primaryKey 	 Query column to use as the primary key.
			 * @return Returns a structure.
			 * @author Shawn Seley (shawnse@aol.com)
			 * @version 1, March 27, 2002
			 */

			  theStructure  = structnew();
			  // remove primary key from cols listing
			  cols 		    = ListToArray(theQuery.columnList);
			  //cols          = ListToArray(ListDeleteAt(theQuery.columnlist, ListFindNoCase(theQuery.columnlist, primaryKey)));
			  row           = 1;
			  thisRow       = "";
			  col           = 1;

			  for(row = 1; row LTE theQuery.recordcount; row = row + 1){
			    thisRow = structnew();
			    for(col = 1; col LTE arraylen(cols); col = col + 1){
					pos = Find(";",theQuery[cols[col]][row],0);
					if (pos gt 0){
						theQuery[cols[col]][row] = mid(theQuery[cols[col]][row],1,pos-1);
					}
			      thisRow[cols[col]] = theQuery[cols[col]][row];
			    }
			    theStructure[theQuery[primaryKey][row]] = duplicate(thisRow);
			  }
			  return(theStructure);
		</cfscript>


	</cffunction>

     <cffunction name="QueryToStruct" access="public" returntype="any" output="false" hint="
				 Converts an entire query or the given record to a struct. 
				 This might return a structure (single record) or an array of structures.
				 
				 Return: A hash or array of hashes
				 ">

	     <!--- Define arguments. --->
	     <cfargument name="Query" type="query" required="true" />
	     <cfargument name="Row" type="numeric" required="false" default="0" />

	     <cfscript>

		     // Define the local scope.
		     var LOCAL = StructNew();

		     // Determine the indexes that we will need to loop over.
		     // To do so, check to see if we are working with a given row,
		     // or the whole record set.
		     if (ARGUMENTS.Row){
			     // We are only looping over one row.
			     LOCAL.FromIndex = ARGUMENTS.Row;
			     LOCAL.ToIndex = ARGUMENTS.Row;
		     } else {

				 // We are looping over the entire query.
			     LOCAL.FromIndex = 1;
			     LOCAL.ToIndex = ARGUMENTS.Query.RecordCount;
		     }


		     // Get the list of columns as an array and the column count.
		     LOCAL.Columns = ListToArray( ARGUMENTS.Query.ColumnList );
		     LOCAL.ColumnCount = ArrayLen( LOCAL.Columns );


		     // Create an array to keep all the objects.
		     LOCAL.DataArray = ArrayNew( 1 );

		     // Loop over the rows to create a structure for each row.
		     for (LOCAL.RowIndex = LOCAL.FromIndex ; LOCAL.RowIndex LTE LOCAL.ToIndex ; LOCAL.RowIndex = (LOCAL.RowIndex + 1)){
			     // Create a new structure for this row.
			     ArrayAppend( LOCAL.DataArray, StructNew() );


		    	 // Get the index of the current data array object.
			     LOCAL.DataArrayIndex = ArrayLen( LOCAL.DataArray );


		    	 // Loop over the columns to set the structure values.
			     for (LOCAL.ColumnIndex = 1 ; LOCAL.ColumnIndex LTE LOCAL.ColumnCount ; LOCAL.ColumnIndex = (LOCAL.ColumnIndex + 1)){

				     // Get the column value.
				     LOCAL.ColumnName = LOCAL.Columns[ LOCAL.ColumnIndex ];
					
					if (LOCAL.ColumnName.EqualsIgnoreCase('E_VALUE')){
						// Set column value into the structure.
						//LOCAL.DataArray[ LOCAL.DataArrayIndex ][ LOCAL.ColumnName ] = "aaaa4.001";
				     	LOCAL.DataArray[ LOCAL.DataArrayIndex ][ LOCAL.ColumnName ] = ARGUMENTS.Query[ LOCAL.ColumnName ][ LOCAL.RowIndex ];
					} else {
						// Set column value into the structure.
				     	LOCAL.DataArray[ LOCAL.DataArrayIndex ][ LOCAL.ColumnName ] = ARGUMENTS.Query[ LOCAL.ColumnName ][ LOCAL.RowIndex ];
					}
				 }
			}

		     // At this point, we have an array of structure objects that
		     // represent the rows in the query over the indexes that we
		     // wanted to convert. If we did not want to convert a specific
		     // record, return the array. If we wanted to convert a single
		     // row, then return the just that STRUCTURE, not the array.
		     if (ARGUMENTS.Row){
			     // Return the first array item.
			     return( LOCAL.DataArray[ 1 ] );
		     } else {
			     // Return the entire array.
			     return( LOCAL.DataArray );
		     }
		</cfscript>
     </cffunction>

	<cffunction name="SortArrayOfStrut" access="public" returntype="array" hint="
				Given an array of hashes deep sort hashes based on key and sort order defined.
				
				Return: A array of hashes
				">
		<cfargument name="aOfS" type="array" required="true">
		<cfargument name="key" type="string" required="true">
		<cfargument name="sOrder" type="string" default="asc">
		<cfargument name="sType" type="string" default="textnocase">
		<cfargument name="delim" type="string" default=".">
		
		
		<cfscript>
			/**
			* Sorts an array of structures based on a key in the structures.
			*
			* @param aofS      Array of structures.
			* @param key      Key to sort by.
			* @param sortOrder      Order to sort by, asc or desc.
			* @param sortType      Text, textnocase, or numeric.
			* @param delim      Delimiter used for temporary data storage. Must not exist in data. Defaults to a period.
			* @return Returns a sorted array.
			* @author Nathan Dintenfass (nathan@changemedia.com)
			* @version 1, December 10, 2001
			* @version 1.0 Dec 29, 2012 by Jaysheel Bhavsar
			*/
			        //by default we'll use an ascending sort
			        var sortOrder = arguments.sOrder;        
			        
			        //by default, we'll use a textnocase sort
			        var sortType = arguments.sType;
			        
			        //by default, use ascii character 30 as the delim
			        var delimeter = arguments.delim;
			        
			        //make an array to hold the sort stuff
			        var sortArray = arraynew(1);
			        
			        //make an array to return
			        var returnArray = arraynew(1);
			        
			        //grab the number of elements in the array (used in the loops)
			        var count = arrayLen(arguments.aOfS);
			        
			        //make a variable to use in the loop
			        var ii = 1;
			        
			        //loop over the array of structs, building the sortArray
			        for(ii = 1; ii lte count; ii = ii + 1)
			            sortArray[ii] = arguments.aOfS[ii][key] & delimeter & ii;
			        
			        //now sort the array
			        arraySort(sortArray,sortType,sortOrder);
			        
			        //now build the return array
			        for(ii = 1; ii lte count; ii = ii + 1)
			            returnArray[ii] = arguments.aOfS[listLast(sortArray[ii], delimeter)];
			        
			        //return the array
			        return returnArray;
		</cfscript>
	</cffunction>


	<cffunction name="getMedianEvalue" access="public" returntype="Numeric" hint="
				Get media (not mean) of a given array
				
				Return: Median value.
				">
		<cfargument name="arr" type="array" required="true">

		<cfset mid = 0>
		<cfset meval = 0>

		<cfscript>
			ArraySort(arr,"numeric","asc");
			mid = Ceiling(ArrayLen(arr)/2);

			if (mid != 0)
				meval = arr[mid];

			return meval;
		</cfscript>
	</cffunction>

	<cffunction name="ECToHexColor" access="public" returntype="String" hint="
				Given a E-value convert it into RGB Hex value for heat map display
				
				Return: A string in RGB Hex Color
				">
		<cfargument name="evalue" type="Numeric" required="true" />
		<cfargument name="coverage" type="Numeric" required="true" />
		<cfargument name="emin" type="Numeric" required="true" />
		<cfargument name="emax" type="Numeric" required="true" />
		<cfargument name="cmin" type="Numeric" required="true" />
		<cfargument name="cmax" type="Numeric" required="true" />
		
		<cftry>
			<cfif arguments.emin eq 0>
				<cfset arguments.emin = 1e-300>
			</cfif>
			
			<cfif arguments.evalue eq 0>
				<cfset arguments.evalue = 1e-300>
			</cfif>
			
			<cfset red = abs(log10(arguments.evalue)-log10(arguments.emax))>

			<cfif (log10(arguments.emin) eq log10(arguments.emax))>
				<cfset red=255>
			<cfelse>
				<cfset diff = abs(log10(arguments.emax) - log10(arguments.emin)) />			
				<cfset factor = (255/diff) />
				<cfset red = Int(red*factor)>
			</cfif>
			
			<cfif red gt 255>				
				<cfset red = 255>
			</cfif>
			
			<cfset blue = 255-red>
			<cfset green=0>
			
			<!---
			Now, we can create HEX numbers using RGB values. When
			creating the colors, things are little more complicated
			because we need a 6 digit value, but simply converting
			base 10 to hex might not give us two digit values for
			each color.
			--->
			<cfset strRed = FormatBaseN( red, 16 ) />
			<cfset strGreen = FormatBaseN( green, 16 ) />
			<cfset strBlue = FormatBaseN( Blue, 16 ) />
			 
			<!--- Now, make sure they have two digits. --->
			<cfif (Len( strRed ) EQ 1)>
				<cfset strRed = ("0" & strRed) />
			</cfif> 
			
			<cfif (Len( strGreen ) EQ 1)>
				<cfset strGreen = ("0" & strGreen) />
			</cfif>
			
			<cfif (Len( strBlue ) EQ 1)>
				<cfset strBlue = ("0" & strBlue) />
			</cfif>
			 
			<!--- Combine the RGB HEX values to get the color HEX. --->
			<cfset strHEX = UCase(strRed & strGreen & strBlue) />
			 
			 <cfreturn "##" & strHEX/>
			
			<cfcatch type="any">
				<cfset reporterror("UTILITY.CFC - ECToHexColor emin: #arguments.emin# emax: #arguments.emax# eval: #arguments.evalue#", cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="sortArrayOfStruct" access="private" returntype="array" hint="
				Given an array of hashes deep sort hashes based on key and sort order defined.
				
				Return: A array of hashes
				">

		<cfargument name="aOfS" type="array" required="true">
		<cfargument name="key" type="string" required="true">
		<cfargument name="sortOrder" type="String" default="asc">
		<cfargument name="sortType" type="String" default="textnocase">

		<cfset delim = ".">;
		<cfset srotArray = ArrayNew(1)>
		<cfset returnArray = ArrayNew(1)>
		<cfset count = ArrayLen(aOfS)>
		<cfset ii = 1>

		<cfscript>
			/**
			 * Sorts an array of structures based on a key in the structures.
			 *
			 * @param aofS 	 Array of structures.
			 * @param key 	 Key to sort by.
			 * @param sortOrder 	 Order to sort by, asc or desc.
			 * @param sortType 	 Text, textnocase, or numeric.
			 * @param delim 	 Delimiter used for temporary data storage. Must not exist in data. Defaults to a period.
			 * @return Returns a sorted array.
			 * @author Nathan Dintenfass (nathan@changemedia.com)
			 * @version 1, December 10, 2001
			 */

			//loop over the array of structs, building the sortArray
			for(ii = 1; ii lte count; ii = ii + 1)
				sortArray[ii] = aOfS[ii][key] & delim & ii;
			//now sort the array
			arraySort(sortArray,sortType,sortOrder);
			//now build the return array
			for(ii = 1; ii lte count; ii = ii + 1)
				returnArray[ii] = aOfS[listLast(sortArray[ii],delim)];
			//return the array
			return returnArray;
		</cfscript>
	</cffunction>

	<cffunction name="DecimalToScientific" access="public" returntype="String" hint="
				Convert a decimal number into scientific notation
				">
		<cfargument name="num" type="numeric" required="true">

		<cfscript>
			CorrectAnswer=num;
			CorrectExponent=Int(Log(CorrectAnswer)/Log(10));
			CorrectMantissa=CorrectAnswer/(10^CorrectExponent);
			return ((0.001*Round(1000*CorrectMantissa)) & "e" & CorrectExponent);
		</cfscript>
	</cffunction>

	<cffunction name="ScientificToDecimal" access="public" returntype="numeric" hint="
				Convert a number in scientific notation to decimal point
				">
		<cfargument name="num" type="string" required="true">

		<cfscript>
			matissa = 0.0;
			idx = FindNoCase("e",num,0);
			if (idx gt 0){
				matissa = Mid(num,0,idx);
				exponent = Mid(num,idx+1,len(num));
				correctAnswer = matissa*(10^exponent);
			}
			else correctAnswer = num;

			return correctAnswer;

		</cfscript>
	</cffunction>

	<cffunction name="perRound" access="private" returnType="String" hint="
				Convert a number to give precision value.  Pad a number if zeros if neccessary
				">
				
		<cfargument name="num" type="string" required="true">
		<cfargument name="precision" type="numeric" default="3">

		<cfset result1 = num * (10^precision)>
		<cfset result2 = Round(result1)>
		<cfset result3 = result2 / (10^precision)>

		<cfreturn zerosPad(result3, precision)>
	</cffunction>

	<cffunction name="zerosPad" access="private" returntype="String" hint="
				Pad give decimal number with zero
				">
		<cfargument name="rndVal" type="numeric" required="true">
		<cfargument name="decPlaces" type="numeric" required="true">

		<cfscript>
			valStrg = rndVal.toString(); // Convert the number to a string
    		decLoc = valStrg.indexOf("."); // Locate the decimal point

    		// check for a decimal
    		if (decLoc eq -1) {
		        decPartLen = 0; // If no decimal, then all decimal places will be padded with 0s

		        // If decPlaces is greater than zero, add a decimal point
		        if (decPlaces gt 0)
		        	valStrg += ".";
		        else valStrg += "";

    		} else {
        		decPartLen = valStrg.length - decLoc - 1; // If there is a decimal already, only the needed decimal places will be padded with 0s
    		}

     		totalPad = decPlaces - decPartLen;    // Calculate the number of decimal places that need to be padded with 0s

    		if (totalPad gt 0) {
		        // Pad the string with 0s
        		for (cntrVal = 1; cntrVal <= totalPad; cntrVal++)
            		valStrg += "0";
	        }

    		return valStrg;
		</cfscript>
	</cffunction>

	<cffunction name="MergeStructure" access="public" returntype="struct" hint="
				Merge 2 or more hashes into one
				
				Return: A hash
				">
		<cfscript>
			var base = {};
			var i = 1;

			for( i = 1; i LTE ArrayLen(arguments); i=i+1 ) {
				if( IsStruct(arguments[i]) ) {
					StructAppend(base, arguments[i], true);
				}
			}
			return base;
		</cfscript>>
	</cffunction>

	<cffunction name="generateFilename" access="public" returntype="String" hint="
				Generate a random string based on date and time
				
				Return: String
				">
	
		<cfset d = #DateFormat(now(),"mmddyy")# />
		<cfset t = #TimeFormat(now(),"hhmmss")# />
		<cfset filename = #SESSION.SessionID# & "_" & d & "_" & t />
		
		<cfreturn filename />
	</cffunction>

	<cffunction name="properCase" access="public" returntype="String" hint="
				Convert a string into proper case.
				
				Return: String
				">
		<cfargument name="str" type="String" required="true"/>
		
		<cfset t = "">
		
		<cfloop index="idx" list="#arguments.str#" delimiters=" ">
			<cfset idx = idx.toLowerCase()>

			<cfif len(t)>
				<cfset t = t & " ">
				<cfset t = t & mid(idx,1,1).toUpperCase()>
				<cfset t = t & mid(idx,2,len(idx))>
			<cfelse>
				<cfset t = t & mid(idx,1,1).toUpperCase()>
				<cfset t = t & mid(idx,2,len(idx))>
			</cfif>
		</cfloop>
		
		<cfreturn t>
	</cffunction>
	
	<cffunction name="reverseComplement" access="public" returntype="string" hint="
				Reverse compliment a DNA string
				
				Return: String
				">
		<cfargument name="dna" type="string" required="true">
		
		<cfset arguments.dna = Reverse(arguments.dna)/>
		<cfset revcom = "">
		
		<cfloop index="i" from="1" to="#len(dna)#" step="1">
			<cfswitch expression="#mid(dna,i,1)#">
				<cfcase value="A"><cfset revcom &= "T"></cfcase>
				<cfcase value="T"><cfset revcom &= "A"></cfcase>
				<cfcase value="G"><cfset revcom &= "C"></cfcase>
				<cfcase value="C"><cfset revcom &= "G"></cfcase>
			</cfswitch> 
		</cfloop>
		
		<cfreturn revcom/> 
	</cffunction>
	
	<cffunction name="SeqHeaderToStruct" access="public" returntype="Struct" hint="
				Give a sequence header convert it into a hash 
				
				e.g header:
					size=240 start=511 stop=750 strand=- frame=0 gc=0.477333 score=10.4697 model=bacteria type=lack_start caller=MetaGENE
					
				convert into a hash of
					{
						size => 240,
						start => 511,
						stop => 750,
						strand => -,
						...
						...
					}
				
				Return: A hash
				">
		<cfargument name="header" required="true" type="string" />
		
		<cfscript>
			object = structNew();
			
			arr1 = listToArray(arguments.header, " ");
			for (i=1; i<= arrayLen(arr1); i++) {
				arr2 = listToArray(arr1[i], "=");
				
				structInsert(object, ucase(arr2[1]), arr2[2]);
			}
			
			return object;
		</cfscript>
	</cffunction>
	
	<cffunction name="dereplicateList" access="public" returntype="String" hint="
				Give a comma separated list, ensure that there aren't any duplicate entries
				
				Return: A comma separated list of unique values
				">
		<cfargument name="lst" required="true" type="String" />
		
		<cfscript>
			temp_struct = structNew();
			
			for(i=1; i lte listlen(arguments.lst); i++){
				key = listGetAt(arguments.lst, i);
				if (not structKeyExists(temp_struct, key)) {
					structInsert(temp_struct, key, 1);
				}
			}
			
			return structKeyList(temp_struct);
		</cfscript>
	</cffunction>  
	
</cfcomponent>
