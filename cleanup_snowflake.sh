#!/bin/bash
# cleanup_snowflake.sh - Drop all Snowflake schemas created by dbt

set -e

# Check if connection name is provided
CONNECTION=${1:-snowsecure_deploy}

echo "🗑️  Cleaning up Snowflake artifacts..."
echo "  Using connection: $CONNECTION"
echo ""

# Get the current user's prefix from profiles.yml
# This is a simplified version - you may need to adjust based on your setup
USER=$(snow sql -c "$CONNECTION" -q "SELECT CURRENT_USER()" 2>/dev/null | grep -v "^+" | grep -v "CURRENT_USER" | grep -v "^-" | head -1 | xargs)

if [ -z "$USER" ]; then
    echo "❌ Could not determine current user. Please check your Snowflake connection."
    exit 1
fi

echo "  Current user: $USER"

# Extract prefix (first initial + last name)
# Handle different formats: john.doe@company.com, JOHN.DOE, john_doe
PREFIX=""
if [[ "$USER" == *"@"* ]]; then
    USER_PART="${USER%%@*}"  # Remove @company.com
    USER_CLEAN="${USER_PART//./_}"  # Replace . with _
elif [[ "$USER" == *"."* ]]; then
    USER_CLEAN="${USER//./_}"
else
    USER_CLEAN="$USER"
fi

# Convert to uppercase and extract prefix
USER_UPPER=$(echo "$USER_CLEAN" | tr '[:lower:]' '[:upper:]')
if [[ "$USER_UPPER" == *"_"* ]]; then
    IFS='_' read -ra PARTS <<< "$USER_UPPER"
    FIRST="${PARTS[0]}"
    LAST="${PARTS[-1]}"
    PREFIX="${FIRST:0:1}${LAST}"
else
    # If no delimiter, use whole username
    PREFIX="$USER_UPPER"
fi

echo "  User prefix: $PREFIX"
echo ""

# Drop schemas
SCHEMAS=(
    "${PREFIX}_RAW"
    "${PREFIX}_STAGING"
    "${PREFIX}_INTERMEDIATE"
    "${PREFIX}_MARTS"
    "${PREFIX}_DBT_TEST__AUDIT"
    "public_snapshots"
)

for SCHEMA in "${SCHEMAS[@]}"; do
    echo "  Dropping schema: $SCHEMA"
    snow sql -c "$CONNECTION" -q "DROP SCHEMA IF EXISTS DBT_LEARNING.$SCHEMA CASCADE" 2>/dev/null || echo "    (schema may not exist)"
done

echo ""
echo "✅ Snowflake artifacts cleaned!"
echo ""
echo "📋 Database preserved:"
echo "  DBT_LEARNING database still exists for future runs"
