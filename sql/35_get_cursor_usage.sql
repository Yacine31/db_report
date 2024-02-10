-- SCRIPT - to Set the 'SESSION_CACHED_CURSORS' and 'OPEN_CURSORS' Parameters Based on Usage (Doc ID 208857.1)
prompt <h2>Sessions and Cursors usage </h2>

SELECT
	'session_cached_cursors'         PARAMETER,
	LPAD(VALUE, 5)                   VALUE,
	DECODE(VALUE, 0, ' n/a', TO_CHAR(100 * USED / VALUE, '990')
	                         || '%') USAGE
FROM
	(
		SELECT
			MAX(S.VALUE) USED
		FROM
			V$STATNAME N,
			V$SESSTAT  S
		WHERE
			N.NAME = 'session cursor cache count'
			AND S.STATISTIC# = N.STATISTIC#
	),
	(
		SELECT
			VALUE
		FROM
			V$PARAMETER
		WHERE
			NAME = 'session_cached_cursors'
	)
UNION
ALL
SELECT
	'open_cursors',
	LPAD(VALUE, 5),
	TO_CHAR(100 * USED / VALUE, '990')
	|| '%'
FROM
	(
		SELECT
			MAX(SUM(S.VALUE)) USED
		FROM
			V$STATNAME N,
			V$SESSTAT  S
		WHERE
			N.NAME IN ('opened cursors current')
			AND S.STATISTIC# = N.STATISTIC#
		GROUP BY
			S.SID
	),
	(
		SELECT
			VALUE
		FROM
			V$PARAMETER
		WHERE
			NAME = 'open_cursors'
	);