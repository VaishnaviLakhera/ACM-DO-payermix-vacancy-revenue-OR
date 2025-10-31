CREATE OR REPLACE PROCEDURE dim.load_campus()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.campus;


INSERT INTO dim.campus (
    fromdate,
    todate,
    campusname,
    campusshortname,
    campusabbreviation,
    campusdescription,
    entitycode,
    entityid,
    lineofbusinessid,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT
    fromdate,
    todate,
    campusname,
    campusname AS campusshortname,
    campusabbreviation,
    campusname AS campusdescription,
    entitycode,
    entityid,
    lineofbusinessid,
    sourcetable,
    sourcesystem,
    tenant
FROM (
    SELECT DISTINCT
        CURRENT_DATE                        AS fromdate,
        '9999-12-31'::date                  AS todate,
        SUBSTRING(facility_code FROM 2)     AS campuscode,
        TRIM(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(name, 'Oakview Personal Care', ''),
                        'Forestview Healthcare Center', ''),
                    'Residential Living', ''),
                'Assisted Living', ''),
            'Healthcare Center', '')
        )                                   AS campusname,
        UPPER(REGEXP_REPLACE(
            TRIM(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(name, 'Oakview Personal Care', ''),
                            'Forestview Healthcare Center', ''),
                        'Residential Living', ''),
                    'Assisted Living', ''),
                'Healthcare Center', '')
            ),
            '[^A-Z]+', ''
        ))                                  AS campusabbreviation,
        e.entitycode                        AS entitycode,
        e.entityid                          AS entityid,
        1                                   AS lineofbusinessid,
        'facility'                          AS sourcetable,
        'source_pcc'                        AS sourcesystem,
        'ACM'                               AS tenant
    FROM source_pcc.facility AS sf
    INNER JOIN dim.entity AS e ON e.entityname IS NOT NULL AND substring(sf.facility_code FROM 2) = e.entitycode
)
where campuscode <> ''
;



END;
$$
