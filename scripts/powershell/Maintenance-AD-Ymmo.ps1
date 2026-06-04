<#
.SYNOPSIS
    Activation des fonctionnalités de maintenance AD pour Ymmo.
    Responsable : Stan
#>

Import-Module ActiveDirectory

# 1. Activation de la Corbeille AD
$DomainDN = (Get-ADDomain).DistinguishedName
Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $DomainDN -Confirm:$false
Write-Host "♻️ Corbeille Active Directory activée pour $DomainDN" -ForegroundColor Green

# 2. Vérification du Catalogue Global
Set-ADDomainController -Identity $env:COMPUTERNAME -IsGlobalCatalog $true
Write-Host "🌍 Serveur promu en tant que Catalogue Global (GC)." -ForegroundColor Green

# 3. Vérification des rôles FSMO
$fsmo = Get-ADDomain | Select-Object InfrastructureMaster, PDCEmulator, RIDMaster
Write-Host "👑 Détenteurs des rôles FSMO (Domaine) : $($fsmo.PDCEmulator)" -ForegroundColor Cyan
