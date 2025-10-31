CREATE
OR REPLACE VIEW "qlik"."vw_pm_budgetplandayssumperbuilding" AS
SELECT
  DISTINCT x.date,
  x.datenumber,
  x.endofmonthnumber,
  x.buildingid,
  x.levelofcare,
  x.budgetresidentdaysperbuilding,
  x.entityid,
  sum(x.budgetresidentdaysperbuilding) OVER(
    PARTITION BY x.buildingid,
    x.levelofcare
    ORDER BY
      x.date ROWS BETWEEN 364 PRECEDING
      AND CURRENT ROW
  ) AS budgetresidentdaysperbuildingrunning12,
  sum(x.budgetresidentdaysperbuilding) OVER(
    PARTITION BY x.buildingid,
    x.levelofcare,
    "date_part"('year':: character varying:: text, x.date)
    ORDER BY
      x.date ROWS BETWEEN UNBOUNDED PRECEDING
      AND CURRENT ROW
  ) AS budgetresidentdaysperbuildingytd
FROM
  (
    SELECT
      dt.date,
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
      bp.buildingid,
      loc.levelofcareabbreviation AS levelofcare,
      sum(bp.budgetplandays) AS budgetresidentdaysperbuilding,
      bp.entityid
    FROM
      dim.budgetplandays bp
      JOIN dim.datetable dt ON dt.date >= bp.startdate
      AND dt.date <= bp.enddate
      JOIN dim.building b ON b.buildingid = bp.buildingid
      JOIN dim.levelofcare loc ON loc.levelofcareid = b.levelofcareid
      JOIN dim.campusactivedates ca ON bp.entityid:: character varying:: text = ca.entityid:: character varying:: text
      AND dt.date >= ca.startdate
      AND dt.date <= ca.enddate
    GROUP BY
      dt.date,
      bp.buildingid,
      loc.levelofcareabbreviation,
      bp.entityid
  ) x
WHERE
  x.date < 'now':: character varying:: date
ORDER BY
  x.date;
