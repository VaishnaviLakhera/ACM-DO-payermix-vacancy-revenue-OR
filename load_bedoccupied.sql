CREATE OR REPLACE PROCEDURE dim.load_bedoccupied()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.bedoccupied;
DROP TABLE IF EXISTS #src;


SELECT DISTINCT
    b.bedid,
    ads.effectivedate::date,
    ads.ineffectivedate::date,
    ads.admissionid,
    ads.admissiondate,
    ads.primary_payer_id
INTO #src
FROM source_pcc.census_item AS ci
INNER JOIN dim.bed AS b ON ci.bed_id = b.sourceid
LEFT JOIN dim.admission AS ads ON ci.census_id = ads.census_id
LEFT JOIN source_pcc.census_codes AS cc ON ci.status_code_id = cc.item_id
WHERE ci.deleted = 'N'
    AND b.deleted = 'N'
    AND cc.short_desc NOT IN ('HUP', 'HN3', 'TUP')

UNION

SELECT DISTINCT
    b.bedid,
    ads.effectivedate::date,
    ads.ineffectivedate::date,
    ads.admissionid,
    ads.admissiondate,
    ads.primary_payer_id
FROM source_pcc.census_item AS ci
INNER JOIN source_pcc.census_item_secondary_bed cis ON cis.census_id = ci.census_id
INNER JOIN dim.bed AS b ON cis.bed_id = b.sourceid
LEFT JOIN dim.admission AS ads ON ci.census_id = ads.census_id
LEFT JOIN source_pcc.census_codes AS cc ON ci.status_code_id = cc.item_id
WHERE ci.deleted = 'N'
    AND b.deleted = 'N'
    AND cc.short_desc NOT IN ('HUP', 'HN3', 'TUP')
;


INSERT INTO dim.bedoccupied(
    date,
    bedid,
    admissionid,
    occupied,
    isadmitted,
    tenant
)
SELECT DISTINCT
    dt.date                                     AS date,
    s.bedid                                     AS bedid,
    max(coalesce(s.admissionid, 0))             AS admissionid,
    CASE
        WHEN count(s.admissionid) = 0 THEN 0
        ELSE 1
    END                                         AS occupied,
    CASE
        WHEN s.admissiondate = dt.date THEN 1
        ELSE 0
    END                                         AS isadmitted,
    'ACM'                                       AS tenant
FROM dim.datetable dt
INNER JOIN #src AS s
ON s.effectivedate <= dt.date
AND (s.ineffectivedate > dt.date OR s.ineffectivedate IS null)
AND dt.date BETWEEN '2008-09-01'::date AND dateadd(d, -1, current_date)
GROUP BY
    dt.date,
    s.bedid,
    s.admissiondate
;


UPDATE dim.bedoccupied
SET
    payerplanid = p.payerplanid,
    primary_payer_id = s.primary_payer_id
FROM dim.bedoccupied AS b
INNER JOIN #src AS s ON b.bedid = s.bedid
    AND b.admissionid = s.admissionid
    AND s.effectivedate <= b.date
    AND (s.ineffectivedate >= b.date OR s.ineffectivedate IS null)
INNER JOIN dim.payerplan p ON s.primary_payer_id = p.sourceid
;



END;
$$
