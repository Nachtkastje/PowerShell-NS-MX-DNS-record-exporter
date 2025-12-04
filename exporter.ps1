$InputFile  = "domains.txt"
$OutputFile = "results.csv"

if (-not (Test-Path $InputFile)) {
    Write-Error "Input file '$InputFile' not found!"
    exit 1
}

$Results = @()
$Domains = Get-Content $InputFile | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }

foreach ($Domain in $Domains) {
    Write-Host "Processing: $Domain" -ForegroundColor Cyan


    $nsList = @()
    try {
        $nsRecords = Resolve-DnsName -Name $Domain -Type NS -ErrorAction Stop | Where-Object Type -EQ 'NS'
        foreach ($rec in $nsRecords) {
            $ns = $rec.NameHost.TrimEnd('.')
            if ($ns -and $nsList -notcontains $ns) { $nsList += $ns }
        }
    } catch { Write-Warning "  NS lookup failed: $_" }


    $mxList = @()
    try {
        $mxRecords = Resolve-DnsName -Name $Domain -Type MX -ErrorAction Stop | Where-Object Type -EQ 'MX'
        foreach ($rec in $mxRecords) {
            $mx = $rec.NameExchange.TrimEnd('.')
            if ($mx -and $mxList -notcontains $mx) { $mxList += $mx }
        }
    } catch { Write-Warning "  MX lookup failed: $_" }


    $nsJoined = ($nsList | Sort-Object) -join ' / '
    $mxJoined = ($mxList | Sort-Object) -join ' / '


    $Results += [pscustomobject]@{
        Domeinnaam   = $Domain
        nameservers  = $nsJoined
        'mx-records' = $mxJoined
    }
}

$Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "`nExport completed: $OutputFile" -ForegroundColor Green
