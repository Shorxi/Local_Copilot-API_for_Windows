# Basis-URL deines GitHub-Hauptverzeichnisses
$baseUrl = "https://github.com/Shorxi/Local_Copilot-API_for_Windows/tree/main/"

# Lokale Dateien im Ordner einlesen
$files = Get-ChildItem -File

Write-Host "=== Dateien im Repository ===" -ForegroundColor White

# Liste anzeigen
for ($i = 0; $i -lt $files.Count; $i++) {
    Write-Host "$($i+1)) $($files[$i].Name)"
}

# Auswahl
$choice = Read-Host "Welche Datei möchtest du markieren?"

# Index berechnen
$index = [int]$choice - 1

# Datei auswählen
$selected = $files[$index].Name

# GitHub-Link erzeugen
$fullPath = $baseUrl + $selected

# Markierung
$marked = "$selected (01)"

Write-Host ""
Write-Host "Ausgewählt: $marked" -ForegroundColor Green
Write-Host "GitHub-Pfad:" -ForegroundColor Yellow
Write-Host $fullPath -ForegroundColor Cyan
