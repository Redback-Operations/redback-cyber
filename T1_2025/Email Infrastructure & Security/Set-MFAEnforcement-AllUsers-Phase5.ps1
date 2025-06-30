<# Enforce MFA for all user accounts when accessing any Microsoft 365 (including Exchange Online) or Azure cloud services. #>

# Install the Microsoft Graph PowerShell SDK (if not already installed)
Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber

# Temporarily set the execution policy to bypass restrictions for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Import the Microsoft Graph PowerShell module
Import-Module Microsoft.Graph.Identity.SignIns

# Connect to Microsoft Graph with the required scope for Conditional Access policies.
# Connect to using an account with 'Global Administrator' permissions.
Connect-MgGraph -Scopes `
    "Policy.Read.All", `
    "Policy.ReadWrite.ConditionalAccess"


## 15.1. IMPLEMENT - Define and create a Conditional Access policy for MFA enforcement
# Get object IDs for breakglass accounts
$excludeUser1 = Get-MgUser -UserId "admin-breakglass-1@redbackops.com"
$excludeUser2 = Get-MgUser -UserId "admin-breakglass-2@redbackops.com"

# Define the Conditional Access Policy
$policy = @{
    displayName = "RedbackOps – Enforce MFA for All Users (All Apps)"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("All")
            # Exclude your breakglass accounts.
            # Consult with the Security Team leader for breakglass account/s.
            excludeUsers = @($excludeUser1.Id, $excludeUser2.Id)
        }
        applications = @{
            includeApplications = @("All")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("mfa")
    }
}

# Create the Conditional Access policy
New-MgIdentityConditionalAccessPolicy -BodyParameter $policy

## 15.2 VALIDATE - Confirm that the Conditional Access Policy exists and is applied
# Get the Conditional Access Policy ID based on display name
$policy = Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "RedbackOps – Enforce MFA for All Users (All Apps)" }

# Use the policy ID to get the policy details
Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id | Format-List

