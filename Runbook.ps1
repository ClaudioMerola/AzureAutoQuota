<#
Modules: Az.Accounts , Az.Compute, Az.ResourceGraph
#>

###############################################################  VARIABLES  #############################################################################

<# % to Trigger the increase #>
$Trigger = 20

<# % to increase #>
$Increase = 20

<# Subscriptions to run #>
$TargetSubscription = '3d5f753d-ef56-4b30-97c3-fb1860e8f44c','c44908f1-44a3-47f7-aae3-fbd1c0457d9c'


###############################################################  READING  #############################################################################

Clear-AzContext -Force

Connect-AzAccount -Identity

$Subscriptions = Get-AzContext -ListAvailable | Where-Object {$_.Subscription.State -ne 'Disabled' -and $_.Subscription.Id -in $TargetSubscription}

Write-Output ('Running in the following Subscriptions:'+$Subscriptions.Name)

$Subscriptions = $Subscriptions.Subscription


$Location = Search-AzGraph -Query "resources | where type == 'microsoft.compute/virtualmachines' or type == 'microsoft.compute/virtualmachinescalesets' | summarize by location"


$Quotas = @()

foreach($sub in $Subscriptions)
    {
        Set-azContext -Subscription $sub
        foreach($Loc in $Location)
            {
                $Quota = Get-AzVMUsage -Location $Loc.location
                
                $Quota = $Quota | Where-Object {$_.CurrentValue -ge 1}
                $Q = @{
                    'Location' = $Loc;
                    'Subscription' = $Sub;
                    'Data' = $Quota
                }
                $Quotas += $Q                
            }
    }

################################################################   PROCESSING    #######################################################################################

$Token = Get-AzAccessToken

$Token = $Token.Token

$headers = @{
    Authorization="Bearer $Token"
}

foreach($Quota in $Quotas)
    {
        foreach($Data in $Quota.Data)
            {
                if($Data.Name.LocalizedValue -like '*Family vCPUs')
                    {
                        $PvCPU = ($Data.currentValue / $Data.limit)*100

                        if($PvCPU -ge $Trigger)
                            {
                                Write-Output ('---------------------------------------')

                                $Name = $Data.Name.value

                                Write-Output ('Requesting Increase of Quota for Family: '+$Name +'. For Location: '+[string]$Quota.Location.location)

                                $NewLimit = $Data.limit + (($Data.limit/100)*$Increase)

                                Write-Output ('Old Quota: '+$Data.limit. '| New Quota: '+$NewLimit)


$Body = @"
{ 
 "properties": { 
 "limit": $NewLimit,
 "unit": "Count", 
 "name": { 
   "value": "$Name"
 } 
 } 
} 
"@

                                $Sub = [string]$Quota.Subscription.id
                                $Locate = [string]$Quota.Location.location
                                $FamilyName = ([string]$Data.Name.value+'?api-version=2020-10-25')

                                $Uri = "https://management.azure.com/subscriptions/$Sub/providers/Microsoft.Capacity/resourceProviders/Microsoft.Compute/locations/$Locate/serviceLimits/$FamilyName"

                                $Request = Invoke-WebRequest -Uri $Uri -Headers $headers -Body $Body -Method Put -UseBasicParsing

                                Write-Output ('Request Status: '+$Request.StatusCode)
                            }
                    }
            }
    }
