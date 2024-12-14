<#
Documentation Reference: https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dkim-configure?view=o365-worldwide
This script helps you configure DKIM for your domain. In this case, the domain is 'redbackops.com'.

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

## Step 5: Check Existing DKIM Configuration
Get-DkimSigningConfig -Identity redbackops.com | Format-List Name,Enabled,Status,Selector1CNAME,Selector2CNAME

##!!!IMPORTANT - Run 'Step 5.1' ONLY if no SELECTORS are returned in 'Step 5'. If DKIM is already configured, 'Step 5' will return 2 SELECTORS!!!
## Step 5.1: Create a New DKIM Signing Configuration.
# This command sets up DKIM for the domain 'redbackops.com' with a 2048-bit key size.
New-DkimSigningConfig -DomainName redbackops.com -KeySize 2048 -Enabled $false

##!!IMPORTANT - Before proceeding to 'Step 6', create CNAME records at your domain registrar using the SELECTOR information from either 'Step 5' or 'Step 5.1'!!!
## Step 6: Enable DKIM Signing for the domain - 'redbackops.com'
Set-DkimSigningConfig -Identity redbackops.com -Enabled $true

## Step 7: Verify DKIM Configuration
# Retrieve only selected key details (Name, Enabled,Status,Selector Names) of DKIM signing configuration.
Get-DkimSigningConfig -Identity redbackops.com | Format-List Name,Enabled,Status,Selector1CNAME,Selector2CNAME

# Retrieve detailed DKIM signing configuration information. 
Get-DkimSigningConfig -Identity redbackops.com | Format-List

## Step 8: Disconnect from the Exchange Online session
Disconnect-ExchangeOnline