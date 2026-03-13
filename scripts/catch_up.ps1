# Catch-up script for dbt Learning Platform
# Automatically copies missing files to get students caught up to a specific lesson
# Usage: .\scripts\catch_up.ps1 <lesson_number>

param(
    [Parameter(Mandatory=$true)]
    [int]$Lesson
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "🚀 Catching up to Lesson $Lesson..." -ForegroundColor Cyan
Write-Host ""

function Copy-IfMissing {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    
    $DestPath = Join-Path $ProjectRoot $Destination
    if (!(Test-Path $DestPath)) {
        $DestDir = Split-Path -Parent $DestPath
        if (!(Test-Path $DestDir)) {
            New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
        }
        $SourcePath = Join-Path $ProjectRoot $Source
        Copy-Item $SourcePath $DestPath
        Write-Host "✓ Copied $Description" -ForegroundColor Green
    } else {
        Write-Host "→ Already exists: $Description" -ForegroundColor Blue
    }
}

switch ($Lesson) {
    1 {
        Write-Host "Setting up for Lesson 1: Project Setup & First Model"
        Write-Host "======================================================"
        Copy-IfMissing "assets\seeds\customers.csv" "seeds\customers.csv" "customers.csv"
        Copy-IfMissing "assets\seeds\orders.csv" "seeds\orders.csv" "orders.csv"
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Run: dbt seed"
        Write-Host "2. Create models\staging\sources.yml (follow lesson instructions)"
        Write-Host "3. Create models\staging\stg_customers.sql (follow lesson instructions)"
    }
    
    2 {
        Write-Host "Setting up for Lesson 2: Understanding YML Files"
        Write-Host "================================================="
        # Lesson 1 prereqs
        Copy-IfMissing "assets\seeds\customers.csv" "seeds\customers.csv" "customers.csv"
        Copy-IfMissing "assets\seeds\orders.csv" "seeds\orders.csv" "orders.csv"
        Copy-IfMissing "assets\models\staging\stg_customers.sql" "models\staging\stg_customers.sql" "stg_customers.sql"
        Copy-IfMissing "assets\models\staging\stg_orders.sql" "models\staging\stg_orders.sql" "stg_orders.sql"
        Copy-IfMissing "assets\yml_templates\sources.yml" "models\staging\sources.yml" "sources.yml"
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Run: dbt seed"
        Write-Host "2. Run: dbt run --select staging"
        Write-Host "3. Create models\staging\schema.yml (follow lesson instructions)"
    }
    
    3 {
        Write-Host "Setting up for Lesson 3: The Staging Layer"
        Write-Host "==========================================="
        # Copy all seeds
        Copy-IfMissing "assets\seeds\customers.csv" "seeds\customers.csv" "customers.csv"
        Copy-IfMissing "assets\seeds\orders.csv" "seeds\orders.csv" "orders.csv"
        Copy-IfMissing "assets\seeds\products.csv" "seeds\products.csv" "products.csv"
        Copy-IfMissing "assets\seeds\order_items.csv" "seeds\order_items.csv" "order_items.csv"
        Copy-IfMissing "assets\seeds\payments.csv" "seeds\payments.csv" "payments.csv"
        # Copy all staging models
        Copy-IfMissing "assets\models\staging\stg_customers.sql" "models\staging\stg_customers.sql" "stg_customers.sql"
        Copy-IfMissing "assets\models\staging\stg_orders.sql" "models\staging\stg_orders.sql" "stg_orders.sql"
        Copy-IfMissing "assets\models\staging\stg_products.sql" "models\staging\stg_products.sql" "stg_products.sql"
        Copy-IfMissing "assets\models\staging\stg_order_items.sql" "models\staging\stg_order_items.sql" "stg_order_items.sql"
        Copy-IfMissing "assets\models\staging\stg_payments.sql" "models\staging\stg_payments.sql" "stg_payments.sql"
        Copy-IfMissing "assets\yml_templates\sources.yml" "models\staging\sources.yml" "sources.yml"
        Copy-IfMissing "assets\yml_templates\staging_schema.yml" "models\staging\schema.yml" "staging schema.yml"
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Run: dbt seed"
        Write-Host "2. Run: dbt run --select staging"
        Write-Host "3. Run: dbt test --select staging"
    }
    
    4 {
        Write-Host "Setting up for Lesson 4: Intermediate & Mart Models"
        Write-Host "===================================================="
        # Lesson 3 prereqs
        Copy-IfMissing "assets\seeds\customers.csv" "seeds\customers.csv" "customers.csv"
        Copy-IfMissing "assets\seeds\orders.csv" "seeds\orders.csv" "orders.csv"
        Copy-IfMissing "assets\seeds\products.csv" "seeds\products.csv" "products.csv"
        Copy-IfMissing "assets\seeds\order_items.csv" "seeds\order_items.csv" "order_items.csv"
        Copy-IfMissing "assets\seeds\payments.csv" "seeds\payments.csv" "payments.csv"
        Copy-IfMissing "assets\models\staging\stg_customers.sql" "models\staging\stg_customers.sql" "stg_customers.sql"
        Copy-IfMissing "assets\models\staging\stg_orders.sql" "models\staging\stg_orders.sql" "stg_orders.sql"
        Copy-IfMissing "assets\models\staging\stg_products.sql" "models\staging\stg_products.sql" "stg_products.sql"
        Copy-IfMissing "assets\models\staging\stg_order_items.sql" "models\staging\stg_order_items.sql" "stg_order_items.sql"
        Copy-IfMissing "assets\models\staging\stg_payments.sql" "models\staging\stg_payments.sql" "stg_payments.sql"
        Copy-IfMissing "assets\yml_templates\sources.yml" "models\staging\sources.yml" "sources.yml"
        # Lesson 4 - intermediate models
        Copy-IfMissing "assets\models\intermediate\int_orders_with_payments.sql" "models\intermediate\int_orders_with_payments.sql" "int_orders_with_payments.sql"
        Copy-IfMissing "assets\models\intermediate\int_order_items_with_products.sql" "models\intermediate\int_order_items_with_products.sql" "int_order_items_with_products.sql"
        Copy-IfMissing "assets\models\intermediate\int_customers__order_summary.sql" "models\intermediate\int_customers__order_summary.sql" "int_customers__order_summary.sql"
        # Lesson 4 - mart models
        Copy-IfMissing "assets\models\marts\dim_customers.sql" "models\marts\dim_customers.sql" "dim_customers.sql"
        Copy-IfMissing "assets\models\marts\fct_orders.sql" "models\marts\fct_orders.sql" "fct_orders.sql"
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Run: dbt seed"
        Write-Host "2. Run: dbt run"
        Write-Host "3. Review the complete data flow: staging → intermediate → marts"
    }
    
    5 {
        Write-Host "Setting up for Lesson 5: Testing & Data Quality"
        Write-Host "================================================"
        # All previous prereqs
        & "$PSScriptRoot\catch_up.ps1" 4  # Recursively call to set up lesson 4
        Copy-IfMissing "assets\yml_templates\intermediate_schema.yml" "models\intermediate\schema.yml" "intermediate schema.yml"
        Copy-IfMissing "assets\yml_templates\marts_schema.yml" "models\marts\schema.yml" "marts schema.yml"
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
        & "$PSScriptRoot\catch_up.ps1" 5  # Recursively call to set up lesson 5
    }
    
    7 {
        Write-Host "Setting up for Lesson 7: Snapshots & SCD Type 2"
        Write-Host "================================================"
        & "$PSScriptRoot\catch_up.ps1" 5  # Recursively call to set up lesson 5
        Copy-IfMissing "assets\snapshots\snap_orders.sql" "snapshots\snap_orders.sql" "snap_orders.sql"
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Run: dbt snapshot"
        Write-Host "2. Modify seeds\orders.csv to simulate changes"
        Write-Host "3. Run: dbt seed && dbt snapshot"
    }
    
    8 {
        Write-Host "Setting up for Lesson 8: Writing Macros"
        Write-Host "========================================"
        & "$PSScriptRoot\catch_up.ps1" 5  # Recursively call to set up lesson 5
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
        & "$PSScriptRoot\catch_up.ps1" 8  # Recursively call to set up lesson 8
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Add descriptions to models\marts\schema.yml"
        Write-Host "2. Create models\docs.md with doc blocks"
        Write-Host "3. Run: dbt docs generate && dbt docs serve"
    }
    
    10 {
        Write-Host "Setting up for Lesson 10: Graph Operators & dbt build"
        Write-Host "======================================================"
        & "$PSScriptRoot\catch_up.ps1" 8  # Recursively call to set up lesson 8
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Run: dbt build"
        Write-Host "2. Practice selection syntax: dbt run --select +dim_customers+"
    }
    
    12 {
        Write-Host "Setting up for Lesson 12: dbt_constraints (Advanced Testing)"
        Write-Host "============================================================="
        & "$PSScriptRoot\catch_up.ps1" 5  # Recursively call to set up lesson 5
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Add dbt_constraints package to packages.yml"
        Write-Host "2. Run: dbt deps"
        Write-Host "3. Follow Lesson 12 instructions"
    }
    
    default {
        Write-Host "Invalid lesson number: $Lesson" -ForegroundColor Red
        Write-Host "Usage: .\scripts\catch_up.ps1 <1-10 or 12>"
        exit 1
    }
}

Write-Host ""
Write-Host "✓ Catch-up complete!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Tip: Run '.\scripts\check_lesson_prerequisites.ps1 $Lesson' to verify all prerequisites are met."
