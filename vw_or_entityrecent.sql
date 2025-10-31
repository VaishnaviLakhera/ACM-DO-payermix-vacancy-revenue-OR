CREATE
OR REPLACE VIEW "qlik"."vw_or_entityrecent" AS
SELECT
   DISTINCT e.entitycode,
   e.entityname AS entity
FROM
   dim.bedoccupancy bo
   JOIN dim.vwbed v ON v.bedid = bo.bedid
   JOIN dim.entity e ON e.entityid = v.entityid
WHERE
   bo.date >= date_trunc(
      'year':: character varying:: text,
      'now':: character varying:: date:: timestamp without time zone
   );
