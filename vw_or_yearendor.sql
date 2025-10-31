CREATE
OR REPLACE VIEW "qlik"."vw_or_yearendor" AS
SELECT
   et.entityid,
   et.entitycode,
   et."year" AS targetyear,
   et.targetoperatingrevenue,
   et.targetoperatingexpense
FROM
   dim.entityoperatingratiotarget et;
