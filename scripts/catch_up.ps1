# catch_up.ps1 - Catch-up script for dbt Learning Platform
# Usage: .\scripts\catch_up.ps1 <lesson_number>
$ErrorActionPreference = "Stop"

$Lesson = $args[0]
if (-not $Lesson) {
    Write-Host "Usage: .\scripts\catch_up.ps1 <1-12>" -ForegroundColor Yellow
    exit 1
}

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)

function Copy-IfMissing {
    param([string]$Src, [string]$Dest, [string]$Description)
    $FullDest = Join-Path $ProjectRoot $Dest
    if (-not (Test-Path $FullDest)) {
        $DestDir = Split-Path -Parent $FullDest
        if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir -Force | Out-Null }
        Copy-Item (Join-Path $ProjectRoot $Src) $FullDest
        Write-Host "  + Copied $Description" -ForegroundColor Green
    } else {
        Write-Host "  > Already exists: $Description" -ForegroundColor Cyan
    }
}

function Setup-Lesson {
    param([int]$LessonNum)

    switch ($LessonNum) {
        1 {
            Write-Host "Setting up for Lesson 1: Project Setup & First Model"
            Write-Host "======================================================"
            Copy-IfMissing "assets\seeds\customers.csv" "seeds\customers.csv" "customers.csv"
            Copy-IfMissing "assets\seeds\orders.csv" "seeds\orders.csv" "orders.csv"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Run: dbt seed"
            Write-Host "2. Create models\staging\sources.yml (follow lesson instructions)"
            Write-Host "3. Create models\staging\stg_raw__customers.sql (follow lesson instructions)"
        }
        2 {
            Write-Host "Setting up for Lesson 2: Understanding YML Files"
            Write-Host "================================================="
            Copy-IfMissing "assets\seeds\customers.csv" "seeds\customers.csv" "customers.csv"
            Copy-IfMissing "assets\seeds\orders.csv" "seeds\orders.csv" "orders.csv"
            Copy-IfMissing "assets\models\staging\stg_raw__customers.sql" "models\staging\stg_raw__customers.sql" "stg_raw__customers.sql"
            Copy-IfMissing "assets\models\staging\stg_raw__orders.sql" "models\staging\stg_raw__orders.sql" "stg_raw__orders.sql"
            Copy-IfMissing "assets\yml_templates\sources.yml" "models\staging\sources.yml" "sources.yml"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Run: dbt seed"
            Write-Host "2. Run: dbt run --select staging"
            Write-Host "3. Create stg_raw__customers.yml and stg_raw__orders.yml (follow lesson instructions)"
        }
        3 {
            Write-Host "Setting up for Lesson 3: The Staging Layer"
            Write-Host "==========================================="
            Copy-IfMissing "assets\seeds\customers.csv" "seeds\customers.csv" "customers.csv"
            Copy-IfMissing "assets\seeds\orders.csv" "seeds\orders.csv" "orders.csv"
            Copy-IfMissing "assets\seeds\products.csv" "seeds\products.csv" "products.csv"
            Copy-IfMissing "assets\seeds\order_items.csv" "seeds\order_items.csv" "order_items.csv"
            Copy-IfMissing "assets\seeds\payments.csv" "seeds\payments.csv" "payments.csv"
            Copy-IfMissing "assets\models\staging\stg_raw__customers.sql" "models\staging\stg_raw__customers.sql" "stg_raw__customers.sql"
            Copy-IfMissing "assets\models\staging\stg_raw__orders.sql" "models\staging\stg_raw__orders.sql" "stg_raw__orders.sql"
            Copy-IfMissing "assets\models\staging\stg_raw__products.sql" "models\staging\stg_raw__products.sql" "stg_raw__products.sql"
            Copy-IfMissing "assets\models\staging\stg_raw__order_items.sql" "models\staging\stg_raw__order_items.sql" "stg_raw__order_items.sql"
            Copy-IfMissing "assets\models\staging\stg_raw__payments.sql" "models\staging\stg_raw__payments.sql" "stg_raw__payments.sql"
            Copy-IfMissing "assets\yml_templates\sources.yml" "models\staging\sources.yml" "sources.yml"
            Copy-IfMissing "assets\yml_templates\staging\stg_raw__customers.yml" "models\staging\stg_raw__customers.yml" "stg_raw__customers.yml"
            Copy-IfMissing "assets\yml_templates\staging\stg_raw__orders.yml" "models\staging\stg_raw__orders.yml" "stg_raw__orders.yml"
            Copy-IfMissing "assets\yml_templates\staging\stg_raw__products.yml" "models\staging\stg_raw__products.yml" "stg_raw__products.yml"
            Copy-IfMissing "assets\yml_templates\staging\stg_raw__order_items.yml" "models\staging\stg_raw__order_items.yml" "stg_raw__order_items.yml"
            Copy-IfMissing "assets\yml_templates\staging\stg_raw__payments.yml" "models\staging\stg_raw__payments.yml" "stg_raw__payments.yml"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Run: dbt seed"
            Write-Host "2. Run: dbt run --select staging"
            Write-Host "3. Run: dbt test --select staging"
        }
        4 {
            Write-Host "Setting up for Lesson 4: Intermediate & Mart Models"
            Write-Host "===================================================="
            Copy-IfMissing "assets\seeds\customers.csv" "seeds\customers.csv" "customers.csv"
            Copy-IfMissing "assets\seeds\orders.csv" "seeds\orders.csv" "orders.csv"
            Copy-IfMissing "assets\seeds\products.csv" "seeds\products.csv" "products.csv"
            Copy-IfMissing "assets\seeds\order_items.csv" "seeds\order_items.csv" "order_items.csv"
            Copy-IfMissing "assets\seeds\payments.csv" "seeds\payments.csv" "payments.csv"
            Copy-IfMissing "assets\models\staging\stg_raw__customers.sql" "models\staging\stg_raw__customers.sql" "stg_raw__customers.sql"
            Copy-IfMissing "assets\models\staging\stg_raw__orders.sql" "models\staging\stg_raw__orders.sql" "stg_raw__orders.sql"
            Copy-IfMissing "assets\models\staging\stg_raw__products.sql" "models\staging\stg_raw__products.sql" "stg_raw__products.sql"
            Copy-IfMissing "assets\models\staging\stg_raw__order_items.sql" "models\staging\stg_raw__order_items.sql" "stg_raw__order_items.sql"
            Copy-IfMissing "assets\models\staging\stg_raw__payments.sql" "models\staging\stg_raw__payments.sql" "stg_raw__payments.sql"
            Copy-IfMissing "assets\yml_templates\sources.yml" "models\staging\sources.yml" "sources.yml"
            Copy-IfMissing "assets\models\intermediate\int_orders_with_payments.sql" "models\intermediate\int_orders_with_payments.sql" "int_orders_with_payments.sql"
            Copy-IfMissing "assets\models\intermediate\int_order_items_with_products.sql" "models\intermediate\int_order_items_with_products.sql" "int_order_items_with_products.sql"
            Copy-IfMissing "assets\models\intermediate\int_customers__order_summary.sql" "models\intermediate\int_customers__order_summary.sql" "int_customers__order_summary.sql"
            Copy-IfMissing "assets\models\marts\dim_customers.sql" "models\marts\dim_customers.sql" "dim_customers.sql"
            Copy-IfMissing "assets\models\marts\fct_orders.sql" "models\marts\fct_orders.sql" "fct_orders.sql"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Run: dbt seed"
            Write-Host "2. Run: dbt run"
            Write-Host "3. Review the complete data flow: staging > intermediate > marts"
        }
        5 {
            Write-Host "Setting up for Lesson 5: Testing & Data Quality"
            Write-Host "================================================"
            Setup-Lesson 4
            Copy-IfMissing "assets\yml_templates\intermediate\int_orders_with_payments.yml" "models\intermediate\int_orders_with_payments.yml" "int_orders_with_payments.yml"
            Copy-IfMissing "assets\yml_templates\intermediate\int_order_items_with_products.yml" "models\intermediate\int_order_items_with_products.yml" "int_order_items_with_products.yml"
            Copy-IfMissing "assets\yml_templates\intermediate\int_customers__order_summary.yml" "models\intermediate\int_customers__order_summary.yml" "int_customers__order_summary.yml"
            Copy-IfMissing "assets\yml_templates\marts\dim_customers.yml" "models\marts\dim_customers.yml" "dim_customers.yml"
            Copy-IfMissing "assets\yml_templates\marts\fct_orders.yml" "models\marts\fct_orders.yml" "fct_orders.yml"
            Copy-IfMissing "assets\tests\assert_order_amount_matches_line_items.sql" "tests\assert_order_amount_matches_line_items.sql" "singular test"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Run: dbt deps (install dbt_utils)"
            Write-Host "2. Run: dbt test"
        }
        6 {
            Write-Host "Setting up for Lesson 6: dbt_project.yml Deep Dive"
            Write-Host "==================================================="
            Write-Host "No additional files needed beyond Lesson 5 setup."
            Setup-Lesson 5
        }
        7 {
            Write-Host "Setting up for Lesson 7: Snapshots & SCD Type 2"
            Write-Host "================================================"
            Setup-Lesson 5
            Copy-IfMissing "assets\snapshots\snap_orders.sql" "snapshots\snap_orders.sql" "snap_orders.sql"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Run: dbt snapshot"
            Write-Host "2. Modify seeds\orders.csv to simulate changes"
            Write-Host "3. Run: dbt seed; dbt snapshot"
        }
        8 {
            Write-Host "Setting up for Lesson 8: Writing Macros"
            Write-Host "========================================"
            Setup-Lesson 5
            Copy-IfMissing "assets\macros\clean_string.sql" "macros\clean_string.sql" "clean_string macro"
            Copy-IfMissing "assets\macros\classify_tier.sql" "macros\classify_tier.sql" "classify_tier macro"
            Copy-IfMissing "assets\macros\cents_to_dollars.sql" "macros\cents_to_dollars.sql" "cents_to_dollars macro"
            Copy-IfMissing "assets\macros\generate_schema_name.sql" "macros\generate_schema_name.sql" "generate_schema_name macro"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Run: dbt compile --select dim_customers"
            Write-Host "2. Review compiled SQL in target\compiled\"
        }
        9 {
            Write-Host "Setting up for Lesson 9: Documentation & dbt docs"
            Write-Host "=================================================="
            Setup-Lesson 8
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Add descriptions to model .yml files"
            Write-Host "2. Create models\docs.md with doc blocks"
            Write-Host "3. Run: dbt docs generate; dbt docs serve"
        }
        10 {
            Write-Host "Setting up for Lesson 10: Graph Operators & dbt build"
            Write-Host "======================================================"
            Setup-Lesson 8
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Run: dbt build"
            Write-Host "2. Practice selection syntax: dbt run --select +dim_customers+"
        }
        11 {
            Write-Host "Setting up for Lesson 11: dbt_constraints (Enterprise Data Quality)"
            Write-Host "===================================================================="
            Setup-Lesson 5
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Add dbt_constraints package to packages.yml"
            Write-Host "2. Run: dbt deps"
            Write-Host "3. Follow Lesson 11 instructions"
        }
        12 {
            Write-Host "Setting up for Lesson 12: Production Patterns"
            Write-Host "=============================================="
            Setup-Lesson 8
            Copy-IfMissing "assets\models\marts\fct_orders_incremental.sql" "models\marts\fct_orders_incremental.sql" "fct_orders_incremental.sql"
            Copy-IfMissing "assets\models\marts\fct_daily_revenue.sql" "models\marts\fct_daily_revenue.sql" "fct_daily_revenue.sql"
            Copy-IfMissing "assets\yml_templates\marts\fct_orders_incremental.yml" "models\marts\fct_orders_incremental.yml" "fct_orders_incremental.yml"
            Copy-IfMissing "assets\yml_templates\marts\fct_daily_revenue.yml" "models\marts\fct_daily_revenue.yml" "fct_daily_revenue.yml"
            Copy-IfMissing "assets\yml_templates\exposures.yml" "models\exposures.yml" "exposures.yml"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Run: dbt run --select fct_orders_incremental"
            Write-Host "2. Run it again to see incremental behavior"
            Write-Host "3. Explore exposures with: dbt docs generate; dbt docs serve"
        }
        default {
            Write-Host "Invalid lesson number: $LessonNum" -ForegroundColor Yellow
            Write-Host "Usage: .\scripts\catch_up.ps1 <1-12>"
            exit 1
        }
    }
}

Write-Host "Catching up to Lesson $Lesson..."
Write-Host ""

Setup-Lesson ([int]$Lesson)

Write-Host ""
Write-Host "Catch-up complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Tip: Run '.\scripts\check_lesson_prerequisites.ps1 $Lesson' to verify all prerequisites are met."
