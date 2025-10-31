CREATE
OR REPLACE VIEW "qlik"."vw_vrevenue_bedoccupancy2ndperson" AS
SELECT
   dt.dateid,
   bo.date,
   vb.bedid,
   sum(sbed.occupied) AS secondperson
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
         bo.occupied
      FROM
         dim.bedoccupancy bo
         JOIN dim.bed b ON b.bedid = bo.bedid
         JOIN dim.room r ON r.roomid = b.roomid
      WHERE
         "date_part"('year':: character varying:: text, bo.date) >= 2024
         AND b.issecondperson = 1
   ) sbed ON sbed.date = bo.date
   AND sbed.roomid = vb.roomid
   JOIN dim.building bld ON bld.buildingid = vb.buildingid
   JOIN dim.levelofcare loc ON loc.levelofcareid = vb.levelofcareid
   JOIN dim.campus e ON e.entityid = vb.entityid
   JOIN dim.datetable dt ON dt.date = bo.date
   LEFT JOIN dim.facility f ON f.facilityid = bld.facilityid
WHERE
   "date_part"('year':: character varying:: text, bo.date) >= 2024
   AND b.issecondperson = 0
GROUP BY
   dt.dateid,
   bo.date,
   vb.bedid;
