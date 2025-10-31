CREATE OR REPLACE PROCEDURE dim.load_payer()
 LANGUAGE plpgsql
AS $$
BEGIN
  
/*
    call dim.load_payer()
    select * from dim.payer
*/

    IF EXISTS (SELECT 1 FROM source_pcc.ar_lib_payers LIMIT 1)
       AND EXISTS (SELECT 1 FROM source_pcc.common_code LIMIT 1) 
       AND EXISTS (SELECT 1 FROM source_static.budget_plan_days LIMIT 1) 
       
       THEN
    
        -- Truncate the table before inserting new data
        TRUNCATE TABLE dim.payer;

    -- Insert data into the dim.payer table
    INSERT INTO dim.payer (
        payername,
        payerabbreviation,
        payershortname,
        payer_reporting_group,
        sourcecolumn,
        sourcetable,
        sourcesystem,
        tenant
    )
    SELECT DISTINCT 
        cc.item_description AS Payername,
        cc.item_description AS payerabbreviation,
        cc.item_description AS payershortname,
        p.payer_reporting_group,
        'payername' AS sourcecolumn,
        'tbl_ar_lib_payers' AS sourcetable,
        'PCC' AS sourcesystem,
        'ACM' AS tenant
    FROM source_pcc.ar_lib_payers AS p
    INNER JOIN source_pcc.common_code AS cc ON p.payer_reporting_group = cc.item_id
    WHERE p.collections_template_id IS NOT NULL

    UNION

    SELECT 
    CASE 
        WHEN payername = 'medicarea/mc hmo' THEN 'MedicareA/MC HMO'
        WHEN payername = 'medicare advantage' THEN 'Medicare Advantage'
        ELSE payername 
    END AS payername_transformed,
    payername AS payerabbreviation,
    payername AS payershortname,
    0 AS payer_reporting_group,
    'payername' AS sourcecolumn,
    'source_static.budget_plan_days' AS sourcetable,
    'PCC' AS sourcesystem,
    'ACM' AS tenant
FROM (
    SELECT DISTINCT LOWER(payername) AS payername
    FROM source_static.budget_plan_days
    WHERE LOWER(payername) NOT IN (
        SELECT DISTINCT LOWER(cc.item_description)
        FROM source_pcc.ar_lib_payers p
        INNER JOIN source_pcc.common_code cc 
            ON p.payer_reporting_group = cc.item_id
        WHERE p.collections_template_id IS NOT NULL
    )
    AND LOWER(payername) <> 'private pay'
) 

UNION

    SELECT 
     'Benevolent' as payername ,
    'Benevolent' AS payerabbreviation,
    'Benevolent' AS payershortname,
    0 AS payer_reporting_group,
    'payername' AS sourcecolumn,
    'Manual' AS sourcetable,
    'PCC' AS sourcesystem,
    'ACM' AS tenant

;

 ELSE
        RAISE NOTICE 'No data found.';
        -- in future, insert into error table 
        -- insert into error_table (stored_procedure_name, error_datetime, error_messge)
    END IF;


  

END;
$$
