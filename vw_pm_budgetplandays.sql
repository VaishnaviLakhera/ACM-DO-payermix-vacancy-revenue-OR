CREATE
OR REPLACE VIEW "qlik"."vw_pm_budgetplandays" AS
SELECT
     y.date,
     y.datenumber,
     y.endofmonthnumber,
     y.buildingid,
     y.payerplanid,
     y.payerid,
     y.levelofcare,
     y.budgetresidentdays,
     y.facilityid,
     y.budgetresidentdaysrunning12,
     y.budgetresidentdaysytd
FROM
     (
          SELECT
               x.date,
               x.datenumber,
               x.endofmonthnumber,
               x.buildingid,
               x.payerplanid,
               x.payerid,
               x.levelofcare,
               x.budgetresidentdays,
               x.facilityid,
               sum(x.budgetresidentdays) OVER(
                    PARTITION BY x.payerplanid,
                    x.buildingid,
                    x.levelofcare
                    ORDER BY
                         x.date ROWS BETWEEN 364 PRECEDING
                         AND CURRENT ROW
               ) AS budgetresidentdaysrunning12,
               sum(x.budgetresidentdays) OVER(
                    PARTITION BY x.payerplanid,
                    x.buildingid,
                    x.levelofcare,
                    "date_part"('year':: character varying:: text, x.date)
                    ORDER BY
                         x.date ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW
               ) AS budgetresidentdaysytd
          FROM
               (
                    SELECT
                         DISTINCT dt.date,
                         "replace"(
                              dt.date:: character varying:: text,
                              '-':: character varying:: text,
                              '':: character varying:: text
                         ) AS datenumber,
                         "replace"(
                              last_day(dt.date:: timestamp without time zone):: character varying:: text,
                              '-':: character varying:: text,
                              '':: character varying:: text
                         ) AS endofmonthnumber,
                         b.buildingid,
                         COALESCE(
                              bpd.payerplanid:: numeric:: numeric(18, 0),
                              0:: numeric:: numeric(18, 0)
                         ) AS payerplanid,
                         bpd.payerid,
                         lc.levelofcareabbreviation AS levelofcare,
                         bpd.budgetplandays AS budgetresidentdays,
                         b.facilityid
                    FROM
                         dim.budgetplandays bpd
                         JOIN dim.datetable dt ON dt.date >= bpd.startdate
                         AND dt.date <= bpd.enddate
                         LEFT JOIN dim.levelofcare lc ON lc.levelofcareshortname:: text = bpd.levelofcarename:: text
                         LEFT JOIN dim.building b ON b.buildingid = bpd.buildingid
                         JOIN dim.campusactivedates ca ON bpd.entityid:: character varying:: text = ca.entityid:: character varying:: text
                         AND dt.date >= ca.startdate
                         AND dt.date <= ca.enddate
               ) x
          WHERE
               x.budgetresidentdays:: character varying:: text > 0:: character varying:: text
     ) y
WHERE
     y.date < 'now':: character varying:: date
ORDER BY
     y.date;
