<#
.SYNOPSIS
    Configuration des GPO de sécurité pour Ymmo (CNIL & USB).
    Responsable : Titouan
#>

Import-Module GroupPolicy

$Domain = "ymmo.local"

# 1. GPO CNIL-Hardening
$GpoCnil = "YMMO-Sécurité-CNIL"
if (-not (Get-GPO -Name $GpoCnil -Domain $Domain -ErrorAction SilentlyContinue)) {
    New-GPO -Name $GpoCnil -Comment "Politiques de mots de passe et verrouillage (Normes CNIL 2026)"
    Write-Host "✅ GPO $GpoCnil créée." -ForegroundColor Green
    # Note : Les paramètres spécifiques seraient appliqués ici via Set-GPPrefRegistryValue
}

# 2. GPO Blocage USB
$GpoUsb = "YMMO-Blocage-USB"
if (-not (Get-GPO -Name $GpoUsb -Domain $Domain -ErrorAction SilentlyContinue)) {
    New-GPO -Name $GpoUsb -Comment "Interdiction des périphériques de stockage amovibles"
    Write-Host "✅ GPO $GpoUsb créée." -ForegroundColor Green
}

# 3. Liaison aux OUs
$OUs = @("OU=YMMO_Siège,DC=ymmo,DC=local", "OU=YMMO_Agences,DC=ymmo,DC=local")
foreach ($ou in $OUs) {
    New-GPLink -Name $GpoCnil -Target $ou
    New-GPLink -Name $GpoUsb -Target $ou
    Write-Host "🔗 GPOs liées à l'OU : $ou" -ForegroundColor Cyan
}
