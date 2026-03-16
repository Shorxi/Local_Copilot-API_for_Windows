# ============================================
# GitHub Index Tool – Full Version
# Repo: Shorxi/Local_Copilot-API_for_Windows
# ============================================

$Owner = "Shorxi"
$Repo  = "Local_Copilot-API_for_Windows"
$BaseApi = "https://api.github.com/repos/$Owner/$Repo/contents"
$IndexJson = "index.json"
$IndexMarkdown = "index.md"

# Index-Datei initialisieren
if (!(Test-Path $IndexJson)) {
    @() | ConvertTo-Json | Out-File -FilePath $IndexJson -Encoding UTF8
}

function Get-Index {
    if (!(Test-Path $IndexJson)) {
        return @()
    }
    $raw = Get-Content $IndexJson -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }
    try {
        return $raw | ConvertFrom-Json
    } catch {
        return @()
    }
}

function Save-Index($index) {
    $index | ConvertTo-Json -Depth 5 | Out-File -FilePath $IndexJson -Encoding UTF8
}

function Get-NextNumber {
    $index = Get-Index
    if ($index.Count -eq 0) {
        return "01"
    }
    $nums = $index.Number | ForEach-Object { [int]$_ }
    $next = ($nums | Measure-Object -Maximum).Maximum + 1
    return "{0:D2}" -f $next
}

function Get-GitHubItems {
    param(
        [string]$Path = ""
    )
    $url = if ([string]::IsNullOrWhiteSpace($Path)) {
        $BaseApi
    } else {
        "$BaseApi/$Path"
    }

    Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "PowerShell" }
}

function Show-Items {
    param(
        [string]$Path = ""
    )

    $items = Get-GitHubItems -Path $Path

    $folders = $items | Where-Object { $_.type -eq "dir" }
    $files   = $items | Where-Object { $_.type -eq "file" }

    Write-Host ""
    Write-Host "=== Inhalt von: /$Path ===" -ForegroundColor White

    if ($folders.Count -gt 0) {
        Write-Host ""
        Write-Host "[Ordner]" -ForegroundColor Yellow
        for ($i = 0; $i -lt $folders.Count; $i++) {
            Write-Host "D$($i+1)) $($folders[$i].name)" -ForegroundColor Yellow
        }
    }

    if ($files.Count -gt 0) {
        Write-Host ""
        Write-Host "[Dateien]" -ForegroundColor Cyan
        for ($i = 0; $i -lt $files.Count; $i++) {
            Write-Host "F$($i+1)) $($files[$i].name)" -ForegroundColor Cyan
        }
    }

    return [PSCustomObject]@{
        Path    = $Path
        Folders = $folders
        Files   = $files
    }
}

function Select-Path {
    param(
        [string]$CurrentPath = ""
    )

    $view = Show-Items -Path $CurrentPath
    $folders = $view.Folders

    if ($folders.Count -eq 0) {
        Write-Host "`nKeine Unterordner vorhanden." -ForegroundColor DarkGray
        return $CurrentPath
    }

    Write-Host ""
    $choice = Read-Host "Ordner wählen (D1, D2, ...), '..' für zurück, Enter für Abbruch"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return $CurrentPath
    }

    if ($choice -eq "..") {
        if ([string]::IsNullOrWhiteSpace($CurrentPath)) {
            return ""
        }
        $parts = $CurrentPath.Split("/") | Where-Object { $_ -ne "" }
        if ($parts.Count -le 1) {
            return ""
        } else {
            return ($parts[0..($parts.Count-2)] -join "/")
        }
    }

    if ($choice -like "D*") {
        $numStr = $choice.Substring(1)
        if (-not [int]::TryParse($numStr, [ref]$null)) {
            Write-Host "Ungültige Eingabe." -ForegroundColor Red
            return $CurrentPath
        }
        $idx = [int]$numStr - 1
        if ($idx -lt 0 -or $idx -ge $folders.Count) {
            Write-Host "Ungültige Auswahl." -ForegroundColor Red
            return $CurrentPath
        }
        $selectedFolder = $folders[$idx].name
        if ([string]::IsNullOrWhiteSpace($CurrentPath)) {
            return $selectedFolder
        } else {
            return "$CurrentPath/$selectedFolder"
        }
    }

    Write-Host "Ungültige Eingabe." -ForegroundColor Red
    return $CurrentPath
}

function Mark-File {
    param(
        [string]$CurrentPath = ""
    )

    $view = Show-Items -Path $CurrentPath
    $files = $view.Files

    if ($files.Count -eq 0) {
        Write-Host "`nKeine Dateien in diesem Pfad." -ForegroundColor DarkGray
        return
    }

    Write-Host ""
    $choice = Read-Host "Datei wählen (F1, F2, ...), Enter für Abbruch"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return
    }

    if ($choice -notlike "F*") {
        Write-Host "Ungültige Eingabe." -ForegroundColor Red
        return
    }

    $numStr = $choice.Substring(1)
    if (-not [int]::TryParse($numStr, [ref]$null)) {
        Write-Host "Ungültige Eingabe." -ForegroundColor Red
        return
    }

    $idx = [int]$numStr - 1
    if ($idx -lt 0 -or $idx -ge $files.Count) {
        Write-Host "Ungültige Auswahl." -ForegroundColor Red
        return
    }

    $selected = $files[$idx]
    $fullPath = $selected.html_url
    $number   = Get-NextNumber

    $index = Get-Index

    $entry = [PSCustomObject]@{
        Number = $number
        Name   = $selected.name
        Path   = if ([string]::IsNullOrWhiteSpace($CurrentPath)) { "/" } else { "/$CurrentPath" }
        Url    = $fullPath
        Time   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    $index = $index + $entry
    Save-Index -index $index

    Write-Host ""
    Write-Host "Markiert:" -ForegroundColor Green
    Write-Host "$($entry.Number) - $($entry.Path)/$($entry.Name)" -ForegroundColor Cyan
    Write-Host $entry.Url -ForegroundColor DarkCyan
}

function Show-Index {
    $index = Get-Index
    Write-Host ""
    Write-Host "=== Markierungen ===" -ForegroundColor Yellow

    if ($index.Count -eq 0) {
        Write-Host "Noch keine Markierungen vorhanden." -ForegroundColor DarkGray
        return
    }

    foreach ($e in $index) {
        Write-Host "$($e.Number) - $($e.Path)/$($e.Name)" -ForegroundColor Cyan
        Write-Host "  $($e.Url)" -ForegroundColor DarkCyan
        Write-Host "  [$($e.Time)]" -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Delete-Entry {
    $index = Get-Index
    if ($index.Count -eq 0) {
        Write-Host "`nKeine Einträge zum Löschen." -ForegroundColor DarkGray
        return
    }

    Show-Index
    $choice = Read-Host "Welche Nummer löschen? (z.B. 01), Enter für Abbruch"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return
    }

    $filtered = $index | Where-Object { $_.Number -ne $choice }
    if ($filtered.Count -eq $index.Count) {
        Write-Host "Nummer nicht gefunden." -ForegroundColor Red
        return
    }

    Save-Index -index $filtered
    Write-Host "Eintrag $choice gelöscht." -ForegroundColor Green
}

function Export-Markdown {
    $index = Get-Index
    Write-Host ""
    Write-Host "=== Export als Markdown ===" -ForegroundColor Yellow

    if ($index.Count -eq 0) {
        Write-Host "Keine Einträge zum Export." -ForegroundColor DarkGray
        return
    }

    $lines = @("# Index – $Owner/$Repo", "")
    foreach ($e in $index) {
        $line = "* **$($e.Number)** – [$($e.Name)]($($e.Url)) – \`$($e.Path)\` – $($e.Time)"
        $lines += $line
    }

    $lines | Out-File -FilePath $IndexMarkdown -Encoding UTF8
    Write-Host "Exportiert nach: $IndexMarkdown" -ForegroundColor Green
}

function Menu {
    $currentPath = ""

    while ($true) {
        Write-Host ""
        Write-Host "=== GitHub Index Tool – Full Version ===" -ForegroundColor White
        Write-Host "Aktueller Pfad: /$currentPath" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "1) Inhalt anzeigen"
        Write-Host "2) Ordner wechseln"
        Write-Host "3) Datei markieren"
        Write-Host "4) Markierungen anzeigen"
        Write-Host "5) Markierung löschen"
        Write-Host "6) Export als Markdown"
        Write-Host "7) Beenden"

        $choice = Read-Host "`nAuswahl"

        switch ($choice) {
            "1" { Show-Items -Path $currentPath | Out-Null }
            "2" { $currentPath = Select-Path -CurrentPath $currentPath }
            "3" { Mark-File -CurrentPath $currentPath }
            "4" { Show-Index }
            "5" { Delete-Entry }
            "6" { Export-Markdown }
            "7" { Write-Host "Beendet." -ForegroundColor Red; break }
            default { Write-Host "Ungültige Eingabe!" -ForegroundColor Red }
        }
    }
}

Menu
