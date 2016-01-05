<cfcomponent output="false" displayname="User" hint="
			This componented allows user management.  It is used to register new user,
			identifing user groups, retrieve password, and keep track of user logins
			">

	<cffunction name="GetUser" access="remote" returntype="Struct" hint="
				Get all user information

				This function is called directly from Flex to populate user cookie
				as well as acts as helper function for:
					InsertUser() and
					UpdateUser()

				Return: A hash
				">

		<cfargument name="obj" type="Struct" required="true" />

		<cfset userStruct = structnew()>
		<!--- this is only set in InsertUser when a new user is registerd. --->
		<cfset userStruct["TYPE"] = iif(isDefined('arguments.obj.TYPE'), """register""", """login""") />
		<cfset userStruct["MSG"] = "failed"/>
		<cfset userStruct["LIBRARYID"] = ''/>

		<cfset local.key = "krypton"/>

		<cftry>
			<cfquery name="q" datasource="#request.mainDSN#">
				SELECT	userId,
						groupId,
						username,
						password,
						institute,
						email,
						firstname,
						lastname,
						annotation,
						viewdetail,
						god,
						upload,
						download,
						noOfLogins
				FROM	user
				WHERE 	deleted = 0
					<cfif isDefined("arguments.obj.USERNAME") and len(arguments.obj.USERNAME)>
						and username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.USERNAME#" null="false">
					</cfif>
					<cfif isDefined("arguments.obj.PASSWORD") and len(arguments.obj.PASSWORD)>
						and password = <cfqueryparam cfsqltype="cf_sql_varchar" value="#encrypt(arguments.obj.PASSWORD,local.key,"CFMX_COMPAT")#" null="false">
					</cfif>
					<cfif isDefined("arguments.obj.INSTITUTE") and len(arguments.obj.INSTITUTE)>
						and institute = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.INSTITUTE#" null="false">
					</cfif>
					<cfif isDefined("arguments.obj.EMAIL") and len(arguments.obj.EMAIL)>
						and email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.EMAIL#" null="false">
					</cfif>
					<cfif isDefined("arguments.obj.FIRSTNAME") and len(arguments.obj.FIRSTNAME)>
						and firstname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.FIRSTNAME#" null="false">
					</cfif>
					<cfif isDefined("arguments.obj.LASTNAME") and len(arguments.obj.LASTNAME)>
						and lastname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.LASTNAME#" null="false">
					</cfif>
					<cfif isDefined("arguments.obj.ANNOTATION") and (arguments.obj.ANNOTATION gt -1)>
						and annotation = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.ANNOTATION#" null="false">
					</cfif>
					<cfif isDefined("arguments.obj.VIEWDETAIL") and (arguments.obj.VIEWDETAIL gt -1)>
						and viewdetail = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.VIEWDETAIL#" null="false">
					</cfif>
					<cfif isDefined("arguments.obj.USERID") and (arguments.obj.USERID gt -1)>
						and userId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.USERID#" null="false">
					</cfif>
					<cfif isDefined("arguments.obj.DOWNLOAD") and (arguments.obj.DOWNLOAD gt -1)>
						and download = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.DOWNLOAD#" null="false">
					</cfif>
				ORDER BY lastname, firstname, email, username, viewdetail, annotation
			</cfquery>

			<!--- set user cookie for error reports --->
			<cfif isdefined("cookie.VIROMEDEBUGCOOKIE") and isDefined("arguments.obj.USERNAME") and len(arguments.obj.USERNAME)>
				<cfcookie name="VIROMEDEBUGCOOKIE" expires="NOW"/>
				<cfcookie name="VIROMEDEBUGCOOKIE" expires="1" value="#arguments.obj.USERNAME#;#now()#"/>
			</cfif>


			<!--- get all groups this user belongs to --->
			<cfif q.recordcount gt 0>
				<!--- return a struct --->
				<cfset userStruct["MSG"] = "success"/>
				<cfset structappend(userStruct, CreateObject("component", request.cfc & ".Utility").QueryToStruct(q, 1))>

				<cfquery name="g" datasource="#request.mainDSN#">
					SELECT	id,userList
					FROM	groups
					WHERE 	deleted=0
				</cfquery>

				<cfloop query="g">
					<cfif listFindNoCase(g.userList,q.userId,',') and (not listFindNoCase(userStruct["GROUPID"],g.id,','))>
						<cfset userStruct["GROUPID"] &= ',#g.id#'/>
					</cfif>
				</cfloop>

				<!--- check if there are any private librarys for this user --->
				<cfquery name="l" datasource="#request.mainDSN#">
					SELECT	id
					FROM	library
					WHERE	deleted=0
						and publish=0
						and groupId in (#userStruct["GROUPID"]#)
				</cfquery>

				<!--- create list of all private libraries user have access to --->
				<cfset userStruct["LIBRARYID"] = valuelist(l.id,",")/>

				<!--- update number of logins --->
				<cfset updateLogin(q.userId, (q.noOfLogins+1)) />
			</cfif>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="User",
																		function_name=getFunctionCalledName(),
																		args=arguments,
																		msg=cfcatch.Message,
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn userStruct/>
			</cffinally>
		</cftry>
	</cffunction>


	<cffunction name="InsertUser" access="remote" returntype="Struct" hint="
				Add new user and group information

				This function is called directly from Flex to register new user.

				Return: A hash
				">
		<cfargument name="obj" type="Struct" required="true" />

		<cftry>
			<cfset userStruct = structnew()>
			<cfset local.key = "krypton"/>

			<cfquery name="checkUser" datasource="#request.mainDSN#">
				SELECT 	userId
				FROM	user
				WHERE	username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.USERNAME#" null="false">
			</cfquery>

			<cfif checkUser.recordcount eq 0>
				<cftransaction>
					<cfquery name="adduser" datasource="#request.mainDSN#" result="newUser">
						INSERT INTO user(username,
										password,
										institute,
										email,
										firstname,
										lastname,
										annotation,
										viewdetail,
										download,
										groupId)
								VALUE (
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.USERNAME#" null="false">,
								  	<cfqueryparam cfsqltype="cf_sql_varchar" value="#encrypt(arguments.obj.PASSWORD, local.key, "CFMX_COMPAT")#" null="false">,
								  	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.INSTITUTE#" null="false">,
								  	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.EMAIL#" null="false">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.FIRSTNAME#" null="false">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.LASTNAME#" null="false">,
									<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.ANNOTATION#" null="false">,
									<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.VIEWDETAIL#" null="false">,
									<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.DOWNLOAD#" null="false">,
									-1
									)
					</cfquery>

					<!--- insert a new group first --->
					<cfquery name="grpadd" datasource="#request.mainDSN#" result="newGrp">
						INSERT INTO groups(name,userList,dateCreated)
							   VALUE(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.USERNAME#" null="false">,
									 #newUser.GENERATED_KEY#,
									 #CreateODBCDateTime(now())#
									 )
					</cfquery>

					<cfquery name="updUserGrp" datasource="#request.mainDSN#">
						UPDATE user SET groupId=#newGrp.GENERATED_KEY# WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.USERNAME#" null="false">
					</cfquery>
				</cftransaction>

				<cfset arguments.obj.TYPE="register"/>
				<cfset userStruct = GetUser(obj=arguments.obj)>
			</cfif>

			<cfcatch type="any">
				<cfset flag = false>
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="User",
																		function_name=getFunctionCalledName(),
																		args=arguments,
																		msg=cfcatch.Message,
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn userStruct>
			</cffinally>
		</cftry>
	</cffunction>


	<cffunction name="UpdateUser" access="remote" returntype="Struct" hint="
				Edit user information

				NOT IN USE

				Return: A hash
				">
		<cfargument name="obj" type="Struct" required="true" />

		<cftry>
			<cfset userStruct = structnew()>
			<cfset local.key = "krypton"/>

			<cfquery name="u" datasource="#request.mainDSN#">
				UPDATE user set
						dateModified = #CreateODBCDateTime(now())#
						<cfif isDefined("arguments.obj.USERNAME") and len(arguments.obj.USERNAME)>
							,username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.USERNAME#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.PASSWORD") and len(arguments.obj.PASSWORD)>
							,password = <cfqueryparam cfsqltype="cf_sql_varchar" value="#encrypt(arguments.obj.PASSWORD,local.key,"CFMX_COMPAT")#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.INSTITUTE") and len(arguments.obj.INSTITUTE)>
							,institute = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.INSTITUTE#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.EMAIL") and len(arguments.obj.EMAIL)>
							,email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.EMAIL#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.FIRSTNAME") and len(arguments.obj.FIRSTNAME)>
							,firstname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.FIRSTNAME#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.LASTNAME") and len(arguments.obj.LASTNAME)>
							,lastname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.LASTNAME#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.ANNOTATION") and arguments.obj.ANNOTATION gt -1>
							,annotation = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.ANNOTATION#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.VIEWDETAIL") and arguments.obj.VIEWDETAIL gt -1>
							,viewdetail = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.VIEWDETAIL#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.DELETED") and arguments.obj.DELETED gt -1>
							,deleted = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.DELETED#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.DOWNLOAD") and arguments.obj.DOWNLOAD gt -1>
							,download = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.DOWNLOAD#" null="false">
						</cfif>
						<cfif isDefined("arguments.obj.NOOFLOGINS") and arguments.obj.NOOFLOGINS gt -1>
							,noOfLogins = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.NOOFLOGINS#" null="false">
						</cfif>
				WHERE	userId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.obj.USERID#" null="false">
			</cfquery>

			<cfset userStruct = GetUser(obj=arguments.obj)>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="User",
																		function_name=getFunctionCalledName(),
																		args=arguments,
																		msg=cfcatch.Message,
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn userStruct>
			</cffinally>
		</cftry>
	</cffunction>


	<cffunction name="updateLogin" access="remote" returntype="void" hint="
				Update number of times user logins and time of last login
				as a way to track VIROME usage.

				Return: NA
				">
		<cfargument name="userId" type="Numeric" required="true">
		<cfargument name="num" type="numeric" required="true">

		<cftry>
			<cfquery name="q" datasource="#request.mainDSN#">
				UPDATE 	user
				SET		noOfLogins = <cfqueryparam cfsqltype="cf_sql_integer" value="#num#" null="false">,
						lastLogin = #CreateODBCDateTime(now())#
				WHERE 	userId = <cfqueryparam cfsqltype="cf_sql_integer" value="#userId#" null="false">
			</cfquery>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="User",
																		function_name=getFunctionCalledName(),
																		args=arguments,
																		msg=cfcatch.Message,
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="RetrievePassword" access="remote" returntype="boolean" hint="
				In case user forgets their password, send password information to
				the email address on file.

				Return: A hash
				">
		<cfargument name="obj" type="Struct" required="true" />

		<cftry>
			<cfset userStruct = structnew()>
			<cfset local.key = "krypton"/>

			<cfquery name="q" datasource="#request.mainDSN#">
				SELECT 	username, firstname, lastname, password, email
				FROM	user
				WHERE	username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.USERNAME#" null="false">
					and firstname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.FIRSTNAME#" null="false">
					and lastname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.LASTNAME#" null="false">
					and email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.obj.EMAIL#" null="false">
					and deleted = 0
			</cfquery>

			<cfif q.RecordCount>
				<cfset pass = #decrypt(q.password,local.key,"CFMX_COMPAT")#/>

				<cfmail to="#q.email#" type="html"
					from="bjaysheel@gmail.com"
						subject="Password retrieval from VIROME Application">

					This is an automatic email generated from VIROME.<br/>
					-------------------------------------------------------<br/><br/>

					Please find attached user information we have file.<br/><br/>

					Username: #q.username#<br/>
					Password: #pass#<br/><br/>

					As always please do not share your password with anyone else.
					<br/><br/>VIROME APP
				</cfmail>

				<cfreturn true/>
			</cfif>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="User",
																		function_name=getFunctionCalledName(),
																		args=arguments,
																		msg=cfcatch.Message,
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn false/>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="DecryptPassword" access="remote" returntype="boolean" hint="
				In case user forgets their password, send password information to
				the email address on file.

				Return: A hash
				">

		<cftry>
			<cfset userStruct = structnew()>
			<cfset local.key = "krypton"/>

			<cfquery name="getQ" datasource="#request.mainDSN#">
				SELECT 	userID, username, firstname, lastname, password, email
				FROM	user
				WHERE   1
				order by userID
			</cfquery>

			<cfloop query="getQ">
				<cfif len(getQ.password)>
					<cfoutput>#getQ.password#----</cfoutput>
					<cfset pass = #decrypt(getQ.password,local.key,"CFMX_COMPAT")#/>

					<cfoutput>#pass#---->#getQ.userID#<br/></cfoutput>

					<cfquery name="a" datasource="#request.mainDSN#">
						UPDATE app_info.user
						SET	npassword = <cfqueryparam cfsqltype="cf_sql_varchar" value="#pass#" null="false">
						WHERE	userID = #getQ.userID#
					</cfquery>
				</cfif>
			</cfloop>

			<cfcatch type="any">
				<cfset CreateObject("component",  request.cfc & ".Utility").reporterror(method_name="User",
																		function_name=getFunctionCalledName(),
																		args=arguments,
																		msg=cfcatch.Message,
																		detail=cfcatch.Detail,
																		tagcontent=cfcatch.tagcontext)>
			</cfcatch>

			<cffinally>
				<cfreturn false/>
			</cffinally>
		</cftry>
	</cffunction>

</cfcomponent>
