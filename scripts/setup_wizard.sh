#!/bin/bash
# Interactive Setup Wizard for dbt Learning Platform
# Usage: ./scripts/setup_wizard.sh [--test]
#   --test  Run in non-interactive mode (for testing)

set -e

# Parse arguments
TEST_MODE=false
if [[ "$1" == "--test" ]]; then
    TEST_MODE=true
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       dbt Learning Platform - Setup Wizard                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Helper functions
check_mark() { echo -e "${GREEN}✓${NC} $1"; }
warn_mark() { echo -e "${YELLOW}⚠${NC} $1"; }
error_mark() { echo -e "${RED}✗${NC} $1"; }
info_mark() { echo -e "${BLUE}ℹ${NC} $1"; }

prompt_continue() {
    if [ "$TEST_MODE" = true ]; then
        echo ""
        return
    fi
    echo ""
    read -p "Press Enter to continue (or Ctrl+C to exit)..."
    echo ""
}

# ============================================================================
# PHASE 1: Python Environment
# ============================================================================
echo -e "${BLUE}━━━ Phase 1: Python Environment ━━━${NC}"
echo ""

# Check Python
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
fi

if [ -z "$PYTHON_CMD" ]; then
    error_mark "Python not found. Please install Python 3.9 or higher."
    echo "   Visit: https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 9 ]); then
    error_mark "Python $PYTHON_VERSION found, but 3.9+ is required."
    exit 1
fi

check_mark "Python $PYTHON_VERSION found"

# Create/check virtual environment
if [ -d "$PROJECT_ROOT/.venv" ]; then
    check_mark "Virtual environment exists at .venv/"
else
    info_mark "Creating virtual environment..."
    $PYTHON_CMD -m venv "$PROJECT_ROOT/.venv"
    check_mark "Virtual environment created"
fi

# Activate virtual environment
info_mark "Activating virtual environment..."
source "$PROJECT_ROOT/.venv/bin/activate"
check_mark "Virtual environment activated"

# Install/check dbt
if pip show dbt-core &> /dev/null && pip show dbt-snowflake &> /dev/null; then
    DBT_VERSION=$(pip show dbt-core | grep Version | cut -d' ' -f2)
    check_mark "dbt-core $DBT_VERSION already installed"
else
    info_mark "Installing dbt-core and dbt-snowflake..."
    pip install --upgrade pip --quiet
    pip install dbt-core dbt-snowflake --quiet
    DBT_VERSION=$(pip show dbt-core | grep Version | cut -d' ' -f2)
    check_mark "dbt-core $DBT_VERSION installed"
fi

echo ""
echo -e "${GREEN}Phase 1 Complete!${NC}"

# ============================================================================
# PHASE 2: Snowflake Connection
# ============================================================================
prompt_continue
echo -e "${BLUE}━━━ Phase 2: Snowflake Connection ━━━${NC}"
echo ""

# Check for existing profiles.yml
PROFILES_PATH="$HOME/.dbt/profiles.yml"
PROFILE_EXISTS=false

if [ -f "$PROFILES_PATH" ]; then
    if grep -q "dbt_learning:" "$PROFILES_PATH" 2>/dev/null; then
        check_mark "Found existing dbt_learning profile in ~/.dbt/profiles.yml"
        PROFILE_EXISTS=true
    else
        warn_mark "profiles.yml exists but no dbt_learning profile found"
    fi
else
    info_mark "No profiles.yml found - we'll create one"
fi

if [ "$PROFILE_EXISTS" = false ]; then
    if [ "$TEST_MODE" = true ]; then
        error_mark "No dbt_learning profile found. In test mode, profile must already exist."
        echo "   Please run the wizard interactively first, or manually create ~/.dbt/profiles.yml"
        exit 1
    fi
    
    echo ""
    echo "Let's set up your Snowflake connection."
    echo ""
    
    # Gather connection info
    read -p "Snowflake account (e.g., abc12345.us-west-2): " SF_ACCOUNT
    read -p "Snowflake username: " SF_USER
    read -p "Snowflake role [ACCOUNTADMIN]: " SF_ROLE
    SF_ROLE=${SF_ROLE:-ACCOUNTADMIN}
    read -p "Snowflake warehouse [COMPUTE_WH]: " SF_WAREHOUSE
    SF_WAREHOUSE=${SF_WAREHOUSE:-COMPUTE_WH}
    read -p "Database name [DBT_LEARNING]: " SF_DATABASE
    SF_DATABASE=${SF_DATABASE:-DBT_LEARNING}
    
    echo ""
    echo "Authentication method:"
    echo "  1) SSO/Okta (externalbrowser) - Opens browser for login"
    echo "  2) Key-pair (SNOWFLAKE_JWT) - Uses private key file"
    echo "  3) Username/Password - Basic authentication"
    echo ""
    read -p "Choose [1/2/3]: " AUTH_CHOICE
    
    # Create profiles.yml
    mkdir -p "$HOME/.dbt"
    
    case $AUTH_CHOICE in
        1)
            AUTH_TYPE="externalbrowser"
            cat > "$PROFILES_PATH" << EOF
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: $SF_ACCOUNT
      user: $SF_USER
      role: $SF_ROLE
      warehouse: $SF_WAREHOUSE
      database: $SF_DATABASE
      schema: public
      authenticator: externalbrowser
      threads: 4
EOF
            check_mark "Created profiles.yml with SSO authentication"
            ;;
        2)
            read -p "Path to private key file [~/.snowflake/rsa_key.p8]: " KEY_PATH
            KEY_PATH=${KEY_PATH:-~/.snowflake/rsa_key.p8}
            KEY_PATH="${KEY_PATH/#\~/$HOME}"
            
            if [ ! -f "$KEY_PATH" ]; then
                warn_mark "Key file not found. Would you like to generate a new key pair?"
                read -p "Generate key pair? [y/N]: " GEN_KEY
                if [[ "$GEN_KEY" =~ ^[Yy]$ ]]; then
                    mkdir -p "$(dirname "$KEY_PATH")"
                    openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out "$KEY_PATH" -nocrypt 2>/dev/null
                    chmod 600 "$KEY_PATH"
                    PUB_KEY_PATH="${KEY_PATH%.p8}.pub"
                    openssl rsa -in "$KEY_PATH" -pubout -out "$PUB_KEY_PATH" 2>/dev/null
                    check_mark "Generated key pair"
                    echo ""
                    echo -e "${YELLOW}IMPORTANT: Add this public key to your Snowflake user:${NC}"
                    echo ""
                    echo "  ALTER USER $SF_USER SET RSA_PUBLIC_KEY='"
                    grep -v "PUBLIC KEY" "$PUB_KEY_PATH" | tr -d '\n'
                    echo "';"
                    echo ""
                    prompt_continue
                fi
            fi
            
            cat > "$PROFILES_PATH" << EOF
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: $SF_ACCOUNT
      user: $SF_USER
      role: $SF_ROLE
      warehouse: $SF_WAREHOUSE
      database: $SF_DATABASE
      schema: public
      authenticator: SNOWFLAKE_JWT
      private_key_path: $KEY_PATH
      threads: 4
EOF
            check_mark "Created profiles.yml with key-pair authentication"
            ;;
        3)
            echo ""
            warn_mark "Password authentication is less secure. Consider using SSO or key-pair."
            read -s -p "Snowflake password: " SF_PASSWORD
            echo ""
            
            cat > "$PROFILES_PATH" << EOF
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: $SF_ACCOUNT
      user: $SF_USER
      password: "$SF_PASSWORD"
      role: $SF_ROLE
      warehouse: $SF_WAREHOUSE
      database: $SF_DATABASE
      schema: public
      threads: 4
EOF
            chmod 600 "$PROFILES_PATH"
            check_mark "Created profiles.yml with password authentication"
            ;;
        *)
            error_mark "Invalid choice"
            exit 1
            ;;
    esac
fi

# Test connection
echo ""
info_mark "Testing Snowflake connection..."
echo ""

cd "$PROJECT_ROOT"
if dbt debug 2>&1 | grep -q "All checks passed"; then
    check_mark "Connection test passed!"
else
    error_mark "Connection test failed. Please check your profiles.yml"
    echo ""
    echo "Run 'dbt debug' for detailed error information."
    echo "See SETUP_WIZARD.md for troubleshooting tips."
    exit 1
fi

echo ""
echo -e "${GREEN}Phase 2 Complete!${NC}"

# ============================================================================
# PHASE 3: Project Setup
# ============================================================================
prompt_continue
echo -e "${BLUE}━━━ Phase 3: Project Setup ━━━${NC}"
echo ""

# Install dbt packages
info_mark "Installing dbt packages..."
cd "$PROJECT_ROOT"
dbt deps --quiet
check_mark "dbt packages installed"

# Quick test
echo ""
info_mark "Running quick verification test..."

# Copy test seeds if not present
if [ ! -f "$PROJECT_ROOT/seeds/customers.csv" ]; then
    cp "$PROJECT_ROOT/assets/seeds/customers.csv" "$PROJECT_ROOT/seeds/"
    cp "$PROJECT_ROOT/assets/seeds/orders.csv" "$PROJECT_ROOT/seeds/"
fi

# Run seed
if dbt seed --select customers orders 2>&1 | grep -qE "(Completed successfully|OK loaded)"; then
    check_mark "Seed data loaded successfully"
else
    warn_mark "Seed loading had issues - check 'dbt seed' output"
fi

# Clean up test seeds (leave repo in clean state)
rm -f "$PROJECT_ROOT/seeds/customers.csv" "$PROJECT_ROOT/seeds/orders.csv"

echo ""
echo -e "${GREEN}Phase 3 Complete!${NC}"

# ============================================================================
# COMPLETE
# ============================================================================
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    Setup Complete! 🎉                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Your environment is ready for the dbt Learning Platform!"
echo ""
echo -e "${BLUE}Quick Start:${NC}"
echo ""
echo "  1. Activate the virtual environment:"
echo "     source .venv/bin/activate"
echo ""
echo "  2. Start with Lesson 1:"
echo "     cat lessons/01_project_setup.md"
echo ""
echo "  3. Or run the prerequisite check:"
echo "     ./scripts/check_lesson_prerequisites.sh 1"
echo ""
echo -e "${BLUE}Your Schema Prefix:${NC}"

# Get username from profiles.yml if not already set
if [ -z "$SF_USER" ]; then
    SF_USER=$(grep -A10 'dbt_learning:' ~/.dbt/profiles.yml | grep 'user:' | head -1 | sed 's/.*user: *//' | tr -d '"' | tr -d "'")
fi

# Calculate schema prefix
SF_USER_LOWER=$(echo "$SF_USER" | tr '[:upper:]' '[:lower:]')
if [[ "$SF_USER_LOWER" == *"@"* ]]; then
    SF_USER_LOWER=$(echo "$SF_USER_LOWER" | cut -d'@' -f1)
fi

if [[ "$SF_USER_LOWER" == *"."* ]]; then
    FIRST_CHAR=$(echo "$SF_USER_LOWER" | cut -c1)
    LAST_NAME=$(echo "$SF_USER_LOWER" | rev | cut -d'.' -f1 | rev)
    SCHEMA_PREFIX=$(echo "${FIRST_CHAR}${LAST_NAME}" | tr '[:lower:]' '[:upper:]')
else
    SCHEMA_PREFIX=$(echo "$SF_USER_LOWER" | tr '[:lower:]' '[:upper:]')
fi

echo "  Your models will be created in schemas like:"
echo "    - ${SCHEMA_PREFIX}_RAW"
echo "    - ${SCHEMA_PREFIX}_STAGING"
echo "    - ${SCHEMA_PREFIX}_MARTS"
echo ""
echo -e "${YELLOW}Happy learning!${NC}"
echo ""
