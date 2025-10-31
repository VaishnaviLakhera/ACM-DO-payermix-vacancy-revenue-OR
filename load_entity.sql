CREATE OR REPLACE PROCEDURE dim.load_entity()
 LANGUAGE plpgsql
AS $$
BEGIN

TRUNCATE TABLE dim.entity;


INSERT INTO dim.entity (
    fromdate,
    todate,
    entitycode,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT
    current_date                        AS fromdate,
    '12-31-9999'::date                  AS todate,
    substring(l.locationcode, 1, 3)     AS entitycode,
    l.locationcode                      AS sourceid,
    'locationcode'                      AS sourcecolumn,
    'ultiprolocation'                   AS sourcetable,
    'test_ultipro'                      AS sourcesystem,
    'acm'                               AS tenant
FROM test_ultipro.ultiprolocation AS l
;




UPDATE dim.entity
SET
    entityname = s.entityname,
    sourcecolumn = 'actnumbr_1',
    sourcetable = 'tbl_gl00100',
    sourcesystem = 'source_gp'
FROM dim.entity AS e
INNER JOIN (
    SELECT DISTINCT 
        actnumbr_1                      AS locationcode,
        max(isnull(b.dscriptn,''))      AS entityname	
    FROM source_gp.tbl_gl00100 AS a
    LEFT JOIN source_gp.tbl_gl40200 AS b ON a.actnumbr_1 = b.sgmntid
        AND b.sgmtnumb = 1
        AND NOT b.database ILIKE '%elim%'
    WHERE NOT a.database ILIKE '%elim%'
    GROUP BY actnumbr_1
) AS s ON e.sourceid = s.locationcode
AND s.entityname <> ''
;


INSERT INTO dim.entity (
    fromdate,
    todate,
    entitycode,
    entityname,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT
    current_date                        AS fromdate,
    '12-31-9999'::date                  AS todate,
    s.locationcode                      AS entitycode,
    s.entityname                        AS entityname,
    s.locationcode                      AS sourceid,
    'actnumbr_1'                        AS sourcecolumn,
    'tbl_gl00100'                       AS sourcetable,
    'source_gp'                         AS sourcesystem,
    'acm'                               AS tenant
FROM (
    SELECT DISTINCT 
        actnumbr_1                      AS locationcode,
        max(isnull(b.dscriptn,''))      AS entityname	
    FROM source_gp.tbl_gl00100 AS a
    LEFT JOIN source_gp.tbl_gl40200 AS b ON a.actnumbr_1 = b.sgmntid
        AND b.sgmtnumb = 1
        AND NOT b.database ILIKE '%elim%'
    WHERE NOT a.database ILIKE '%elim%'
    GROUP BY actnumbr_1
) AS s
WHERE s.locationcode NOT IN (
    SELECT sourceid
    FROM dim.entity
    WHERE sourcesystem = 'source_gp'
)
;


UPDATE dim.entity
SET
    entityname = s.entityname,
    sourcecolumn = 'custrecordentity_code',
    sourcetable = 'subsidiary',
    sourcesystem = 'source_netsuite'
FROM dim.entity AS e
INNER JOIN (
    SELECT DISTINCT
        s.custrecordentity_code     AS locationcode,
        max(isnull(s.name, ''))     AS entityname
    FROM source_netsuite.subsidiary s 
    WHERE s.name NOT ILIKE '%elim%'
    GROUP BY s.custrecordentity_code
) AS s ON e.sourceid = s.locationcode
AND s.entityname <> ''
;


INSERT INTO dim.entity (
    fromdate,
    todate,
    entitycode,
    entityname,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT
    current_date                        AS fromdate,
    '12-31-9999'::date                  AS todate,
    s.locationcode                      AS entitycode,
    s.entityname                        AS entityname,
    s.locationcode                      AS sourceid,
    'custrecordentity_code'             AS sourcecolumn,
    'subsidiary'                        AS sourcetable,
    'source_netsuite'                   AS sourcesystem,
    'acm'                               AS tenant
FROM (
    SELECT DISTINCT
        s.custrecordentity_code     AS locationcode,
        max(isnull(s.name, ''))     AS entityname
    FROM source_netsuite.subsidiary s 
    WHERE s.name NOT ILIKE '%elim%'
    GROUP BY s.custrecordentity_code
) AS s
WHERE s.locationcode NOT IN (
    SELECT sourceid
    FROM dim.entity
    WHERE sourcesystem = 'source_netsuite'
)
; 


UPDATE dim.entity
SET lineofbusinessid = 1
WHERE entitycode IN ('100','200','324','323','610','810','820','840','835')
;

UPDATE dim.entity
SET lineofbusinessid = 2
WHERE entitycode LIKE '7%'
;

UPDATE dim.entity
SET lineofbusinessid = 3
WHERE entitycode IN ('400','500')
;

UPDATE dim.entity
SET lineofbusinessid = 4
WHERE entitycode IN ('900','910')
;


DELETE FROM dim.entity
WHERE entityname IS NULL
;

update dim.entity 
set entityAbbreviation = UPPER(REGEXP_REPLACE(entityname, '[^A-Z]+', ''));

update dim.entity set entityAbbreviation = 'RW' where entityname = 'Riverwoods';


END;
$$
