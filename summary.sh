#!/bin/bash
#------------------------------------------------------------------------------
# This script executes SQL to provide a global view of certain aspects of the database
# e.g., all datafiles, all backups, all alert log errors, ...
#------------------------------------------------------------------------------

# Imports utility functions
# The path is relative to the calling script (rapport_bdd.sh)
source "$(dirname "$0")/sh/utils.sh"

# Variables DATETIME, HNAME, OUTPUT_DIR, and .env environment are already handled by rapport_bdd.sh
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

    for sid in $(ps -eaf | grep pmon | egrep -v 'grep|ASM|APX1' | cut -d '_' -f3)
    do
            export ORAENV_ASK=NO
            export ORACLE_SID="$sid"
            # shellcheck source=/dev/null
            . oraenv -s > /dev/null

            # Add database name
            echo "<h2>Database: ${sid}</h2>" >> "${HTML_FILE}"
            # Add SQL script result to the HTML page
            # Use standard sql_header.txt
            cat sql/sql_header.txt "$sqlfile" | sqlplus -s / as sysdba >> "${HTML_FILE}"
    done

    # Insert HTML footer
    cat html/99_html_footer.html >> "${HTML_FILE}"
        log_info "Summary report for ${FILENAME} generated."
        echo "<p><a href=\"#top\">Back to top</a></p>" >> "${HTML_FILE}"
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
            # Exécution du script local en utilisant run_and_print
            print_h2 "Script Result: ${FILENAME}" >> "${HTML_FILE}"
            # The shfile script itself must be executed, and it already contains its own print_h2/run_and_print calls
            # Therefore, execute it directly.
            bash "$shfile" >> "${HTML_FILE}"            # Insert HTML footer
            cat html/99_html_footer.html >> "${HTML_FILE}"
            log_info "Summary report for ${FILENAME} generated."
            echo "<p><a href=\"#top\">Back to top</a></p>" >> "${HTML_FILE}"
        done
    else
        log_info "No local scripts detected in ${LOCAL_DIR}."
    fi
    log_info "Finished execution of summary scripts."