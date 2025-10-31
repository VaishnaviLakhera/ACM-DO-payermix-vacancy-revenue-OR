CREATE OR REPLACE PROCEDURE dim.load_payerplan()
 LANGUAGE plpgsql
AS $$
BEGIN

/*
    call dim.load_payerplan()
    select * from dim.payerplan
*/

    IF EXISTS (SELECT 1 FROM source_pcc.ar_lib_payers LIMIT 1)
       AND EXISTS (SELECT 1 FROM source_pcc.common_code LIMIT 1) 
       AND EXISTS (SELECT 1 FROM source_static.budget_plan_days LIMIT 1) 
       
       THEN
    
        -- Truncate the table before inserting new data
        TRUNCATE TABLE dim.payerplan;


insert into dim.payerplan(	
    PayerID,
    payername ,
	PlanID,
	PlanName,
    planabbriviation,
    planshortname,
	FromDate,
	ToDate,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem, 
    tenant 
)
select distinct 
    pp.payerid                                      AS PayerID,
    cc.item_description AS Payername,
	concat(payer_code, concat(' ', payer_code2))    AS PlanID,
	description                                     AS PlanName,
	description                                     AS planabbriviation,
	description                                     AS planshortname,
	to_date(p.created_date, 'YYYY-MM-DD')             AS FromDate,
	case
        when p.deleted_date is null or p.deleted_date = '' then cast('9999-12-31' as date)
        else to_date(p.deleted_date, 'YYYY-MM-DD')
    end                                             AS ToDate,
    payer_id                                        AS sourceid,
    'payer_id'                                      AS sourcecolumn,
    'source_pcc.ar_lib_payers'                      AS sourcetable,
    'PCC'                                           AS sourcesystem,
    'ACM'                                           AS tenant
from source_pcc.ar_lib_payers p 
left join source_pcc.common_code as cc on p.payer_reporting_group = cc.item_id 
left join dim.payer as pp on pp.payer_reporting_group = cc.item_id and p.payer_reporting_group = pp.payer_reporting_group --and  p.payer_code = pp.Payercode
 --where concat(payer_code, concat(' ', payer_code2)) is not NULL 

UNION 


select 
payerid as payerid ,
 payername AS Payername,
	null   AS PlanID,
    planname                                     AS PlanName,
	planname                                     AS planabbriviation,
	planname                                     AS planshortname,
	'2025=01-01'                                 AS FromDate,
    '9999-12-31'                                 AS ToDate,
    0                                            AS sourceid,
    'payer_id'                                   AS sourcecolumn,
    'source_pcc.ar_lib_payers'                   AS sourcetable,
    'PCC'                                        AS sourcesystem,
    'ACM'  AS tenant 
from
(

SELECT
 DISTINCT     
     planname, 
    p.payername ,
    p.payerid 
FROM source_static.budget_plan_days b
join dim.payer p on lower(p.payername) = lower(b.payername)
where lower(planname) not in ('ppm al' , 'ppm il' , 'private pay' ,'pa medicaid' )

)
;

UPDATE dim.payerplan
SET payername = 'Benevolent',
    payerid = (
        SELECT payerid
        FROM dim.payer
        WHERE payername = 'Benevolent'
        LIMIT 1
    )
WHERE planname LIKE '%Benevolent%';

ELSE
        RAISE NOTICE 'No data found.';
        -- in future, insert into error table 
        -- insert into error_table (stored_procedure_name, error_datetime, error_messge)
    END IF;


--select * from dim.payerplan Where planname like '%Benevolent%';


END;
$$
