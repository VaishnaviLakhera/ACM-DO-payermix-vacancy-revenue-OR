CREATE
OR REPLACE VIEW "qlik"."vwbedoccupancy2ndperson" AS
SELECT
   dt.dateid,
   bo.date,
   vb.campusname,
   e.entitycode,
   loc.levelofcareabbreviation AS levelofcare,
   loc.facilitycode,
   vb.buildingname,
   vb.buildingid,
   (
      to_char(
         bo.date:: timestamp without time zone,
         'MM/DD/YYYY':: character varying:: text
      ) || vb.buildingid:: character varying:: text
   ) || vb.buildingid:: character varying:: text AS datebuildingkey,
   vb.unitname,
   vb.roomid,
   vb.roomname,
   vb.bedname,
   vb.bedid,
   sbed.occupied AS secondperson,
   sbed.available AS secondpersoninservicedays
FROM
   dim.bedoccupancy bo
   JOIN dim.bed b ON b.bedid = bo.bedid
   JOIN dim.vwbed vb ON vb.bedid = bo.bedid
   LEFT JOIN (
      SELECT
         bo.date,
         r.roomid,
         bo.bedid,
         b.bedname,
         bo.occupied,
         bo.available
      FROM
         dim.bedoccupancy bo
         JOIN dim.bed b ON b.bedid = bo.bedid
         JOIN dim.room r ON r.roomid = b.roomid
      WHERE
         "date_part"('year':: character varying:: text, bo.date) >= 2024
         AND b.issecondperson = 1
   ) sbed ON sbed.date = bo.date
   AND sbed.roomid = vb.roomid
   AND sbed.bedid = vb.bedid
   JOIN dim.building bld ON bld.buildingid = vb.buildingid
   JOIN dim.levelofcare loc ON loc.levelofcareid = vb.levelofcareid
   JOIN dim.entity e ON e.entityid = vb.entityid
   JOIN dim.datetable dt ON dt.date = bo.date
WHERE
   "date_part"('year':: character varying:: text, bo.date) >= 2024
   AND b.issecondperson = 1;
