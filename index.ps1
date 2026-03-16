# ============================================
# GitHub Index Tool – Version 3
# ============================================

# Basis-API-URL
$baseApi = "https://api.github.com/repos/Shorxi/Local_Copilot-API_for_Windows/contents/"
$indexFile = "index.txt"

# Index-Datei anlegen, falls nicht vorhanden
if (!(Test-Path $indexFile)) {
    New-Item $indexFile -ItemType File | Out-Null
}

# Funktion: GitHub-Dateien laden
function Get-GitHubFiles {
    param([string]$Path = "")

    $url = $baseApi + $Path
    return Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "PowerShell" }
}

# Funktion: Dateien anzeigen
function Show-Files {
    param([string]$Path = "")

    $response = Get-GitHubFiles -Path $Path
    $files = $response | Where-Object { $_.type -eq "file" }

    Write-Host "`n=== Dateien im Repository ===" -ForegroundColor White
    for ($i = 0; $i -lt $files.Count; $i++) {
        Write-Host "$($i+1)) $($files[$i].name)"
    }

    return $files
}

# Funktion: Unterordner anzeigen
function Show-Folders {
    $response = Get-GitHubFiles
    $folders = $response | Where-Object { $_.type -eq "dir" }

    Write-Host "`n=== Unterordner ===" -ForegroundColor White
    for ($i = 0; $i -lt $folders.Count; $i++) {
        Write-Host "$($i+1)) $($folders[$i].name)"
    }

    return $folders
}

# Funktion: Datei markieren
function Mark-File {
    $files = Show-Files
    $choice = Read-Host "`nWelche Datei möchtest du markieren?"
    $index = [int]$choice - 1

    if ($index -lt 0 -or $index -ge $files.Count) {
        Write-Host "Ungültige Auswahl!" -ForegroundColor Red
        return
    }

    $selected = $files[$index]
    $fullPath = $selected.html_url

    # Automatische Nummerierung
    $existing = Get-Content $indexFile
    $nextNumber = "{0:D2}" -f ($existing.Count + 1)

    # Markierung
    $entry = "$nextNumber - $($selected.name) - $fullPath"
    Add-Content -Path $indexFile -Value $entry

    Write-Host "`nMarkiert:" -ForegroundColor Green
    Write-Host $entry -ForegroundColor Cyan
}

# Funktion: Markierungen anzeigen
function Show-Index {
    Write-Host "`n=== Markierungen ===" -ForegroundColor Yellow
    if ((Get-Content $indexFile).Count -eq 0) {
        Write-Host "Noch keine Markierungen vorhanden." -ForegroundColor DarkGray
    } else {
        Get-Content $indexFile
    }
}

# Hauptmenü
function Menu {
    while ($true) {
        Write-Host "`n=== GitHub Index Tool – Version 3 ===" -ForegroundColor White
        Write-Host "1) Dateien anzeigen"
        Write-Host "2) Datei markieren"
        Write-Host "3) Markierungen anzeigen"
        Write-Host "4) Unterordner anzeigen"
        Write-Host "5) Beenden"

        $choice = Read-Host "`nAuswahl"

        switch ($choice) {
            "1" { Show-Files }
            "2" { Mark-File }
            "3" { Show-Index }
            "4" { Show-Folders }
            "5" { Write-Host "Beendet." -ForegroundColor Red; exit }
            default { Write-Host "Ungültige Eingabe!" -ForegroundColor Red }
        }
    }
}

# Start
Menu

