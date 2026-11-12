# DB Report

Generates detailed HTML reports on the configuration of a server and its Oracle databases.

## Features

- Generates a configuration report for the host server.
- Automatically collects information about running Oracle databases.
- Generates a structured and detailed HTML report for each database.
- Support for ASM instances and PDBs (Pluggable Databases).
- Modular scripts for easy customization.

## Prerequisites

- Linux/Unix system with Bash.
- Oracle Database 12c or later, installed and configured (with `sqlplus` and `oraenv`).
- Permissions to execute SQL queries as `sysdba`.

## Installation

```bash
git clone https://github.com/Yacine31/db_report
cd db_report
# Copy the example configuration file (optional)
cp .env.example .env
# Edit .env if necessary (e.g., to customize OUTPUT_DIR)
```

## Usage

```bash
# All running databases
bash oracle_db_report.sh

# Only one database (the option can be repeated)
bash oracle_db_report.sh -s ORCL
bash oracle_db_report.sh -s ORCL -s TEST

# Show the help
bash oracle_db_report.sh -h
```

The script can be started from any directory.

| Option | Description |
|---|---|
| `-s SID` | Report only this database. Can be repeated. The database must be running, otherwise the script stops and lists the running databases. Default: all running databases. |
| `--vmstat` | Add a live `vmstat 2 20` sample to the server report (about 40 seconds). Off by default. |
| `-h`, `--help` | Show the usage and exit. |

The server report is always generated, whatever the options.

At the end of the run, the log lists the SQL errors (`ORA-`, `SP2-`, `PLS-`) raised by the report scripts, with the database and the script concerned, or `No SQL error detected`.

## Output

The script generates the following reports in the `output/YYYYMMDD/` directory (`{hostname}` is the short host name):

1.  **Server Report**: A single report containing the operating system configuration information (OS, disks, memory, swap activity, Oracle homes and patches, network, kernel parameters).
    - Filename: `Rapport_{hostname}_{timestamp}.html`

2.  **Database Reports**: A detailed report for each selected Oracle database instance.
    - Filename: `Rapport_{hostname}_{SID}_{timestamp}.html`

3.  **Summary Reports**: One page per topic (health summary, datafiles, tablespaces, alert log errors, RMAN backups) gathering all the selected databases, produced by `summary.sh`.
    - Filename: `Summary_{topic}_{hostname}_{timestamp}.html`

4.  **RMAN Chart**: Backup size and duration over the last 90 days for each selected database, produced by `generate_rman_chart.sh`.
    - Filename: `RMAN_Chart_{hostname}_{timestamp}.html`

The reports are self-contained HTML files: no external font, script or library is loaded, so they can be opened offline and sent as single files.

## Health Summary

Each report starts with a health summary: one line per check, with its value, its threshold and a status (`OK`, `WARNING`, `CRITICAL` or `INFO`). The detail of each check is in the matching section further down.

- Server checks and their thresholds: top of `sh/05_health_summary.sh`.
- Database checks: `sql/00a_health_summary.sql` (checks possible on a mounted database) and `sql/00b_health_summary_open.sql` (checks that need an open database); their thresholds: `sql/common/health_thresholds.sql`.
- `Summary_health_{hostname}_{timestamp}.html` gathers the database summaries of all the selected databases on one page.

## Mounted Databases (Standby)

On a database that is only mounted (for example a physical standby managed by Dbvisit or Data Guard), the dictionary views (`DBA_*`, `CDB_*`) cannot be read. SQL scripts that need an open database start with the line `-- db-report: requires-open`: they are skipped on a mounted database, and the report says so at the top of the database section. Add this line to any new script that reads the dictionary.

## Project Structure

- `oracle_db_report.sh`: Main script that orchestrates the generation of the server report and database reports.
- `sh/`: Bash scripts for collecting system information (used for the server report).
- `sql/`: SQL queries for database data.
- `sql/common/`: queries shared by a database report section and a summary page (not run on their own).
- `html/`: HTML templates for the report headers and footers.
- `asm/`: SQL scripts specific to ASM instances.
- `summary/`: SQL scripts used by the summary script.
- `summary.sh`: Report aggregation script.
- `rman_chart/`: HTML template and SQL script for the RMAN chart.
- `generate_rman_chart.sh`: RMAN chart generation script.

## Customization

- Modify `.env` to change the output directory.
- Add scripts in `sh/` or `sql/` to extend the reports.
