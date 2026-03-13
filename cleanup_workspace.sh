#!/bin/bash
# cleanup_workspace.sh - Reset local dbt workspace to clean state

set -e

echo "🧹 Cleaning up local dbt workspace..."

# Remove compiled artifacts
echo "  Removing target/ and dbt_packages/..."
rm -rf target/ dbt_packages/

# Remove completed models (keep .gitkeep)
echo "  Removing models/..."
find models/ -type f ! -name '.gitkeep' -delete

# Remove completed tests (keep .gitkeep)
echo "  Removing tests/..."
find tests/ -type f ! -name '.gitkeep' -delete

# Remove seeds (keep .gitkeep)
echo "  Removing seeds/..."
find seeds/ -type f ! -name '.gitkeep' -delete

# Remove snapshots (keep .gitkeep)
echo "  Removing snapshots/..."
find snapshots/ -type f ! -name '.gitkeep' -delete

# Remove all macros except generate_schema_name (keep .gitkeep)
echo "  Removing macros/ (keeping generate_schema_name.sql)..."
find macros/ -type f ! -name '.gitkeep' ! -name 'generate_schema_name.sql' -delete

# Remove package-lock.yml
if [ -f "package-lock.yml" ]; then
    echo "  Removing package-lock.yml..."
    rm package-lock.yml
fi

echo "✅ Local workspace cleaned!"
echo ""
echo "📋 Next steps:"
echo "  1. Copy broken seeds to test failing test workflow:"
echo "     cp assets/seeds/orders_broken.csv seeds/orders.csv"
echo "     cp assets/seeds/*.csv seeds/ (for other seed files)"
echo ""
echo "  2. Start with Lesson 1 and follow instructions to build models"
