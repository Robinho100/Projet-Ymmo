# ===============================================================================
# Ymmo Project - Active Directory Setup Script
# Purpose: Create security groups, OUs, and set permissions
# Target: Windows Server 2022 with Active Directory
# Author: Titouan (Lead INFRA)
# ===============================================================================

param(
    [string]$DomainName = "ymmo.local",
    [string]$RootOU = "OU=Ymmo",
    [string]$FilePath = "\\10.0.0.2\Partages"
)

# Color output helper
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red; exit 1 }

# ===============================================================================
# Create Organizational Units (OUs)
# ===============================================================================

function Create-OUs {
    Write-Info "Creating Organizational Units..."

    $RootDN = "DC=$($DomainName.Replace('.', ',DC='))"

    # Create main OU
    try {
        New-ADOrganizationalUnit -Name $RootOU.Replace("OU=", "") `
            -Path $RootDN `
            -ProtectedFromAccidentalDeletion $true `
            -ErrorAction SilentlyContinue
        Write-Success "Created OU: $RootOU"
    } catch {
        Write-Warning "OU already exists: $RootOU"
    }

    # Create sub-OUs
    $SubOUs = @("Users", "Groups", "Computers", "ServiceAccounts")

    foreach ($SubOU in $SubOUs) {
        $OUPath = "CN=$SubOU,$RootOU,$RootDN"
        try {
            New-ADOrganizationalUnit -Name $SubOU `
                -Path "$RootOU,$RootDN" `
                -ProtectedFromAccidentalDeletion $true `
                -ErrorAction SilentlyContinue
            Write-Success "Created OU: OU=$SubOU,$RootOU"
        } catch {
            Write-Warning "OU already exists: OU=$SubOU"
        }
    }
}

# ===============================================================================
# Create Security Groups
# ===============================================================================

function Create-SecurityGroups {
    Write-Info "Creating Security Groups..."

    $RootDN = "DC=$($DomainName.Replace('.', ',DC='))"
    $GroupOU = "OU=Groups,$RootOU,$RootDN"

    $Groups = @(
        @{
            Name = "GS_Direction"
            DisplayName = "Direction Ymmo"
            Description = "Membres de la direction générale"
        },
        @{
            Name = "GS_Commercial"
            DisplayName = "Équipe Commerciale"
            Description = "Agents commerciaux - Siège et agences"
        },
        @{
            Name = "GS_Marketing"
            DisplayName = "Équipe Marketing"
            Description = "Communication et Marketing"
        },
        @{
            Name = "GS_Administratif"
            DisplayName = "Équipe Administrative"
            Description = "RH, Juridique, Administratif"
        },
        @{
            Name = "GS_IT_Support"
            DisplayName = "IT Support"
            Description = "Équipe technique et support"
        }
    )

    foreach ($Group in $Groups) {
        try {
            New-ADGroup -Name $Group.Name `
                -SamAccountName $Group.Name `
                -GroupCategory Security `
                -GroupScope Global `
                -DisplayName $Group.DisplayName `
                -Description $Group.Description `
                -Path $GroupOU `
                -ErrorAction SilentlyContinue
            Write-Success "Created group: $($Group.Name)"
        } catch {
            Write-Warning "Group already exists: $($Group.Name)"
        }
    }
}

# ===============================================================================
# Create Shared Folder Structure
# ===============================================================================

function Create-SharedFolders {
    Write-Info "Creating shared folder structure..."

    $SharePath = "\\10.0.0.2\Partages"

    # Verify path exists
    if (-not (Test-Path "\\10.0.0.2\Partages")) {
        Write-Error "Share path not accessible: $SharePath"
    }

    $Folders = @(
        "01_Direction",
        "02_Commercial",
        "03_Marketing",
        "04_Administratif",
        "05_IT_Support"
    )

    foreach ($Folder in $Folders) {
        $Path = Join-Path $SharePath $Folder
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force
            Write-Success "Created folder: $Folder"
        } else {
            Write-Warning "Folder already exists: $Folder"
        }
    }
}

# ===============================================================================
# Set NTFS Permissions
# ===============================================================================

function Set-FolderPermissions {
    Write-Info "Setting NTFS permissions..."

    # Permission matrix (from docs/Matrice_Droits_Acces.md)
    $Permissions = @(
        @{ Folder = "01_Direction"; Group = "GS_Direction"; Right = "Modify" },
        @{ Folder = "01_Direction"; Group = "GS_Commercial"; Right = "Read" },
        @{ Folder = "01_Direction"; Group = "GS_Marketing"; Right = "Read" },
        @{ Folder = "01_Direction"; Group = "GS_Administratif"; Right = "Read" },

        @{ Folder = "02_Commercial"; Group = "GS_Commercial"; Right = "Modify" },
        @{ Folder = "02_Commercial"; Group = "GS_Direction"; Right = "Read" },
        @{ Folder = "02_Commercial"; Group = "GS_Marketing"; Right = "Read" },

        @{ Folder = "03_Marketing"; Group = "GS_Marketing"; Right = "Modify" },
        @{ Folder = "03_Marketing"; Group = "GS_Direction"; Right = "Read" },
        @{ Folder = "03_Marketing"; Group = "GS_Commercial"; Right = "Read" },

        @{ Folder = "04_Administratif"; Group = "GS_Administratif"; Right = "Modify" },
        @{ Folder = "04_Administratif"; Group = "GS_Direction"; Right = "Read" },
        @{ Folder = "04_Administratif"; Group = "GS_Commercial"; Right = "Read" },

        @{ Folder = "05_IT_Support"; Group = "GS_IT_Support"; Right = "Modify" },
        @{ Folder = "05_IT_Support"; Group = "GS_Direction"; Right = "Read" },
        @{ Folder = "05_IT_Support"; Group = "GS_Commercial"; Right = "Read" }
    )

    foreach ($Perm in $Permissions) {
        $Path = "\\10.0.0.2\Partages\$($Perm.Folder)"
        $Group = "$DomainName\$($Perm.Group)"

        try {
            $ACL = Get-Acl $Path
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $Group,
                [System.Security.AccessControl.FileSystemRights]::$($Perm.Right),
                [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
                [System.Security.AccessControl.PropagationFlags]::InheritOnly,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $ACL.AddAccessRule($AccessRule)
            Set-Acl -Path $Path -AclObject $ACL
            Write-Success "Set $($Perm.Right) for $($Perm.Group) on $($Perm.Folder)"
        } catch {
            Write-Warning "Failed to set permissions: $_"
        }
    }
}

# ===============================================================================
# Create Group Policy Objects (GPO)
# ===============================================================================

function Configure-GPO {
    Write-Info "Configuring Group Policy Objects..."

    # Password Policy
    Write-Info "Setting password complexity policy..."

    # Note: This requires GPMC (Group Policy Management Console) or direct registry editing
    # For now, we'll use secedit (Security Configuration Editor)

    $SecEditTemplate = @"
[Unicode]
Unicode=yes
[System Access]
MinimumPasswordAge = 1
MaximumPasswordAge = 90
MinimumPasswordLength = 12
PasswordComplexity = 1
PasswordHistorySize = 5
LockoutBadCount = 5
LockoutDuration = 30
ResetLockoutCount = 30
[Kerberos Policy]
MaxTicketAge = 10
MaxRenewAge = 7
MaxServiceAge = 600
MaxClockSkew = 5
TicketValidateClient = 1
"@

    # Save template
    $TemplatePath = "C:\Temp\security-policy.inf"
    Set-Content -Path $TemplatePath -Value $SecEditTemplate

    # Apply policy
    secedit /configure /db C:\Windows\Security\Database\secedit.sdb /cfg $TemplatePath

    Write-Success "Password policy configured"

    # Session Timeout Policy (10 minutes of inactivity)
    Write-Info "Setting session timeout policy..."

    # This requires domain-wide GPO deployment, shown as manual step
    Write-Warning "Manual step required: Deploy GPO 'Screen Lock - 10min' via GPMC"
}

# ===============================================================================
# Main Execution
# ===============================================================================

function Main {
    Write-Host "=============================================="
    Write-Host "Ymmo Active Directory Configuration"
    Write-Host "Domain: $DomainName"
    Write-Host "=============================================="
    Write-Host ""

    # Verify running as admin
    $IsAdmin = ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')
    if (-not $IsAdmin) {
        Write-Error "This script must run as Administrator"
    }

    # Execute setup phases
    Create-OUs
    Create-SecurityGroups
    Create-SharedFolders
    Set-FolderPermissions
    Configure-GPO

    Write-Host ""
    Write-Success "Active Directory setup complete!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Info "1. Add users to security groups via Active Directory Users & Computers"
    Write-Info "2. Deploy GPO 'Screen Lock Timeout' via Group Policy Management"
    Write-Info "3. Test file permissions: net use X: $FilePath\01_Direction"
}

# Execute main function
Main
