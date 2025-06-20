# convert.ps1 – Extract <desc> from Skraper XML into media\text\<game>.txt

# 1) Find all .xml files recursively
$xmlFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.xml" -Recurse -File

if ($xmlFiles.Count -eq 0) {
    Write-Warning "No XML files found under $PSScriptRoot"
    exit 1
}

foreach ($xmlFile in $xmlFiles) {
    # 2) Load the XML
    try {
        [xml]$doc = Get-Content $xmlFile.FullName -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to load XML '$($xmlFile.FullName)': $_"
        continue
    }

    # 3) Ensure media\text folder exists
    $outputDir = Join-Path $xmlFile.DirectoryName "media\text"
    if (-not (Test-Path $outputDir)) {
        try {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        catch {
            Write-Warning "Cannot create folder '$outputDir': $_"
            continue
        }
    }

    # 4) Extract each <game>
    $games = $doc.SelectNodes("//game")
    if ($null -eq $games) {
        Write-Host "No <game> entries in '$($xmlFile.Name)', skipping."
        continue
    }

    foreach ($game in $games) {
        $pathNode = $game.SelectSingleNode("path")
        $descNode = $game.SelectSingleNode("desc")

        if ($null -eq $pathNode -or $null -eq $descNode) {
            Write-Warning "Skipping an entry missing <path> or <desc> in '$($xmlFile.Name)'."
            continue
        }

        # 5) Sanitize the filename
        $romPath  = $pathNode.InnerText.Trim()
        $baseName = [IO.Path]::GetFileNameWithoutExtension($romPath)
        $safeName = $baseName -replace '[\\/:*?"<>|]', '_'
        $txtPath  = Join-Path $outputDir ("$safeName.txt")

        # 6) Write the description
        try {
            Set-Content -Path $txtPath -Value $descNode.InnerText -Encoding UTF8 -Force
            Write-Host "✔ Wrote `"$txtPath`""
        }
        catch {
            Write-Warning "Failed to write '$txtPath': $_"
        }
    }
}

Write-Host "Done processing all XML files." -ForegroundColor Green
