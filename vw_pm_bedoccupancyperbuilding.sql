CREATE
OR REPLACE VIEW "qlik"."vw_pm_bedoccupancyperbuilding" AS
SELECT
        y.date,
        y.datenumber,
        y.endofmonthnumber,
        y.buildingid,
        y.levelofcare,
        y.residentdaysperbuilding,
        y.residentdaysperbuildingrunning12,
        y.residentdaysperbuildingytd
FROM
        (
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
                                        bo.date,
                                        "replace"(
                                                to_char(
                                                        bo.date:: timestamp without time zone,
                                                        'YYYYMMDD':: character varying:: text
                                                ),
                                                '-':: character varying:: text,
                                                '':: character varying:: text
                                        ) AS datenumber,
                                        "replace"(
                                                to_char(
                                                        last_day(bo.date:: timestamp without time zone):: timestamp without time zone,
                                                        'YYYYMMDD':: character varying:: text
                                                ),
                                                '-':: character varying:: text,
                                                '':: character varying:: text
                                        ) AS endofmonthnumber,
                                        v.buildingid,
                                        loc.levelofcareabbreviation AS levelofcare,
                                        sum(bo.occupied) AS residentdaysperbuilding
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
                                        bo.date >= date_add(
                                                'year':: character varying:: text,
                                                - 2:: bigint,
                                                'now':: character varying:: date:: timestamp without time zone
                                        )
                                        AND bo.date <= 'now':: character varying:: date
                                GROUP BY
                                        bo.date,
                                        v.buildingid,
                                        loc.levelofcareabbreviation
                        ) x
                WHERE
                        x.residentdaysperbuilding > 0
        ) y
WHERE
        y.date >= date_add(
                'year':: character varying:: text,
                - 1:: bigint,
                'now':: character varying:: date:: timestamp without time zone
        )
ORDER BY
        y.date;
