# Use Goal 1 to scan Quotas and Goal 2 to request increase
$Goal = 1

$Sub = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
$Location = 'brazilsouth'
$VMFamily = 'standardBSFamily'
$Quota = 200

if($Goal -eq 1)
  {
    write-host "Scanning used Quotas"
    $Quota = Get-AzVMUsage -Location $Location
    $Quota = $Quota | Where-Object {$_.CurrentValue -ge 1 -and $_.Name.LocalizedValue -like '*vCPUs'}
    $Quota | Format-Table -property @{label='Name';e={$_.Name.LocalizedValue}}, @{label='Family Name';e={$_.Name.Value}}, CurrentValue, Limit
  }

if($Goal -eq 2)
  {
    write-host ("Starting to request Quota Increase for: " + $Sub)
    write-host ("Requesting Quota for VM Family: " + $VMFamily)
    write-host ("Requesting Quota for Location: " + $Location)
    write-host ("Requesting Quota increase to: " + $Quota)
    write-host "Authenticating..."
    ###############################################################  AUTHENTICATE  #############################################################################

    Clear-AzContext -Force
    Connect-AzAccount -UseDeviceAuthentication
    Set-azContext -Subscription $Sub

    ################################################################   PROCESSING    #######################################################################################

    write-host "Creating headers..."
    $Token = Get-AzAccessToken
    $Token = $Token.Token
    $headers = @{
        Authorization="Bearer $Token"
    }

    write-host "Creating body..."
$Body = @"
{
  "properties": {
    "limit": {
      "limitObjectType": "LimitValue",
      "value": $Quota
    },
    "name": {
      "value": "$VMFamily"
    }
  }
}
"@

    write-host "Recording Family Name..."
    $FamilyName = ([string]$VMFamily+'?api-version=2021-03-15-preview')

    #$Uri = "https://management.azure.com/subscriptions/$Sub/providers/Microsoft.Capacity/resourceProviders/Microsoft.Compute/locations/$Location/providers/Microsoft.Quota/quotas/$FamilyName"

    write-host "Creating Resource ID..."

    $RUI = "subscriptions/$Sub/providers/Microsoft.Compute/locations/$Location"

    write-host "Recording URI..."

    $Uri = "https://management.azure.com/$RUI/providers/Microsoft.Quota/quotas/$FamilyName"

    write-host "Invoking REST API..."

    $Response = Invoke-WebRequest -Uri $Uri -Headers $headers -Body $Body -Method Put -UseBasicParsing

    $Response = $Response.Content | convertfrom-Json

    write-host ("Quota Increase Request Created, Request ID: "+$Response.name)

    $ResponseName = $Response.name

    write-host "Creating Quota Increase Status Request..."

    $Request = ('https://management.azure.com/'+ $RUI + '/providers/Microsoft.Quota/quotaRequests/'+ $ResponseName +'?api-version=2021-03-15-preview')
    
    write-host "Invoking REST API to get Request Status..."

    $Status = Invoke-WebRequest -Uri $Request -Headers $headers -Method Get -UseBasicParsing

    $Status = $Status.content | convertfrom-json

    write-host ("Response: "+ $Status.properties.message)

    while($Status.properties.message -like "*Request processing*")
      {
        write-host "Waiting Request to be completed..."
        start-sleep 30
        $Status = Invoke-WebRequest -Uri $Request -Headers $headers -Method Get -UseBasicParsing
        $Status = $Status.content | convertfrom-json        
      }

    write-host ("Request Status: "+ $Status.properties.message)
    if($Status.error.code)
      {
        write-host ("Error Message: "+$Status.error.code)
      }

    write-host "End."
  }
