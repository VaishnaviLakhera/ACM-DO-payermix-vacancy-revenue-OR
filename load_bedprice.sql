CREATE OR REPLACE PROCEDURE dim.load_bedprice()
 LANGUAGE plpgsql
AS $$
BEGIN

/*
select * from dim.bedprice
call dim.load_bedprice()

*/

If exists 
 (Select 1 from source_pcc.ar_market_rates limit 1)
Then

 TRUNCATE TABLE dim.bedprice;


--extract correct bedprice 
create temp  table temp_bedprice as --5898
select distinct
   --f.name
     l.levelofcarename as facilityname
   , levelofcareabbreviation as levelofcare
   , entitycode 
   , u.unit_desc as unitname
   , r.room_desc as roomname
   , CASE 
    WHEN levelofcare = 'IL' AND lr.short_description IN (
        'CO','DU','COU','CU','EU','FU','AU','BU','FR25','AR25','COBU','ER25','B','A','COB','C','CON'
    ) THEN 'A'
    
    WHEN levelofcare = 'IL' AND lr.short_description IN (
        'CO2','DU2','COU2','CU2','EU2','FU2','AU2','BU2','FR2','AR2','COBU2','ER2','B2','A2','COB2','C2','CON2'
    ) THEN 'B'
    WHEN levelofcare = 'AL' AND lr.short_description IN (
       'AL',	'MS25',	'PCP',	'CEP1',	'CEP4',	'CEP3',	'CEP2',	'SHAL',	'SHRS',	'AR2'
    ) THEN 'A'
    WHEN levelofcare = 'AL' AND lr.short_description IN (
        'AL2',	'M225',	'PC2',	'CEP2P',	'SH2P'
    ) THEN 'B'
    WHEN levelofcare = 'IL' AND lr.short_description IN (
        'CO2','DU2','COU2','CU2','EU2','FU2','AU2','BU2','FR2','AR2','COBU2','ER2','B2','A2','COB2','C2','CON2'
    ) THEN 'C'

    ELSE NULL
END AS bedname
   , lr.long_description
   , lr.short_description
   , dr.eff_date_from as effectivedate
   , dr.eff_date_to as ineffectivedate
   , mr.daily_rate
   , mr.monthly_rate
-- select *
FROM source_pcc.ar_market_rates mr
    join source_pcc.ar_lib_rate_type lr on lr.rate_type_id = mr.rate_type_id and lr.deleted = 'N'
    join source_pcc.ar_date_range_market_rates dr on dr.eff_date_range_id = mr.eff_date_range_id  
    join source_pcc.facility f on f.fac_id = mr.fac_id
    join dim.levelofcare l on l.sourceid = mr.fac_id
    JOIN source_pcc.room r ON r.room_id = mr.room_id
    join source_pcc.unit u on u.unit_Id = r.unit_id
where mr.deleted = 'N'
-- and lr.short_description in ('IL2','ILP','PC2','PCP','MC2','MCP','MCS','CO','CO2','AL2P','ALPV','AL','AL2','MS25','M225','P','S',
-- 'TCUP','TCUDP','TCUSP','PDX','EU','EU2','FU','FU2','DU','DU2','COU','COU2','CU','CU2','AU','AU2','BU','BU2','FR25','FR2','AR25','AR2',
-- 'COBU','COBU2','ER25','ER2','B','B2','A','A2','AUP','PCS','COB2','COB','C','C2','CEP1','CEP2P','CEP4','CEP3','CEP2','PCDP','PCDS','CON',
-- 'CON2','SH2P','SHAL','SHRS')
AND (
    (facilityname = 'Springhill Residential Living' AND unitname in ('Oak') and roomname in ('453B' , '303D') and  mr.monthly_rate = '5753'  and  lr.short_description IN ('AU')
    OR
    (facilityname = 'Springhill Residential Living' AND lr.short_description IN ('AU', 'AU2', 'CO', 'CO2') )
    )
    OR
    (facilityname = 'Asbury Methodist Village Residential Living' AND lr.short_description IN (
        'EU','EU2','FU','FU2','DU','DU2','COU','COU2','CU','CU2','AU','AU2','BU','BU2','FR25','FR2',
        'AR25','AR2','COBU','COBU2','ER25','ER2'     )
    )
    OR 
    (facilityname = 'RiverWoods Residential Living' AND roomname like '%-%' and lr.short_description IN ('CON','CON2')
    OR
    facilityname = 'RiverWoods Residential Living' AND roomname not like '%-%' and lr.short_description IN ('A','A2','CO','CO2')
    )
    OR
    (facilityname = 'Asbury Grace Park Residential Living' AND lr.short_description IN ('AU', 'AU2', 'CO', 'CO2'))
    OR
    (facilityname = 'Asbury Solomons Residential Living' AND lr.short_description IN ('B','B2','A','A2','AU', 'AU2', 'CO', 'CO2'))
    OR
    (facilityname = 'Bethany Village Residential Living' AND lr.short_description IN ('B','B2','A','A2','C','C2','COB2','COB','CON','CON2', 'CO', 'CO2'))
    OR
    (facilityname = 'Chandler Estate Residential Living' AND lr.short_description IN ('A','A2','CO', 'CO2'))
    OR
    (facilityname = 'Normandie Ridge Residential Living' AND lr.short_description IN ('A','A2','CO', 'CO2'))
     OR
    (levelofcare = 'SNF' AND lr.short_description IN ('P','S','TCUP','TCUDP','TCUSP','PDX' ))
     OR
    (facilityname = 'Asbury Solomons Assisted Living' AND lr.short_description IN ('PC2','PCP'))
    OR
    (facilityname = 'Springhill Oakview Personal Care' AND roomname <> 200 AND mr.daily_rate is null AND  lr.short_description IN ('SH2P','SHAL')
    oR
     facilityname = 'Springhill Oakview Personal Care' AND roomname = 200 and lr.short_description IN ('SHRS')
    )
    OR
    (levelofcare = 'AL' AND facilityname not in ( 'Asbury Solomons Assisted Living' , 'Springhill Oakview Personal Care') AND
     lr.short_description IN ('AL','AL2','MS25','M225','PC2','PCP','MC2','MCP','MCS','AL2P','ALPV','AUP','PCS','CEP1','CEP2P','CEP4','CEP3',
    'CEP2','PCDP','PCDS'))
)
and CAST(dr.eff_date_from AS DATE) = DATE '2025-01-01'
--and levelofcareabbreviation = 'AL' 
--and facilityname = 'Springhill Oakview Personal Care'    
order by  1, 2, 3, 4 ;


Delete from temp_bedprice 
where facilityname = 'Springhill Residential Living' AND unitname in ('Oak') 
and roomname in ('453B' , '303D') and  short_description IN ('AU') and  monthly_rate <> '5753'  ;

Delete from temp_bedprice 
where facilityname = 'Asbury Methodist Village Assisted Living' and roomname in ('605') and  daily_rate in ( 349 ,192 )  ;

Delete from temp_bedprice 
where facilityname = 'Asbury Methodist Village Residential Living' and roomname in ('226','323','325','329','337','349','425','429','435',209,608) and  monthly_rate in ( 4210,0)  ;

-- Delete from temp_bedprice 
-- where facilityname = 'Asbury Solomons Healthcare Center' AND EXTRACT(YEAR FROM CAST(effectivedate AS DATE)) = 2024  
-- and ineffectivedate is null  ;

-- Delete from temp_bedprice 
-- where EXTRACT(YEAR FROM CAST(effectivedate as date )) = 2025 
-- and effectivedate <> '2025-01-01 00:00:00.000' ;

INSERT INTO temp_bedprice (
    facilityname,
    levelofcare,
    entitycode,
    unitname,
    roomname,
    bedname,
    long_description,
    short_description,
    effectivedate,
    monthly_rate
)
(
SELECT
    'RiverWoods Residential Living',
    'IL',
    835,
    'GC-1st Floor',
    '60',
    'A',
    'IL Cottages A',
    'CO',
    '2025-06-01 00:00:00.000',
    1889.00
WHERE NOT EXISTS (
    SELECT 1
    FROM temp_bedprice
    WHERE facilityname = 'RiverWoods Residential Living'
      AND unitname = 'GC-1st Floor'
      AND roomname = '60'
    and bedname = 'A' )
    UNION
SELECT
    'RiverWoods Residential Living',
    'IL',
    835,
    'GC-1st Floor',
    '60',
    'B',
    'IL Cottages A 2P',
    'CO2',
    '2025-06-01 00:00:00.000',
    413.00
WHERE NOT EXISTS (
    SELECT 1
    FROM temp_bedprice
    WHERE facilityname = 'RiverWoods Residential Living'
      AND unitname = 'GC-1st Floor'
      AND roomname = '60'
      and bedname = 'B'

)
);




------ IL-------------------

INSERT INTO dim.bedprice (  
    bedname,
    bedid,
    roomid,
    roomname,
    buildingid,  
    buildingname,
    entitycode,
    campusname,
    levelofcare,
    facilityname,
    unitname,
    roomdescription,
    effectivedate,
    ineffectivedate,
    daily_rate ,
    monthly_rate,
   -- bedprice,
    ServiceDescription,
    BillPeriod,
    sourcetable,
    tenant
)
SELECT DISTINCT
    vw.bedname  AS bedname,
    vw.bedid AS bedid,
    vw.roomid AS roomid,
    vw.roomname  AS roomname,
    vw.buildingid  AS buildingid,
    buildingname AS buildingname,
    bp.entitycode AS entitycode,
    campusname AS campusname,
    vw.levelofcareabbreviation AS levelofcare,
    vw.facilityname,
    vw.unitname AS unitname,
    bp.long_description AS roomdescription,
    bp.effectivedate::DATE AS effectivedate,
     '9999-12-31'::DATE AS ineffectivedate,
     daily_rate ,
    monthly_rate,
    --COALESCE(bp.daily_rate::INTEGER ,bp.monthly_rate::INTEGER )  AS bedprice,
    NULL AS ServiceDescription,
    CASE 
    WHEN bp.levelofcare IN ('AL', 'SNF') THEN 'DY'
    WHEN bp.levelofcare = 'IL' THEN 'MO'
END AS BillPeriod,
   -- bp.issecondperson AS issecondperson,
    'bed_price_static' AS sourcetable,
    'ACM' AS tenant
FROM temp_bedprice bp 
JOIN dim.vwbed vw 
    ON  vw.facilityname = bp.facilityname
    AND vw.levelofcareabbreviation = bp.levelofcare
    AND vw.roomname = bp.roomname 
    AND vw.unitname = bp.unitname
    And vw.bedname = bp.bedname
WHERE 
bp.levelofcare in ('IL')

      ;

-------------SNF-------------

-- Step 1: Get latest bed availability per bedid for 2025
CREATE TEMP TABLE temp_latest_beds AS 
 SELECT 
        lb.bedid,
        lb.date,
        lb.available,
        ROW_NUMBER() OVER (
            PARTITION BY lb.bedid 
            ORDER BY CASE 
                WHEN EXTRACT(YEAR FROM lb.date) = 2025 AND lb.available = 'true' THEN 0 
                ELSE 1 
            END,
            lb.date DESC
        ) AS rn
    FROM dim.bedavailable lb
WHERE EXTRACT(YEAR FROM date) = 2025 
;
-- Step 2: Get available beds with metadata
CREATE TEMP TABLE temp_available_beds AS
SELECT 
    lb.date,
    vb.bedid,
    vb.bedname,               -- 'A' or 'B'
    vb.roomname,
    vb.roomid,
    vb.facilityname,
    vb.buildingname,
    vb.buildingid,
    vb.unitname,
    vb.issecondperson,
    vb.campusname,
    vb.levelofcareabbreviation
FROM temp_latest_beds lb
JOIN dim.vwbed vb ON vb.bedid = lb.bedid
WHERE lb.rn = 1
  AND lb.available = 'true';

-- Step 3: Identify available bed types per room & facility
CREATE TEMP TABLE temp_room_classification AS
SELECT 
    roomname,
    facilityname,
    LISTAGG(DISTINCT bedname, ',') AS bed_types
FROM temp_available_beds
GROUP BY roomname, facilityname;

-- Step 4: Final result with room type
CREATE TEMP TABLE temp_final_result AS
SELECT 
    ab.*,
    rc.bed_types,
    CASE 
    --SNF---
        WHEN ab.levelofcareabbreviation = 'SNF' and rc.bed_types = 'A' THEN 'Private'
        WHEN ab.levelofcareabbreviation = 'SNF' and rc.bed_types = 'L' THEN 'Private'
        WHEN ab.levelofcareabbreviation = 'SNF' and rc.bed_types = 'R' THEN 'Private'
        WHEN ab.levelofcareabbreviation = 'SNF' and rc.bed_types = 'B' THEN 'Second Person'
        WHEN ab.levelofcareabbreviation = 'SNF' and rc.bed_types IN ('A,B', 'B,A', 'L,R', 'R,L') THEN 'Semi'
         --AL--- 

   When ab.levelofcareabbreviation = 'AL' AND ab.campusname = 'Asbury Grace Park' AND ab.roomname IN (201,202,203,204,205,206,207,208,209,210,211,212) and rc.bed_types = 'A'  THEN 'MC - Private'
   When ab.levelofcareabbreviation = 'AL' AND ab.campusname = 'Asbury Grace Park'  and rc.bed_types = 'B'  THEN '2nd Person' 
   When ab.levelofcareabbreviation = 'AL' AND ab.campusname = 'Asbury Grace Park'  and rc.bed_types IN ('A,B', 'B,A') THEN 'Semi Private'

    When ab.levelofcareabbreviation = 'AL' AND ab.campusname = 'RiverWoods' AND ab.roomname IN (26,33,34,35,36,37,38,40,41,42,43,44,45,46,47,48,49,50,51,52,54,56,57,60,61,62,63,64,65,66,67,70,71,81) and rc.bed_types = 'A' Then 'PC - Private'
    When ab.levelofcareabbreviation = 'AL' AND ab.campusname = 'RiverWoods' AND ab.roomname IN (27,28,29,30,31,32,39,53,55,68,69) and rc.bed_types = 'A' Then 'PC - Dbl Private'
   
        WHEN ab.levelofcareabbreviation = 'AL' and rc.bed_types = 'A' THEN 'Private'
    WHEN ab.levelofcareabbreviation = 'AL' and rc.bed_types = 'B' THEN '2nd Person'
    WHEN ab.levelofcareabbreviation = 'AL' AND ab.campusname = 'Asbury Ivy Gables' AND ab.roomname NOT IN ('112','113','114','115','116','117','118','119','120') and ab.bedname = 'A'  THEN 'Private'
    WHEN ab.levelofcareabbreviation = 'AL' AND ab.campusname = 'Asbury Ivy Gables' AND ab.roomname NOT IN ('112','113','114','115','116','117','118','119','120') and ab.bedname = 'B'  THEN '2nd Person'
    WHEN ab.levelofcareabbreviation = 'AL'  AND ab.campusname = 'Asbury Ivy Gables' THEN  'C - Semi Private'
    WHEN ab.levelofcareabbreviation = 'AL' AND ab.campusname = 'Bethany Village' AND ab.roomname  IN (101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129) and ab.bedname = 'A'  THEN 'Private'
    WHEN ab.levelofcareabbreviation = 'AL' AND ab.campusname = 'Bethany Village' AND ab.roomname IN (101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129) and ab.bedname = 'B'  THEN '2nd Person'
    
    WHEN ab.levelofcareabbreviation = 'AL' AND ab.campusname not in('Asbury Ivy Gables' ) and rc.bed_types IN ('A,B', 'B,A') THEN 'Semi Private'
 
    
    ELSE 'Unknown'
END AS room_type
FROM temp_available_beds ab
JOIN temp_room_classification rc 
    ON ab.roomname = rc.roomname 
   AND ab.facilityname = rc.facilityname;

/*

select * from temp_final_result
where roomname in ( 205 )
and campusname = 'Asbury Grace Park' 

*/

-- Step 5: Final insert into dim.bedprice
INSERT INTO dim.bedprice (  
    bedname,
    bedid,
    roomid,
    roomname,
    buildingid,
    buildingname,
    entitycode,
    campusname,
    levelofcare,
    facilityname,
    unitname,
    roomdescription,
    effectivedate,
    ineffectivedate,
    daily_rate ,
    monthly_rate,
    --bedprice,
    ServiceDescription,
    BillPeriod,
   -- issecondperson,
    sourcetable,
    tenant
)
SELECT DISTINCT
    vw.bedname,
    vw.bedid,
    vw.roomid,
    vw.roomname,
    vw.buildingid,
    vw.buildingname,
    bp.entitycode,
    vw.campusname,
    vw.levelofcareabbreviation AS levelofcare,
    vw.facilityname,
    vw.unitname,
    bp.long_description,
    bp.effectivedate::DATE,
    '9999-12-31'::DATE AS ineffectivedate,
    daily_rate ,
    monthly_rate,
    --COALESCE(bp.daily_rate::INTEGER, bp.monthly_rate::INTEGER) AS bedprice,
    NULL AS ServiceDescription,
    'DY' AS BillPeriod,
  --  bp.issecondperson,
    'bed_price_static' AS sourcetable,
    'ACM' AS tenant
FROM temp_bedprice bp
JOIN temp_final_result vw
    ON vw.facilityname = bp.facilityname
   AND vw.levelofcareabbreviation = bp.levelofcare
   AND vw.roomname = bp.roomname
   AND vw.unitname = bp.unitname
--   AND vw.issecondperson = bp.issecondperson
   AND bp.long_description ILIKE '%' || vw.room_type || '%'
WHERE  bp.levelofcare in ( 'SNF' )

  ; 

INSERT INTO dim.bedprice (  
    bedname,
    bedid,
    roomid,
    roomname,
    buildingid,
    buildingname,
    entitycode,
    campusname,
    levelofcare,
    facilityname,
    unitname,
    roomdescription,
    effectivedate,
    ineffectivedate,
    daily_rate ,
    monthly_rate,
   -- bedprice,
    ServiceDescription,
    BillPeriod,
  --  issecondperson,
    sourcetable,
    tenant
)
SELECT DISTINCT
    vw.bedname  AS bedname,
    vw.bedid AS bedid,
    vw.roomid AS roomid,
    vw.roomname  AS roomname,
    vw.buildingid  AS buildingid,
    buildingname AS buildingname,
    bp.entitycode AS entitycode,
    campusname AS campusname,
    vw.levelofcareabbreviation AS levelofcare,
    vw.facilityname,
    vw.unitname AS unitname,
    bp.long_description AS roomdescription,
    bp.effectivedate::DATE AS effectivedate,
     '9999-12-31'::DATE AS ineffectivedate,
     daily_rate ,
    monthly_rate,
    --COALESCE(bp.daily_rate::INTEGER ,bp.monthly_rate::INTEGER )  AS bedprice,
    NULL AS ServiceDescription,
    CASE 
    WHEN bp.levelofcare IN ('AL', 'SNF') THEN 'DY'
    WHEN bp.levelofcare = 'IL' THEN 'MO'
END AS BillPeriod,
   -- bp.issecondperson AS issecondperson,
    'bed_price_static' AS sourcetable,
    'ACM' AS tenant
FROM temp_bedprice bp 
JOIN dim.vwbed vw 
    ON  vw.facilityname = bp.facilityname
    AND vw.levelofcareabbreviation = bp.levelofcare
    AND vw.roomname = bp.roomname
    AND vw.unitname = bp.unitname
    And vw.bedname = bp.bedname
   -- And vw.issecondperson = bp.issecondperson
WHERE 
 bp.levelofcare in ('AL') 
and campusname in ('Asbury Solomons' , 'Springhill' ,'Chandler Estate' , 'Asbury Methodist Village' )

      ;  


INSERT INTO dim.bedprice (  
    bedname,
    bedid,
    roomid,
    roomname,
    buildingid,
    buildingname,
    entitycode,
    campusname,
    levelofcare,
    facilityname,
    unitname,
    roomdescription,
    effectivedate,
    ineffectivedate,
    daily_rate ,
    monthly_rate,
    --bedprice,
    ServiceDescription,
    BillPeriod,
   -- issecondperson,
    sourcetable,
    tenant
)
SELECT DISTINCT
    vw.bedname,
    vw.bedid,
    vw.roomid,
    vw.roomname,
    vw.buildingid,
    vw.buildingname,
    bp.entitycode,
    vw.campusname,
    vw.levelofcareabbreviation AS levelofcare,
    vw.facilityname,
    vw.unitname,
    bp.long_description,
    bp.effectivedate::DATE,
    '9999-12-31'::DATE AS ineffectivedate,
    daily_rate ,
    monthly_rate,
    --COALESCE(bp.daily_rate::INTEGER, bp.monthly_rate::INTEGER) AS bedprice,
    NULL AS ServiceDescription,
    'DY' AS BillPeriod,
    --vw.issecondperson,
    'bed_price_static' AS sourcetable,
    'ACM' AS tenant
 fROM temp_bedprice bp
JOIN temp_final_result vw
    ON vw.facilityname = bp.facilityname
   AND vw.levelofcareabbreviation = bp.levelofcare
   AND vw.roomname = bp.roomname
   AND vw.unitname = bp.unitname
  -- AND vw.issecondperson = bp.issecondperson
  AND bp.long_description ILIKE '%' || vw.room_type || '%'
  --and TRIM(LOWER(bp.long_description)) = TRIM(LOWER(vw.room_type))

WHERE  bp.levelofcare in (  'AL' )
and bp.long_description not in ('IL - 2nd Person' , 'IL - Private' )
 and  campusname not in ('Asbury Solomons' , 'Springhill' ,'Chandler Estate', 'Asbury Methodist Village')
-- and campusname = 'Asbury Grace Park'
-- and bp.roomname = 205
  ; 




ELSE
        INSERT INTO dim.error_load (storedprocedure_name, error_datetime, error_message)
        VALUES ('dim.load_bedprice', GETDATE(), 'Source tables missing data');

        RAISE NOTICE 'No data found: dim.load_bedprice()'; 
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO dim.error_load (storedprocedure_name, error_datetime, error_message)
        VALUES ('dim.load_bedprice', GETDATE(), SQLERRM);

        RAISE NOTICE 'Error with stored procedure: dim.load_bedprice() %', SQLERRM;


drop table if exists temp_bedprice ;
Drop table IF EXISTS temp_latest_beds ;
Drop table IF EXISTS temp_available_beds ;
Drop table IF EXISTS temp_room_classification ;
Drop table IF EXISTS temp_final_result ;

create temp  table temp_bedprice2 as
select
     b.bed_desc as bedname
   , b.bed_id  
   , l.levelofcarename as facilityname 
   , levelofcareabbreviation as levelofcare
   , entitycode 
   , u.unit_desc as unitname
   , r.room_desc as roomname    
   , lr.long_description
   , lr.short_description
   , dr.eff_date_from as effectivedate
   --, dr.eff_date_to as ineffectivedate
   ,'9999-12-31'::DATE AS ineffectivedate
   ,min( mr.daily_rate ) as daily_rate
   , min(mr.monthly_rate) as monthly_rate
FROM source_pcc.ar_market_rates mr
    join source_pcc.ar_lib_rate_type lr on lr.rate_type_id = mr.rate_type_id and lr.deleted = 'N'
    join source_pcc.ar_date_range_market_rates dr on dr.eff_date_range_id = mr.eff_date_range_id  
    join source_pcc.facility f on f.fac_id = mr.fac_id
    join dim.levelofcare l on l.sourceid = mr.fac_id
    JOIN source_pcc.room r ON r.room_id = mr.room_id
    join source_pcc.bed AS b on  b.room_id = r.room_id 
    join source_pcc.unit u on u.unit_Id = r.unit_id
where mr.deleted = 'N'
and CAST(dr.eff_date_from AS DATE) = DATE '2025-01-01'
and lr.short_description in ('A2','COB2','SH2P','FR25','COU2','AUN','CO2') 
AND b.bed_id  in
(select b.sourceid
from dim.bed b 
left join dim.bedprice bp on b.bedid=bp.bedid 
left join dim.vwbed v on b.bedid = v.bedid 
left join dim.bedavailable a on a.bedid = b.bedid
where bp.bedid is null and b.deleted='N'
and available = 'True' and date = CURRENT_DATE -1 )
group by 
 b.bed_desc ,b.bed_id  
   , l.levelofcarename 
   , levelofcareabbreviation
   , entitycode 
   , u.unit_desc 
   , r.room_desc  
   , lr.long_description
   , lr.short_description
   , dr.eff_date_from 
   ,ineffectivedate
   order by b.bed_id
;

INSERT INTO dim.bedprice (  
    bedname,
    bedid,
    roomid,
    roomname,
    buildingid,  
    buildingname, 
    entitycode,
    campusname,
    levelofcare,
    facilityname,
    unitname,
    roomdescription,
    effectivedate,
    ineffectivedate,
    daily_rate ,
    monthly_rate,
   -- bedprice,
    ServiceDescription,
    BillPeriod,
    sourcetable,
    tenant
)
SELECT DISTINCT
    vw.bedname  AS bedname,
    vw.bedid AS bedid,
    vw.roomid AS roomid,
    vw.roomname  AS roomname,
    vw.buildingid  AS buildingid,
    buildingname AS buildingname,
    bp.entitycode AS entitycode,
    campusname AS campusname,
    vw.levelofcareabbreviation AS levelofcare,
    vw.facilityname,
    vw.unitname AS unitname,
    bp.long_description AS roomdescription,
    bp.effectivedate::DATE AS effectivedate,
    '9999-12-31'::DATE AS ineffectivedate,
     daily_rate ,
     monthly_rate,
    NULL AS ServiceDescription,
    CASE 
    WHEN bp.levelofcare IN ('AL', 'SNF') THEN 'DY'
    WHEN bp.levelofcare = 'IL' THEN 'MO'
END AS BillPeriod,
   -- bp.issecondperson AS issecondperson,
    'bed_price_static' AS sourcetable,
    'ACM' AS tenant
FROM temp_bedprice2 bp 
JOIN dim.vwbed vw 
    ON  vw.facilityname = bp.facilityname
    AND vw.levelofcareabbreviation = bp.levelofcare
    AND vw.roomname = bp.roomname
    AND vw.unitname = bp.unitname
    And vw.bedname = bp.bedname
      ;

UPDATE dim.bedprice
SET billperiod = CASE
    WHEN monthly_rate IS NOT NULL THEN 'MO'
    WHEN daily_rate IS NOT NULL THEN 'DY'
    ELSE billperiod
END;





END;
$$
