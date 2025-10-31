CREATE
OR REPLACE VIEW qlik.vw_vrevenue_bedoccupancy AS
SELECT
  SUM(bo.vacant) OVER (
    PARTITION BY bo.bedid,
    DATE_PART('year', bo.date)
    ORDER BY
      bo.date ROWS BETWEEN UNBOUNDED PRECEDING
      AND CURRENT ROW
  ) AS ytdvacancysum,
  dt.dateid,
  bo.date,
  vb.campusname,
  c.campusabbreviation,
  e.entitycode,
  loc.levelofcareabbreviation AS levelofcare,
  f.facilitycode,
  vb.buildingname,
  vb.buildingid,
  TO_CHAR(bo.date, 'MM/DD/YYYY') || vb.buildingid:: TEXT AS datebuildingkey,
  vb.unitname,
  vb.roomid,
  vb.roomname,
  vb.bedname,
  vb.bedid,
  bo.occupied AS residentdays,
  bo.available AS inservicedays,
  bo.vacant,
  bo.occupancydays,
  bo.vacancydays,
  bo.outofservicedays,
  CASE
  WHEN bo.available = 1 THEN 0
  ELSE 1 END AS outofservice,
  -- pd.bedprice AS price,
  TRUNC(
    CASE
    WHEN pd.daily_rate IS NOT NULL THEN pd.daily_rate
    WHEN pd.monthly_rate IS NOT NULL THEN pd.monthly_rate / DATE_PART('day', LAST_DAY(bo.date))
    ELSE NULL END,
    2
  ) AS price,
  0 AS secondperson,
  vb.campusname || '-' || vb.buildingname || '-' || vb.roomname AS fullroomname
FROM
  dim.bedoccupancy bo
  JOIN dim.bed b ON b.bedid = bo.bedid
  JOIN dim.vwbed vb ON vb.bedid = bo.bedid
  JOIN dim.building bld ON bld.buildingid = vb.buildingid
  JOIN dim.levelofcare loc ON loc.levelofcareid = vb.levelofcareid
  JOIN dim.entity e ON e.entityid = vb.entityid
  JOIN dim.campus c ON c.entityid = vb.entityid
  JOIN dim.datetable dt ON dt.date = bo.date
  LEFT JOIN dim.facility f ON f.facilityid = bld.facilityid
  left JOIN dim.bedprice pd ON vb.bedid = pd.bedid
  AND vb.roomid = pd.roomid
  AND vb.buildingid = pd.buildingid
  AND e.entitycode = pd.entitycode
  AND loc.levelofcareabbreviation = pd.levelofcare
  AND bo.date >= pd.effectivedate
  AND bo.date <= pd.ineffectivedate
WHERE
  DATE_PART('year', bo.date) >= 2024
  AND b.issecondperson = 0 WITH NO SCHEMA BINDING;
