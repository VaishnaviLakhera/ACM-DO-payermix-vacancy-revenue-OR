CREATE OR REPLACE PROCEDURE dim.load_entityoperatingratiomontlytarget()
 LANGUAGE plpgsql
AS $$
BEGIN

-- call dim.load_entityoperatingratiomontlytarget();
-- Select * from dim.EntityOperatingRatioMonthlyTarget;
TRUNCATE table dim.EntityOperatingRatioMonthlyTarget;

INSERT INTO dim.EntityOperatingRatioMonthlyTarget (
        entityid,
        entityname,
        year,
        Month,
        Entitycode,
        TargetOperatingRevenue,
        TargetOperatingExpenses
    )
SELECT DISTINCT
    e.entityid AS entityid,
    e.entityname AS entityname,
    Title AS year,
    mt.Month AS Month,
    e.entitycode As entitycode,
    "target operating revenue",
    "target operating expenses"
FROM 
    "source_sharepoint"."entityoperatingratiomonthlytarget" mt
JOIN 
    dim.entity e ON e.entitycode = mt.entity
    Where entityname IS NOT NULL;

End;
$$
