# Project Overview

This project is a collection of shell and SQL scripts designed to generate comprehensive HTML reports on the status of Oracle databases. The reports include various details such as server information, database configuration, file structures, logs, and backup status. It is designed to be runnable on both Linux and Windows environments.

# Key Files and Directories

*   **`rapport_bdd.sh`**: The main shell script that orchestrates the entire report generation process. It detects running Oracle instances, executes various SQL and shell scripts, and compiles their output into a detailed HTML report for each database.
*   **`summary.sh`**: A supplementary shell script that generates additional summary HTML reports based on specific SQL queries and local shell scripts.
*   **`sh/utils.sh`**: Contains utility shell functions, such as `print_h2` for adding HTML headings and `run_and_print` for executing commands and embedding their output within `<pre>` tags in the HTML reports, handling potential errors gracefully.
*   **`html/00_html_header.html`**: The HTML header template used for all generated reports, including CSS styling for a consistent look and feel.
*   **`html/99_html_footer.html`**: The HTML footer template used for all generated reports.
*   **`sql/`**: This directory contains a variety of SQL scripts that gather detailed information about Oracle database configuration, parameters, storage, users, and more.
*   **`sh/`**: This directory holds shell scripts that collect system-level information relevant to the database environment.
*   **`asm/`**: Contains SQL scripts specifically designed to retrieve information about Automatic Storage Management (ASM) instances.
*   **`summary/`**: Houses SQL scripts used by `summary.sh` to generate high-level overview reports.
*   **`sql/cdb/`**: Contains SQL scripts tailored for Oracle Container Databases (CDBs) to provide information about Pluggable Databases (PDBs).
*   **`.env`**: An optional file to override default configuration variables, such as the output directory.

# Building and Running

The project generates HTML reports by executing a series of shell and SQL scripts.

## On Linux

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Yacine31/db_report
    cd db_report
    ```
2.  **Copy the environment file (optional):**
    ```bash
    cp .env.local .env
    # Modify .env if you need to customize output directory or other variables.
    ```
3.  **Execute the main report script:**
    ```bash
    bash rapport_bdd.sh
    ```
    The generated reports will be located in the `output/YYYYMMDD` directory.

## On Windows

1.  **Download the ZIP or clone with Git:**
    *   **Download ZIP:** [https://github.com/Yacine31/db_report/archive/refs/heads/main.zip](https://github.com/Yacine31/db_report/archive/refs/heads/main.zip)
        *   Decompress it to `c:\db_report`.
        *   Execute `rapport_bdd.cmd`.
    *   **Using Git:**
        ```cmd
        cd /d c:\
        git clone https://github.com/Yacine31/db_report
        cd db_report
        rapport_bdd.cmd
        ```

# Development Conventions

*   **Scripting Languages:** Primarily uses Bash for orchestration and SQL for database interaction.
*   **Error Handling:** Shell scripts utilize `set -euo pipefail` for robust error handling, ensuring scripts exit immediately upon encountering errors.
*   **SQL Execution:** SQL scripts are executed via `sqlplus -s / as sysdba`, indicating a focus on administrative-level database information.
*   **HTML Output:** All script outputs are formatted into HTML using predefined header and footer templates, and utility functions help embed command outputs cleanly.
*   **Modularity:** Scripts are organized into logical directories (`sql/`, `sh/`, `asm/`, `summary/`, `sql/cdb/`) based on their function and target.
