CREATE
OR REPLACE VIEW "qlik"."vw_or_entitygroup2" AS
SELECT
   DISTINCT g.entitygroupid,
   g.entitygroupname,
   g.sortorder,
   g.entitycode
FROM
   dim.entitygroup g
   JOIN dim.entity e ON e.entitycode:: text = g.entitycode:: character varying:: text;
