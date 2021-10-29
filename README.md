# AzureAutoQuota
Powershell Script to Automatically Increase Azure vCPU Quotas

This script is made to be run inside Azure Automation Account.

The script will run in a subcription, validate the usage of Virtual Machine Families vCPU per location and AUTOMATICALLY request the increase of quota for that specific Virtual Machine Family in the specific location.

## How to:

1) Just create an Automation Account and enable System Management Identity for the Automation Account (https://docs.microsoft.com/en-us/azure/automation/enable-managed-identity-for-automation). 

2) Give the following permissions for the Automation Account System Managed Identity in all the Subscriptions you want the script to run:
  a) Reader
  b) Quota Request Operator

3) Import the following Modules to the Automation Account:
  a) Az.Accounts
  b) Az.Compute
  c) Az.ResourceGraph
  
4) Create a Runbook and paste the content of the file Runbook.ps1.

5) Configure the 3 variables inside the script:
  a) "Trigger" is the percentage left in the vCPU Famility to hit the limit of the current Quota.
  b) "Increase" is the Quota percentage the script should increase when the "Trigger" is hit.
  c) "TargetSubscription" are the Subscriptions the script should run. THE SCRIPT WILL ONLY RUN IN THOSE SUBSCRIPTIONS.
  

