CREATE OR REPLACE PROCEDURE dim.load_entityoperatingratiotarget()
 LANGUAGE plpgsql
AS $$
BEGIN

-- call dim.load_entityoperatingratiotarget()
-- Select * from dim.EntityOperatingRatioTarget;

TRUNCATE TABLE dim.EntityOperatingRatioTarget;

INSERT INTO dim.EntityOperatingRatioTarget (
        EntityId
        ,Year
        ,TargetOperatingRevenue
        ,TargetOperatingExpense
        ,entitycode
        ,entityname
)

SELECT 
    e.entityId AS entityid
    , title AS year
    , "target operating revenue"
    , "target operating expenses"
    , e.entitycode::INTEGER AS entitycode	
    ,e.entityname
FROM source_sharepoint.entity_operating_ratio_target ort
    inner join dim.entity e on e.entitycode = CAST(REGEXP_REPLACE(SPLIT_PART(ort.entity, '#', 2), '[^0-9]', '') AS INT) 
;

END;
$$
