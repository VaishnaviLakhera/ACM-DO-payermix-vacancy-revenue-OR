CREATE OR REPLACE PROCEDURE dim.load_entityoperatingratio()
 LANGUAGE plpgsql
AS $$
BEGIN
/*
call dim.load_entityoperatingratio();
select * from dim.entityoperatingratio;
*/

    -- Truncate the target table before loading data
    TRUNCATE TABLE dim.EntityOperatingRatio;

    -- Insert the transformed data
    INSERT INTO dim.EntityOperatingRatio (
        EntityId
        , Year
        , Month
        , YTDOperatingRevenue
        , YTDOperatingExpense
        , entitycode
    )
    select  
        e.entityId
        , CAST(SUBSTRING(eor.title::TEXT FROM 1 FOR 4) AS INTEGER) AS Year
        , eor.month
        , eor."ytd operating revenue" 
        , eor."ytd operating expense"
        , e.entityCode
    FROM "source_sharepoint"."entity_operating_ratio"  eor
        inner join dim.entity e on e.entityCode = CAST(REGEXP_REPLACE(SPLIT_PART(eor.entity, '#', 2), '[^0-9]', '') AS INT) 


    -- SELECT DISTINCT
    --     -- CAST(REGEXP_SUBSTR(entity, '^\\d+') AS INT) AS EntityId, 
    --     f.entityid,
    --     CAST(SUBSTRING(eor.title::TEXT FROM 1 FOR 4) AS INTEGER) AS Year,
    --     month, 
    --     "ytd operating revenue", 
    --     "ytd operating expense",
    --     REGEXP_REPLACE(SPLIT_PART(entity, '#', 2), '[^0-9]', '') AS entitycode
    -- FROM "source_sharepoint"."entity_operating_ratio"  eor
    -- LEFT JOIN (
    --     SELECT 
    --         facilityid,
    --         entityid, 
    --         CAST(REGEXP_REPLACE(facilitycode, '[^0-9]', '') AS INT) AS numeric_facilitycode -- Remove alphabets from facilitycode
    --     FROM dim.facility 
    -- ) AS f
    -- ON CAST(REGEXP_REPLACE(SPLIT_PART(eor.entity, '#', 2), '[^0-9]', '') AS INT) = f.numeric_facilitycode
    -- --Where eor.title >= 2024;


;

END;
$$
