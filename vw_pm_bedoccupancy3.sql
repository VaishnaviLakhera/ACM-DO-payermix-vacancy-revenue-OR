CREATE
OR REPLACE VIEW "qlik"."vw_pm_bedoccupancy3" AS
SELECT
        x.date,
        x.datenumber,
        x.endofmonthnumber,
        x.buildingid,
        x.levelofcare,
        x.residentdaysperbuilding,
        sum(x.residentdaysperbuilding) OVER(
                PARTITION BY x.buildingid,
                x.levelofcare
                ORDER BY
                        x.date ROWS BETWEEN 364 PRECEDING
                        AND CURRENT ROW
        ) AS residentdaysperbuildingrunning12,
        sum(x.residentdaysperbuilding) OVER(
                PARTITION BY x.buildingid,
                x.levelofcare,
                "date_part"('year':: character varying:: text, x.date)
                ORDER BY
                        x.date ROWS BETWEEN UNBOUNDED PRECEDING
                        AND CURRENT ROW
        ) AS residentdaysperbuildingytd
FROM
        (
                SELECT
                        a.date,
                        a.datenumber,
                        a.endofmonthnumber,
                        a.buildingid,
                        a.levelofcare,
                        sum(a.residentdays) AS residentdaysperbuilding
                FROM
                        (
                                SELECT
                                        bo.date,
                                        "replace"(
                                                bo.date:: character varying:: text,
                                                '-':: character varying:: text,
                                                '':: character varying:: text
                                        ) AS datenumber,
                                        to_char(
                                                last_day(bo.date:: timestamp without time zone):: timestamp without time zone,
                                                'YYYYMMDD':: character varying:: text
                                        ) AS endofmonthnumber,
                                        COALESCE(bo.payerplanid, 0) AS payerplanid,
                                        v.buildingid,
                                        loc.levelofcareabbreviation AS levelofcare,
                                        sum(bo.occupied) AS residentdays,
                                        v.campusid
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
                                        bo.payerplanid IS NOT NULL
                                GROUP BY
                                        bo.date,
                                        bo.payerplanid,
                                        v.buildingid,
                                        loc.levelofcareabbreviation,
                                        v.campusid
                        ) a
                GROUP BY
                        a.date,
                        a.datenumber,
                        a.endofmonthnumber,
                        a.buildingid,
                        a.levelofcare
        ) x;
