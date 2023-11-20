@echo off
setlocal enabledelayedexpansion

REM for /f "tokens=3 delims=_" %%r in ('tasklist /fi "imagename eq OracleService*" ^| findstr /v "APX1"') do (
for /f "tokens=3 delims=_" %%r in ('netstart | find /i "OracleService"') do (
    set ORAENV_ASK=NO
    set ORACLE_SID=%%r
    set ORACLE_SID=%ORACLE_SID:~13%
    set HTML_FILE=Rapport_%HNAME%_!ORACLE_SID!_%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%.html
    call oraenv -s >nul

    type sql\00_html_header.html >> !HTML_FILE!

    set DATE_JOUR=!DATE:~0,2!/!DATE:~3,2!/!DATE:~6,4! !TIME:~0,2!h!TIME:~3,2!
    echo ^<h1^>Rapport de base de données^</h1^> >> !HTML_FILE!
    echo ^<h2^>Date : !DATE_JOUR!^</h2^> >> !HTML_FILE!
    echo ^<h2^>Hostname : %COMPUTERNAME%^</h2^> >> !HTML_FILE!
    echo ^<h2^>Base de données : !ORACLE_SID!^</h2^> >> !HTML_FILE!
    echo ^<br^><br^> >> !HTML_FILE!

    echo ^<h1^>Configuration système^</h1^> >> !HTML_FILE!
    for %%f in (sh\*.sh) do (
        echo call %%f >> !HTML_FILE!
    )
)
