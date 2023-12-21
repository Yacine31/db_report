@echo off

setlocal enabledelayedexpansion

for /f "tokens=*" %%r in ('net start ^| find /i "OracleService"') do (
    set "ORACLE_SID=%%r"
    set "ORACLE_SID=!ORACLE_SID:~13!"
    set HTML_FILE=Rapport_%COMPUTERNAME%_!ORACLE_SID!_%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%.html
    set TMP_SQLFILE="tmp_sqlfile.sql"
    set DATE_JOUR=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%

    type sql\00_html_header.html                            > !HTML_FILE!
    echo ^<h1^>Rapport de base de donnees^</h1^>            >> !HTML_FILE!
    echo ^<h2^>Date : !DATE_JOUR!^</h2^>                    >> !HTML_FILE!
    echo ^<h2^>Hostname : %COMPUTERNAME%^</h2^>             >> !HTML_FILE!
    echo ^<h2^>Base de donnees : !ORACLE_SID!^</h2^>        >> !HTML_FILE!
    echo ^<br^><br^>                                        >> !HTML_FILE!

    echo ^<h1^>Configuration de la base de donnees !ORACLE_SID! ^</h1^> >> !HTML_FILE!
    for %%f in (sql\*.sql) do (
        echo SET PAGES 999 FEEDBACK OFF MARKUP HTML ON SPOOL ON PREFORMAT OFF ENTMAP OFF > !TMP_SQLFILE! 
        echo WHENEVER SQLERROR CONTINUE >> !TMP_SQLFILE! 
        type %%f >> !TMP_SQLFILE!
        echo "" >> !TMP_SQLFILE! 
        echo EXIT >> !TMP_SQLFILE! 
        echo Execution du script %%f
        call sqlplus -S / as sysdba @!TMP_SQLFILE! >> !HTML_FILE!
    )

    type sql\99_html_footer.html >> !HTML_FILE!
    echo Rapport de la base !ORACLE_SID! dans le fichier html : !HTML_FILE!
)