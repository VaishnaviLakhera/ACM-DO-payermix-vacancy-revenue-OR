CREATE
OR REPLACE VIEW "qlik"."vw_or_entities" AS
SELECT
   DISTINCT g.entitygroupid,
   g.entitygroupname,
   e.entityid,
   e.entitycode,
   e.entityname,
   e.entityabbreviation,
   l.lineofbusinessid,
   l.lineofbusinessname,
   e.isactive,
   g.sortorder
FROM
   dim.entitygroup g
   JOIN dim.entitygroupmember m ON m.entitygroupid = g.entitygroupid
   LEFT JOIN dim.entity e ON e.entitycode:: text = g.entitycode:: character varying:: text
   LEFT JOIN dim.lineofbusiness l ON l.lineofbusinessid = e.lineofbusinessid;
