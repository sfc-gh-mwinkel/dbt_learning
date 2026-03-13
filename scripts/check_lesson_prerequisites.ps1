# Checkpoint validation script for dbt Learning Platform
# Usage: .\scripts\check_lesson_prerequisites.ps1 <lesson_number>

param(
    [Parameter(Mandatory=$true)]
    [int]$Lesson
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "🔍 Checking prerequisites for Lesson $Lesson..." -ForegroundColor Cyan
Write-Host ""

$AllChecksPassed = $true

function Check-File {
    param(
        [string]$File,
        [string]$Description
    )
    
    $FullPath = Join-Path $ProjectRoot $File
    if (Test-Path $FullPath) {
        Write-Host "✓ $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ $Description" -ForegroundColor Red
        Write-Host "   Missing: $File"
        return $false
    }
}

function Check-Model {
    param(
        [string]$Model,
        [string]$Description
    )
    
    $FullPath = Join-Path $ProjectRoot "models\$Model"
    if (Test-Path $FullPath) {
        Write-Host "✓ $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ $Description" -ForegroundColor Red
        Write-Host "   Missing: models\$Model"
        Write-Host "   Run: Copy-Item assets\models\$Model models\$Model"
        return $false
    }
}

function Check-Seed {
    param(
        [string]$Seed,
        [string]$Description
    )
    
    $FullPath = Join-Path $ProjectRoot "seeds\$Seed"
    if (Test-Path $FullPath) {
        Write-Host "✓ $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "⚠ $Description" -ForegroundColor Yellow
        Write-Host "   Missing: seeds\$Seed"
        Write-Host "   Run: Copy-Item assets\seeds\$Seed seeds\"
        return $false
    }
}

switch ($Lesson) {
    1 {
        Write-Host "Lesson 1: Project Setup & First Model"
        Write-Host "======================================="
        if (!(Check-File "dbt_project.yml" "dbt_project.yml exists")) { $AllChecksPassed = $false }
        if (!(Check-Seed "customers.csv" "customers.csv seed file")) { $AllChecksPassed = $false }
        if (!(Check-Seed "orders.csv" "orders.csv seed file")) { $AllChecksPassed = $false }
        if (!(Check-File "models\staging\sources.yml" "sources.yml configuration")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_customers.sql" "stg_customers model")) { $AllChecksPassed = $false }
    }
    
    2 {
        Write-Host "Lesson 2: Understanding YML Files"
        Write-Host "=================================="
        if (!(Check-File "models\staging\sources.yml" "sources.yml with tests")) { $AllChecksPassed = $false }
        if (!(Check-File "models\staging\schema.yml" "schema.yml for staging models")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_customers.sql" "stg_customers model")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_orders.sql" "stg_orders model")) { $AllChecksPassed = $false }
    }
    
    3 {
        Write-Host "Lesson 3: The Staging Layer"
        Write-Host "============================"
        if (!(Check-Seed "customers.csv" "customers.csv")) { $AllChecksPassed = $false }
        if (!(Check-Seed "orders.csv" "orders.csv")) { $AllChecksPassed = $false }
        if (!(Check-Seed "products.csv" "products.csv")) { $AllChecksPassed = $false }
        if (!(Check-Seed "order_items.csv" "order_items.csv")) { $AllChecksPassed = $false }
        if (!(Check-Seed "payments.csv" "payments.csv")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_customers.sql" "stg_customers")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_orders.sql" "stg_orders")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_products.sql" "stg_products")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_order_items.sql" "stg_order_items")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_payments.sql" "stg_payments")) { $AllChecksPassed = $false }
    }
    
    4 {
        Write-Host "Lesson 4: Intermediate & Mart Models"
        Write-Host "====================================="
        # Check all staging models exist
        if (!(Check-Model "staging\stg_customers.sql" "stg_customers")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_orders.sql" "stg_orders")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_products.sql" "stg_products")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_order_items.sql" "stg_order_items")) { $AllChecksPassed = $false }
        if (!(Check-Model "staging\stg_payments.sql" "stg_payments")) { $AllChecksPassed = $false }
        # Check intermediate models
        if (!(Check-Model "intermediate\int_orders_with_payments.sql" "int_orders_with_payments")) { $AllChecksPassed = $false }
        if (!(Check-Model "intermediate\int_order_items_with_products.sql" "int_order_items_with_products")) { $AllChecksPassed = $false }
        if (!(Check-Model "intermediate\int_customers__order_summary.sql" "int_customers__order_summary")) { $AllChecksPassed = $false }
        # Check mart models
        if (!(Check-Model "marts\dim_customers.sql" "dim_customers")) { $AllChecksPassed = $false }
        if (!(Check-Model "marts\fct_orders.sql" "fct_orders")) { $AllChecksPassed = $false }
    }
    
    5 {
        Write-Host "Lesson 5: Testing & Data Quality"
        Write-Host "================================="
        if (!(Check-File "packages.yml" "packages.yml with dbt_utils")) { $AllChecksPassed = $false }
        if (!(Check-Model "marts\dim_customers.sql" "dim_customers")) { $AllChecksPassed = $false }
        if (!(Check-Model "marts\fct_orders.sql" "fct_orders")) { $AllChecksPassed = $false }
        if (!(Check-File "models\marts\schema.yml" "schema.yml with tests")) { $AllChecksPassed = $false }
    }
    
    6 {
        Write-Host "Lesson 6: dbt_project.yml Deep Dive"
        Write-Host "===================================="
        if (!(Check-File "dbt_project.yml" "dbt_project.yml configured")) { $AllChecksPassed = $false }
    }
    
    7 {
        Write-Host "Lesson 7: Snapshots & SCD Type 2"
        Write-Host "================================="
        if (!(Check-Seed "orders.csv" "orders.csv seed")) { $AllChecksPassed = $false }
        if (!(Check-File "models\staging\sources.yml" "sources.yml")) { $AllChecksPassed = $false }
    }
    
    8 {
        Write-Host "Lesson 8: Writing Macros"
        Write-Host "========================"
        if (!(Check-Model "marts\dim_customers.sql" "dim_customers")) { $AllChecksPassed = $false }
    }
    
    9 {
        Write-Host "Lesson 9: Documentation & dbt docs"
        Write-Host "==================================="
        if (!(Check-File "models\marts\schema.yml" "schema.yml with descriptions")) { $AllChecksPassed = $false }
        if (!(Check-Model "marts\dim_customers.sql" "dim_customers")) { $AllChecksPassed = $false }
        if (!(Check-Model "marts\fct_orders.sql" "fct_orders")) { $AllChecksPassed = $false }
    }
    
    10 {
        Write-Host "Lesson 10: Graph Operators & dbt build"
        Write-Host "======================================="
        # All models should exist by now
        if (!(Check-Model "marts\dim_customers.sql" "dim_customers")) { $AllChecksPassed = $false }
        if (!(Check-Model "marts\fct_orders.sql" "fct_orders")) { $AllChecksPassed = $false }
    }
    
    default {
        Write-Host "Invalid lesson number: $Lesson" -ForegroundColor Red
        Write-Host "Usage: .\scripts\check_lesson_prerequisites.ps1 <1-10>"
        exit 1
    }
}

Write-Host ""
if ($AllChecksPassed) {
    Write-Host "✓ All prerequisites met! Ready to start Lesson $Lesson." -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Some prerequisites are missing. Please complete the steps above." -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Tip: Run '.\scripts\catch_up.ps1 $Lesson' to automatically copy missing files."
    exit 1
}
