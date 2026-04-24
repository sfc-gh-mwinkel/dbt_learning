#!/bin/bash
# Catch-up script for dbt Learning Platform
# Automatically copies missing files to get students caught up to a specific lesson
# Usage: ./scripts/catch_up.sh <lesson_number>

set -e

LESSON=$1
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🚀 Catching up to Lesson $LESSON..."
echo ""

copy_if_missing() {
    local src=$1
    local dest=$2
    local description=$3
    
    if [ ! -f "$PROJECT_ROOT/$dest" ]; then
        mkdir -p "$(dirname "$PROJECT_ROOT/$dest")"
        cp "$PROJECT_ROOT/$src" "$PROJECT_ROOT/$dest"
        echo -e "${GREEN}✓${NC} Copied $description"
    else
        echo -e "${BLUE}→${NC} Already exists: $description"
    fi
}

case $LESSON in
    1)
        echo "Setting up for Lesson 1: Project Setup & First Model"
        echo "======================================================"
        copy_if_missing "assets/seeds/customers.csv" "seeds/customers.csv" "customers.csv"
        copy_if_missing "assets/seeds/orders.csv" "seeds/orders.csv" "orders.csv"
        echo ""
        echo "Next steps:"
        echo "1. Run: dbt seed"
        echo "2. Create models/staging/sources.yml (follow lesson instructions)"
        echo "3. Create models/staging/stg_raw__customers.sql (follow lesson instructions)"
        ;;
        
    2)
        echo "Setting up for Lesson 2: Understanding YML Files"
        echo "================================================="
        # Lesson 1 prereqs
        copy_if_missing "assets/seeds/customers.csv" "seeds/customers.csv" "customers.csv"
        copy_if_missing "assets/seeds/orders.csv" "seeds/orders.csv" "orders.csv"
        copy_if_missing "assets/models/staging/stg_raw__customers.sql" "models/staging/stg_raw__customers.sql" "stg_raw__customers.sql"
        copy_if_missing "assets/models/staging/stg_raw__orders.sql" "models/staging/stg_raw__orders.sql" "stg_raw__orders.sql"
        copy_if_missing "assets/yml_templates/sources.yml" "models/staging/sources.yml" "sources.yml"
        echo ""
        echo "Next steps:"
        echo "1. Run: dbt seed"
        echo "2. Run: dbt run --select staging"
        echo "3. Create stg_raw__customers.yml and stg_raw__orders.yml (follow lesson instructions)"
        ;;
        
    3)
        echo "Setting up for Lesson 3: The Staging Layer"
        echo "==========================================="
        # Copy all seeds
        copy_if_missing "assets/seeds/customers.csv" "seeds/customers.csv" "customers.csv"
        copy_if_missing "assets/seeds/orders.csv" "seeds/orders.csv" "orders.csv"
        copy_if_missing "assets/seeds/products.csv" "seeds/products.csv" "products.csv"
        copy_if_missing "assets/seeds/order_items.csv" "seeds/order_items.csv" "order_items.csv"
        copy_if_missing "assets/seeds/payments.csv" "seeds/payments.csv" "payments.csv"
        # Copy all staging models
        copy_if_missing "assets/models/staging/stg_raw__customers.sql" "models/staging/stg_raw__customers.sql" "stg_raw__customers.sql"
        copy_if_missing "assets/models/staging/stg_raw__orders.sql" "models/staging/stg_raw__orders.sql" "stg_raw__orders.sql"
        copy_if_missing "assets/models/staging/stg_raw__products.sql" "models/staging/stg_raw__products.sql" "stg_raw__products.sql"
        copy_if_missing "assets/models/staging/stg_raw__order_items.sql" "models/staging/stg_raw__order_items.sql" "stg_raw__order_items.sql"
        copy_if_missing "assets/models/staging/stg_raw__payments.sql" "models/staging/stg_raw__payments.sql" "stg_raw__payments.sql"
        copy_if_missing "assets/yml_templates/sources.yml" "models/staging/sources.yml" "sources.yml"
        # Copy staging yml files (1:1 pattern)
        copy_if_missing "assets/yml_templates/staging/stg_raw__customers.yml" "models/staging/stg_raw__customers.yml" "stg_raw__customers.yml"
        copy_if_missing "assets/yml_templates/staging/stg_raw__orders.yml" "models/staging/stg_raw__orders.yml" "stg_raw__orders.yml"
        copy_if_missing "assets/yml_templates/staging/stg_raw__products.yml" "models/staging/stg_raw__products.yml" "stg_raw__products.yml"
        copy_if_missing "assets/yml_templates/staging/stg_raw__order_items.yml" "models/staging/stg_raw__order_items.yml" "stg_raw__order_items.yml"
        copy_if_missing "assets/yml_templates/staging/stg_raw__payments.yml" "models/staging/stg_raw__payments.yml" "stg_raw__payments.yml"
        echo ""
        echo "Next steps:"
        echo "1. Run: dbt seed"
        echo "2. Run: dbt run --select staging"
        echo "3. Run: dbt test --select staging"
        ;;
        
    4)
        echo "Setting up for Lesson 4: Intermediate & Mart Models"
        echo "===================================================="
        # Lesson 3 prereqs
        copy_if_missing "assets/seeds/customers.csv" "seeds/customers.csv" "customers.csv"
        copy_if_missing "assets/seeds/orders.csv" "seeds/orders.csv" "orders.csv"
        copy_if_missing "assets/seeds/products.csv" "seeds/products.csv" "products.csv"
        copy_if_missing "assets/seeds/order_items.csv" "seeds/order_items.csv" "order_items.csv"
        copy_if_missing "assets/seeds/payments.csv" "seeds/payments.csv" "payments.csv"
        copy_if_missing "assets/models/staging/stg_raw__customers.sql" "models/staging/stg_raw__customers.sql" "stg_raw__customers.sql"
        copy_if_missing "assets/models/staging/stg_raw__orders.sql" "models/staging/stg_raw__orders.sql" "stg_raw__orders.sql"
        copy_if_missing "assets/models/staging/stg_raw__products.sql" "models/staging/stg_raw__products.sql" "stg_raw__products.sql"
        copy_if_missing "assets/models/staging/stg_raw__order_items.sql" "models/staging/stg_raw__order_items.sql" "stg_raw__order_items.sql"
        copy_if_missing "assets/models/staging/stg_raw__payments.sql" "models/staging/stg_raw__payments.sql" "stg_raw__payments.sql"
        copy_if_missing "assets/yml_templates/sources.yml" "models/staging/sources.yml" "sources.yml"
        # Lesson 4 - intermediate
        copy_if_missing "assets/models/intermediate/int_orders_with_payments.sql" "models/intermediate/int_orders_with_payments.sql" "int_orders_with_payments.sql"
        copy_if_missing "assets/models/intermediate/int_order_items_with_products.sql" "models/intermediate/int_order_items_with_products.sql" "int_order_items_with_products.sql"
        copy_if_missing "assets/models/intermediate/int_customers__order_summary.sql" "models/intermediate/int_customers__order_summary.sql" "int_customers__order_summary.sql"
        # Lesson 4 - mart models
        copy_if_missing "assets/models/marts/dim_customers.sql" "models/marts/dim_customers.sql" "dim_customers.sql"
        copy_if_missing "assets/models/marts/fct_orders.sql" "models/marts/fct_orders.sql" "fct_orders.sql"
        echo ""
        echo "Next steps:"
        echo "1. Run: dbt seed"
        echo "2. Run: dbt run"
        echo "3. Review the complete data flow: staging → intermediate → marts"
        ;;
        
    5)
        echo "Setting up for Lesson 5: Testing & Data Quality"
        echo "================================================"
        # All previous prereqs
        "$0" 4  # Recursively call to set up lesson 4
        # Copy intermediate yml files (1:1 pattern)
        copy_if_missing "assets/yml_templates/intermediate/int_orders_with_payments.yml" "models/intermediate/int_orders_with_payments.yml" "int_orders_with_payments.yml"
        copy_if_missing "assets/yml_templates/intermediate/int_order_items_with_products.yml" "models/intermediate/int_order_items_with_products.yml" "int_order_items_with_products.yml"
        copy_if_missing "assets/yml_templates/intermediate/int_customers__order_summary.yml" "models/intermediate/int_customers__order_summary.yml" "int_customers__order_summary.yml"
        # Copy marts yml files (1:1 pattern)
        copy_if_missing "assets/yml_templates/marts/dim_customers.yml" "models/marts/dim_customers.yml" "dim_customers.yml"
        copy_if_missing "assets/yml_templates/marts/fct_orders.yml" "models/marts/fct_orders.yml" "fct_orders.yml"
        copy_if_missing "assets/tests/assert_order_amount_matches_line_items.sql" "tests/assert_order_amount_matches_line_items.sql" "singular test"
        echo ""
        echo "Next steps:"
        echo "1. Run: dbt deps (install dbt_utils)"
        echo "2. Run: dbt test"
        ;;
        
    6)
        echo "Setting up for Lesson 6: dbt_project.yml Deep Dive"
        echo "==================================================="
        echo "No additional files needed beyond Lesson 5 setup."
        "$0" 5  # Recursively call to set up lesson 5
        ;;
        
    7)
        echo "Setting up for Lesson 7: Snapshots & SCD Type 2"
        echo "================================================"
        "$0" 5  # Recursively call to set up lesson 5
        copy_if_missing "assets/snapshots/snap_orders.sql" "snapshots/snap_orders.sql" "snap_orders.sql"
        echo ""
        echo "Next steps:"
        echo "1. Run: dbt snapshot"
        echo "2. Modify seeds/orders.csv to simulate changes"
        echo "3. Run: dbt seed && dbt snapshot"
        ;;
        
    8)
        echo "Setting up for Lesson 8: Writing Macros"
        echo "========================================"
        "$0" 5  # Recursively call to set up lesson 5
        copy_if_missing "assets/macros/clean_string.sql" "macros/clean_string.sql" "clean_string macro"
        copy_if_missing "assets/macros/classify_tier.sql" "macros/classify_tier.sql" "classify_tier macro"
        copy_if_missing "assets/macros/cents_to_dollars.sql" "macros/cents_to_dollars.sql" "cents_to_dollars macro"
        copy_if_missing "assets/macros/generate_schema_name.sql" "macros/generate_schema_name.sql" "generate_schema_name macro"
        echo ""
        echo "Next steps:"
        echo "1. Run: dbt compile --select dim_customers"
        echo "2. Review compiled SQL in target/compiled/"
        ;;
        
    9)
        echo "Setting up for Lesson 9: Documentation & dbt docs"
        echo "=================================================="
        "$0" 8  # Recursively call to set up lesson 8
        echo ""
        echo "Next steps:"
        echo "1. Add descriptions to model .yml files"
        echo "2. Create models/docs.md with doc blocks"
        echo "3. Run: dbt docs generate && dbt docs serve"
        ;;
        
    10)
        echo "Setting up for Lesson 10: Graph Operators & dbt build"
        echo "======================================================"
        "$0" 8  # Recursively call to set up lesson 8
        echo ""
        echo "Next steps:"
        echo "1. Run: dbt build"
        echo "2. Practice selection syntax: dbt run --select +dim_customers+"
        ;;
        
    11)
        echo "Setting up for Lesson 11: dbt_constraints (Enterprise Data Quality)"
        echo "===================================================================="
        "$0" 5  # Recursively call to set up lesson 5
        echo ""
        echo "Next steps:"
        echo "1. Add dbt_constraints package to packages.yml"
        echo "2. Run: dbt deps"
        echo "3. Follow Lesson 11 instructions"
        ;;
        
    12)
        echo "Setting up for Lesson 12: Production Patterns"
        echo "=============================================="
        "$0" 8  # Recursively call to set up lesson 8
        # Copy incremental model examples
        copy_if_missing "assets/models/marts/fct_orders_incremental.sql" "models/marts/fct_orders_incremental.sql" "fct_orders_incremental.sql"
        copy_if_missing "assets/models/marts/fct_daily_revenue.sql" "models/marts/fct_daily_revenue.sql" "fct_daily_revenue.sql"
        copy_if_missing "assets/yml_templates/marts/fct_orders_incremental.yml" "models/marts/fct_orders_incremental.yml" "fct_orders_incremental.yml"
        copy_if_missing "assets/yml_templates/marts/fct_daily_revenue.yml" "models/marts/fct_daily_revenue.yml" "fct_daily_revenue.yml"
        copy_if_missing "assets/yml_templates/exposures.yml" "models/exposures.yml" "exposures.yml"
        echo ""
        echo "Next steps:"
        echo "1. Run: dbt run --select fct_orders_incremental"
        echo "2. Run it again to see incremental behavior"
        echo "3. Explore exposures with: dbt docs generate && dbt docs serve"
        ;;
        
    *)
        echo -e "${YELLOW}Invalid lesson number: $LESSON${NC}"
        echo "Usage: ./scripts/catch_up.sh <1-12>"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Catch-up complete!${NC}"
echo ""
echo "💡 Tip: Run './scripts/check_lesson_prerequisites.sh $LESSON' to verify all prerequisites are met."
