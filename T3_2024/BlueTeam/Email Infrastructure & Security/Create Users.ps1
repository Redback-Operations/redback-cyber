# Install Azure AD module
Install-Module -Name AzureAD

# Import the Azure AD module
Import-Module -Name AzureAD

# Connect to Azure AD
Connect-AzureAD

# Path to the CSV file
$csvPath = "users.csv"

# Validate the CSV file exists
if (-not (Test-Path -Path $csvPath)) {
    Write-Host "CSV file not found at path: $csvPath"
    exit
}

# Import CSV data
$userData = Import-Csv -Path $csvPath

# Loop through each row in the CSV
foreach ($user in $userData) {
	# Create Password Profile
    $passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $passwordProfile.Password = $user.Password
    $passwordProfile.ForceChangePasswordNextLogin = $true

    # Create user parameters
    $userParams = @{
        GivenName          = $user.FirstName
        Surname            = $user.LastName
        DisplayName        = "$($user.FirstName) $($user.LastName)"
        UserPrincipalName  = "$($user.Username)@redbackops.com"
        $passwordProfile   = $passwordProfile
        AccountEnabled     = $true
    }

    try {
        # Create the user
        New-AzureADUser @userParams

        # Output status
        Write-Host "Created user: $($user.Username)"
    }
    catch {
        Write-Host "Error creating user $($user.Username): $_"
    }
}

Write-Host "All users processed."
