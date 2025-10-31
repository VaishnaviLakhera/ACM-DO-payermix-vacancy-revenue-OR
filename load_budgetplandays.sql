CREATE OR REPLACE PROCEDURE dim.load_budgetplandays()
 LANGUAGE plpgsql
AS $$
BEGIN

IF EXISTS (
        SELECT 1 
        FROM  "source_static"."budget_plan_days"
        LIMIT 1
    ) THEN
  
        TRUNCATE TABLE dim.budgetplandays ;

INSERT INTO dim.budgetplandays (
    startdate, 
    enddate, 
    payername, 
    planname, 
    entityname, 
    entityid,
    levelofcarename,
    buildingname,
    buildingid,
    payerplanid,
    payerid ,
    budgetplandays,
    days_between ,
    total_budgetplandays
)
SELECT DISTINCT
    -- Parse startdate dynamically
    TO_DATE(startdate,  'DD-MM-YYYY') AS startdate, 
    TO_DATE(enddate, 'DD-MM-YYYY') AS enddate, 
    bpd.payername  AS payername,
    bpd.Planname AS planname,
    campusname AS entityname,
    e.entityid ,
    mappedlevelofcare AS levelofcarename,
    b.buildingname AS Buildingname,
    b.buildingid,
    p.payerplanid,
    pp.payerid,
    Budgetplandays AS Budgetplandays,     
    -- Calculate the number of days between startdate and enddate
     GREATEST(DATEDIFF(DAY, TO_DATE(startdate,  'DD-MM-YYYY'), TO_DATE(enddate, 'DD-MM-YYYY')) + 1, 0) AS days_between,
    -- Multiply the number of days by Budgetplandays
    GREATEST(DATEDIFF(DAY, TO_DATE(startdate,  'DD-MM-YYYY'), TO_DATE(enddate, 'DD-MM-YYYY')) + 1, 0) * Budgetplandays AS total_budgetpplandays
   FROM
    "source_static"."budget_plan_days" bpd
    LEFT JOIN dim.building b ON b.buildingname = 
        CASE 
            WHEN mappedbuildingname = 'Wilson HCC' THEN 'Wilson HCC 2 N' 
            ELSE mappedbuildingname 
        END
    inner join dim.facility f  on f.facilityid = b.facilityid
    inner join dim.entity e on e.entityid = f.entityid 
    LEFT JOIN dim."payerplan" p ON p.planname =
    CASE 
            WHEN bpd.planname = 'PPM IL' then 'Private Pay'
            WHEN bpd.planname = 'PPM AL' then 'Private Pay'
            WHEN bpd.planname = 'PA MEDICAID' then 'Medicaid PA'
           -- WHEN bpd.planname = 'Hospice - Private Pay' then 'Hospice'
            WHEN bpd.planname = 'PRIVATE PAY' then 'Private Pay'
             --WHEN bpd.planname = 'MEDICARE A HIGHMARK' then 'Medicarea/Mc Hmo'

            ELSE bpd.planname
        END  
 left join dim.payer pp on pp.payername =
 CASE 
            WHEN bpd.payername = 'Private Pay' then 'Private'
           WHEN bpd.payername = 'Medicare Advantage' then 'Managed Medicare'
            ELSE bpd.payername 
        END
 
  --and p.payerid = pp.payerid
   -- where pp.payername = 'Hospice' -- levelofcare = 'SNF'
    --and p.payerid is NULL 
    
    ;


END IF;


END;
$$
