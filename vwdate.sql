CREATE
OR REPLACE VIEW "qlik"."vwdate" AS
SELECT
    datetable.date,
    datetable.calendardayofmonth AS "day",
    datetable.weekdayname AS weekday,
    datetable.calendaryear AS "year",
    datetable.calendarmonth AS "month",
    datetable.month_name AS monthname,
    datetable.calendarquarter AS quarter,
    datetable.dateid AS _dateserial,
    datetable.calendaryear * 12 + datetable.calendarmonth AS _monthserial,
    datetable.calendaryear * 4 + datetable.calendarquarter AS _quarterserial,
    datetable.isoyearweekno AS _weekserial,
    CASE
    WHEN datetable.date > 'now':: character varying:: date THEN 1
    ELSE 0 END AS _qvc_calendar_dateisfuture,
    (
        datetable.calendaryear:: character varying:: text || '-':: character varying:: text
    ) || lpad(
        datetable.calendarmonth:: character varying:: text,
        2,
        '0':: character varying:: text
    ) AS "year-month",
    (
        datetable.calendaryear:: character varying:: text || '-Q':: character varying:: text
    ) || datetable.calendarquarter:: character varying:: text AS "year-quarter",
    (
        date_add(
            'month':: character varying:: text,
            1:: bigint,
            date_trunc(
                'month':: character varying:: text,
                datetable.date:: timestamp without time zone
            )
        ) - '1 day':: interval
    ):: date AS calendarendofmonthdate
FROM
    dim.datetable
WHERE
    datetable.date:: character varying:: text >= (
        "date_part"(
            'year':: character varying:: text,
            'now':: character varying:: date
        ) - 5
    ):: character varying:: text
    AND datetable.date < 'now':: character varying:: date
ORDER BY
    datetable.date;
