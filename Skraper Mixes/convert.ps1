# convert.ps1 – Extract <desc> from Skraper XML into media\text\<game>.txt
# It will:
#  • Recursively find all .xml files under the script root
#  • For each, create a media\text folder beside it (if missing)
#  • For each <game>, write a UTF-8 .txt named after the ROM, containing only its <desc>

# Recursively collect all XML files from where this script is run
$xmlFiles = Get-ChildItem -Path $PSScriptRoot -Filter *.xml -Recurse -File

if (-not $xmlFiles) {
    Write-Warning "No XML files found under $PSScriptRoot"
    exit 1
}

# Relative subfolder for output under each XML’s folder
$relativeOut = 'media\text'

foreach ($xmlFile in $xmlFiles) {
    try {
        # 3) Load XML
        [xml]$doc = Get-Content $xmlFile.FullName -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to load XML '$($xmlFile.FullName)': $_"
        continue
    }

    # Determine the output folder next to this XML
    $baseDir = $xmlFile.DirectoryName
    $outputFolder = Join-Path $baseDir $relativeOut

    # Create it if missing
    if (-not (Test-Path $outputFolder)) {
        try {
            New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
        }
        catch {
            Write-Warning "Cannot create folder '$outputFolder': $_"
            continue
        }
    }

    # Process each <game>
    $games = $doc.SelectNodes('//game')
    if (-not $games) {
        Write-Host "No <game> nodes in '$($xmlFile.Name)'. Skipping."
        continue
    }

    foreach ($game in $games) {
        # Safely extract nodes
        $pathNode = $game.SelectSingleNode('path')
        $descNode = $game.SelectSingleNode('desc')

        if (-not $pathNode -or -not $descNode) {
            Write-Warning "Missing <path> or <desc> in a <game> of '$($xmlFile.Name)'. Skipping entry."
            continue
        }

        $romPath = $pathNode.InnerText.Trim()
        $desc    = $descNode.InnerText

        # Derive a safe filename
        $baseName = [IO.Path]::GetFileNameWithoutExtension($romPath)
        # Remove any invalid chars for Windows filenames
        $safeName = [IO.Path]::GetInvalidFileNameChars() | ForEach-Object { $baseName = $baseName -replace [Regex]::Escape($_), '_' }
        $outFile  = Join-Path $outputFolder "$safeName.txt"

        try {
            # Write the description as UTF8
            Set-Content -Path $outFile -Value $desc -Encoding UTF8 -Force
            Write-Host "✔ Wrote '$outFile'"
        }
        catch {
            Write-Warning "Failed to write '$outFile': $_"
        }
    }
}

Write-Host "Done processing all XML files." -ForegroundColor Green
