<#
Documentation Reference: https://www.cisecurity.org/benchmark/microsoft_365
This script helps to implement CIS Benchmark recommended controls for Email and Collaboration.

Instructions:
- You can use 'Powershell', 'Windows PowerShell ISE', or 'Visual Studio Code' to run this. Ensure to 'Run as Administrator'.
- Run the steps one by one in a sequential order.
- Ensure to use an account with either 'Global Administrator' role permissions.

Disclaimer: This PowerShell Script is still in development, and needs to be thoroughly tested and validated, which is planned for T1/2025.
#>

## Install Exchange Online Management Powershell module (if not already installed)
Install-Module -Name ExchangeOnlineManagement

## Temporarily set the execution policy to bypass any restrictions for the current session.
Set-ExecutionPolicy Bypass -Scope Process -Force

## Import the Exchange Online Management Module
Import-Module ExchangeOnlineManagement

# Use an account with 'Global Administrator' or 'Exchange Administrator' permissions.
Connect-ExchangeOnline

# Enable advanced Exchange Online features for the organization.
# This step is necessary if the organization is in a "dehydrated" state, which prevents advanced customization (e.g., custom policies or rules).
Enable-OrganizationCustomization # Can take up to 24 hours to take effect

## Verify the current state of the organization.
# The `IsDehydrated` attribute should return `False` once the customization is enabled.
# If it returns `True`, the organization is still in a dehydrated state.
Get-OrganizationConfig | Format-List isDehydrated

## 2.1.1 (L2) Ensure Safe Links for Office Applications is Enabled (Automated)
# Create Policy
$params = @{ 
    Name = "Redback_CIS_SafeLinksPolicy_All"
    AdminDisplayName  = "Custom Safe Links Policy for all domains as per - 2.1.1 (L2) Ensure Safe Links for Office Applications is Enabled."
    EnableSafeLinksForEmail = $true
    EnableSafeLinksForTeams = $true
    EnableSafeLinksForOffice = $true
    TrackClicks = $true
    AllowClickThrough = $false
    ScanUrls = $true
    EnableForInternalSenders = $true
    DeliverMessageAfterScan = $true
    DisableUrlRewrite = $false 
}
New-SafeLinksPolicy @params

# Create the rule for all users in all valid domains and associate with Policy
New-SafeLinksRule -Name "Redback_CIS_SafeLinksRule_All" -SafeLinksPolicy "Redback_CIS_SafeLinksPolicy_All" -RecipientDomainIs (Get-AcceptedDomain).Name -Priority 0

# Validate Policy
Get-SafeLinksPolicy -Identity "Redback_CIS_SafeLinksPolicy_All"
<# 
Verify the value for the following.
EnableSafeLinksForEmail: True
EnableSafeLinksForTeams: True
EnableSafeLinksForOffice: True
TrackClicks: True
AllowClickThrough: False
ScanUrls: True
EnableForInternalSenders: True
DeliverMessageAfterScan: True
DisableUrlRewrite: False
#>


## 2.1.2 (L1) Ensure the Common Attachment Types Filter is enabled (Automated)
# Enable
# Note: If you get 'WARNING: The command completed successfully but no settings of 'Default' have been modified.', it menas the setting is already ENABLED.
Set-MalwareFilterPolicy -Identity Default -EnableFileFilter $true

# Validate - ensure that 'EnableFileFilter' is set to 'True'.
Get-MalwareFilterPolicy -Identity Default | Select-Object EnableFileFilter


## 2.1.3 (L1) Ensure notifications for internal users sending malware is Enabled (Automated)
# Enable
Set-MalwareFilterPolicy -Identity 'Default' -EnableInternalSenderAdminNotifications $True -InternalSenderAdminAddress blueteam@redbackops.com

# Validate
Get-MalwareFilterPolicy | Format-List Identity, EnableInternalSenderAdminNotifications, InternalSenderAdminAddress


## 2.1.4 (L2) Ensure Safe Attachments policy is enabled (Automated)
<#
https://learn.microsoft.com/en-us/defender-office-365/safe-attachments-policies-configure
Creating a Safe Attachments policy in PowerShell is a two-step process:
1. Create the safe attachment policy.
2. Create the safe attachment rule that specifies the safe attachment policy that the rule applies to.
#>

# Create Policy
$params = @{ 
    Name = "Redback_CIS_SafeAttachmentsPolicy_All"
    AdminDisplayName  = "Custom Safe Attachments Policy for all domains as per - CIS Benchmark 2.1.4 (L2) Ensure Safe Attachments policy is enabled."
    Enable = $true
    Action = "Block"
    Redirect = $true
    RedirectAddress = "blueteam@redbackops.com"
    QuarantineTag = "AdminOnlyAccessPolicy"
}
New-SafeAttachmentPolicy @params

# Create Rule
New-SafeAttachmentRule -Name "Redback_CIS_SafeAttachmentsRule_All" -SafeAttachmentPolicy "Redback_CIS_SafeAttachmentsPolicy_All" -RecipientDomainIs (Get-AcceptedDomain).Name -Priority 0

# Validate
# Get-SafeAttachmentPolicy | where-object {$_.Enable -eq "True"}
Get-SafeAttachmentPolicy -Identity "Redback_CIS_SafeAttachmentsPolicy_All"
Get-SafeAttachmentRule -Identity "Redback_CIS_SafeAttachmentsRule_All"


## 2.1.5 (L2) Ensure Safe Attachments for SharePoint, OneDrive, and Microsoft Teams is Enabled (Automated)
# Enable
# Note: If you get 'WARNING: The command completed successfully but no settings of 'Default' have been modified.', it menas the setting is already ENABLED.
Set-AtpPolicyForO365 -EnableATPForSPOTeamsODB $true -EnableSafeDocs $true -AllowSafeDocsOpen $false

# Validate
Get-AtpPolicyForO365 | Format-List Name,EnableATPForSPOTeamsODB,EnableSafeDocs,AllowSafeDocsOpen
<#
Verify the values for each parameter as below:
EnableATPForSPOTeamsODB : True
EnableSafeDocs : True
AllowSafeDocsOpen : False
#>


## 2.1.6 (L1) Ensure Exchange Online Spam Policies are set to notify administrators (Automated)
# Create Policy
$BccEmailAddress = @("blueteam@redbackops.com")
$NotifyEmailAddress = @("blueteam@redbackops.com")

Set-HostedOutboundSpamFilterPolicy -Identity Default -BccSuspiciousOutboundAdditionalRecipients $BccEmailAddress -BccSuspiciousOutboundMail $true -NotifyOutboundSpam $true -NotifyOutboundSpamRecipients $NotifyEmailAddress

# Validate - Verify both BccSuspiciousOutboundMail and NotifyOutboundSpam are set to True and the email addresses to be notified are correct.
Get-HostedOutboundSpamFilterPolicy | Select-Object Bcc*, Notify*


## 2.1.7 (L2) Ensure that an anti-phishing policy has been created (Automated)
# Create Policy
$params = @{ 
    Name = "Redback_CIS_AntiPhishingPolicy"
    PhishThresholdLevel = 3 
    EnableTargetedUserProtection = $true 
    EnableOrganizationDomainsProtection = $true 
    EnableMailboxIntelligence = $true 
    EnableMailboxIntelligenceProtection = $true 
    EnableSpoofIntelligence = $true 
    TargetedUserProtectionAction = 'Quarantine' 
    TargetedDomainProtectionAction = 'Quarantine' 
    MailboxIntelligenceProtectionAction = 'Quarantine' 
    TargetedUserQuarantineTag = 'DefaultFullAccessWithNotificationPolicy' 
    MailboxIntelligenceQuarantineTag = 'DefaultFullAccessWithNotificationPolicy' 
    TargetedDomainQuarantineTag = 'DefaultFullAccessWithNotificationPolicy' 
    EnableFirstContactSafetyTips = $true 
    EnableSimilarUsersSafetyTips = $true 
    EnableSimilarDomainsSafetyTips = $true 
    EnableUnusualCharactersSafetyTips = $true 
    HonorDmarcPolicy = $true
} 
    
New-AntiPhishPolicy @params 

# Create the rule for all users in all valid domains and associate with Policy 
New-AntiPhishRule -Name $params.Name -AntiPhishPolicy $params.Name -RecipientDomainIs (Get-AcceptedDomain).Name -Priority 0

# Validate - Verify there is a policy created the matches the values for the following parameters
$params = @( 
    "name","Enabled","PhishThresholdLevel","EnableTargetedUserProtection" 
    "EnableOrganizationDomainsProtection","EnableMailboxIntelligence" 
    "EnableMailboxIntelligenceProtection","EnableSpoofIntelligence" 
    "TargetedUserProtectionAction","TargetedDomainProtectionAction" 
    "MailboxIntelligenceProtectionAction","EnableFirstContactSafetyTips" 
    "EnableSimilarUsersSafetyTips","EnableSimilarDomainsSafetyTips" 
    "EnableUnusualCharactersSafetyTips","TargetedUsersToProtect" 
    "HonorDmarcPolicy" )
Get-AntiPhishPolicy | Format-List $params

<# 
# Verify there is a policy created the matches the values for the following parameters
Enabled : True 
PhishThresholdLevel : 3 
EnableTargetedUserProtection : True 
EnableOrganizationDomainsProtection : True 
EnableMailboxIntelligence : True 
EnableMailboxIntelligenceProtection : True 
EnableSpoofIntelligence : True 
TargetedUserProtectionAction : Quarantine 
TargetedDomainProtectionAction : Quarantine 
MailboxIntelligenceProtectionAction : Quarantine 
EnableFirstContactSafetyTips : True 
EnableSimilarUsersSafetyTips : True 
EnableSimilarDomainsSafetyTips : True 
EnableUnusualCharactersSafetyTips : True 
TargetedUsersToProtect : {<contains users>} 
HonorDmarcPolicy : True 

# Verify that TargetedUsersToProtect contains a subset of the organization, up to 350 users, for targeted Impersonation Protection.
#>

# Validate - verify the AntiPhishRule is configured and enabled
Get-AntiPhishRule | Format-Table AntiPhishPolicy,Priority,State,SentToMemberOf,RecipientDomainIs


## 2.1.11 (L2) Ensure comprehensive attachment filtering is applied (Automated)
# Create an attachment policy and associated rule to block 186 malicious file types. The rule is # intentionally disabled allowing the org to enable it when ready 
$Policy = @{ 
    Name = "Redback_CIS_L2AttachmentPolicy" 
    EnableFileFilter = $true 
    ZapEnabled = $true 
    EnableInternalSenderAdminNotifications = $true 
    InternalSenderAdminAddress = 'blueteam@redbackops.com'
} 

$L2Extensions = @( 
    "7z", "a3x", "ace", "ade", "adp", "ani", "app", "appinstaller",
    "applescript", "application", "appref-ms", "appx", "appxbundle", "arj",
    "asd", "asx", "bas", "bat", "bgi", "bz2", "cab", "chm", "cmd", "com",
    "cpl", "crt", "cs", "csh", "daa", "dbf", "dcr", "deb",
    "desktopthemepackfile", "dex", "diagcab", "dif", "dir", "dll", "dmg",
    "doc", "docm", "dot", "dotm", "elf", "eml", "exe", "fxp", "gadget", "gz",
    "hlp", "hta", "htc", "htm", "htm", "html", "html", "hwpx", "ics", "img",
    "inf", "ins", "iqy", "iso", "isp", "jar", "jnlp", "js", "jse", "kext",
    "ksh", "lha", "lib", "library-ms", "lnk", "lzh", "macho", "mam", "mda",
    "mdb", "mde", "mdt", "mdw", "mdz", "mht", "mhtml", "mof", "msc", "msi",
    "msix", "msp", "msrcincident", "mst", "ocx", "odt", "ops", "oxps", "pcd",
    "pif", "plg", "pot", "potm", "ppa", "ppam", "ppkg", "pps", "ppsm", "ppt",
    "pptm", "prf", "prg", "ps1", "ps11", "ps11xml", "ps1xml", "ps2",
    "ps2xml", "psc1", "psc2", "pub", "py", "pyc", "pyo", "pyw", "pyz",
    "pyzw", "rar", "reg", "rev", "rtf", "scf", "scpt", "scr", "sct",
    "searchConnector-ms", "service", "settingcontent-ms", "sh", "shb", "shs",
    "shtm", "shtml", "sldm", "slk", "so", "spl", "stm", "svg", "swf", "sys",
    "tar", "theme", "themepack", "timer", "uif", "url", "uue", "vb", "vbe",
    "vbs", "vhd", "vhdx", "vxd", "wbk", "website", "wim", "wiz", "ws", "wsc",
    "wsf", "wsh", "xla", "xlam", "xlc", "xll", "xlm", "xls", "xlsb", "xlsm",
    "xlt", "xltm", "xlw", "xnk", "xps", "xsl", "xz", "z"
) 
# Create the policy 
New-MalwareFilterPolicy @Policy -FileTypes $L2Extensions 

# Create the rule for all accepted domains 
$Rule = @{ Name = 
    $Policy.Name 
    Enabled = $true
    MalwareFilterPolicy = $Policy.Name 
    RecipientDomainIs = (Get-AcceptedDomain).Name 
    Priority = 0 
}
New-MalwareFilterRule @Rule

# Validate - Confirm the Policy Was Created
Get-MalwareFilterPolicy -Identity "Redback_CIS_L2AttachmentPolicy"

# Validate - Confirm the Rule Was Created and Applied
Get-MalwareFilterRule -Identity "Redback_CIS_L2AttachmentPolicy" | Format-List Name,Enabled,MalwareFilterPolicy,RecipientDomainIs

# Validate - Evaluate each Malware policy. If one exist with more than 120 extensionsthen the script will output a report showing a list of missing extensions along with other parameters.
$L2Extensions = @(
    "7z", "a3x", "ace", "ade", "adp", "ani", "app", "appinstaller",
    "applescript", "application", "appref-ms", "appx", "appxbundle", "arj",
    "asd", "asx", "bas", "bat", "bgi", "bz2", "cab", "chm", "cmd", "com",
    "cpl", "crt", "cs", "csh", "daa", "dbf", "dcr", "deb",
    "desktopthemepackfile", "dex", "diagcab", "dif", "dir", "dll", "dmg",
    "doc", "docm", "dot", "dotm", "elf", "eml", "exe", "fxp", "gadget", "gz",
    "hlp", "hta", "htc", "htm", "htm", "html", "html", "hwpx", "ics", "img",
    "inf", "ins", "iqy", "iso", "isp", "jar", "jnlp", "js", "jse", "kext",
    "ksh", "lha", "lib", "library-ms", "lnk", "lzh", "macho", "mam", "mda",
    "mdb", "mde", "mdt", "mdw", "mdz", "mht", "mhtml", "mof", "msc", "msi",
    "msix", "msp", "msrcincident", "mst", "ocx", "odt", "ops", "oxps", "pcd",
    "pif", "plg", "pot", "potm", "ppa", "ppam", "ppkg", "pps", "ppsm", "ppt",
    "pptm", "prf", "prg", "ps1", "ps11", "ps11xml", "ps1xml", "ps2",
    "ps2xml", "psc1", "psc2", "pub", "py", "pyc", "pyo", "pyw", "pyz",
    "pyzw", "rar", "reg", "rev", "rtf", "scf", "scpt", "scr", "sct",
    "searchConnector-ms", "service", "settingcontent-ms", "sh", "shb", "shs",
    "shtm", "shtml", "sldm", "slk", "so", "spl", "stm", "svg", "swf", "sys",
    "tar", "theme", "themepack", "timer", "uif", "url", "uue", "vb", "vbe",
    "vbs", "vhd", "vhdx", "vxd", "wbk", "website", "wim", "wiz", "ws", "wsc",
    "wsf", "wsh", "xla", "xlam", "xlc", "xll", "xlm", "xls", "xlsb", "xlsm",
    "xlt", "xltm", "xlw", "xnk", "xps", "xsl", "xz", "z"
)

$MissingCount = 0
$ExtensionPolicies = $null
$RLine = $ExtensionReport = @()
$FilterRules = Get-MalwareFilterRule
$DateTime = $(((Get-Date).ToUniversalTime()).ToString("yyyyMMddTHHmmssZ"))
$OutputFilePath = "$PWD\CIS-Report_$($DateTime).txt"

$RLine += "$(Get-Date)`n"
function Test-MalwarePolicy {
    param (
        $PolicyId
    )

    # Find the matching rule for custom policies
    $FoundRule = $null
    $FoundRule = $FilterRules | Where-Object { $_.MalwareFilterPolicy -eq $PolicyId }

    if ($PolicyId.EnableFileFilter -eq $false) {
        $script:RLine += "WARNING: Common attachments filter is disabled."
    }
    if ($FoundRule.State -eq 'Disabled') {
        $script:RLine += "WARNING: The Anti-malware rule is disabled."
    }

    $script:RLine += "`nManual review needed - Domains, inclusions and exclusions must be valid:"
    $script:RLine += $FoundRule | Format-List Name, RecipientDomainIs, Sent*, Except*
}

# Match any policy that has over 120 extensions defined
$ExtensionPolicies = Get-MalwareFilterPolicy | Where-Object {$_.FileTypes.Count -gt 120 }

if (!$ExtensionPolicies) {
    Write-Host "`nFAIL: A policy containing the minimum number of extensions was not found." -ForegroundColor Red

    Write-Host "Only policies with over 120 extensions defined will be evaluated." -ForegroundColor Red
    
    Exit
}

# Check each policy for missing extensions
foreach ($policy in $ExtensionPolicies) {
    $MissingExtensions = $L2Extensions |
        Where-Object {
            $extension = $_; -not $policy.FileTypes.Contains($extension)
        }

    if ($MissingExtensions.Count -eq 0) {
        $RLine += "-" * 60
        $RLine += "[FOUND] $($policy.Identity)"
        $RLine += "-" * 60
        $RLine += "PASS: Policy contains all extensions"
        Test-MalwarePolicy -PolicyId $policy
    } else {
        $MissingCount++
        $ExtensionReport += @{
            Identity = $policy.Identity
            MissingExtensions = $MissingExtensions -join ', '
        }
    }
}

if ($MissingCount -gt 0) {
    foreach ($fpolicy in $ExtensionReport) {
        $RLine += "-" * 60
        $RLine += "[PARTIAL] $($fpolicy.Identity)"
        $RLine += "-" * 60
        $RLine += "NOTICE - The following extensions were not found:`n"
        $RLine += "$($fpolicy.MissingExtensions)`n"
        Test-MalwarePolicy -PolicyId $fpolicy.Identity
    }
}

# Output the report to a text file
Out-File -FilePath $OutputFilePath -InputObject $RLine
Get-Content $OutputFilePath
Write-Host "`nLog file exported to" $OutputFilePath


## 2.1.12 (L1) Ensure the connection filter IP allow list is not used (Automated)
# Remove any IP entries (IP addresses or adress ranges) from the Connection Filter Policy
Set-HostedConnectionFilterPolicy -Identity Default -IPAllowList @{}

# Validate
Get-HostedConnectionFilterPolicy -Identity Default | Format-List IPAllowList


## 2.1.13 (L1) Ensure the connection filter safe list is off (Automated)
# Set the connection filter safe list state to Off or False
Set-HostedConnectionFilterPolicy -Identity Default -EnableSafeList $false

# Validate - Ensure Safe list is Off
Get-HostedConnectionFilterPolicy -Identity Default | Format-List EnableSafeList


## 2.1.14 (L1) Ensure inbound anti-spam policies do not contain allowed domains (Automated)
# Remove allowed domains from all inbound anti-spam policies:
$AllowedDomains = Get-HostedContentFilterPolicy | Where-Object {$_.AllowedSenderDomains}
$AllowedDomains | Set-HostedContentFilterPolicy -AllowedSenderDomains @{}

# Validate - vertify that AllowedSenderDomains is undefined for each inbound policy.
Get-HostedContentFilterPolicy | Format-Table Identity,AllowedSenderDomains

## Disconnect from the Exchange Online session
Disconnect-ExchangeOnlineA