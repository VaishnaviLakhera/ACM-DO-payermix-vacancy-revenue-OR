CREATE
OR REPLACE VIEW "qlik"."vw_pm_campusbuilding" AS
SELECT
   b.buildingid,
   b.buildingname,
   c.entityid,
   c.campusname,
   c.campusabbreviation AS facilityabbreviation,
   loc.levelofcareabbreviation AS levelofcare
FROM
   dim.building b
   JOIN dim.levelofcare loc ON loc.levelofcareid = b.levelofcareid
   LEFT JOIN dim.campus c ON c.entitycode:: text = loc.entitycode:: character varying:: text;
