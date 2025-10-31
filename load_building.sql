CREATE OR REPLACE PROCEDURE dim.load_building()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.building;


INSERT INTO dim.building (
    fromdate,
    todate,
    buildingname,
    buildingshortname,
    buildingdescription,
    entityid,
    campusid,
    levelofcareid,
    facilityId,
    fac_id,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT DISTINCT
    current_date                AS fromdate,
    '9999-12-31'::date          AS todate,
    fl.floor_desc               AS buildingname,
    fl.floor_desc               AS buildingshortname,
    fl.floor_desc               AS buildingdescription,
    lc.entityid::int            AS entityid,
    lc.campusid::int            AS campusid,
    lc.levelofcareid::int       AS levelofcareid,
    f.facilityId                AS facilityid,
    fl.fac_id                   AS fac_id,
    fl.floor_id::int            AS sourceid,
    'floor_id'                  AS sourcecolumn,
    'floor'                     AS sourcetable,
    'source_pcc'                AS sourcesystem,
    'acm'                       AS tenant

-- select distinct
--     c.campusName
--     , fl.floor_desc
--     , fm.facilityCode
--     , f.facilityId
--        , lc.levelofcareabbreviation

FROM source_pcc.floor fl
    INNER JOIN dim.levelofcare lc ON fl.fac_id = lc.sourceid
   inner join dim.campus c on c.entityId = lc.entityId 
   left join source_static.facility_code_to_building_table_mapping fm on  fm.entityName = c.campusName
        and  fm.mappedbuildingname =  fl.floor_desc      
   left join dim.facility f on f.facilitycode = fm.facilityCode
        and f.entityid = c.entityId 
--where f.facilityId is NULL
;



END;
$$
