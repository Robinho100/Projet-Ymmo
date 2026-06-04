<#
.SYNOPSIS
    Génération de la hiérarchie des OUs pour Ymmo.
#>

Import-Module ActiveDirectory

$BaseDN = "DC=ymmo,DC=local"

# 1. Création des OUs de base
$TopOUs = @("YMMO_Siège", "YMMO_Agences", "YMMO_Groupes", "YMMO_Serveurs")

foreach ($ou in $TopOUs) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'")) {
        New-ADOrganizationalUnit -Name $ou -Path $BaseDN -ProtectedFromAccidentalDeletion $true
        Write-Host "✅ OU Créée : $ou" -ForegroundColor Green
    }
}

# 2. Sous-OUs Siège
$SiegePath = "OU=YMMO_Siège,$BaseDN"
$SiegeSubOUs = @("Direction", "Marketing", "IT", "Administratif")

foreach ($sub in $SiegeSubOUs) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$sub' -and DistinguishedName -like '*$SiegePath*'")) {
        New-ADOrganizationalUnit -Name $sub -Path $SiegePath -ProtectedFromAccidentalDeletion $true
        Write-Host "  └─ ✅ Sous-OU Siège : $sub" -ForegroundColor Green
    }
}

# 3. Sous-OUs Agences (12 agences)
$AgencePath = "OU=YMMO_Agences,$BaseDN"
for ($i=1; $i -le 12; $i++) {
    $name = "Agence_$( "{0:D2}" -f $i )"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$name'")) {
        New-ADOrganizationalUnit -Name $name -Path $AgencePath -ProtectedFromAccidentalDeletion $true
        Write-Host "  └─ ✅ Sous-OU Agence : $name" -ForegroundColor Green
    }
}
