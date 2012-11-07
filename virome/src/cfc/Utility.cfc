<cfcomponent output="false">

	<cffunction name="getMGOLDescription" access="remote" returntype="String">
		<cfargument name="hitName" type="String" required="true" />
		
		<cfset str="" />
		
		<cftry>
			<!--- get metagenoems data --->
			<cfquery name="mgoldesc" datasource="#request.mainDSN#">
				SELECT	ls.seq_type,
						ls.lib_type,
						ls.na_type,
						ls.phys_subst,
						ls.org_substr,
						ls.ecosystem,
						ls.geog_place_name,
						ls.country,
						ls.lib_shortname
				FROM	lib_summary ls
				WHERE	ls.lib_prefix = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(arguments.hitName,3)#" />
			</cfquery>
			
			<cfset dwel = "N/A"/>
			<cfif mgoldesc.recordcount>				
				<cfif len(mgoldesc.org_substr)>
					<cfset dwel = 'dwelling ' & mgoldesc.org_substr>
				<cfelse>
					<cfset dwel = mgoldesc.phys_subst>
				</cfif>
				
				<cfset str = "#mgoldesc.lib_type# metagenome from #mgoldesc.ecosystem# #dwel#"&
						 " near #mgoldesc.geog_place_name#, #mgoldesc.country# [library: #mgoldesc.lib_shortname#]"/>	
			</cfif>
			
			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror("UTILITY.CFC - GETMGOLDESCRIPTION #arguments.hitName#", 
									cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn str>
	</cffunction>
	
	<cffunction name="getServerName" access="public" returntype="Struct">

		<cfargument name="environment" type="string" default="-1" required="false">
		<cfargument name="sequence_name" type="string" default="" required="false">
		<cfargument name="mgol_hit" type="boolean" default="false">
		
		<cfset obj=StructNew()>
		<cfset obj['server'] = "">
		<cfset obj['environment'] = "">
		<cfset obj['library'] = 0>
		
		<cftry>
			<cfquery name="q" datasource="#request.mainDSN#">
				SELECT 	server, environment, id
				FROM	library
				WHERE	deleted = 0
					<cfif len(arguments.environment) && (arguments.environment neq "-1")>
						and	environment = <cfqueryparam cfsqltype="cf_sql_varchar" null="false" value="#arguments.environment#">
					<cfelseif len(arguments.sequence_name)>
						and prefix = <cfqueryparam cfsqltype="cf_sql_varchar" null="false" value="#left(arguments.sequence_name,3)#"/>
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
				<cfset reporterror("UTILITY.CFC - GETSERVERNAME",cfcatch.Message, cfcatch.Detail, cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
		
		<cfreturn obj>
	</cffunction>
	
	<cffunction name="getLibraryList" access="public" returntype="String">

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

	<cffunction name="reporterror" access="public" returntype="Any">

		<cfargument name="funcName" default="" type="String" required="true">
		<cfargument name="msg" default="" type="String" required="true">
		<cfargument name="detail" default="" type="String" required="true">
		<cfargument name="tagcontent" type="Array" required="true">

		
		<cfloop array="#tagcontent#" index="idx">
			<cflog type="error" file="virome" text="#idx.TEMPLATE#: #idx.RAW_TRACE#"/>
		</cfloop>

		<cfmail to="#request.reportErrorTo#" type="html"
				from="#request.reportFrom#"
				subject="ERROR IN VIROME APPLICATION">

			This is an automatic email generated from VIROME.<br/>
			-------------------------------------------------------<br/><br/>

			There has been an error in VIROME (#CGI.HTTP_HOST#) application in <br/>

			#funcName#<br/><br/>

			ERROR MESSAGE:<br/>
			#msg#<br/><br/>

			ERROR DETAILS:<br/>
			#detail#<br/><br/>
			
			TAGCONTENT:<br/>
			<cfloop array="#tagcontent#" index="idx">
			#idx.TEMPLATE#: #idx.RAW_TRACE#<br/>
			</cfloop>
			
			<br/><br/>
			<cfif isDefined('cookie.VIROMEDEBUGCOOKIE')>
				USER LOGGED IN: #cookie.VIROMEDEBUGCOOKIE#<br/>
				CURRENT TIME: #now()#
			</cfif>
			<br/><br/><br/>VIROME APP
		</cfmail>
		
	</cffunction>
	
	<cffunction name="reportFlexError" access="remote" returntype="void">
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
	
	<cffunction name="reportServerError" access="public" returntype="void">
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
	
	<cffunction name="reportLibrarySubmission" access="public" returntype="void" >
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

	<cffunction name="PrintLog" access="public" returntype="void">

		<cfargument name="str" type="string" default="">

		<cflog type="information" file="virome" text="#str#">

	</cffunction>

	<cffunction name="QueryToStructure" access="public" returntype="Struct">

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

     <cffunction name="QueryToStruct" access="public" returntype="any" output="false"
	     hint="Converts an entire query or the given record to a struct. This might return a structure (single record) or an array of structures.">

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

	<cffunction name="getMedianEvalue" access="public" returntype="Numeric">
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

	<cffunction name="ECToHexColor" access="public" returntype="String">
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

	<cffunction name="sortArrayOfStruct" access="private" returntype="array">

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

	<cffunction name="DecimalToScientific" access="public" returntype="String">
		<cfargument name="num" type="numeric" required="true">

		<cfscript>
			CorrectAnswer=num;
			CorrectExponent=Int(Log(CorrectAnswer)/Log(10));
			CorrectMantissa=CorrectAnswer/(10^CorrectExponent);
			return ((0.001*Round(1000*CorrectMantissa)) & "e" & CorrectExponent);
		</cfscript>
	</cffunction>

	<cffunction name="ScientificToDecimal" access="public" returntype="numeric">
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

	<cffunction name="perRound" access="private" returnType="String">
		<cfargument name="num" type="string" required="true">
		<cfargument name="precision" type="numeric" default="3">

		<cfset result1 = num * (10^precision)>
		<cfset result2 = Round(result1)>
		<cfset result3 = result2 / (10^precision)>

		<cfreturn zerosPad(result3, precision)>
	</cffunction>

	<cffunction name="zerosPad" access="private" returntype="String">
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

	<cffunction name="MergeStructure" access="public" returntype="struct">
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

	<cffunction name="generateFilename" access="public" returntype="String">
	
		<cfset d = #DateFormat(now(),"mmddyy")# />
		<cfset t = #TimeFormat(now(),"hhmmss")# />
		<cfset filename = #SESSION.SessionID# & "_" & d & "_" & t />
		
		<cfreturn filename />
	</cffunction>

	<cffunction name="properCase" access="public" returntype="String">
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
	
	<cffunction name="reverseComplement" access="public" returntype="string">
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
	
	<cffunction name="SeqHeaderToStruct" access="public" returntype="Struct">
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
	
	<cffunction name="dereplicateList" access="public" returntype="String">
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