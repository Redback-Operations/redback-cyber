<#
Documentation Reference: 
https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dkim-configure?view=o365-worldwide
https://learn.microsoft.com/en-us/powershell/module/exchange/rotate-dkimsigningconfig?view=exchange-ps

This script helps you to rotate DKIM keys.

Instructions:
- You can use 'Powershell', 'Windows PowerShell ISE', or 'Visual Studio Code' to run this. Ensure to 'Run as Administrator'.
- Run the steps one by one in a sequential order.
- Ensure to use an account with either 'Global Administrator' or 'Exchange Administrator' permissions.
#>

## Step 1: Install Exchange Online Management Powershell module (if not already installed)
Install-Module -Name ExchangeOnlineManagement

## Step 2: Temporarily set the execution policy to bypass any restrictions for the current session.
Set-ExecutionPolicy Bypass -Scope Process -Force

## Step 3: Import the Exchange Online Management Module
Import-Module ExchangeOnlineManagement

## Step 4: Connect to Exchange Powershell
# Use an account with 'Global Administrator' or 'Exchange Administrator' permissions.
Connect-ExchangeOnline -UserPrincipalName adm-redbackops@redbackops.com

## Step 5: Retrieve detailed DKIM signing configuration information.
# Make note of these attributes - KeyCreationTime, RotateOnDate, SelectorBeforeRotateOnDate, SelectorAfterRotateOnDate
Get-DkimSigningConfig -Identity redbackops.com | Format-List

## Step 6: Rotate DKIM signing keys
Rotate-DkimSigningConfig -KeySize 2048 -Identity redbackops.com

## Step 7: Validate - Retrieve detailed DKIM signing configuration information.
# Check changes of these attributes' values - KeyCreationTime, RotateOnDate, SelectorBeforeRotateOnDate, SelectorAfterRotateOnDate
Get-DkimSigningConfig -Identity redbackops.com | Format-List

## Step 8: Disconnect from the Exchange Online session
Disconnect-ExchangeOnline