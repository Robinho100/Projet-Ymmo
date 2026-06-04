<#
.SYNOPSIS
    Installation des services AD DS et promotion du DC pour Ymmo.
    
.DESCRIPTION
    Domaine : ymmo.local
    NetBIOS : YMMO
#>

$DomainName = "ymmo.local"
$NetbiosName = "YMMO"
$LogPath = "C:\Users\raykx\Projet-Ymmo\logs\ADDS_Deployment.log"

Write-Host "🚀 Installation de l'Active Directory pour $DomainName..." -ForegroundColor Cyan

# Installation des binaires
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promotion du DC
Import-Module ADDSDeployment
Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true
