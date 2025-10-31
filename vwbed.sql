CREATE
OR REPLACE VIEW "dim"."vwbed" AS
SELECT
   e.lineofbusinessid,
   e.entityid,
   loc.campusid,
   bld.facilityid,
   loc.levelofcareid,
   bld.buildingid,
   u.unitid,
   r.roomid,
   b.bedid,
   b.sourceid AS bedsourceid,
   b.sourceid AS bedorgentsys,
   c.campusname,
   c.campusabbreviation,
   loc.facilityname,
   btrim(
      "replace"(
         loc.levelofcarename:: text,
         e.entityname:: text,
         '':: character varying:: text
      )
   ) AS levelofcarename,
   loc.levelofcareabbreviation,
   bld.buildingname,
   u.unitname,
   r.roomname,
   b.bedname,
   b.issecondperson
FROM
   dim.levelofcare loc
   JOIN dim.entity e ON loc.entitycode:: character varying:: text = e.entitycode:: text
   JOIN dim.campus c ON loc.campusid = c.campusid
   AND e.entityid = c.entityid
   JOIN dim.building bld ON loc.levelofcareid = bld.levelofcareid
   JOIN dim.unit u ON bld.buildingid = u.buildingid
   JOIN dim.room r ON u.unitid = r.unitid
   JOIN dim.bed b ON r.roomid = b.roomid
ORDER BY
   e.entityid,
   loc.levelofcareid,
   bld.buildingid,
   bld.facilityid,
   u.unitid,
   r.roomid,
   b.bedid;
