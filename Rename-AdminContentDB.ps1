<#
.Synopsis
   This script renames the SharePoint Server Admin Content database.
.DESCRIPTION
   This script will rename the Admin Content database for your SharePoint Server 2013/2016 environment.

   =========================
   **IMPORTANT FOR SP2016 **
   =========================
   The Admin Content database will need to be upgraded first!!
   Please refer to my blog post for a step-by-step procedure: http://bit.ly/2BpcuJI

.EXAMPLE
   .\Rename-AdminContentDB.ps1 -NewAdminDBName "<New_Name>" -CAUrl "http://<site:port>" -DBServer "<Server\Instance>"
.EXAMPLE
   .\Rename-AdminContentDB.ps1  (parameters are mandatory, and will be required if not entered with initially)
.NOTES
   Script is also available on my TechNet Gallery at http://bit.ly/2yOa9sa (@VeronicaGeek)

#>
[CmdletBinding()]
param(    
    [Parameter(Mandatory=$true,HelpMessage="NEW name for the AdminContent database",Position=1)] 
    [string]$NewAdminDBName,
    [Parameter(Mandatory=$true,HelpMessage="Current Central Admin URL (ex: http://<servername>:<port>)",Position=2)] 
    [string]$CAUrl,
    [Parameter(Mandatory=$true,HelpMessage="Current location of the AdminContent DB (ex: SQLServer\instance)",Position=3)] 
    [string]$DBServer
)
#Add SharePoint snapin
Write-Host "Adding SharePoint Snapin…" -f Yellow
Add-PSSnapin Microsoft.SharePoint.PowerShell


#Get "Id" of the current Admin Content DB (with GUID)
Write-Host "** Gathering the Id for OLD AdminContent DB... " -f Yellow
$OldId = (Get-SPWebApplication -Identity $CAUrl | Get-SPContentDatabase).Id

#Create new Admin Content DB and grab the Id
Write-Host "** Creating NEW Admin Content DB and grabbing the Id... Be patient." -f Yellow
New-SPContentDatabase -Name $NewAdminDBName -WebApplication $CAUrl -DatabaseServer $DBServer
$NewId = (Get-SPWebApplication -Identity $CAUrl | Get-SPContentDatabase | ? {$_.Name -eq "$NewAdminDBName"}).Id


#Move the content from OLD Admin DB to the NEW Admin DB
Write-Host "** Moving DB's..." -f Yellow
Get-SPSite -ContentDatabase $OldId | Move-SPSite -DestinationDatabase $NewId

#Resetting IIS
Write-Host "** Performing IISReset... " -f Yellow
iisreset

#Removing the OLD Admin Content DB
Write-Host "** Removing OLD AdminContent DB..." -f Yellow
Remove-SPContentDatabase $OldId -Force
Write-Host "OLD AdminContent DB removed!" -f Green

#Checking the only Admin Content DB available
Write-Host "New Admin Content database: " -f Magenta
Get-SPWebApplication -Identity $CAUrl | Get-SPContentDatabase | Select Id, Name | Format-List
