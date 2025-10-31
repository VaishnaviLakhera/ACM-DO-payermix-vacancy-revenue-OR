CREATE
OR REPLACE VIEW "qlik"."vw_pm_bedoccupancy2" AS
SELECT
    x.date,
    x.datenumber,
    x.endofmonthnumber,
    x.payerplanid,
    x.buildingid,
    x.levelofcare,
    x.residentdays,
    x.campusid,
    x.facilityid,
    CASE
    WHEN x.date >= '2024-02-01':: date THEN '2024-02-01 00:00:00':: timestamp without time zone
    ELSE date_add(
        'day':: character varying:: text,
        1:: bigint,
        date_add(
            'year':: character varying:: text,
            - 1:: bigint,
            x.date:: timestamp without time zone
        )
    ) END AS running12begindate,
    sum(x.residentdays) OVER(
        PARTITION BY x.payerplanid,
        x.buildingid,
        x.levelofcare
        ORDER BY
            x.date ROWS BETWEEN 364 PRECEDING
            AND CURRENT ROW
    ) AS residentdaysrunning12,
    sum(x.residentdays) OVER(
        PARTITION BY x.payerplanid,
        x.buildingid,
        x.levelofcare,
        "date_part"('year':: character varying:: text, x.date)
        ORDER BY
            x.date ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS residentdaysytd
FROM
    (
        SELECT
            bo.date,
            to_char(
                bo.date:: timestamp without time zone,
                'YYYYMMDD':: character varying:: text
            ) AS datenumber,
            to_char(
                last_day(bo.date:: timestamp without time zone):: timestamp without time zone,
                'YYYYMMDD':: character varying:: text
            ) AS endofmonthnumber,
            COALESCE(bo.payerplanid, 0) AS payerplanid,
            v.buildingid,
            loc.levelofcareabbreviation AS levelofcare,
            sum(bo.occupied) AS residentdays,
            v.campusid,
            v.facilityid
        FROM
            dim.bedoccupancy bo
            JOIN dim.vwbed v ON v.bedid = bo.bedid
            JOIN dim.bed b ON b.bedid = v.bedid
            AND b.issecondperson = 0
            JOIN dim.levelofcare loc ON loc.levelofcareid = v.levelofcareid
            JOIN dim.campusactivedates ca ON v.entityid = ca.entityid
            AND bo.date >= ca.startdate
            AND bo.date <= ca.enddate
        GROUP BY
            bo.date,
            bo.payerplanid,
            v.buildingid,
            loc.levelofcareabbreviation,
            v.campusid,
            v.facilityid
    ) x
WHERE
    x.residentdays > 0
    AND x.payerplanid IS NOT NULL;
