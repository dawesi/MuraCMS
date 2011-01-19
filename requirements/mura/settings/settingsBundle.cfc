<!--- This file is part of Mura CMS.

Mura CMS is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, Version 2 of the License.

Mura CMS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. �See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Mura CMS. �If not, see <http://www.gnu.org/licenses/>.

Linking Mura CMS statically or dynamically with other modules constitutes
the preparation of a derivative work based on Mura CMS. Thus, the terms and 	
conditions of the GNU General Public License version 2 (�GPL�) cover the entire combined work.

However, as a special exception, the copyright holders of Mura CMS grant you permission
to combine Mura CMS with programs or libraries that are released under the GNU Lesser General Public License version 2.1.

In addition, as a special exception, �the copyright holders of Mura CMS grant you permission
to combine Mura CMS �with independent software modules that communicate with Mura CMS solely
through modules packaged as Mura CMS plugins and deployed through the Mura CMS plugin installation API,
provided that these modules (a) may only modify the �/trunk/www/plugins/ directory through the Mura CMS
plugin installation API, (b) must not alter any default objects in the Mura CMS database
and (c) must not alter any files in the following directories except in cases where the code contains
a separately distributed license.

/trunk/www/admin/
/trunk/www/tasks/
/trunk/www/config/
/trunk/www/requirements/mura/

You may copy and distribute such a combined work under the terms of GPL for Mura CMS, provided that you include
the source code of that other code when and as the GNU GPL requires distribution of source code.

For clarity, if you create a modified version of Mura CMS, you are not obligated to grant this special exception
for your modified version; it is your choice whether to do so, or to make such modified version available under
the GNU General Public License version 2 �without this exception. �You may, if you choose, apply this exception
to your own modified versions of Mura CMS.
--->
<cfcomponent extends="mura.cfobject" output="false">

	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="configBean" type="any" required="yes"/>

		<cfset variables.configBean	= arguments.configBean />
		<cfset variables.dsn		= variables.configBean.getDatasource() />

		<cfset variables.data		= StructNew() />
		<cfset variables.Bundle	= "" />
		<cfset variables.zipTool	= createObject("component","mura.Zip") />
		<cfset variables.fileWriter	= application.serviceFactory.getBean("fileWriter")>
		<cfset variables.utility	= application.utility.getBean("utility")>
		<cfset variables.fileDelim	= application.configBean.getFileDelim()>
		<cfset variables.dirName	= "Bundle_#createUUID()#" />
		<cfset variables.BundleDir	= variables.dirName />
		<cfset variables.workDir	= "#expandPath('/muraWRM/admin/')#temp#variables.fileDelim#">
		<cfset variables.procDir	= "#workdir#proc#variables.fileDelim#" />
		<cfset variables.unpackPath	= "#procDir##BundleDir##variables.fileDelim#" />
		<cfset variables.backupDir	= "#variables.procDir##variables.dirName##variables.fileDelim#" />
		<cfset variables.unpackPath	= "#variables.procDir##variables.BundleDir##variables.fileDelim#" />
		
		<cfif not directoryExists(variables.workDir)>
			<cfset variables.fileWriter.createDir(directory="#variables.workDir#")>
		</cfif>
		<cfif not directoryExists(variables.procDir)>
			<cfset variables.fileWriter.createDir(directory="#variables.procDir#")>
		</cfif>
		
		<cfreturn this />
	</cffunction>

	<cffunction name="restore" returntype="boolean">
		<cfargument name="BundleFile" type="string" required="yes"/>
		<cfset var rsStruct			= StructNew() />
		<cfset var importValue	= "" />
		<cfset var fname			= "" />
		<cfset var sArgs			= StructNew() />

		<cfset variables.Bundle	= variables.unpackPath />
 

		<cfif fileExists( arguments.BundleFile )>
			<cfif getBean("settingsManager").isBundle(arguments.BundleFile)>
				<cfset variables.zipTool.Extract(zipFilePath="#arguments.BundleFile#",extractPath=variables.unpackPath, overwriteFiles=true)>
			<cfelse>
				<cffile action="delete" file="#arguments.BundleFile#">
				<cfthrow message="The submitted Bundle is not valid.">
			</cfif>
		<cfelse>
			<cfoutput>NOT FOUND!!!: #arguments.BundleFile#</cfoutput><cfabort>
			<cfreturn false />
		</cfif>

		<cfdirectory action="list" directory="#variables.unpackPath#" name="rsImportFiles" filter="*.xml" type="file">

		<cfloop query="rsImportFiles">
			<cfset fname = rereplace(name,"^wddx_(.*)\.xml","\1") />
			<cffile action="read" file="#variables.unpackPath##name#" variable="importWDDX" charset="utf-8">
			<cfset importWDDX=REReplace(importWDDX,'[\xc]','','ALL')>
			<cftry>
				<cfwddx action="wddx2cfml" input=#importWDDX# output="importValue">
			<cfcatch>
				<cfdump var="An error happened while trying to deserialize #name#.">
				<cfdump var="#cfcatch#">
				<cfabort>
			</cfcatch>
			</cftry>
			<cfset variables.data[fname] = importValue />
		</cfloop>

		<cfreturn true />
	</cffunction>

	<cffunction name="renameFiles" returntype="void">
		<cfargument name="siteID" type="string" default="" required="true">
		<cfargument name="keyFactory" type="any" required="true">
		<cfargument name="dsn" type="string" default="#variables.configBean.getDatasource()#" required="true">

		<cfset var filePath = variables.configBean.getValue('filedir') & variables.fileDelim & arguments.siteID & variables.fileDelim & "cache#variables.fileDelim#file#variables.fileDelim#" />
		<cfset var toName	= "" />
		<cfset var keys		= arguments.keyFactory />
		<cfset var nFileID	= "" />
		<cfset var rsNameFiles	= "" />
		<cfset var rstFiles = getValue("rstFiles") />

		<cfif not rstFiles.recordCount>
			<cfreturn>
		</cfif>

		<cfloop query="rstfiles">
			<cfset nFileID = rstfiles.fileID />
			<cfdirectory name="rsNameFiles" directory="#filePath#" filter="#nFileID#*.*">
			<cfloop query="rsNameFiles">
				<cfset toName = replace(name,nFileID,keys.get(nFileID))>
				<cfset variables.fileWriter.renameFile(source="#filePath##variables.fileDelim##name#", destination="#filePath##variables.fileDelim##toName#")>
			</cfloop>
		</cfloop>
	</cffunction>

	<cffunction name="bundleFiles" returntype="void">
		<cfargument name="siteID" type="string" default="" required="true">
		<cfargument name="dsn" type="string" default="#variables.configBean.getDatasource()#" required="true">
		<cfargument name="includeVersionHistory" type="boolean" default="true" required="true">
		<cfargument name="includeTrash" type="boolean" default="true" required="true">
		<cfargument name="moduleID" type="string" default="" required="true">
		<cfargument name="sinceDate" type="any" default="">
		<cfargument name="includeUsers" type="boolean" default="false" required="true">
		
		<cfset var siteRoot = variables.configBean.getValue('webroot') & variables.fileDelim & arguments.siteID /> 
		<cfset var zipDir	= "" />
		<cfset var rstplugins = "" />
		<cfset var rsInActivefiles = "" />
		<cfset var deleteList =	"" />
		<cfset var moduleIDSQLlist="" />
		<cfset var i="" />
		
		<cfif isDate(arguments.sinceDate)>
			<cfset arguments.includeTrash=true>
		</cfif>
		
		<cfloop list="#arguments.moduleID#" index="i">
			<cfset moduleIDSQLlist=listAppend(moduleIDlist,"'#i#'")>
		</cfloop>
	
		<cfif len(arguments.siteID)>
			<cfset variables.zipTool.AddFiles(zipFilePath="#variables.backupDir#sitefiles.zip",directory=siteRoot,recurse="true",sinceDate=arguments.sinceDate)>
	
			<!--- We do not want to include files collected from mura forms or the advertising manager --->
			<cfquery name="rsInActivefiles" datasource="#arguments.dsn#">
				select fileID,fileExt from tfiles  
				where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
				and (
					
					moduleid in ('00000000000000000000000000000000000'<cfif len(moduleIDSQLlist)>,#moduleIDSQLlist#</cfif><cfif arguments.includeUsers>,'00000000000000000000000000000000008'</cfif>)
							
					<cfif not arguments.includeVersionHistory>
						or 
						(fileID not in
							(
								select fileID from tcontent where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
								and fileID is not null
								and (active = 1 or (changesetID is not null and approved=0))
							)
							
						and fileID not in
							(
								select attributeValue from tclassextenddata
								inner join tclassextendattributes on (tclassextenddata.attributeID=tclassextendattributes.attributeID)
								inner join tcontent on (tclassextenddata.baseID=tcontent.contenthistID)
								where tcontent.siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
								and lower(tclassextendattributes.type)='File'
								and tclassextenddata.stringvalue !=''
								and (tcontent.active = 1 or (tcontent.changesetID is not null and tcontent.approved=0))
							)
						)
					</cfif>
							
					<cfif not arguments.includeTrash>
						or deleted=1
					</cfif>
				)	
				
				<cfif isDate(arguments.sinceDate)>
					and created >= #createODBCDateTime(arguments.sinceDate)#
				</cfif>
			</cfquery>
				
			<cfif variables.configBean.getValue('assetdir') neq variables.configBean.getValue('webroot')>
				<cfset zipDir = variables.configBean.getValue('assetdir') & variables.fileDelim & arguments.siteID />
				<cffile action="write" file="#zipDir##variables.fileDelim#blank.txt" output="empty file" />  
				<cfset variables.zipTool.AddFiles(zipFilePath="#variables.backupDir#assetfiles.zip",directory=#zipDir#,recurse="true",sinceDate=arguments.sinceDate,excludeDirs="cache")>
			</cfif> 
			<cfif variables.configBean.getValue('filedir') neq variables.configBean.getValue('webroot')>
				<cfset zipDir = variables.configBean.getValue('filedir') & variables.fileDelim & arguments.siteID /> 
				<cffile action="write" file="#zipDir##variables.fileDelim#blank.txt" output="empty file" />  
				<cfset variables.zipTool.AddFiles(zipFilePath="#variables.backupDir#filefiles.zip",directory=#zipDir#,recurse="true",sinceDate=arguments.sinceDate,excludeDirs="assets")>
				
					<cfif variables.configBean.getValue('filedir') eq variables.configBean.getValue('webroot')>
						<cfloop query="rsInActivefiles">
							<cfif fileExists("#variables.configBean.getValue('filedir')##variables.fileDelim#cache#variables.fileDelim#file#variables.fileDelim##rsInActivefiles.fileid#.#rsInActivefiles.fileEXT#")>
								<cfset deleteList=listAppend(deleteList,"cache#variables.fileDelim#file#variables.fileDelim##rsInActivefiles.fileid#.#rsInActivefiles.fileEXT#","|")>
								<cfif listFindNoCase("gif,jpg,jpeg,png",rsInActivefiles.fileEXT)>
									<cfset deleteList=listAppend(deleteList,"cache#variables.fileDelim#file#variables.fileDelim##rsInActivefiles.fileid#_small.#rsInActivefiles.fileEXT#","|")>
									<cfset deleteList=listAppend(deleteList,"cache#variables.fileDelim#file#variables.fileDelim##rsInActivefiles.fileid#_medium.#rsInActivefiles.fileEXT#","|")>
								</cfif>
							</cfif>
						</cfloop>
						
						<cfif len(deleteList)>
							<cfset variables.zipTool.deleteFiles(zipFilePath="#variables.backupDir#filefiles.zip",files="#deleteList#")>
						</cfif>
					</cfif>
				
			<cfelse>
				<cfloop query="rsInActivefiles">
					<cfif fileExists("#variables.configBean.getValue('filedir')##variables.fileDelim#cache#variables.fileDelim#file#variables.fileDelim##rsInActivefiles.fileid#.#rsInActivefiles.fileEXT#")>
						<cfset deleteList=listAppend(deleteList,"cache#variables.fileDelim#file#variables.fileDelim##rsInActivefiles.fileid#.#rsInActivefiles.fileEXT#","|")>
						<cfif listFindNoCase("gif,jpg,jpeg,png",rsInActivefiles.fileEXT)>
							<cfset deleteList=listAppend(deleteList,"cache#variables.fileDelim#file#variables.fileDelim##rsInActivefiles.fileid#_small.#rsInActivefiles.fileEXT#","|")>
							<cfset deleteList=listAppend(deleteList,"cache#variables.fileDelim#file#variables.fileDelim##rsInActivefiles.fileid#_medium.#rsInActivefiles.fileEXT#","|")>
						</cfif>
					</cfif>
				</cfloop>
				
				<cfif len(deleteList)>
					<cfset variables.zipTool.deleteFiles(zipFilePath="#variables.backupDir#sitefiles.zip",files="#deleteList#")>
				</cfif>
			</cfif>
		</cfif>
		
		<!--- Plugins --->
		<cfquery datasource="#arguments.dsn#" name="rstplugins">
			select * from tplugins where 
			1=1	
			<cfif len(arguments.siteID)>
				and moduleID in ( select moduleID from tcontent where siteid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteid#"/> and type='Plugin')
			</cfif>		
			<cfif len(arguments.moduleID)>
				and moduleID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.moduleID#" list="true">)
			<cfelse>
				and 0=1
			</cfif>
		</cfquery>
		
		<cfif rstplugins.recordcount>
			<cfif not directoryExists("#variables.backupDir#plugins/")>
				<cfdirectory action="create" directory="#variables.backupDir#plugins/">
				<cffile action="write" file="#variables.backupDir#plugins#variables.fileDelim#blank.txt" output="empty file" /> 
			</cfif>
			<cfloop query="rstplugins">
				<cfset variables.utility.copyDir( expandPath("/plugins/#rstplugins.directory#"),"#variables.backupDir#plugins/#rstplugins.directory#" )>
			</cfloop>
			<cfset variables.zipTool.AddFiles(zipFilePath="#variables.backupDir#pluginfiles.zip",directory="#variables.backupDir#plugins/",recurse="true")>
		</cfif>
		<!--- end plugins --->
		
	</cffunction>

	<cffunction name="unpackFiles" returntype="string">
		<cfargument name="siteID" type="string" default="" required="true">
		<cfargument name="keyFactory" type="any" required="true">
		<cfargument name="dsn" type="string" default="#variables.configBean.getDatasource()#" required="true">
		<cfargument name="moduleID" type="string" default="" required="true">
		<cfargument name="errors" type="any" required="true" default="#structNew()#">
		<cfargument name="renderingMode" type="any" required="true" default="all">
		<cfargument name="contentMode" type="any" required="true" default="all">
		<cfargument name="pluginMode" type="any" required="true" default="all">
		<cfargument name="sinceDate" type="any" required="true" default="">
		<cfargument name="keyMode" type="string" default="copy" required="true">
		
		<cfset var zipPath = "" />
		<cfset var siteRoot = variables.configBean.getValue('webroot') & variables.fileDelim & arguments.siteID /> 
		<cfset var tmpDir = "" />
		<cfset var destDir = "" />
		<cfset var qCheck = "" />
		<cfset var isFileEmpty = false />
		<cfset var rstplugins="">
		<cfset var pluginConfig="">
		<cfset var pluginCFC="">
		<cfset var theme="">
		
		<cfif not len( getBundle() ) or not directoryExists( getBundle() )>
			<cfreturn>
		</cfif>
		
		<cfif len(arguments.siteID)>
			<cfif arguments.contentMode eq "all">
				
				<cfif not isDate(arguments.sinceDate)>
					<!---
					<cfset variables.utility.deleteDir( variables.configBean.getValue('filedir') & variables.fileDelim  & arguments.siteID & variables.fileDelim & "assets"  )>
					--->
					<cfset variables.utility.deleteDir( variables.configBean.getValue('filedir') & variables.fileDelim  & arguments.siteID & variables.fileDelim & "cache"  )>
				</cfif>
				<cfif fileExists( getBundle() & "sitefiles.zip" )>
					<cfset zipPath = getBundle() & "sitefiles.zip" />
					<cfset variables.zipTool.Extract(zipFilePath="#zipPath#",extractPath=siteRoot, overwriteFiles=true, extractDirs="cache|assets")>
				</cfif>
				<cfif fileExists( getBundle() & "assetfiles.zip" )>
					<cfset zipPath = getBundle() & "assetfiles.zip" />
					<cfset destDir = variables.configBean.getValue('assetdir') & variables.fileDelim & arguments.siteID & variables.fileDelim & "assets" & variables.fileDelim />
					<cfset variables.zipTool.Extract(zipFilePath="#zipPath#",extractPath=destDir, overwriteFiles=true)>
				</cfif>
				<cfif fileExists( getBundle() & "filefiles.zip" )>
					<cfset zipPath = getBundle() & "filefiles.zip" />
					<cfset destDir = variables.configBean.getValue('filedir') & variables.fileDelim & arguments.siteID />
					<cfset variables.zipTool.Extract(zipFilePath="#zipPath#",extractPath=destDir, overwriteFiles=true)>
				</cfif>
			</cfif>
			<cfif arguments.renderingMode eq "all">
				<cfset zipPath = getBundle() & "sitefiles.zip" />
				<cfset variables.zipTool.Extract(zipFilePath="#zipPath#",extractPath=siteRoot, overwriteFiles=true, excludeDirs="cache|assets")>
			<cfelseif arguments.renderingMode eq "theme">
				<cfset zipPath = getBundle() & "sitefiles.zip" />
				<cfset theme=application.settingsManager.getSite(siteID).getTheme()>>
				<cfset variables.zipTool.Extract(zipFilePath="#zipPath#",extractPath=siteRoot, overwriteFiles=true, extractDirs="includes#variables.fileDelim#themes#variables.fileDelim##theme#")>
			</cfif>
		</cfif>
		
		<cfif arguments.pluginMode eq "all" and fileExists( getBundle() & "pluginfiles.zip" )>
			<cfset rstplugins=getValue("rstplugins")>
			<cfif len(arguments.moduleID)>
				<cfquery name="rstplugins" dbtype="query">
					select * from rstplugins 
					where moduleID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.moduleID#" list="true">)
				</cfquery>
			</cfif>
			
			<cfif not directoryExists(getBundle() & "plugins")>
				<cfset variables.fileWriter.createDir(directory=getBundle() & "plugins")>
			</cfif>
			
			<cfset variables.zipTool.Extract(zipFilePath=getBundle() & "pluginfiles.zip",extractPath=getBundle() & "plugins", overwriteFiles=true)>
			
			<cfloop query="rstplugins">
				
				<cfif not structKeyExists(arguments.errors,rstplugins.moduleID)>
					<cfquery datasource="#arguments.dsn#" name="qCheck">
						select directory from tplugins 
						where moduleID =<cfqueryparam cfsqltype="cf_sql_varchar" value="#keyFactory.get(rstplugins.moduleID)#"/>
					</cfquery>
					
					<cfset pluginDir=variables.configBean.getPluginDir() & variables.fileDelim & qCheck.directory>
				
					<cfset variables.utility.copyDir( getBundle() & "plugins" & variables.fileDelim & rstplugins.directory, pluginDir )>
					
					<cfif fileExists("#pluginDir#/plugin/plugin.cfc")>	
						<cfset pluginConfig=getPlugin(ID=keyFactory.get(rstplugins.moduleID), siteID="", cache=false)>
						<cfset pluginCFC= createObject("component","plugins.#rstplugins.directory#.plugin.plugin") />
						
						<!--- only call the methods if they have been defined --->
						<cfif structKeyExists(pluginCFC,"init")>
							<cfset pluginCFC.init(pluginConfig)>
							<cfif structKeyExists(pluginCFC,"fromBundle")>
								<cfset pluginCFC.fromBundle(pluginConfig=pluginConfig,Bundle=this,keyFactory=arguments.keyFactory, siteID=arguments.siteID, errors=arguments.errors)>
							</cfif>
						</cfif>
					</cfif>	
				</cfif>
			</cfloop>
		</cfif>
	</cffunction>

	<cffunction name="bundle" returntype="void">
		<cfargument name="siteID" type="string" default="" required="true">
		<cfargument name="dsn" type="string" default="#variables.configBean.getDatasource()#" required="true">
		<cfargument name="includeVersionHistory" type="boolean" default="true" required="true">
		<cfargument name="includeTrash" type="boolean" default="true" required="true">
		<cfargument name="includeMetaData" type="boolean" default="true" required="true">
		<cfargument name="moduleID" type="string" default="" required="true">
		<cfargument name="bundleName" type="string" default="" required="true">
		<cfargument name="sinceDate" default="">
		<cfargument name="includeMailingListMembers" type="boolean" default="false" required="true">
		<cfargument name="includeUsers" type="boolean" default="false" required="true">
		
		<cfset var rstcontent=""/>
		<cfset var rstcontentstats=""/>
		<cfset var rstcontentObjects=""/>
		<cfset var rstcontentTags=""/>
		<cfset var rstsystemobjects=""/>
		<cfset var rsSettings=""/>
		<cfset var rstadcampaigns=""/>
		<cfset var rstadcreatives=""/>
		<cfset var rstadipwhitelist=""/>
		<cfset var rstadzones=""/>
		<cfset var rstadplacements=""/>
		<cfset var rstadplacementdetails=""/>
		<cfset var rstcontentcategoryassign=""/>
		<cfset var rstcontentfeeds=""/>
		<cfset var rstcontentfeeditems=""/>
		<cfset var rstcontentfeedadvancedparams=""/>
		<cfset var rstcontentrelated=""/>
		<cfset var rstmailinglist=""/>
		<cfset var rstmailinglistmembers="">
		<cfset var rstfiles=""/>
		<cfset var rstcontentcategories=""/>
		<cfset var rstcontentcomments=""/>
		<cfset var rstcontentratings=""/>
		<cfset var rstusersinterests=""/>
		<cfset var rstclassextend=""/>
		<cfset var rstclassextendsets=""/>
		<cfset var rstclassextendattributes=""/>
		<cfset var rstclassextenddata=""/>
		<cfset var rstclassextenddatauseractivity="">
		<cfset var rstchangesets=""/>
		<cfset var rstpluginmodules=""/>
		<cfset var rstplugins=""/>
		<cfset var rstpluginscripts=""/>
		<cfset var rstplugindisplayobjects=""/>
		<cfset var rstpluginsettings=""/>	
		<cfset var rsttrash=""/>
		<cfset var rsttrashfiles=""/>
		
		<cfset var rstusers=""/>
		<cfset var rstusersmemb=""/>	
		<cfset var rstusersinterests=""/>
		<cfset var rstuserstags=""/>
		<cfset var rstuseraddresses=""/>
		<cfset var rstusersfavorites=""/>
		<cfset var rstpermissions=""/>	
		<cfset var publicUserPoolID=application.settingsManager.getSite(arguments.siteID).getPublicUserPoolID()>
		<cfset var privateUserPoolID=application.settingsManager.getSite(arguments.siteID).getPrivateUserPoolID()>
		
		<cfset var sArgs		= StructCopy( arguments ) />
		<cfset var rsZipFile	= "" />
		<cfset var requiredSpace=variables.configBean.getValue("BundleMinSpaceRequired")>
		<cfset var rssite	= "" />
		<cfset var moduleIDSqlList="">
		<cfset var i="">
		<cfset var availableSpace=0>
		
		<cfloop list="#arguments.moduleID#" index="i">
			<cfset moduleIDSQLlist=listAppend(moduleIDlist,"'#i#'")>
		</cfloop>
		
		<cfif isDate(arguments.sinceDate)>
			<cfset arguments.includeTrash=true>
			<cfset arguments.includeUser=false>
			<cfset arguments.includeMailingListMembers=false>
		</cfif>
		
		<cfif not isNumeric(requiredSpace)>
			<cfset requiredSpace=1>
		</cfif>
		
		<cftry>
			<cfset availableSpace=variables.fileWriter.getUsableSpace(variables.backupDir) >
		<cfcatch></cfcatch>
		</cftry>
		
		<cfif availableSpace and availableSpace lt requiredSpace>
			<cfthrow message="The required disk space of #requiredSpace# gb is not available.  You currently only have #availableSpace# gb available.">
		</cfif>
		
		<cfif not directoryExists(variables.backupDir)>
			<cfdirectory action="create" directory="#variables.backupDir#">
		</cfif>

		<cfset BundleFiles( argumentCollection=sArgs ) />
	
		<cfif len(arguments.siteID)>	
			<cfquery datasource="#arguments.dsn#" name="rstcontent">
				select * from tcontent where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
				and type !='Module'
				<cfif not arguments.includeVersionHistory>
					and (active = 1 or (changesetID is not null and approved=0))
				</cfif>
				<cfif isDate(arguments.sinceDate)>
					and lastUpdate >= #createODBCDateTime(arguments.sinceDate)#
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontent",rstcontent)>
													
			<cfquery datasource="#arguments.dsn#" name="rstcontentobjects">
				select * from tcontentobjects where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif not arguments.includeVersionHistory>
				and contenthistID in 
				(
					select contenthistID from tcontent where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
					and (active = 1 or (changesetID is not null and approved=0))
				)
				</cfif>
				<cfif isDate(arguments.sinceDate)>
				and contentHistID in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valueList(rstcontent.contentHistID)#">)
				</cfif>
				
				<cfif not arguments.includeTrash>
				and contentID in (select distinct contentID from tcontent)
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontentobjects",rstcontentobjects)>
	
			<cfquery datasource="#arguments.dsn#" name="rstcontenttags">
				select * from tcontenttags where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif not arguments.includeVersionHistory>
				and contenthistID in
				(
					select contenthistID from tcontent where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
					and (active = 1 or (changesetID is not null and approved=0))
				)
				</cfif>
				<cfif isDate(arguments.sinceDate)>
				and contentHistID in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valueList(rstcontent.contentHistID)#">)
				</cfif>
				<cfif not arguments.includeTrash>
				and contentID in (select distinct contentID from tcontent)
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontenttags",rstcontenttags)>
	
			<cfquery datasource="#arguments.dsn#" name="rstsystemobjects">
				select * from tsystemobjects where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
			</cfquery>
	
			<cfset setValue("rstsystemobjects",rstsystemobjects)>
	
			<cfif arguments.includeUsers>
			<!--- BEGIN INCLUDE USERS only supported by full bundles--->
			<cfquery datasource="#arguments.dsn#" name="rstpermissions">
				select * from tpermissions where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
			</cfquery>
	
			<cfset setValue("rstpermissions",rstpermissions)>
	
			<cfquery datasource="#arguments.dsn#" name="rstusers">
				select * from tusers where 
				(
					(
						siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#privateUserPoolID#"/>
						and isPublic=0
					)
					
					or
					
					(
						siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#publicUserPoolID#"/>
						and isPublic=1
					)
				)
				<!---
				<cfif isDate(arguments.sinceDate)>
					and lastUpdate>=#createODBCDateFormat(arguments.sinceDate)#
				</cfif>
				--->
				
			</cfquery>
	
			<cfset setValue("rstusers",rstusers)>
			
			<cfif rstusers.recordcount>
				<cfquery datasource="#arguments.dsn#" name="rstusersmemb">
					select * from tusersmemb where
					userID in (
								select userID from tusers where 
								(
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#privateUserPoolID#"/>
										and isPublic=0
									)
									
									or
									
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#publicUserPoolID#"/>
										and isPublic=1
									)
								)
								<!---
								<cfif isDate(arguments.sinceDate)>
									and lastUpdate>=#createODBCDateFormat(arguments.sinceDate)#
								</cfif>
								--->
							
							)
				</cfquery>
		
				<cfset setValue("rstusersmemb",rstusersmemb)>
				
				<cfquery datasource="#arguments.dsn#" name="rstuseraddresses">
					select * from tuseraddresses where
					userID in (
								select userID from tusers where 
								(
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#privateUserPoolID#"/>
										and isPublic=0
									)
									
									or
									
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#publicUserPoolID#"/>
										and isPublic=1
									)
								)
								<!---
								<cfif isDate(arguments.sinceDate)>
									and lastUpdate>=#createODBCDateFormat(arguments.sinceDate)#
								</cfif>
								--->
							)
				</cfquery>
				
				<cfset setValue("rstuseraddresses",rstuseraddresses)>
				
				<cfquery datasource="#arguments.dsn#" name="rstusersinterests">
					select * from tusersinterests where
					userID in (
								select userID from tusers where 
								(
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#privateUserPoolID#"/>
										and isPublic=0
									)
									
									or
									
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#publicUserPoolID#"/>
										and isPublic=1
									)
								)
								
								<!---
								<cfif isDate(arguments.sinceDate)>
									and lastUpdate>=#createODBCDateFormat(arguments.sinceDate)#
								</cfif>
								--->
							
							)
				</cfquery>
				
				<cfset setValue("tusersinterests",rstusersinterests)>
				
				<cfquery datasource="#arguments.dsn#" name="rstuserstags">
					select * from tuserstags where
					userID in (
								select userID from tusers where 
								(
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#privateUserPoolID#"/>
										and isPublic=0
									)
									
									or
									
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#publicUserPoolID#"/>
										and isPublic=1
									)
								)
								
								<!---
								<cfif isDate(arguments.sinceDate)>
									and lastUpdate>=#createODBCDateFormat(arguments.sinceDate)#
								</cfif>
								--->
							
							)
				</cfquery>
				
				<cfset setValue("tuserstags",rstuserstags)>
				
				<cfquery datasource="#arguments.dsn#" name="rstusersfavorites">
					select * from tusersfavorites where
					userID in (
								select userID from tusers where 
								(
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#privateUserPoolID#"/>
										and isPublic=0
									)
									
									or
									
									(
										siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#publicUserPoolID#"/>
										and isPublic=1
									)
								)
								
								<!---
								<cfif isDate(arguments.sinceDate)>
									and lastUpdate>=#createODBCDateFormat(arguments.sinceDate)#
								</cfif>
								--->
							
							)
					and siteID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				</cfquery>
				
				<cfset setValue("rstusersfavorites",rstusersfavorites)>
				<!--- END INCLUDE USERS --->
			</cfif>
			
			</cfif>
			
			<!--- BEGIN ADVERTISING --->
			<!--- removed until further evaluation 
			<cfquery datasource="#arguments.dsn#" name="rsSettings">
				select advertiserUserPoolID from tsettings where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
			</cfquery>
	
			<cfquery datasource="#arguments.dsn#" name="rstadcampaigns">
				select * from tadcampaigns
				where userID in 
				(select userID from tusers where
				siteid = '#application.settingsManager.getSite(rsSettings.advertiserUserPoolID).getPrivateUserPoolID()#' or
				siteid = '#application.settingsManager.getSite(rsSettings.advertiserUserPoolID).getPublicUserPoolID()#')
			</cfquery>
	
			<cfset setValue("rstadcampaigns",rstadcampaigns)>
					
			<cfquery datasource="#arguments.dsn#" name="rstadcreatives">
				select * from tadcreatives
				where userID in 
				(select userID from tusers where
				siteid = '#application.settingsManager.getSite(rsSettings.advertiserUserPoolID).getPrivateUserPoolID()#' or
				siteid = '#application.settingsManager.getSite(rsSettings.advertiserUserPoolID).getPublicUserPoolID()#')
			</cfquery>
	
			<cfset setValue("rstadcampaigns",rstadcampaigns)>
	
			<cfquery datasource="#arguments.dsn#" name="rstadipwhitelist">
				select * from tadipwhitelist where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
			</cfquery>
	
			<cfset setValue("rstadipwhitelist",rstadipwhitelist)>
	
			<cfquery datasource="#arguments.dsn#" name="rstadzones">
				select * from tadzones where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
			</cfquery>
	
			<cfset setValue("rstadzones",rstadzones)>
	
			<cfquery datasource="#arguments.dsn#" name="rstadplacements">
				select * from tadplacements where adzoneid in (select adzoneid from tadzones where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>)
			</cfquery>
	
			<cfset setValue("rstadplacements",rstadplacements)>
	
			<cfquery datasource="#arguments.dsn#" name="rstadplacementdetails">
				select * from tadplacementdetails where placementid in (select placementid from tadplacements where adzoneid in (select adzoneid from tadzones where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>))
			</cfquery>
	
			<cfset setValue("rstadplacementdetails",rstadplacementdetails)>
				
			<!--- rstadplacementcategories --->
			<cfquery datasource="#arguments.dsn#" name="rstadplacementcategories">
				select * from tadplacementcategoryassign where placementid in (select placementid from tadplacements where adzoneid in (select adzoneid from tadzones where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>))
			</cfquery>
	
			<cfset setValue("rstadplacementcategories",rstadplacementcategories)>
			--->
			<!--- END ADVERTISING --->
			
			
			<!--- tcontentcategoryassign --->
			<cfquery datasource="#arguments.dsn#" name="rstcontentcategoryassign">
				select * from tcontentcategoryassign where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif not arguments.includeVersionHistory>
				and contentHistID in
				(
					select contenthistID from tcontent where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
					and (active = 1 or (changesetID is not null and approved=0))
				)
				</cfif>
				<cfif isDate(arguments.sinceDate)>
				and contentHistID in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valueList(rstcontent.contentHistID)#">)
				</cfif>
				<cfif not arguments.includeTrash>
				and categoryID in (select categoryID from tcontentcategories)
				and contentID in (select distinct contentID from tcontent)
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontentcategoryassign",rstcontentcategoryassign)>
	
			<!--- tcontentfeeds --->
			<cfquery datasource="#arguments.dsn#" name="rstcontentfeeds">
				select * from tcontentfeeds where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif isDate(arguments.sinceDate)>
				and lastUpdate >= #createODBCDateTime(arguments.sinceDate)#
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontentfeeds",rstcontentfeeds)>
	
			<!--- tcontentfeeditems --->
			<cfquery datasource="#arguments.dsn#" name="rstcontentfeeditems">
				select * from tcontentfeeditems where feedID in (select feedID from tcontentfeeds where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>)
				<cfif isDate(arguments.sinceDate)>
				and feedID in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valueList(rstcontentfeeds.feedID)#">)
				</cfif>
				<cfif not arguments.includeTrash>
				and feedID in (select feedID from tcontentfeeds)
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontentfeeditems",rstcontentfeeditems)>
	
			<!--- tcontentfeedadvancedparams --->
			<cfquery datasource="#arguments.dsn#" name="rstcontentfeedadvancedparams">
				select * from tcontentfeedadvancedparams where feedID in (select feedID from tcontentfeeds where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>)
				<cfif isDate(arguments.sinceDate)>
				and feedID in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valueList(rstcontentfeeds.feedID)#">)
				</cfif>
				<cfif not arguments.includeTrash>
				and feedID in (select feedID from tcontentfeeds)
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontentfeedadvancedparams",rstcontentfeedadvancedparams)>
	
			<!--- tcontentrelated --->
			<cfquery datasource="#arguments.dsn#" name="rstcontentrelated">
				select * from tcontentrelated where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif not arguments.includeVersionHistory>
				and contenthistID in 
				(
					select contenthistID from tcontent where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
					and (active = 1 or (changesetID is not null and approved=0))
				)
				</cfif>
				<cfif isDate(arguments.sinceDate)>
				and contentHistID in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valueList(rstcontent.contentHistID)#">)
				</cfif>
				<cfif not arguments.includeTrash>
				and contentID in (select distinct contentID from tcontent)
				and relatedID in (select distinct contentID from tcontent)
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontentrelated",rstcontentrelated)>
	
			<!--- tmailinglist --->
			<cfquery datasource="#arguments.dsn#" name="rstmailinglist">
				select * from tmailinglist where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif isDate(arguments.sinceDate)>
				and lastUpdate >= #createODBCDateTime(arguments.sinceDate)#
				</cfif>
			</cfquery>
	
			<cfset setValue("rstmailinglist",rstmailinglist)>
			
			<cfif arguments.includeMailingListMembers>
			<!--- tmailinglistmembers only support for full archives--->
			<cfquery datasource="#arguments.dsn#" name="rstmailinglistmembers">
				select * from tmailinglistmembers where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
			</cfquery>
	
			<cfset setValue("rstmailinglistmembers",rstmailinglistmembers)>
			</cfif>
			
			<!--- tfiles --->
			<cfquery datasource="#arguments.dsn#" name="rstfiles">
				select * from tfiles where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				and moduleid in ('00000000000000000000000000000000000'<cfif len(moduleIDSQLlist)>,#moduleIDSQLlist#</cfif><cfif arguments.includeUsers>,'00000000000000000000000000000000008'</cfif>)
				<cfif not arguments.includeVersionHistory>
				and fileID in
				(
					select fileID from tcontent where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
					and fileID is not null
					and (active = 1 or (changesetID is not null and approved=0))
				)
				</cfif>
				<cfif not arguments.includeTrash>
					and (deleted is null or deleted != 1)
				</cfif>
				<cfif isDate(arguments.sinceDate)>
				and created >= #createODBDateTime(arguments.sinceDate)#
				</cfif>
			</cfquery>
	
			<cfset setValue("rstfiles",rstfiles)>
			
			<cfset setValue("hasmetadata",arguments.includeMetaData)>
			
			<cfif arguments.includeMetaData>
			<cfquery datasource="#arguments.dsn#" name="tcontentstats">
				select * from tcontentstats where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif isDate(arguments.sinceDate)>
				and contentID in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valueList(rstcontent.contentID)#">)
				</cfif>
				<cfif not arguments.includeTrash>
				and contentID in (select distinct contentID from tcontent)
				</cfif>
			</cfquery>
	
			<cfset setValue("tcontentstats",tcontentstats)>

			<cfquery datasource="#arguments.dsn#" name="rstcontentcomments">
				select * from tcontentcomments where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif isDate(arguments.sinceDate)>
				and entered >= #createODBDateTime(arguments.sinceDate)#
				</cfif>
				<cfif not arguments.includeTrash>
				and contentID in (select distinct contentID from tcontent)
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontentcomments",rstcontentcomments)>
	
			<cfquery datasource="#arguments.dsn#" name="rstcontentratings">
				select * from tcontentratings where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif isDate(arguments.sinceDate)>
				and entered >= #createODBDateTime(arguments.sinceDate)#
				</cfif>
				<cfif not arguments.includeTrash>
				and contentID in (select distinct contentID from tcontent)
				</cfif>
			</cfquery>
			
			</cfif>
			
			<cfquery datasource="#arguments.dsn#" name="rstclassextend">
				select * from tclassextend where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif not arguments.includeUsers>
				and type not in ('1','2','User','Group')
				</cfif>
			</cfquery>
	
			<cfset setValue("rstclassextend",rstclassextend)>
	
			<cfquery datasource="#arguments.dsn#" name="rstclassextendsets">
				select * from tclassextendsets 
				where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				and subTypeID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rstclassextend.subtypeID)#" list="true">)
			</cfquery>
	
			<cfset setValue("rstclassextendsets",rstclassextendsets)>
	
			<cfquery datasource="#arguments.dsn#" name="rstclassextendattributes">
				select * from tclassextendattributes where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				and extendsetID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valueList(rstclassextendsets.extendsetID)#" list="true">)
			</cfquery>
	
			<cfset setValue("rstclassextendattributes",rstclassextendattributes)>
	
			<cfquery datasource="#arguments.dsn#" name="rstclassextenddata">
				select tclassextenddata.baseID, tclassextenddata.attributeID, tclassextenddata.attributeValue, 
				tclassextenddata.siteID, tclassextenddata.stringvalue, tclassextenddata.numericvalue, tclassextenddata.datetimevalue, tclassextenddata.remoteID from tclassextenddata 
				inner join tcontent on (tclassextenddata.baseid=tcontent.contenthistid)
				where tclassextenddata.siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif not arguments.includeVersionHistory>
				and (tcontent.active = 1 or (tcontent.changesetID is not null and tcontent.approved=0))
				</cfif>
				<cfif isDate(arguments.sinceDate)>
					and lastUpdate >= #createODBCDateTime(arguments.sinceDate)#
				</cfif>
			</cfquery>
	
			<cfset setValue("rstclassextenddata",rstclassextenddata)>
			
			<cfif arguments.includeUsers>
			<cfquery datasource="#arguments.dsn#" name="rstclassextenddatauseractivity">
				select * from tclassextenddatauseractivity
				where siteID= <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
			</cfquery>
	
			<cfset setValue("rstclassextenddatauseractivity",rstclassextenddatauseractivity)>
			</cfif>
				
			<!--- tcontentcategories --->
			<cfquery datasource="#arguments.dsn#" name="rstcontentcategories">
				select * from tcontentcategories where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif isDate(arguments.sinceDate)>
					and lastUpdate >= #createODBCDateTime(arguments.sinceDate)#
				</cfif>
			</cfquery>
	
			<cfset setValue("rstcontentcategories",rstcontentcategories)>	
			
			<!--- tchangesets --->
			<cfquery datasource="#arguments.dsn#" name="rstchangesets">
				select * from tchangesets where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<cfif not arguments.includeVersionHistory>
				and published=0
				</cfif>
				<cfif isDate(arguments.sinceDate)>
					and lastUpdate >= #createODBCDateTime(arguments.sinceDate)#
				</cfif>
			</cfquery>
	
			<cfset setValue("rstchangesets",rstchangesets)>	
			
			<cfif arguments.includeTrash or isDate(arguments.sinceDate)>
			<!--- ttrash --->
			<cfquery datasource="#arguments.dsn#" name="rsttrash">
				select * from ttrash where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				<!--- We don't want user data in trash --->
				<cfif not arguments.includeUsers>
				and objectClass not in ('userBean','addressBean')
				</cfif>
				<cfif isDate(arguments.sinceDate)>
					and deletedDate >= #createODBCDateTime(arguments.sinceDate)#
				</cfif>
			</cfquery>
			
			<cfset setValue("rsttrash",rsttrash)>	
			
			<!--- deleted files --->
			<cfif isDate(arguments.sinceDate)>
			<cfquery datasource="#arguments.dsn#" name="rsttrashfiles">
				select * from tfiles where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/>
				and moduleid in ('00000000000000000000000000000000000'<cfif len(moduleIDSQLlist)>,#moduleIDSQLlist#</cfif><cfif arguments.includeUsers>,'00000000000000000000000000000000008'</cfif>)
				and deleted=1
			</cfquery>
	
			<cfset setValue("rsttrashfiles",rsttrashfiles)>
			</cfif>
			
			</cfif>
			
			<cfquery datasource="#arguments.dsn#" name="rssite">
				select theme,galleryMainScaleBy,galleryMediumScaleBy,gallerySmallScaleBy,
			    galleryMainScale,galleryMediumScale,gallerySmallScale
			    from tsettings where siteid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#"/> 
			</cfquery>
			
			<cfset setValue("rssite",rssite)>	
			
			
		</cfif>
		<!--- BEGIN PLUGINS --->
		
		<!--- Modules--->
		<cfquery datasource="#arguments.dsn#" name="rstpluginmodules">
			select moduleID from tcontent where 
			1=1
			<cfif len(arguments.siteID)>
				and siteid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteid#"/> and type='Plugin'
			</cfif>
			<cfif len(arguments.moduleID)>
				and moduleID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.moduleID#" list="true">)
			<cfelse>
				and 0=1
			</cfif>
		</cfquery>
		
		<cfset setValue("rstpluginmodules",rstpluginmodules)>
		
		<!--- Plugins --->
		<cfquery datasource="#arguments.dsn#" name="rstplugins">
			select * from tplugins
			where
			1=1 
			<cfif len(arguments.siteID)>
			 	and moduleID in ( select moduleID from tcontent where siteid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteid#"/> and type='Plugin')
			</cfif>
			<cfif len(arguments.moduleID)>
				and moduleID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.moduleID#" list="true">)
			<cfelse>
				and 0=1
			</cfif>
		</cfquery>
		
		<cfset setValue("rstplugins",rstplugins)>
		
		<cfloop query="rstplugins">
			<cfif fileExists(expandPath("/plugins/#rstplugins.directory#/plugin/plugin.cfc"))>	
				<cfset pluginConfig=getPlugin(ID=rstplugins.moduleID, siteID="", cache=false)>
				<cfset pluginCFC= createObject("component","plugins.#rstplugins.directory#.plugin.plugin") />
						
				<!--- only call the methods if they have been defined --->
				<cfif structKeyExists(pluginCFC,"init")>
					<cfset pluginCFC.init(pluginConfig)>
					<cfif structKeyExists(pluginCFC,"toBundle")>
						<cfset pluginCFC.toBundle(pluginConfig=pluginConfig,Bundle=this, siteID=arguments.siteID)>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>	
		
		<!--- Scripts --->
		<cfquery datasource="#arguments.dsn#" name="rstpluginscripts">
			select * from tpluginscripts where
			1=1
			<cfif len(arguments.siteID)>
			 	and moduleID in ( select moduleID from tcontent where siteid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteid#"/> and type='Plugin')
			</cfif>
			<cfif len(arguments.moduleID)>
				and moduleID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.moduleID#" list="true">)
			<cfelse>
				and 0=1
			</cfif>
		</cfquery>
		
		<cfset setValue("rstpluginscripts",rstpluginscripts)>
		
		<!--- Display Objects --->
		<cfquery datasource="#arguments.dsn#" name="rstplugindisplayobjects">
			select * from tplugindisplayobjects where
			1=1
			<cfif len(arguments.siteID)>
			 	and moduleID in ( select moduleID from tcontent where siteid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteid#"/> and type='Plugin')
			</cfif>
			<cfif len(arguments.moduleID)>
				and moduleID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.moduleID#" list="true">)
			<cfelse>
				and 0=1
			</cfif>
		</cfquery>
		
		<cfset setValue("rstplugindisplayobjects",rstplugindisplayobjects)>
		
		<!--- Settings --->
		<cfquery datasource="#arguments.dsn#" name="rstpluginsettings">
			select * from tpluginsettings where
			1=1
			<cfif len(arguments.siteID)>
			 	and moduleID in ( select moduleID from tcontent where siteid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteid#"/> and type='Plugin')
			</cfif>
			<cfif len(arguments.moduleID)>
				and moduleID in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.moduleID#" list="true">)
			<cfelse>
				and 0=1
			</cfif>
		</cfquery>
		
		<cfset setValue("rstpluginsettings",rstpluginsettings)>
		<!--- END PLUGINS --->
		
		<cfset setValue("sincedate",arguments.sincedate)>
		<cfset setValue("bundledate",now())>
			
		<cfset variables.zipTool.AddFiles(zipFilePath="#variables.workDir##variables.dirName#.zip",directory=#variables.backupDir#)>

		<cfdirectory action="list" directory="#variables.procDir#" type="dir" name="rsCleanDir">

		<cfloop query="rsCleanDir">
			<cftry>
			<cfdirectory action="delete" directory="#variables.procDir##name#" recurse="true" >
			<cfcatch></cfcatch>
			</cftry>
		</cfloop>
	
		<cfif not len(arguments.bundleName)>
			<cfset arguments.bundleName="MuraBundle">
		</cfif>
		<cfif len(arguments.siteID)>
			<cfset arguments.bundleName=arguments.bundleName & "_#arguments.siteID#">
		</cfif>
			
		<cfheader name="Content-Disposition" value='attachment;filename="#arguments.bundleName#_#dateformat(now(),"dd_mm_yyyy")#_#timeformat(now(),"HH_mm")#.zip"'>
		<cfcontent TYPE="application/zip" file="#variables.workDir##variables.dirName#.zip" deletefile="Yes">
		
	</cffunction>

	<cffunction name="getBundle" returntype="string">
		<cfreturn variables.Bundle />
	</cffunction>

	<cffunction name="cleanUp" returntype="string">
		<cfif not len( getBundle() ) or not directoryExists( getBundle() )>
			<cfreturn>
		</cfif>
		
		<cftry>
			<cfdirectory action="delete" directory="#getBundle()#" recurse="true">
		<cfcatch>
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="getValue" returntype="any" output="false">
		<cfargument name="name" type="string" required="true">
		<cfargument name="default">

		<cfif structKeyExists(variables.data,arguments.name)>
			<cfreturn variables.data[name] />
		<cfelse>
			<cfif structKeyExists(arguments,"default")>
				<cfreturn arguments.default>
			<cfelse>
				<cfreturn QueryNew("null") />
			</cfif>
		</cfif>
	</cffunction>
	
	<cffunction name="setValue" returntype="void">
		<cfargument name="name" type="string" required="true">
		<cfargument name="value" type="any" required="true">
		<cfset var temp="">
		<cfwddx action="cfml2wddx" input="#arguments.value#" output="temp">
		<cffile action="write" output="#temp#" file="#variables.backupDir#wddx_#arguments.name#.xml">
	</cffunction>

</cfcomponent>