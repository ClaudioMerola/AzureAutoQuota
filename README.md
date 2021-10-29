# AzureAutoQuota
Powershell Script to Automatically Increase Azure vCPU Quotas

This script is made to be run inside Azure Automation Account.

The script will run in a subcription, validate the usage of Virtual Machine Families vCPU per location and AUTOMATICALLY request the increase of quota for that specific Virtual Machine Family in the specific location.

## How to:

- Just create an Automation Account and enable System Management Identity for the Automation Account (https://docs.microsoft.com/en-us/azure/automation/enable-managed-identity-for-automation). 


- Give the following permissions for the Automation Account System Managed Identity in all the Subscriptions you want the script to run:
  - Reader
  - Quota Request Operator


- Import the following Modules to the Automation Account:
  - Az.Accounts
  - Az.Compute
  - Az.ResourceGraph


- Create a Runbook and paste the content of the file Runbook.ps1.


- Configure the 3 variables inside the script:
  - "Trigger" is the percentage left in the vCPU Famility to hit the limit of the current Quota.
  - "Increase" is the Quota percentage the script should increase when the "Trigger" is hit.
  - "TargetSubscription" are the Subscriptions the script should run. THE SCRIPT WILL ONLY RUN IN THOSE SUBSCRIPTIONS.
  

