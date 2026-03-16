# GitHub API URL für dein Hauptverzeichnis
$apiUrl = "https://api.github.com/repos/Shorxi/Local_Copilot-API_for_Windows/contents/"

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

# Markierung
$marked = "$($selected.name) (01)"

Write-Host ""
Write-Host "Ausgewählt: $marked" -ForegroundColor Green
Write-Host "GitHub-Pfad:" -ForegroundColor Yellow
Write-Host $fullPath -ForegroundColor Cyan
