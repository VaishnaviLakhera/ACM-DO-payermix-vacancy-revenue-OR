CREATE
OR REPLACE VIEW "qlik"."vw_or_endofmonthresidentdays" AS
SELECT
   e.entityid,
   e.entityname,
   e.entitycode,
   f.facilityid,
   f.facilitycode,
   f.facilityname,
   vb.levelofcareabbreviation,
   bo.date AS monthenddate,
   "date_part"('year':: character varying:: text, bo.date) AS "year",
   "date_part"('month':: character varying:: text, bo.date) AS "month",
   sum(bo.occupied) AS eomresidentdays,
   sum(bo.available) AS eominservicedays
FROM
   dim.bedoccupancy bo
   LEFT JOIN dim.vwbed vb ON vb.bedid = bo.bedid
   AND vb.issecondperson = 0
   LEFT JOIN dim.facility f ON f.facilityid = vb.facilityid
   JOIN dim.entity e ON e.entityid = vb.entityid
   JOIN dim.campusactivedates ca ON vb.entityid:: character varying:: text = ca.entityid:: character varying:: text
   AND bo.date >= ca.startdate
   AND bo.date <= ca.enddate
WHERE
   bo.date = last_day(bo.date:: timestamp without time zone)
GROUP BY
   e.entityid,
   e.entityname,
   e.entitycode,
   f.facilityid,
   f.facilitycode,
   f.facilityname,
   vb.levelofcareabbreviation,
   bo.date,
   "date_part"('year':: character varying:: text, bo.date),
   "date_part"('month':: character varying:: text, bo.date);
