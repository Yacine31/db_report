# AGENTS.md

## Build/Lint/Test Commands
- **Build/Run**: Execute `bash rapport_bdd.sh` to generate HTML database reports.
- **Lint**: Use `shellcheck` on .sh files: `shellcheck sh/*.sh sh/local/*.sh`.
- **Test**: Run individual scripts manually, e.g., `bash sh/09_os_info.sh` for single test.
- **Single Test**: `bash sh/<script_name>.sh` or `sqlplus -s / as sysdba @sql/<query>.sql`.
- **Full Test Suite**: Run all scripts via main script, verify HTML output in output/ directory.

## Code Style Guidelines
- **Imports**: Use `source` for env files and utils.sh; avoid global imports.
- **Formatting**: 2-space indentation; consistent spacing; French comments.
- **Types**: No typing in bash/SQL; use comments for function documentation.
- **Naming**: UPPER_CASE for env vars; snake_case for functions/vars; descriptive names.
- **Error Handling**: Use `set -euo pipefail`; catch errors in functions with proper logging.
- **SQL Style**: Use CTEs with MATERIALIZE hints; UPPER_CASE keywords; proper formatting.
- **Functions**: Document parameters and purpose; use local variables; return values appropriately.