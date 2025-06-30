## Install Exchange Online Management Powershell module (if not already installed)
Install-Module -Name ExchangeOnlineManagement

## Temporarily set the execution policy to bypass any restrictions for the current session.
Set-ExecutionPolicy Bypass -Scope Process -Force

## Import the Exchange Online Management Module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online using an account with 'Global Administrator', 'Exchange Administrator' or 'Security Administrator' permissions.
Connect-ExchangeOnline

## 12.1 IMPLEMENT - Block Malicious Domains or Addresses via Mail Flow Rule
# Create a new Mail Transport Rule
# Malicious sender source: https://threatview.io/Downloads/DOMAIN-High-Confidence-Feed.txt
New-TransportRule -Name "RedbackOps_Block_Malicious_Senders" `
  -FromAddressContainsWords "0000.ole32.com","027wuhan.com","info@120corona.com" `
  -DeleteMessage $true `
  -SenderAddressLocation HeaderOrEnvelope `
  -Mode Enforce `
  -SetAuditSeverity High `
  -Priority 0

## 12.2. VALIDATE - Block Malicious Domains or Addresses via Mail Flow Rule
# List transport rules to confirm creation
Get-TransportRule | Where-Object {$_.Name -like "*RedbackOps_Block_Malicious_Senders*"} | Format-List Name,FromAddressContainsWords

# Add senders or senders domains to the Mail Transport Rule
Set-TransportRule -Identity "RedbackOps_Block_Malicious_Senders" `
  -FromAddressContainsWords ((Get-TransportRule -Identity "RedbackOps_Block_Malicious_Senders").FromAddressContainsWords + `
    @("redbackops24@gmail.com") | Sort-Object -Unique) # This is not a malicious sender address. Adding it here for testing/validation purposes.

# List transport rules to confirm addition
Get-TransportRule | Where-Object {$_.Name -like "*RedbackOps_Block_Malicious_Senders*"} | Format-List Name,FromAddressContainsWords

# Remove senders or sender domains from the Mail Transport Rule
Set-TransportRule -Identity "RedbackOps_Block_Malicious_Senders" `
  -FromAddressContainsWords ((Get-TransportRule -Identity "RedbackOps_Block_Malicious_Senders").FromAddressContainsWords | `
    Where-Object { $_ -ne "redbackops24@gmail.com"}) # Remove the test entry

# List transport rules to confirm removal
Get-TransportRule | Where-Object {$_.Name -like "*RedbackOps_Block_Malicious_Senders*"} | Format-List Name,FromAddressContainsWords

## 13.1. IMPLEMENT - Block Malicious IP Addresses via Connection Filter Policy
# Add malicious IPs to the block list -  This will reject the connection at SMTP gateway level before message content is even processed.
# Malicious IP source: https://snort.org/downloads/ip-block-list/
Set-HostedConnectionFilterPolicy -Identity "Default" `
  -IPBlockList @("185.234.216.59", "212.83.185.105", "194.143.136.122")

## 13.2. VALIDATE - Validate Connection Filter (IP Block)
# Retrieve current block list
Get-HostedConnectionFilterPolicy -Identity "Default" | Select-Object -ExpandProperty IPBlockList

# Monitor blocked IPs for the last 30 days
#Note: 
    # Message trace only works for messages that have already passed the SMTP connection
    # IP rejections may not appear in the message trace unless logged via Defender
Get-MessageTrace -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) `
| Where-Object {$_.EventType -like "Failed"} | Format-Table SenderAddress,RecipientAddress,Status

# Remove IP address from Connection Filter Policy
Set-HostedConnectionFilterPolicy -Identity "Default" `
  -IPBlockList ((Get-HostedConnectionFilterPolicy -Identity "Default").IPBlockList | Where-Object { $_ -ne "185.234.216.59" })

# 14.1. IMPLEMENT - Enable auditing for all mailboxes
Get-Mailbox -ResultSize Unlimited |
  Set-Mailbox -AuditEnabled $true

# 14.2. VALIDATE - Validate auditing for all mailboxes
# This should all mailboxes as auditing is enabled for all mailboxes.
Get-Mailbox -ResultSize Unlimited -Filter {AuditEnabled -eq $true} | Select-Object Name, UserPrincipalName

# This should return no values as autiting is enabed for all mailboxes.
Get-Mailbox -ResultSize Unlimited -Filter {AuditEnabled -eq $false} | Select-Object Name, UserPrincipalName








