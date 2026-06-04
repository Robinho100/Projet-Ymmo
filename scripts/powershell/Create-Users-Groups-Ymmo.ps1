<#
.SYNOPSIS
    Création des groupes de sécurité et de l'utilisateur admin Stan.
#>

Import-Module ActiveDirectory

$GroupPath = "OU=YMMO_Groupes,DC=ymmo,DC=local"
$Groups = @("GS_Direction", "GS_Commercial", "GS_Marketing", "GS_Administratif", "GS_IT_Support")

foreach ($grp in $Groups) {
    if (-not (Get-ADGroup -Filter "Name -eq '$grp'")) {
        New-ADGroup -Name $grp -Path $GroupPath -GroupScope Global -GroupCategory Security
        Write-Host "👥 Groupe créé : $grp" -ForegroundColor Cyan
    }
}

# Création de l'utilisateur Stan (Admin Web/SQL)
$UserPath = "OU=IT,OU=YMMO_Siège,DC=ymmo,DC=local"
if (-not (Get-ADUser -Filter "SamAccountName -eq 'stan_admin'")) {
    $password = ConvertTo-SecureString "P@sswordYmmo2026!" -AsPlainText -Force
    New-ADUser -Name "Stan Admin" -SamAccountName "stan_admin" -Path $UserPath -AccountPassword $password -Enabled $true -PasswordNeverExpires $true
    Add-ADGroupMember -Identity "GS_IT_Support" -Members "stan_admin"
    Write-Host "👤 Utilisateur 'stan_admin' créé et ajouté à GS_IT_Support." -ForegroundColor Green
}
