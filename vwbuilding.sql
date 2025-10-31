CREATE
OR REPLACE VIEW "dim"."vwbuilding" AS
SELECT
        b.buildingid,
        b.fromdate,
        b.todate,
        b.buildingname,
        b.buildingshortname,
        b.buildingdescription,
        b.facilityid,
        b.entityid,
        b.levelofcareid,
        b.fac_id,
        b.sourceid,
        b.sourcecolumn,
        b.sourcetable,
        b.sourcesystem,
        b.tenant
FROM
        dim.building b
        JOIN (
                SELECT
                        b.facilityid,
                        "max"(b.todate) AS todate
                FROM
                        dim.building b
                GROUP BY
                        b.facilityid
        ) maxb ON maxb.facilityid = b.facilityid
        AND maxb.todate = b.todate;
