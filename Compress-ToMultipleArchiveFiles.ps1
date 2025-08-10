# Settings.
$sourcePath = "C:\Users\Username\Source"
$sourceFilter = "*.xml"
$destinationPath = "C:\Users\Username\Destination"
$outputFileSizeLimit = 500000000 # Total byte limit per compressed archive file (before compression). Set to 0 for unlimited.
$outputFileCountLimit = 40000 # Total file count limit per compressed archive file. Set to 0 for unlimited.

# Loop through the files and compress them.
$sourceFiles = Get-ChildItem -Path $sourcePath -Filter $sourceFilter | Sort-Object -Property Name
$totalSourceFileCount = ($sourceFiles | Measure-Object).Count
Write-Output ('Total source files: {0}' -f $totalSourceFileCount)

$tempOutputFiles = @()
$tempFileSizeSum = 0
$tempFileCount = 0
$tempTotalFileCount = 0
$tempOutputFileSets = @()

foreach ($file in $sourceFiles) {
    $tempOutputFiles += $file
    $tempFileSizeSum += $file.Length
    $tempFileCount += 1
    $tempTotalFileCount += 1

    if (
        (($tempFileSizeSum -ge $outputFileSizeLimit) -and ($outputFileSizeLimit -gt 0)) -or
        (($tempFileCount -ge $outputFileCountLimit) -and ($outputFileCountLimit -gt 0)) -or
        ($tempTotalFileCount -eq $totalSourceFileCount)
    ) {
        $tempOutputFileSets += @{
            Files = $tempOutputFiles
            TotalBytes = $tempFileSizeSum
        }
        $tempOutputFiles = @()
        $tempFileSizeSum = 0
        $tempFileCount = 0
    }
}

$tempOutputFileNumber = 0
Write-Output "Output file sets: $($tempOutputFileSets.Count)"
foreach ($fileSet in $tempOutputFileSets) {
    $tempOutputFileNumber += 1

    # Compress the files, then move on to the next set of files.
    $outputFilePath = Join-Path -Path $destinationPath -ChildPath "output_file_$($tempOutputFileNumber).zip"

    if ((Test-Path -Path $outputFilePath) -eq $false) {
        Write-Output ('Compressing {0} files ({1} MB) to "{2}".' -f ($fileSet.Files | Measure-Object).Count, [Math]::Round($fileSet.TotalBytes / 1MB, 2), $outputFilePath)
        $fileSet.Files.FullName | Compress-Archive -DestinationPath $outputFilePath
    }
    else {
        Write-Warning ('Output file "{0}" already exists.' -f $outputFilePath)
    }
}