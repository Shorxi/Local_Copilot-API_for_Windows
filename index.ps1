# GitHub API URL für dein Hauptverzeichnis
$apiUrl = "https://api.github.com/repos/Shorxi/Local_Copilot-API_for_Windows/contents/"

# Datei für gespeicherte Markierungen
$indexFile = "index.txt"

# Falls Datei nicht existiert → erstellen
if (!(Test-Path $indexFile)) {
    New-Item $indexFile -ItemType File | Out-Null
}

# GitHub API aufrufen
$response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

# Nur Dateien filtern
$files = $response | Where-Object { $_.type -eq "file" }

Write-Host "=== Dateien im GitHub-Repository ===" -ForegroundColor White

# Liste anzeigen
for ($i = 0; $i -lt $files.Count; $i++) {
    Write-Host "$($i+1)) $($files[$i].name)"
}

# Auswahl
$choice = Read-Host "Welche Datei möchtest du markieren?"

# Index berechnen
$index = [int]$choice - 1

# Datei auswählen
$selected = $files[$index]

# GitHub-Link erzeugen
$fullPath = $selected.html_url

# Automatische Nummerierung
$existing = Get-Content $indexFile
$nextNumber = "{0:D2}" -f ($existing.Count + 1)

# Markierung erstellen
$marked = "$nextNumber - $($selected.name) - $fullPath"

# In Datei speichern
Add-Content -Path $indexFile -Value $marked

Write-Host ""
Write-Host "=== Neue Markierung gespeichert ===" -ForegroundColor Green
Write-Host $marked -ForegroundColor Cyan

Write-Host ""
Write-Host "=== Gesamte Historie ===" -ForegroundColor Yellow
Get-Content $indexFile
