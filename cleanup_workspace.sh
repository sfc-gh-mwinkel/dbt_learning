#!/bin/bash
# cleanup_workspace.sh - Reset local dbt workspace to clean state

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── IGNORE LIST ──────────────────────────────────────────────
# Files and folders that should NOT be removed during cleanup.
# Edit these arrays in a client fork to preserve client-specific
# assets without modifying the cleanup logic below.
#
# IGNORE_FILES: filename matches (applies across all directories)
# IGNORE_DIRS:  folder paths relative to project root
#
IGNORE_FILES=(
    ".gitkeep"
    "generate_schema_name.sql"
    # --- Add client-specific files below ---
    # "client_masking_policy.sql"
    # "custom_audit_log.sql"
)

IGNORE_DIRS=(
    # --- Add client-specific folders below ---
    # "models/client_reports"
    # "models/compliance"
    # "macros/client_utils"
    # "tests/client_regression"
)
# ─────────────────────────────────────────────────────────────

clean_directory() {
    local dir="$1"
    local find_args=(-type f)

    for f in "${IGNORE_FILES[@]}"; do
        find_args+=( ! -name "$f" )
    done
    for d in "${IGNORE_DIRS[@]}"; do
        find_args+=( ! -path "$PROJECT_ROOT/$d/*" )
    done

    find "$PROJECT_ROOT/$dir/" "${find_args[@]}" -delete 2>/dev/null || true
}

echo "🧹 Cleaning up local dbt workspace..."

echo "  Removing target/ and dbt_packages/..."
rm -rf "$PROJECT_ROOT/target/" "$PROJECT_ROOT/dbt_packages/"

echo "  Removing models/..."
clean_directory "models"

echo "  Removing tests/..."
clean_directory "tests"

echo "  Removing seeds/..."
clean_directory "seeds"

echo "  Removing snapshots/..."
clean_directory "snapshots"

echo "  Removing macros/..."
clean_directory "macros"

if [ -f "$PROJECT_ROOT/package-lock.yml" ]; then
    echo "  Removing package-lock.yml..."
    rm "$PROJECT_ROOT/package-lock.yml"
fi

# Remove empty subdirectories (but not the top-level dirs themselves)
for dir in models tests seeds snapshots macros; do
    find "$PROJECT_ROOT/$dir/" -mindepth 1 -type d -empty -delete 2>/dev/null || true
done

echo "✅ Local workspace cleaned!"
echo ""
echo "📋 Next steps:"
echo "  1. Copy broken seeds to test failing test workflow:"
echo "     cp assets/seeds/orders_broken.csv seeds/orders.csv"
echo "     cp assets/seeds/*.csv seeds/ (for other seed files)"
echo ""
echo "  2. Start with Lesson 1 and follow instructions to build models"
