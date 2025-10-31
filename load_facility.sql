CREATE OR REPLACE PROCEDURE dim.load_facility()
 LANGUAGE plpgsql
AS $$
BEGIN

/*
call dim.load_facility();

select distinct 
    e.entityCode 
    , f.facilityCode
from dim.facility f
    inner join dim.entity e on e.entityid = f.entityid 
;
select count(*) from dim.facility;
select distinct sourceSystem from dim.facility

*/


truncate dim.facility;


--- insert from Netsuit ---
INSERT into dim.facility(
    fromdate,
    todate,
    facilitycode,
    facilityname,
    facilityabbreviation,
    isactive,
    entityid,
    entityCode,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
select distinct 
    CURRENT_DATE                                  AS fromdate,
    '9999-12-31'::date                            AS todate,
    c.custrecordclass_code                        AS facilitycode,
    c.Name                                        AS facilityname,
    UPPER(REGEXP_REPLACE(c.name, '[^A-Z]+', ''))  AS facilityabbreviation,
    TRUE                                          AS isactive,
    e.entityid                                    AS entityid,
    e.entitycode::int                             AS entityCode,
    concat(efd.entityCode,efd.facilityCode)       AS sourceid,
    'custrecord_valid_comb'                       AS sourcecolumn,
    'customrecord_valid_combo_text'               As sourcetable,
    'netsuite'                                    AS sourcesystem,
    'acm'                                         AS tenant
	-- e.entityID	
	-- , e.EntityCode 
	-- , custrecordclass_code	FacilityCode
	-- , c.Name				FacilityName	
from source_netsuite.Classification c
	inner join (
        select     
            custrecord_valid_comb
            , left(trim(custrecord_valid_comb), 3)          entitycode
            , substring(trim(custrecord_valid_comb), 5, 2)  facilitycode     
        from source_netsuite.customrecord_valid_combo_text	
	) efd on efd.FacilityCode = c.custrecordclass_code

	inner join dim.entity e on e.entityCode = efd.EntityCode

where trim(e.entityCode)  || '-' || trim(efd.facilityCode) not in (
    select 
        trim(e.entityCode)  || '-' || trim(f.facilityCode)
    from dim.facility f
        inner join dim.entity e on e.entityid = f.entityid 
)

;

-- Insert GreatPlains
INSERT INTO dim.facility (
    fromdate,
    todate,
    facilitycode,
    facilityname,
    facilityabbreviation,
    entityid,
    entitycode,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT distinct 
    current_date                        AS fromdate,
    '12-31-9999'::date                  AS todate,
    s.facilityCode                      AS facilitycode,
    s.facilityname                      AS facilityname,
    UPPER(REGEXP_REPLACE(s.facilityname, '[^A-Z]+', ''))  AS facilityabbreviation,
    e.entityid                          AS entityid,
    e.entitycode::INTEGER               AS entitycode,                 
    concat(s.entityCode,s.facilityCode)     AS sourceid,
    'actnumbr_1+actnumbr_2'             AS sourcecolumn,
    'tbl_gl00100'                       AS sourcetable,
    'greatplains'                         AS sourcesystem,
    'acm'                               AS tenant
FROM (
    SELECT DISTINCT 
        actnumbr_1                                              AS entityCode,
        actnumbr_2                                              AS facilityCode,
        ltrim(rtrim(actnumbr_1))+ltrim(rtrim(actnumbr_2))       AS sourceId,
        max(isnull(c.dscriptn,''))                              AS facilityname
    FROM source_gp.tbl_gl00100 AS a
        LEFT JOIN source_gp.tbl_gl40200 AS b ON a.actnumbr_1 = b.sgmntid
            AND b.sgmtnumb = 1
            AND NOT b.database ILIKE '%elim%'
        LEFT JOIN source_gp.tbl_gl40200 AS c ON a.actnumbr_2 = c.sgmntid
            AND c.sgmtnumb = 2
            AND NOT c.database ILIKE '%elim%'
    WHERE NOT a.database ILIKE '%elim%'
    GROUP BY 
        actnumbr_1
        , actnumbr_2
) s
    INNER JOIN dim.entity AS e ON e.entityCode = s.entityCode
where trim(e.entityCode)  || '-' || trim(s.facilityCode) not in (
    select 
        trim(e.entityCode)  || '-' || trim(f.facilityCode)
    from dim.facility f
        inner join dim.entity e on e.entityid = f.entityid 
)

;


-- insert from ultipro
INSERT INTO dim.facility (
    fromdate,
    todate,
    facilitycode,
    entityid,
    entitycode,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT distinct 
    current_date                        AS fromdate,
    '12-31-9999'::date                  AS todate,
    u.org1glsegment                     AS facilitycode,    
    e.entityid                          AS entityid,
    e.entitycode::INTEGER               AS entitycode,
    ltrim(rtrim(u.locationcode))||ltrim(rtrim(u.org1glsegment))    AS sourceid,
    'locationcode+org1glsegment'        AS sourcecolumn,
    'ultiproorglevel1'                  AS sourcetable,
    'ultipro'                           AS sourcesystem,
    'acm'                               AS tenant
--select *
FROM test_ultipro.ultiproorglevel1 AS u
    INNER JOIN dim.entity AS e ON u.locationcode = e.entitycode    
where  trim(u.locationcode) || '-' || trim(u.org1glsegment) not in (
    select 
        trim(e.entityCode)  || '-' || trim(f.facilityCode)
    from dim.facility f
        inner join dim.entity e on e.entityid = f.entityid 
)
;





END;
$$
