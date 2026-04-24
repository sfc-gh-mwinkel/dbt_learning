#!/bin/bash
# Checkpoint validation script for dbt Learning Platform
# Usage: ./scripts/check_lesson_prerequisites.sh <lesson_number>

set -e

LESSON=$1
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔍 Checking prerequisites for Lesson $LESSON..."
echo ""

check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$PROJECT_ROOT/$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        echo "   Missing: $file"
        return 1
    fi
}

check_model() {
    local model=$1
    local description=$2
    
    if [ -f "$PROJECT_ROOT/models/$model" ]; then
        echo -e "${GREEN}✓${NC} $description"
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        echo "   Missing: models/$model"
        echo "   Run: cp assets/models/$model models/$model"
        return 1
    fi
}

check_seed() {
    local seed=$1
    local description=$2
    
    if [ -f "$PROJECT_ROOT/seeds/$seed" ]; then
        echo -e "${GREEN}✓${NC} $description"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $description"
        echo "   Missing: seeds/$seed"
        echo "   Run: cp assets/seeds/$seed seeds/"
        return 1
    fi
}

all_checks_passed=true

case $LESSON in
    1)
        echo "Lesson 1: Project Setup & First Model"
        echo "======================================="
        check_file "dbt_project.yml" "dbt_project.yml exists" || all_checks_passed=false
        check_seed "customers.csv" "customers.csv seed file" || all_checks_passed=false
        check_seed "orders.csv" "orders.csv seed file" || all_checks_passed=false
        check_file "models/staging/sources.yml" "sources.yml configuration" || all_checks_passed=false
        check_model "staging/stg_raw__customers.sql" "stg_raw__customers model" || all_checks_passed=false
        ;;
        
    2)
        echo "Lesson 2: Understanding YML Files"
        echo "=================================="
        check_file "models/staging/sources.yml" "sources.yml with tests" || all_checks_passed=false
        check_file "models/staging/schema.yml" "schema.yml for staging models" || all_checks_passed=false
        check_model "staging/stg_raw__customers.sql" "stg_raw__customers model" || all_checks_passed=false
        check_model "staging/stg_raw__orders.sql" "stg_raw__orders model" || all_checks_passed=false
        ;;
        
    3)
        echo "Lesson 3: The Staging Layer"
        echo "============================"
        check_seed "customers.csv" "customers.csv" || all_checks_passed=false
        check_seed "orders.csv" "orders.csv" || all_checks_passed=false
        check_seed "products.csv" "products.csv" || all_checks_passed=false
        check_seed "order_items.csv" "order_items.csv" || all_checks_passed=false
        check_seed "payments.csv" "payments.csv" || all_checks_passed=false
        check_model "staging/stg_raw__customers.sql" "stg_raw__customers" || all_checks_passed=false
        check_model "staging/stg_raw__orders.sql" "stg_raw__orders" || all_checks_passed=false
        check_model "staging/stg_raw__products.sql" "stg_raw__products" || all_checks_passed=false
        check_model "staging/stg_raw__order_items.sql" "stg_raw__order_items" || all_checks_passed=false
        check_model "staging/stg_raw__payments.sql" "stg_raw__payments" || all_checks_passed=false
        ;;
        
    4)
        echo "Lesson 4: Intermediate & Mart Models"
        echo "====================================="
        # Check all staging models exist
        check_model "staging/stg_raw__customers.sql" "stg_raw__customers" || all_checks_passed=false
        check_model "staging/stg_raw__orders.sql" "stg_raw__orders" || all_checks_passed=false
        check_model "staging/stg_raw__products.sql" "stg_raw__products" || all_checks_passed=false
        check_model "staging/stg_raw__order_items.sql" "stg_raw__order_items" || all_checks_passed=false
        check_model "staging/stg_raw__payments.sql" "stg_raw__payments" || all_checks_passed=false
        # Check intermediate models
        check_model "intermediate/int_orders_with_payments.sql" "int_orders_with_payments" || all_checks_passed=false
        check_model "intermediate/int_order_items_with_products.sql" "int_order_items_with_products" || all_checks_passed=false
        check_model "intermediate/int_customers__order_summary.sql" "int_customers__order_summary" || all_checks_passed=false
        # Check mart models
        check_model "marts/dim_customers.sql" "dim_customers" || all_checks_passed=false
        check_model "marts/fct_orders.sql" "fct_orders" || all_checks_passed=false
        ;;
        
    5)
        echo "Lesson 5: Testing & Data Quality"
        echo "================================="
        check_file "packages.yml" "packages.yml with dbt_utils" || all_checks_passed=false
        check_model "marts/dim_customers.sql" "dim_customers" || all_checks_passed=false
        check_model "marts/fct_orders.sql" "fct_orders" || all_checks_passed=false
        check_file "models/marts/schema.yml" "schema.yml with tests" || all_checks_passed=false
        ;;
        
    6)
        echo "Lesson 6: dbt_project.yml Deep Dive"
        echo "===================================="
        check_file "dbt_project.yml" "dbt_project.yml configured" || all_checks_passed=false
        ;;
        
    7)
        echo "Lesson 7: Snapshots & SCD Type 2"
        echo "================================="
        check_seed "orders.csv" "orders.csv seed" || all_checks_passed=false
        check_file "models/staging/sources.yml" "sources.yml" || all_checks_passed=false
        ;;
        
    8)
        echo "Lesson 8: Writing Macros"
        echo "========================"
        check_model "marts/dim_customers.sql" "dim_customers" || all_checks_passed=false
        ;;
        
    9)
        echo "Lesson 9: Documentation & dbt docs"
        echo "==================================="
        check_file "models/marts/schema.yml" "schema.yml with descriptions" || all_checks_passed=false
        check_model "marts/dim_customers.sql" "dim_customers" || all_checks_passed=false
        check_model "marts/fct_orders.sql" "fct_orders" || all_checks_passed=false
        ;;
        
    10)
        echo "Lesson 10: Graph Operators & dbt build"
        echo "======================================="
        # All models should exist by now
        check_model "marts/dim_customers.sql" "dim_customers" || all_checks_passed=false
        check_model "marts/fct_orders.sql" "fct_orders" || all_checks_passed=false
        ;;
        
    *)
        echo -e "${RED}Invalid lesson number: $LESSON${NC}"
        echo "Usage: ./scripts/check_lesson_prerequisites.sh <1-10>"
        exit 1
        ;;
esac

echo ""
if [ "$all_checks_passed" = true ]; then
    echo -e "${GREEN}✓ All prerequisites met! Ready to start Lesson $LESSON.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some prerequisites are missing. Please complete the steps above.${NC}"
    echo ""
    echo "💡 Tip: Run './scripts/catch_up.sh $LESSON' to automatically copy missing files."
    exit 1
fi
