<#
Modules: Az.Accounts , Az.Compute

Install-Module -Name Az.Accounts
Install-Module -Name Az.Compute
<or>
Install-Module -Name Az
#>


###############################################################  VARIABLES  #############################################################################

$Sub = ''
$Location = 'eastus2'
$VMFamily = 'StandardDSv2Family'
$Quota = 2500


###############################################################  AUTHENTICATE  #############################################################################

Clear-AzContext -Force
Connect-AzAccount
Set-azContext -Subscription $Sub
Get-AzVMUsage -Location $Location

################################################################   PROCESSING    #######################################################################################

$Token = Get-AzAccessToken
$Token = $Token.Token
$headers = @{
    Authorization="Bearer $Token"
}

$Body = @"
{ 
 "properties": { 
 "limit": $Quota,
 "unit": "Count", 
 "name": { 
   "value": "$VMFamily"
 } 
 } 
} 
"@

$FamilyName = ([string]$VMFamily+'?api-version=2020-10-25')

$Uri = "https://management.azure.com/subscriptions/$Sub/providers/Microsoft.Capacity/resourceProviders/Microsoft.Compute/locations/$Location/serviceLimits/$FamilyName"

Invoke-WebRequest -Uri $Uri -Headers $headers -Body $Body -Method Put -UseBasicParsing
