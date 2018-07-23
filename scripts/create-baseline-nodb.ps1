[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$PackagePath
  )



$msdeploy = "C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe"
$verb = "-verb:sync"
$source = "-source:package=`"$PackagePath`""
$ParamFile = $PSScriptRoot+"\parameters.xml"
$declareParamfilePath = $($PackagePath).Replace(".scwdp.zip", ".declareparam.xml")
$declareParamFileDB = "-declareparamfile=`"$($ParamFile)`""
$declareParamFileNoDB = "-declareparamfile=`"$($declareParamfilePath)`""
$declareParam = "-declareparam:name=`"IIS Web Application Name`",kind=ProviderPath,scope=IisApp,match=Website"
$declareParamHasingAlgoritmSQLStep1   = "-declareparam:name=`"HasingAlgoritmSQLStep1`",type=TextFile,scope=SetSitecoreAdminPassword.sql,match=SHA1,defaultValue=SHA2_512"
$declareParamHasingAlgoritmSQLStep2   = "-declareparam:name=`"HasingAlgoritmSQLStep2`",type=TextFile,scope=SetSitecoreAdminPassword.sql,match=20,defaultValue=512"
$declareParamHasingAlgoritmConfig     = "-declareparam:name=`"HasingAlgorithmWebConfig`",kind=XmlFile,scope=Web\.config$,match=//configuration/system.web/membership/@hashAlgorithmType,defaultValue=SHA512"
$skipDbFullSQL = "-skip:objectName=dbFullSql"
$skipDbDacFx = "-skip:objectName=dbDacFx"

#Extract paramter filec ssdsd

Add-Type -Assembly System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($packagePath)
$zip.Entries | where {$_.Name -like 'parameters.xml'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $ParamFile, $true)}
$zip.Dispose()

# read parameter file
[xml]$paramfile_content = Get-Content -Path $ParamFile
$paramfile_paramnames = $paramfile_content.parameters.parameter.name
$paramfile_params = $paramfile_content.parameters.parameter
$params = ""
foreach($param in $paramfile_params){
   $tmpvalue = "tmpvalue"
   if($param.name -eq "License Xml"){ $tmpvalue = "LicenseContent" }
   if($param.name -eq "IP Security Client IP"){ $tmpvalue = "0.0.0.0"}
   if($param.name -eq "IP Security Client IP Mask"){ $tmpvalue = "0.0.0.0"}
   if($param.name -eq "AllowInvalidClientCertificates"){ $tmpvalue = "false"}

   # this entry is needed to copy over the original "match" parameter, otherwise the match  "placeholderforpassword" would be replaced by 'tmpvalue'
   if($param.parameterEntry.Type -eq "TextFile"){ $tmpvalue = "$($param.parameterEntry.match)"}
   $params = "$params -setParam:`"$($param.name)`"=`"$tmpvalue`""
}

# Create no-db
$PackageDestinationPath = $($PackagePath).Replace(".scwdp.zip", "-deploy-nodb.scwdp.zip")
write-output = "$packageDestinationPath"
$destination = "-dest:package=`"$($PackageDestinationPath)`""
Write-Host "& '$msdeploy' --% $verb $source $destination $declareParam $declareParamFile $params $skipDbFullSQL $skipDbDacFx"
Invoke-Expression "& '$msdeploy' --% $verb $source $destination $declareParam $declareParamFileNoDB $params $skipDbFullSQL $skipDbDacFx $declareParamHasingAlgoritmConfig"
#Invoke-Expression "& '$msdeploy' --% $verb $source $destination $declareParam $declareParamFile $params"

# Create with DB
$PackageDestinationPath = $($PackagePath).Replace(".scwdp.zip", "-provision.scwdp.zip")
write-output = "$PackageDestinationPath"
$destination = "-dest:package=`"$($PackageDestinationPath)`""
Invoke-Expression "& '$msdeploy' --% $verb $source $destination $declareParamFileDB $params $declareParamHasingAlgoritmConfig $declareParamHasingAlgoritmSQLStep1 $declareParamHasingAlgoritmSQLStep2"