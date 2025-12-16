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
- Oracle Database installed and configured (with `sqlplus` and `oraenv`).
- Permissions to execute SQL queries as `sysdba`.

## Installation

```bash
git clone https://github.com/Yacine31/db_report
cd db_report
# Copy the example configuration file (optional)
cp .env.local .env
# Edit .env if necessary (e.g., to customize OUTPUT_DIR)
```

## Usage

```bash
# Execute the main script
bash oracle_db_report.sh
```

## Output

The script generates two types of reports in the `output/YYYYMMDD/` directory:

1.  **Server Report**: A single report containing the operating system configuration information.
    - Filename: `Rapport_{hostname}_{timestamp}.html`

2.  **Database Reports**: A detailed report for each detected Oracle database instance.
    - Filename: `Rapport_{hostname}_{SID}_{timestamp}.html`

A summary script (`summary.sh`) is also executed to aggregate certain data from the different databases.

## Project Structure

- `oracle_db_report.sh`: Main script that orchestrates the generation of the server report and database reports.
- `sh/`: Bash scripts for collecting system information (used for the server report).
- `sql/`: SQL queries for database data.
- `html/`: HTML templates for the report headers and footers.
- `asm/`: SQL scripts specific to ASM instances.
- `summary/`: SQL scripts used by the summary script.
- `summary.sh`: Report aggregation script.

## Customization

- Modify `.env` to change the output directory.
- Add scripts in `sh/` or `sql/` to extend the reports.
