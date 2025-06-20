# convert.ps1 – Extract <desc> from Skraper XML into media\text\<game>.txt

# Find all .xml files recursively
$xmlFiles = Get-ChildItem -Path $PSScriptRoot -Filter '*.xml' -Recurse -File

if ($xmlFiles.Count -eq 0) {
    Write-Warning "No XML files found under $PSScriptRoot"
    exit 1
}

foreach ($xmlFile in $xmlFiles) {

    # Try to load the XML
    try {
        [xml]$doc = Get-Content $xmlFile.FullName -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to load XML '$($xmlFile.FullName)': $_"
        continue
    }

    # Ensure media\text folder exists alongside the XML
    $outputDir = Join-Path $xmlFile.DirectoryName 'media\text'
    if (-not (Test-Path $outputDir)) {
        try {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        catch {
            Write-Warning "Cannot create folder '$outputDir': $_"
            continue
        }
    }

    # Grab all <game> nodes
    $games = $doc.SelectNodes('//game')
    if ($null -eq $games) {
        Write-Host "No <game> entries in '$($xmlFile.Name)', skipping."
        continue
    }

    foreach ($game in $games) {
        $pathNode = $game.SelectSingleNode('path')
        $descNode = $game.SelectSingleNode('desc')

        if ($null -eq $pathNode -or $null -eq $descNode) {
            Write-Warning "Missing <path> or <desc> in one <game> of '$($xmlFile.Name)', skipping."
            continue
        }

        # Build a safe filename from the ROM path
        $romPath  = $pathNode.InnerText.Trim()
        $baseName = [IO.Path]::GetFileNameWithoutExtension($romPath)
        $safeName = $baseName -replace '[\\/:*?"<>|]', '_'
        $outFile  = Join-Path $outputDir ("$safeName.txt")

        # Write the description as UTF-8
        try {
            Set-Content -Path $outFile -Value $descNode.InnerText -Encoding UTF8 -Force
            Write-Host "✔ Wrote '$outFile'"
        }
        catch {
            Write-Warning "Failed to write '$outFile': $_"
        }
    }
}

Write-Host 'Done processing all XML files.' -ForegroundColor Green
