<#
This script helps you to Bulk Create Users using Microsoft Graph PowerShell Module.
It processes user data from a CSV file and creates users in Entra ID (formerly Azure AD).

Instructions:
- You can use 'Powershell', 'Windows PowerShell ISE', or 'Visual Studio Code' to run this. Ensure to 'Run as Administrator'.
- Ensure to use an account with either 'Global Administrator' or 'User Management Administrator' role permissions.
- The CSV file must include the following columns: FirstName, LastName, Username, Password.
#>

## Temporarily set the execution policy to bypass any restrictions for the current session.
Set-ExecutionPolicy Bypass -Scope Process -Force

## Install Microsoft Graph Module (if not already installed)
Install-Module -Name Microsoft.Graph.Users -Scope AllUsers

## Import the Graph Users Module
Import-Module -Name Microsoft.Graph.Users

## Connect to Microsoft Graph
Connect-MgGraph -Scopes User.ReadWrite.All

## Path to the CSV file
$csvPath = "users.csv"

# Validate the CSV file exists
if (-not (Test-Path -Path $csvPath)) {
    Write-Host "CSV file not found at path: $csvPath"
    exit
}

## Import CSV data
$users = Import-Csv -Path $csvPath

## Loop through each row in the CSV
foreach ($user in $users) {
	# Create Password Profile
    $PasswordProfile = @{
        Password                      = $User.Password
        ForceChangePasswordNextSignIn = $true
    }

    # Create user parameters
    $NewUserParams = @{
        GivenName          = $user.FirstName
        Surname            = $user.LastName
        DisplayName        = "$($user.FirstName) $($user.LastName)"
        UserPrincipalName  = "$($user.Username)@redbackops.com"
        MailNickName       = $User.Username
        PasswordProfile    = $PasswordProfile
        AccountEnabled     = $true
    }

    try {
        # Create the user
        New-MgUser @NewUserParams -ErrorAction Stop | Out-Null

        # Output status
        Write-Host "Created user: $($user.Username)"
    }
    catch {
        Write-Host "Error creating user $($user.Username): $_"
    }
}

Write-Host "All users processed."
