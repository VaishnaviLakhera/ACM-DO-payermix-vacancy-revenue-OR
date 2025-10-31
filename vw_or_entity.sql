CREATE
OR REPLACE VIEW "qlik"."vw_or_entity" AS
SELECT
   e.entityid,
   e.fromdate,
   e.todate,
   e.entitycode,
   e.entityname,
   e.entityabbreviation,
   e.lineofbusinessid,
   l.lineofbusinessname,
   e.isactive
FROM
   dim.entity e
   LEFT JOIN dim.lineofbusiness l ON l.lineofbusinessid = e.lineofbusinessid
WHERE
   e.entityname IS NOT NULL;
