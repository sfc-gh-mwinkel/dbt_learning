# check_lesson_prerequisites.ps1 - Checkpoint validation for dbt Learning Platform
# Usage: .\scripts\check_lesson_prerequisites.ps1 <lesson_number>
$ErrorActionPreference = "Stop"

$Lesson = $args[0]
if (-not $Lesson) {
    Write-Host "Usage: .\scripts\check_lesson_prerequisites.ps1 <1-12>" -ForegroundColor Yellow
    exit 1
}

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$AllPassed = $true

function Check-File {
    param([string]$File, [string]$Description)
    $FullPath = Join-Path $script:ProjectRoot $File
    if (Test-Path $FullPath) {
        Write-Host "  + $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  x $Description" -ForegroundColor Red
        Write-Host "    Missing: $File"
        $script:AllPassed = $false
        return $false
    }
}

function Check-Model {
    param([string]$Model, [string]$Description)
    $File = "models\$Model"
    $FullPath = Join-Path $script:ProjectRoot $File
    if (Test-Path $FullPath) {
        Write-Host "  + $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  x $Description" -ForegroundColor Red
        Write-Host "    Missing: models\$Model"
        Write-Host "    Run: Copy-Item assets\models\$Model models\$Model"
        $script:AllPassed = $false
        return $false
    }
}

function Check-Seed {
    param([string]$Seed, [string]$Description)
    $File = "seeds\$Seed"
    $FullPath = Join-Path $script:ProjectRoot $File
    if (Test-Path $FullPath) {
        Write-Host "  + $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ! $Description" -ForegroundColor Yellow
        Write-Host "    Missing: seeds\$Seed"
        Write-Host "    Run: Copy-Item assets\seeds\$Seed seeds\"
        $script:AllPassed = $false
        return $false
    }
}

Write-Host "Checking prerequisites for Lesson $Lesson..."
Write-Host ""

switch ([int]$Lesson) {
    1 {
        Write-Host "Lesson 1: Project Setup & First Model"
        Write-Host "======================================="
        Check-File "dbt_project.yml" "dbt_project.yml exists" | Out-Null
        Check-Seed "customers.csv" "customers.csv seed file" | Out-Null
        Check-Seed "orders.csv" "orders.csv seed file" | Out-Null
        Check-File "models\staging\sources.yml" "sources.yml configuration" | Out-Null
        Check-Model "staging\stg_raw__customers.sql" "stg_raw__customers model" | Out-Null
    }
    2 {
        Write-Host "Lesson 2: Understanding YML Files"
        Write-Host "=================================="
        Check-File "models\staging\sources.yml" "sources.yml with tests" | Out-Null
        Check-File "models\staging\schema.yml" "schema.yml for staging models" | Out-Null
        Check-Model "staging\stg_raw__customers.sql" "stg_raw__customers model" | Out-Null
        Check-Model "staging\stg_raw__orders.sql" "stg_raw__orders model" | Out-Null
    }
    3 {
        Write-Host "Lesson 3: The Staging Layer"
        Write-Host "============================"
        Check-Seed "customers.csv" "customers.csv" | Out-Null
        Check-Seed "orders.csv" "orders.csv" | Out-Null
        Check-Seed "products.csv" "products.csv" | Out-Null
        Check-Seed "order_items.csv" "order_items.csv" | Out-Null
        Check-Seed "payments.csv" "payments.csv" | Out-Null
        Check-Model "staging\stg_raw__customers.sql" "stg_raw__customers" | Out-Null
        Check-Model "staging\stg_raw__orders.sql" "stg_raw__orders" | Out-Null
        Check-Model "staging\stg_raw__products.sql" "stg_raw__products" | Out-Null
        Check-Model "staging\stg_raw__order_items.sql" "stg_raw__order_items" | Out-Null
        Check-Model "staging\stg_raw__payments.sql" "stg_raw__payments" | Out-Null
    }
    4 {
        Write-Host "Lesson 4: Intermediate & Mart Models"
        Write-Host "====================================="
        Check-Model "staging\stg_raw__customers.sql" "stg_raw__customers" | Out-Null
        Check-Model "staging\stg_raw__orders.sql" "stg_raw__orders" | Out-Null
        Check-Model "staging\stg_raw__products.sql" "stg_raw__products" | Out-Null
        Check-Model "staging\stg_raw__order_items.sql" "stg_raw__order_items" | Out-Null
        Check-Model "staging\stg_raw__payments.sql" "stg_raw__payments" | Out-Null
        Check-Model "intermediate\int_orders_with_payments.sql" "int_orders_with_payments" | Out-Null
        Check-Model "intermediate\int_order_items_with_products.sql" "int_order_items_with_products" | Out-Null
        Check-Model "intermediate\int_customers__order_summary.sql" "int_customers__order_summary" | Out-Null
        Check-Model "marts\dim_customers.sql" "dim_customers" | Out-Null
        Check-Model "marts\fct_orders.sql" "fct_orders" | Out-Null
    }
    5 {
        Write-Host "Lesson 5: Testing & Data Quality"
        Write-Host "================================="
        Check-File "packages.yml" "packages.yml with dbt_utils" | Out-Null
        Check-Model "marts\dim_customers.sql" "dim_customers" | Out-Null
        Check-Model "marts\fct_orders.sql" "fct_orders" | Out-Null
        Check-File "models\marts\schema.yml" "schema.yml with tests" | Out-Null
    }
    6 {
        Write-Host "Lesson 6: dbt_project.yml Deep Dive"
        Write-Host "===================================="
        Check-File "dbt_project.yml" "dbt_project.yml configured" | Out-Null
    }
    7 {
        Write-Host "Lesson 7: Snapshots & SCD Type 2"
        Write-Host "================================="
        Check-Seed "orders.csv" "orders.csv seed" | Out-Null
        Check-File "models\staging\sources.yml" "sources.yml" | Out-Null
    }
    8 {
        Write-Host "Lesson 8: Writing Macros"
        Write-Host "========================"
        Check-Model "marts\dim_customers.sql" "dim_customers" | Out-Null
    }
    9 {
        Write-Host "Lesson 9: Documentation & dbt docs"
        Write-Host "==================================="
        Check-File "models\marts\schema.yml" "schema.yml with descriptions" | Out-Null
        Check-Model "marts\dim_customers.sql" "dim_customers" | Out-Null
        Check-Model "marts\fct_orders.sql" "fct_orders" | Out-Null
    }
    10 {
        Write-Host "Lesson 10: Graph Operators & dbt build"
        Write-Host "======================================="
        Check-Model "marts\dim_customers.sql" "dim_customers" | Out-Null
        Check-Model "marts\fct_orders.sql" "fct_orders" | Out-Null
    }
    11 {
        Write-Host "Lesson 11: dbt_constraints (Enterprise Data Quality)"
        Write-Host "====================================================="
        Check-File "packages.yml" "packages.yml with dbt_constraints" | Out-Null
        Check-Model "marts\dim_customers.sql" "dim_customers" | Out-Null
        Check-Model "marts\fct_orders.sql" "fct_orders" | Out-Null
    }
    12 {
        Write-Host "Lesson 12: Production Patterns"
        Write-Host "==============================="
        Check-Model "marts\dim_customers.sql" "dim_customers" | Out-Null
        Check-Model "marts\fct_orders.sql" "fct_orders" | Out-Null
        Check-Model "marts\fct_orders_incremental.sql" "fct_orders_incremental" | Out-Null
    }
    default {
        Write-Host "Invalid lesson number: $Lesson" -ForegroundColor Red
        Write-Host "Usage: .\scripts\check_lesson_prerequisites.ps1 <1-12>"
        exit 1
    }
}

Write-Host ""
if ($AllPassed) {
    Write-Host "All prerequisites met! Ready to start Lesson $Lesson." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some prerequisites are missing. Please complete the steps above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Tip: Run '.\scripts\catch_up.ps1 $Lesson' to automatically copy missing files."
    exit 1
}
