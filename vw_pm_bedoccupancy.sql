CREATE
OR REPLACE VIEW "qlik"."vw_pm_bedoccupancy" AS
SELECT
        y.date,
        y.datenumber,
        y.endofmonthnumber,
        y.payerplanid,
        y.buildingid,
        y.residentdays,
        y.levelofcare,
        y.running12begindate,
        y.residentdaysrunning12,
        y.residentdaysytd
FROM
        (
                SELECT
                        x.date,
                        x.datenumber,
                        x.endofmonthnumber,
                        x.payerplanid,
                        x.buildingid,
                        x.residentdays,
                        x.levelofcare,
                        date_add(
                                'd':: character varying:: text,
                                1:: bigint,
                                date_add(
                                        'y':: character varying:: text,
                                        - 1:: bigint,
                                        x.date:: timestamp without time zone
                                )
                        ) AS running12begindate,
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
                                date_part_year(x.date) ROWS BETWEEN UNBOUNDED PRECEDING
                                AND UNBOUNDED FOLLOWING
                        ) AS residentdaysytd
                FROM
                        (
                                SELECT
                                        bo.date,
                                        "replace"(
                                                bo.date:: character varying:: text,
                                                '-':: character varying:: text,
                                                '':: character varying:: text
                                        ) AS datenumber,
                                        "replace"(
                                                last_day(bo.date:: timestamp without time zone):: character varying:: text,
                                                '-':: character varying:: text,
                                                '':: character varying:: text
                                        ) AS endofmonthnumber,
                                        COALESCE(bo.payerplanid, 0) AS payerplanid,
                                        v.buildingid,
                                        sum(bo.occupied) AS residentdays,
                                        loc.levelofcareabbreviation AS levelofcare
                                FROM
                                        dim.bedoccupancy bo
                                        JOIN dim.vwbed v ON v.bedid = bo.bedid
                                        JOIN dim.bed b ON b.bedid = v.bedid
                                        AND b.issecondperson = 0
                                        JOIN dim.levelofcare loc ON loc.levelofcareid = v.levelofcareid
                                        JOIN dim.campusactivedates ca ON v.entityid = ca.entityid
                                        AND bo.date >= ca.startdate
                                        AND bo.date <= ca.enddate
                                WHERE
                                        bo.date >= date_trunc(
                                                'year':: character varying:: text,
                                                date_add(
                                                        'y':: character varying:: text,
                                                        - 2:: bigint,
                                                        getdate()
                                                )
                                        )
                                        AND bo.date <= getdate():: date
                                GROUP BY
                                        bo.date,
                                        bo.payerplanid,
                                        v.buildingid,
                                        loc.levelofcareabbreviation
                        ) x
                WHERE
                        x.residentdays > 0
        ) y
WHERE
        y.payerplanid IS NOT NULL
ORDER BY
        y.date;
