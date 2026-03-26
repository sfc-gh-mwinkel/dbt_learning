# cleanup_workspace.ps1 - Reset local dbt workspace to clean state
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# -- IGNORE LIST --------------------------------------------------------
# Files and folders that should NOT be removed during cleanup.
# Edit these arrays in a client fork to preserve client-specific
# assets without modifying the cleanup logic below.
#
# IgnoreFiles: filename matches (applies across all directories)
# IgnoreDirs:  folder paths relative to project root
#
$IgnoreFiles = @(
    ".gitkeep"
    "generate_schema_name.sql"
    # --- Add client-specific files below ---
    # "client_masking_policy.sql"
    # "custom_audit_log.sql"
)

$IgnoreDirs = @(
    # --- Add client-specific folders below ---
    # "models\client_reports"
    # "models\compliance"
    # "macros\client_utils"
    # "tests\client_regression"
)
# -----------------------------------------------------------------------

function Clean-Directory {
    param([string]$Dir)
    $FullPath = Join-Path $ProjectRoot $Dir
    if (-not (Test-Path $FullPath)) { return }

    Get-ChildItem -Path $FullPath -File -Recurse | Where-Object {
        $file = $_
        $keep = $false
        foreach ($name in $IgnoreFiles) {
            if ($file.Name -eq $name) { $keep = $true; break }
        }
        if (-not $keep) {
            foreach ($dir in $IgnoreDirs) {
                $dirFull = Join-Path $ProjectRoot $dir
                if ($file.FullName.StartsWith($dirFull + [IO.Path]::DirectorySeparatorChar)) {
                    $keep = $true; break
                }
            }
        }
        -not $keep
    } | Remove-Item -Force
}

function Remove-EmptyDirs {
    param([string]$Dir)
    $FullPath = Join-Path $ProjectRoot $Dir
    if (-not (Test-Path $FullPath)) { return }
    Get-ChildItem -Path $FullPath -Directory -Recurse |
        Sort-Object { $_.FullName.Length } -Descending |
        Where-Object { (Get-ChildItem $_.FullName -Force).Count -eq 0 } |
        Remove-Item -Force
}

Write-Host "Cleaning up local dbt workspace..."

Write-Host "  Removing target/ and dbt_packages/..."
foreach ($dir in @("target", "dbt_packages")) {
    $p = Join-Path $ProjectRoot $dir
    if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}

foreach ($dir in @("models", "tests", "seeds", "snapshots", "macros")) {
    Write-Host "  Removing $dir/..."
    Clean-Directory $dir
}

$lockFile = Join-Path $ProjectRoot "package-lock.yml"
if (Test-Path $lockFile) {
    Write-Host "  Removing package-lock.yml..."
    Remove-Item $lockFile -Force
}

foreach ($dir in @("models", "tests", "seeds", "snapshots", "macros")) {
    Remove-EmptyDirs $dir
}

Write-Host ""
Write-Host "Local workspace cleaned!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Copy broken seeds to test failing test workflow:"
Write-Host "     Copy-Item assets\seeds\orders_broken.csv seeds\orders.csv"
Write-Host "     Copy-Item assets\seeds\*.csv seeds\"
Write-Host ""
Write-Host "  2. Start with Lesson 1 and follow instructions to build models"
