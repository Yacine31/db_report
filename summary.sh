#!/bin/bash
#------------------------------------------------------------------------------
# This script executes SQL to provide a global view of certain aspects of the database
# e.g., all datafiles, all backups, all alert log errors, ...
#------------------------------------------------------------------------------

# Imports utility functions
# The path is relative to the calling script (oracle_db_report.sh)
source "$(dirname "$0")/sh/utils.sh"

# Variables DATETIME, HNAME, OUTPUT_DIR, and .env environment are already handled by oracle_db_report.sh
# Ensure OUTPUT_DIR is defined
: "${OUTPUT_DIR:?OUTPUT_DIR not set by calling script}"
: "${DATETIME:?DATETIME not set by calling script}"
: "${HNAME:?HNAME not set by calling script}"

log_info "Starting execution of summary scripts."

#------------------------------------------------------------------------------
# Execution of summary SQL scripts
#------------------------------------------------------------------------------
for sqlfile in summary/*.sql
do
    # Prepare the output file
    FILENAME=$(basename "$sqlfile" | cut -d_ -f2)
    BASENAME="${FILENAME%.*}"
    HTML_FILE="${OUTPUT_DIR}/Summary_${BASENAME}_${HNAME}_${DATETIME}.html"

    log_info "Generating SQL summary report for ${FILENAME} in ${HTML_FILE}"

    # Insert HTML header
    cat html/00_html_header.html > "${HTML_FILE}"

    # DB_REPORT_SIDS est positionnée par oracle_db_report.sh (option -s) ; à défaut, toutes les bases actives
    for sid in ${DB_REPORT_SIDS:-$(list_db_sids)}
    do
        export ORAENV_ASK=NO
        export ORACLE_SID="$sid"
        # shellcheck source=/dev/null
        . oraenv -s > /dev/null

        # Add database name
        echo "<h2>Database: ${sid}</h2>" >> "${HTML_FILE}"
        # Add SQL script result to the HTML page (standard sql_header.txt),
        # les erreurs ORA-/SP2- sont consignées pour le récapitulatif final
        run_sql_script sql/sql_header.txt "$sqlfile" "${HTML_FILE}"
    done

    # "Back to top" link, then HTML footer
    echo "<p><a href=\"#top\">Back to top</a></p>" >> "${HTML_FILE}"
    cat html/99_html_footer.html >> "${HTML_FILE}"
    log_info "Summary report for ${FILENAME} generated."
done

#------------------------------------------------------------------------------
# Execution of scripts in sh/local if present
#------------------------------------------------------------------------------
LOCAL_DIR="sh/local"

if [ -d "$LOCAL_DIR" ]; then
    log_info "Detecting local directory: ${LOCAL_DIR}"
    for shfile in "${LOCAL_DIR}"/*.sh
    do
        [ -f "$shfile" ] || continue
        # Prepare the output file
        FILENAME=$(basename "$shfile")
        BASENAME="${FILENAME%.*}"
        HTML_FILE="${OUTPUT_DIR}/Summary_${BASENAME}_${HNAME}_${DATETIME}.html"
        log_info "Generating Shell summary report for ${FILENAME} in ${HTML_FILE}"
        # Insert HTML header
        cat html/00_html_header.html > "${HTML_FILE}"
        print_h1 "Script Result: ${FILENAME}" >> "${HTML_FILE}"
        # The shfile script already contains its own print_h2/run_and_print calls:
        # execute it directly.
        bash "$shfile" >> "${HTML_FILE}"
        # "Back to top" link, then HTML footer
        echo "<p><a href=\"#top\">Back to top</a></p>" >> "${HTML_FILE}"
        cat html/99_html_footer.html >> "${HTML_FILE}"
        log_info "Summary report for ${FILENAME} generated."
    done
else
    log_info "No local scripts detected in ${LOCAL_DIR}."
fi
log_info "Finished execution of summary scripts."
