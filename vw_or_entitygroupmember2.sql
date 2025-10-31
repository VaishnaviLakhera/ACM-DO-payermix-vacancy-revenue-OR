CREATE
OR REPLACE VIEW "qlik"."vw_or_entitygroupmember2" AS
SELECT
   em.entitygroupmemberid,
   em.entitygroupid,
   em.entityid,
   em.entitycode
FROM
   dim.entitygroupmember em;
