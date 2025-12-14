[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

Write-Host "🗑️  Deleting resource group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "Are you sure you want to delete the resource group and ALL resources? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "❌ Cleanup cancelled" -ForegroundColor Red
    exit 0
}

Write-Host "Deleting resource group (this may take a few minutes)..." -ForegroundColor Yellow
az group delete --name $ResourceGroupName --yes --no-wait

Write-Host "✓ Deletion initiated" -ForegroundColor Green
Write-Host ""
Write-Host "To check deletion status:" -ForegroundColor Cyan
Write-Host "  az group show --name $ResourceGroupName" -ForegroundColor Gray
