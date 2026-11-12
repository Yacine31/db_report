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
# Nom de page d'un script : summary/NN_<page>[_suite].sql -> <page>.
# Les scripts de meme <page> alimentent la meme page, dans l'ordre des fichiers
# (ex. 10_health_summary.sql et 11_health_open.sql -> Summary_health).
summary_page() {
    local name
    name="$(basename "$1" | cut -d_ -f2)"
    echo "${name%.sql}"
}

# DB_REPORT_SIDS est positionnée par oracle_db_report.sh (option -s) ; à défaut, toutes les bases actives
SUMMARY_SIDS="${DB_REPORT_SIDS:-$(list_db_sids)}"

for page in $(for sqlfile in summary/*.sql; do summary_page "$sqlfile"; done | sort -u)
do
    HTML_FILE="${OUTPUT_DIR}/Summary_${page}_${HNAME}_${DATETIME}.html"

    log_info "Generating SQL summary report for ${page} in ${HTML_FILE}"

    # Insert HTML header
    cat html/00_html_header.html > "${HTML_FILE}"

    for sid in ${SUMMARY_SIDS}
    do
        export ORAENV_ASK=NO
        export ORACLE_SID="$sid"
        # shellcheck source=/dev/null
        . oraenv -s > /dev/null
        set_db_open_state

        # Add database name
        echo "<h2>Database: ${sid}</h2>" >> "${HTML_FILE}"
        for sqlfile in summary/*.sql
        do
            [ "$(summary_page "$sqlfile")" = "${page}" ] || continue
            # Base seulement montee : le script est saute par run_sql_script, on l'indique sur la page
            if [ "${DB_REPORT_DB_OPEN}" = "NO" ] && sql_requires_open "$sqlfile"; then
                echo "<p>Database is ${DB_REPORT_OPEN_MODE}: this part requires an open database.</p>" >> "${HTML_FILE}"
            fi
            # Add SQL script result to the HTML page (standard sql_header.txt),
            # les erreurs ORA-/SP2- sont consignées pour le récapitulatif final
            run_sql_script sql/sql_header.txt "$sqlfile" "${HTML_FILE}"
        done
    done

    # "Back to top" link, then HTML footer
    echo "<p><a href=\"#top\">Back to top</a></p>" >> "${HTML_FILE}"
    cat html/99_html_footer.html >> "${HTML_FILE}"
    log_info "Summary report for ${page} generated."
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
