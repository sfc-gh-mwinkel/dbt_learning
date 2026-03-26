#!/usr/bin/env python3
"""
dbt Learning Platform - Interactive Runner
Cross-platform wrapper that works on any OS / shell where Python 3 is available.

Usage:
    python run.py              Interactive menu
    python run.py cleanup      Clean local workspace
    python run.py catchup 8    Catch up to lesson 8
    python run.py check 8      Check prerequisites for lesson 8
    python run.py status       Show current workspace status
"""
import os
import platform
import shutil
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent

IGNORE_FILES = {
    ".gitkeep",
    "generate_schema_name.sql",
    # --- Add client-specific files below ---
    # "client_masking_policy.sql",
}

IGNORE_DIRS = {
    # --- Add client-specific folders below (relative to project root) ---
    # "models/client_reports",
    # "macros/client_utils",
}

CLEAN_DIRS = ["models", "tests", "seeds", "snapshots", "macros"]

LESSONS = {
    1:  "Project Setup & First Model",
    2:  "Understanding YML Files",
    3:  "The Staging Layer",
    4:  "Intermediate & Mart Models",
    5:  "Testing & Data Quality",
    6:  "dbt_project.yml Deep Dive",
    7:  "Snapshots & SCD Type 2",
    8:  "Writing Macros",
    9:  "Documentation & dbt docs",
    10: "Graph Operators & dbt build",
    11: "dbt_constraints (Enterprise Data Quality)",
    12: "Production Patterns",
}

# ---------------------------------------------------------------------------
# Colour helpers (works on Windows 10+, macOS, Linux)
# ---------------------------------------------------------------------------

def _supports_color():
    if os.environ.get("NO_COLOR"):
        return False
    if hasattr(sys.stdout, "isatty") and sys.stdout.isatty():
        return True
    return False

_COLOR = _supports_color()

def _c(code, text):
    return f"\033[{code}m{text}\033[0m" if _COLOR else text

def green(t):  return _c("32", t)
def red(t):    return _c("31", t)
def yellow(t): return _c("33", t)
def cyan(t):   return _c("36", t)
def bold(t):   return _c("1", t)
def dim(t):    return _c("2", t)

# ---------------------------------------------------------------------------
# Input helpers
# ---------------------------------------------------------------------------

def ask(prompt, valid=None):
    while True:
        try:
            val = input(prompt).strip()
        except (KeyboardInterrupt, EOFError):
            print()
            sys.exit(0)
        if valid is None or val in valid:
            return val
        print(red(f"  Invalid choice: {val}"))

def confirm(prompt):
    return ask(f"{prompt} [y/n] ", {"y", "n", "Y", "N"}).lower() == "y"

def pause():
    ask(dim("\nPress Enter to return to menu..."), valid=None)

# ---------------------------------------------------------------------------
# Workspace status
# ---------------------------------------------------------------------------

def count_files(directory, exclude_gitkeep=True):
    d = PROJECT_ROOT / directory
    if not d.exists():
        return 0
    count = 0
    for f in d.rglob("*"):
        if f.is_file():
            if exclude_gitkeep and f.name == ".gitkeep":
                continue
            count += 1
    return count

def show_status():
    print(bold("\n  Workspace Status"))
    print("  " + "=" * 40)
    print(f"  Project root : {PROJECT_ROOT}")
    print(f"  Platform     : {platform.system()} ({platform.machine()})")
    print(f"  Python       : {sys.version.split()[0]}")
    print()
    total = 0
    for d in CLEAN_DIRS:
        n = count_files(d)
        total += n
        indicator = green(f"{n:>3} files") if n > 0 else dim("  empty")
        print(f"  {d + '/':<14} {indicator}")
    has_target = (PROJECT_ROOT / "target").exists()
    has_pkgs = (PROJECT_ROOT / "dbt_packages").exists()
    print(f"  {'target/':<14} {'exists' if has_target else dim('  absent')}")
    print(f"  {'dbt_packages/':<14} {'exists' if has_pkgs else dim('  absent')}")
    print()
    if total == 0:
        print(dim("  Workspace is clean."))
    else:
        print(f"  {bold(str(total))} working files across {len(CLEAN_DIRS)} directories.")
    print()

# ---------------------------------------------------------------------------
# Cleanup workspace
# ---------------------------------------------------------------------------

def _is_ignored(filepath: Path) -> bool:
    if filepath.name in IGNORE_FILES:
        return True
    rel = filepath.relative_to(PROJECT_ROOT).as_posix()
    for d in IGNORE_DIRS:
        if rel.startswith(d + "/") or rel == d:
            return True
    return False

def cleanup_workspace(interactive=True):
    if interactive:
        show_status()
        if not confirm("  Proceed with cleanup?"):
            print(yellow("  Cancelled."))
            return

    print(bold("\n  Cleaning workspace..."))

    for name in ["target", "dbt_packages"]:
        p = PROJECT_ROOT / name
        if p.exists():
            shutil.rmtree(p)
            print(f"  {green('x')} Removed {name}/")

    lock = PROJECT_ROOT / "package-lock.yml"
    if lock.exists():
        lock.unlink()
        print(f"  {green('x')} Removed package-lock.yml")

    removed = 0
    for d in CLEAN_DIRS:
        dp = PROJECT_ROOT / d
        if not dp.exists():
            continue
        for f in list(dp.rglob("*")):
            if f.is_file() and not _is_ignored(f):
                f.unlink()
                removed += 1

    for d in CLEAN_DIRS:
        dp = PROJECT_ROOT / d
        if not dp.exists():
            continue
        for sub in sorted(dp.rglob("*"), key=lambda p: len(str(p)), reverse=True):
            if sub.is_dir() and not any(sub.iterdir()):
                sub.rmdir()

    print(f"  {green('x')} Removed {removed} file(s)")
    print(green("\n  Workspace cleaned!"))
    print(dim("  Preserved: .gitkeep files, generate_schema_name.sql, ignored items"))

# ---------------------------------------------------------------------------
# Catch-up
# ---------------------------------------------------------------------------

def _copy(src_rel, dest_rel):
    src = PROJECT_ROOT / src_rel
    dest = PROJECT_ROOT / dest_rel
    if dest.exists():
        print(f"    {cyan('>')} Already exists: {dest.name}")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    print(f"    {green('+')} Copied {dest.name}")

def _catch_up(lesson: int):
    if lesson == 1:
        _copy("assets/seeds/customers.csv", "seeds/customers.csv")
        _copy("assets/seeds/orders.csv", "seeds/orders.csv")
    elif lesson == 2:
        _catch_up(1)
        _copy("assets/models/staging/stg_customers.sql", "models/staging/stg_customers.sql")
        _copy("assets/models/staging/stg_orders.sql", "models/staging/stg_orders.sql")
        _copy("assets/yml_templates/sources.yml", "models/staging/sources.yml")
    elif lesson == 3:
        _catch_up(2)
        for s in ["products.csv", "order_items.csv", "payments.csv"]:
            _copy(f"assets/seeds/{s}", f"seeds/{s}")
        for m in ["stg_products.sql", "stg_order_items.sql", "stg_payments.sql"]:
            _copy(f"assets/models/staging/{m}", f"models/staging/{m}")
        for y in ["stg_customers.yml", "stg_orders.yml", "stg_products.yml",
                   "stg_order_items.yml", "stg_payments.yml"]:
            _copy(f"assets/yml_templates/staging/{y}", f"models/staging/{y}")
    elif lesson == 4:
        _catch_up(3)
        for m in ["int_orders_with_payments.sql", "int_order_items_with_products.sql",
                   "int_customers__order_summary.sql"]:
            _copy(f"assets/models/intermediate/{m}", f"models/intermediate/{m}")
        _copy("assets/models/marts/dim_customers.sql", "models/marts/dim_customers.sql")
        _copy("assets/models/marts/fct_orders.sql", "models/marts/fct_orders.sql")
    elif lesson == 5:
        _catch_up(4)
        for y in ["int_orders_with_payments.yml", "int_order_items_with_products.yml",
                   "int_customers__order_summary.yml"]:
            _copy(f"assets/yml_templates/intermediate/{y}", f"models/intermediate/{y}")
        _copy("assets/yml_templates/marts/dim_customers.yml", "models/marts/dim_customers.yml")
        _copy("assets/yml_templates/marts/fct_orders.yml", "models/marts/fct_orders.yml")
        _copy("assets/tests/assert_order_amount_matches_line_items.sql",
              "tests/assert_order_amount_matches_line_items.sql")
    elif lesson == 6:
        _catch_up(5)
    elif lesson == 7:
        _catch_up(5)
        _copy("assets/snapshots/snap_orders.sql", "snapshots/snap_orders.sql")
    elif lesson == 8:
        _catch_up(5)
        for m in ["clean_string.sql", "classify_tier.sql", "cents_to_dollars.sql",
                   "generate_schema_name.sql"]:
            _copy(f"assets/macros/{m}", f"macros/{m}")
    elif lesson == 9:
        _catch_up(8)
    elif lesson == 10:
        _catch_up(8)
    elif lesson == 11:
        _catch_up(5)
    elif lesson == 12:
        _catch_up(8)
        for m in ["fct_orders_incremental.sql", "fct_daily_revenue.sql"]:
            _copy(f"assets/models/marts/{m}", f"models/marts/{m}")
        for y in ["fct_orders_incremental.yml", "fct_daily_revenue.yml"]:
            _copy(f"assets/yml_templates/marts/{y}", f"models/marts/{y}")
        _copy("assets/yml_templates/exposures.yml", "models/exposures.yml")

NEXT_STEPS = {
    1:  ["dbt seed",
         "Create models/staging/sources.yml (follow lesson instructions)",
         "Create models/staging/stg_customers.sql (follow lesson instructions)"],
    2:  ["dbt seed", "dbt run --select staging",
         "Create stg_customers.yml and stg_orders.yml (follow lesson instructions)"],
    3:  ["dbt seed", "dbt run --select staging", "dbt test --select staging"],
    4:  ["dbt seed", "dbt run",
         "Review the complete data flow: staging > intermediate > marts"],
    5:  ["dbt deps (install dbt_utils)", "dbt test"],
    6:  ["Review dbt_project.yml settings"],
    7:  ["dbt snapshot", "Modify seeds/orders.csv to simulate changes",
         "dbt seed && dbt snapshot"],
    8:  ["dbt compile --select dim_customers",
         "Review compiled SQL in target/compiled/"],
    9:  ["Add descriptions to model .yml files",
         "Create models/docs.md with doc blocks",
         "dbt docs generate && dbt docs serve"],
    10: ["dbt build",
         "Practice selection syntax: dbt run --select +dim_customers+"],
    11: ["Add dbt_constraints package to packages.yml", "dbt deps",
         "Follow Lesson 11 instructions"],
    12: ["dbt run --select fct_orders_incremental",
         "Run it again to see incremental behavior",
         "Explore exposures with: dbt docs generate && dbt docs serve"],
}

def catch_up(lesson: int, interactive=True):
    title = LESSONS.get(lesson)
    if not title:
        print(red(f"  Invalid lesson number: {lesson}"))
        return
    print(bold(f"\n  Catching up to Lesson {lesson}: {title}"))
    print("  " + "=" * 50)
    _catch_up(lesson)
    steps = NEXT_STEPS.get(lesson, [])
    if steps:
        print(bold("\n  Next steps:"))
        for i, s in enumerate(steps, 1):
            print(f"    {i}. {s}")
    print(green("\n  Catch-up complete!"))

# ---------------------------------------------------------------------------
# Check prerequisites
# ---------------------------------------------------------------------------

PREREQS = {
    1: {
        "files": ["dbt_project.yml"],
        "seeds": ["customers.csv", "orders.csv"],
        "models": ["staging/stg_customers.sql"],
    },
    2: {
        "files": ["models/staging/sources.yml", "models/staging/schema.yml"],
        "models": ["staging/stg_customers.sql", "staging/stg_orders.sql"],
    },
    3: {
        "seeds": ["customers.csv", "orders.csv", "products.csv",
                  "order_items.csv", "payments.csv"],
        "models": ["staging/stg_customers.sql", "staging/stg_orders.sql",
                   "staging/stg_products.sql", "staging/stg_order_items.sql",
                   "staging/stg_payments.sql"],
    },
    4: {
        "models": ["staging/stg_customers.sql", "staging/stg_orders.sql",
                   "staging/stg_products.sql", "staging/stg_order_items.sql",
                   "staging/stg_payments.sql",
                   "intermediate/int_orders_with_payments.sql",
                   "intermediate/int_order_items_with_products.sql",
                   "intermediate/int_customers__order_summary.sql",
                   "marts/dim_customers.sql", "marts/fct_orders.sql"],
    },
    5: {
        "files": ["packages.yml", "models/marts/schema.yml"],
        "models": ["marts/dim_customers.sql", "marts/fct_orders.sql"],
    },
    6: {"files": ["dbt_project.yml"]},
    7: {
        "seeds": ["orders.csv"],
        "files": ["models/staging/sources.yml"],
    },
    8:  {"models": ["marts/dim_customers.sql"]},
    9: {
        "files": ["models/marts/schema.yml"],
        "models": ["marts/dim_customers.sql", "marts/fct_orders.sql"],
    },
    10: {"models": ["marts/dim_customers.sql", "marts/fct_orders.sql"]},
}

def check_prerequisites(lesson: int, interactive=True):
    title = LESSONS.get(lesson)
    if not title:
        print(red(f"  Invalid lesson number: {lesson}"))
        return False
    prereqs = PREREQS.get(lesson)
    if not prereqs:
        print(yellow(f"  No prerequisites defined for Lesson {lesson}."))
        return True

    print(bold(f"\n  Checking prerequisites for Lesson {lesson}: {title}"))
    print("  " + "=" * 50)

    all_ok = True
    for f in prereqs.get("files", []):
        if (PROJECT_ROOT / f).exists():
            print(f"    {green('+')} {Path(f).name}")
        else:
            print(f"    {red('x')} {Path(f).name}  {dim('(' + f + ')')}")
            all_ok = False
    for s in prereqs.get("seeds", []):
        if (PROJECT_ROOT / "seeds" / s).exists():
            print(f"    {green('+')} {s}")
        else:
            print(f"    {yellow('!')} {s}  {dim('(seeds/' + s + ')')}")
            all_ok = False
    for m in prereqs.get("models", []):
        if (PROJECT_ROOT / "models" / m).exists():
            print(f"    {green('+')} {Path(m).stem}")
        else:
            print(f"    {red('x')} {Path(m).stem}  {dim('(models/' + m + ')')}")
            all_ok = False

    print()
    if all_ok:
        print(green(f"  All prerequisites met! Ready for Lesson {lesson}."))
    else:
        print(red("  Some prerequisites are missing."))
        if interactive and confirm("  Run catch-up to fix?"):
            catch_up(lesson, interactive=False)
    return all_ok

# ---------------------------------------------------------------------------
# Lesson picker (shared by catch-up and check)
# ---------------------------------------------------------------------------

def pick_lesson(action_name):
    print(bold(f"\n  {action_name} - Select a lesson"))
    print("  " + "-" * 40)
    for num, title in LESSONS.items():
        print(f"    {num:>2}. {title}")
    print()
    val = ask("  Lesson number (or 'b' to go back): ")
    if val.lower() == "b":
        return None
    try:
        n = int(val)
        if n in LESSONS:
            return n
    except ValueError:
        pass
    print(red(f"  Invalid lesson: {val}"))
    return None

# ---------------------------------------------------------------------------
# Main menu
# ---------------------------------------------------------------------------

BANNER = r"""
     _ _     _     _                          _
  __| | |__ | |_  | | ___  __ _ _ __ _ __   (_)_ __   __ _
 / _` | '_ \| __| | |/ _ \/ _` | '__| '_ \  | | '_ \ / _` |
| (_| | |_) | |_  | |  __/ (_| | |  | | | | | | | | | (_| |
 \__,_|_.__/ \__| |_|\___|\__,_|_|  |_| |_| |_|_| |_|\__, |
                                                       |___/
"""

def main_menu():
    while True:
        print(bold(BANNER))
        print(f"  {dim('Platform:')} {platform.system()} | {dim('Python:')} {sys.version.split()[0]}")
        print(f"  {dim('Project:')}  {PROJECT_ROOT}\n")
        print(bold("  What would you like to do?\n"))
        print(f"    {bold('1.')} Catch up to a lesson     {dim('(copy answer-key files)')}")
        print(f"    {bold('2.')} Check prerequisites       {dim('(verify files before a lesson)')}")
        print(f"    {bold('3.')} Clean workspace            {dim('(remove all working files)')}")
        print(f"    {bold('4.')} Show workspace status      {dim('(file counts & info)')}")
        print(f"    {bold('5.')} Quick start                {dim('(clean + catch up in one step)')}")
        print(f"    {bold('q.')} Quit\n")
        choice = ask("  > ", {"1", "2", "3", "4", "5", "q", "Q"})

        if choice in ("q", "Q"):
            print(dim("\n  Goodbye!\n"))
            break
        elif choice == "1":
            n = pick_lesson("Catch Up")
            if n:
                catch_up(n)
            pause()
        elif choice == "2":
            n = pick_lesson("Check Prerequisites")
            if n:
                check_prerequisites(n)
            pause()
        elif choice == "3":
            cleanup_workspace()
            pause()
        elif choice == "4":
            show_status()
            pause()
        elif choice == "5":
            n = pick_lesson("Quick Start")
            if n:
                print(bold(f"\n  Quick Start: clean workspace, then catch up to Lesson {n}"))
                if confirm("  Proceed?"):
                    cleanup_workspace(interactive=False)
                    catch_up(n, interactive=False)
            pause()

# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def cli():
    if len(sys.argv) < 2:
        main_menu()
        return

    cmd = sys.argv[1].lower()
    if cmd == "cleanup":
        cleanup_workspace(interactive=False)
    elif cmd == "catchup":
        if len(sys.argv) < 3:
            print(red("Usage: python run.py catchup <lesson>"))
            sys.exit(1)
        catch_up(int(sys.argv[2]), interactive=False)
    elif cmd == "check":
        if len(sys.argv) < 3:
            print(red("Usage: python run.py check <lesson>"))
            sys.exit(1)
        ok = check_prerequisites(int(sys.argv[2]), interactive=False)
        sys.exit(0 if ok else 1)
    elif cmd == "status":
        show_status()
    elif cmd == "quickstart":
        if len(sys.argv) < 3:
            print(red("Usage: python run.py quickstart <lesson>"))
            sys.exit(1)
        cleanup_workspace(interactive=False)
        catch_up(int(sys.argv[2]), interactive=False)
    elif cmd in ("-h", "--help", "help"):
        print(__doc__)
    else:
        print(red(f"Unknown command: {cmd}"))
        print(__doc__)
        sys.exit(1)

if __name__ == "__main__":
    cli()
