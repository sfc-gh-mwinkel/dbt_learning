# cleanup_snowflake.ps1 - Drop all Snowflake schemas created by dbt
$ErrorActionPreference = "Stop"

$Connection = if ($args[0]) { $args[0] } else { "default" }

Write-Host "Cleaning up Snowflake artifacts..."
Write-Host "  Using connection: $Connection"
Write-Host ""

# Get the current user from Snowflake
try {
    $Result = snow sql -c $Connection -q "SELECT CURRENT_USER()" 2>$null
    $User = ($Result | Where-Object { $_ -notmatch "^\+" -and $_ -notmatch "CURRENT_USER" -and $_ -notmatch "^-" -and $_.Trim() -ne "" } | Select-Object -First 1).Trim()
} catch {
    $User = $null
}

if (-not $User) {
    Write-Host "ERROR: Could not determine current user. Please check your Snowflake connection." -ForegroundColor Red
    exit 1
}

Write-Host "  Current user: $User"

# Extract prefix (first initial + last name)
# Handle: jon.snow@company.com, JON.SNOW, jon_snow
if ($User -match "@") {
    $UserPart = $User -replace "@.*$", ""
    $UserClean = $UserPart -replace "\.", "_"
} elseif ($User -match "\.") {
    $UserClean = $User -replace "\.", "_"
} else {
    $UserClean = $User
}

$UserUpper = $UserClean.ToUpper()

if ($UserUpper -match "_") {
    $Parts = $UserUpper -split "_"
    $First = $Parts[0]
    $Last  = $Parts[-1]
    $Prefix = $First.Substring(0, 1) + $Last
} else {
    $Prefix = $UserUpper
}

Write-Host "  User prefix: $Prefix"
Write-Host ""

# Drop schemas
$Schemas = @(
    "${Prefix}_RAW"
    "${Prefix}_STAGING"
    "${Prefix}_INTERMEDIATE"
    "${Prefix}_MARTS"
    "${Prefix}_DBT_TEST__AUDIT"
    "${Prefix}_SNAPSHOTS"
)

foreach ($Schema in $Schemas) {
    Write-Host "  Dropping schema: $Schema"
    try {
        snow sql -c $Connection -q "DROP SCHEMA IF EXISTS DBT_LEARNING.$Schema CASCADE" 2>$null | Out-Null
    } catch {
        Write-Host "    (schema may not exist)"
    }
}

Write-Host ""
Write-Host "Snowflake artifacts cleaned!" -ForegroundColor Green
Write-Host ""
Write-Host "Database preserved:"
Write-Host "  DBT_LEARNING database still exists for future runs"
