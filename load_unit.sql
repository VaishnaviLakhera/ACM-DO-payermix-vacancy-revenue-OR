CREATE OR REPLACE PROCEDURE dim.load_unit()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.unit;


INSERT INTO dim.unit(
    fromdate,
    todate,
    unitname,
    unitshortname,
    unitdescription,
    entityid,
    campusid,
    levelofcareid,
    buildingid,
    fac_id,
    floor_id,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT DISTINCT
    current_date                    AS fromdate,
    '9999-12-31'::date              AS todate,
    u.unit_desc                     AS unitname,
    u.unit_desc                     AS unitshortname,
    u.unit_desc                     AS unitdescription,
    lc.entityid                     AS entityid,
    lc.campusid                     AS campusid,
    bld.levelofcareid               AS levelofcareid,
    bld.buildingid                  AS buildingid,
    u.fac_id                        AS fac_id,
    bld.sourceid                    AS floor_id,
    u.unit_id                       AS sourceid,
    'unit_id'                       AS sourcecolumn,
    'unit'                          AS sourcetable,
    'source_pcc'                    AS sourcesystem,
    'acm'                           AS tenant
FROM source_pcc.unit AS u
INNER JOIN dim.levelofcare AS lc ON u.fac_id = lc.sourceid
INNER JOIN dim.building AS bld ON lc.levelofcareid = bld.levelofcareid
;



END;
$$
