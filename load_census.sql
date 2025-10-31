CREATE OR REPLACE PROCEDURE dim.load_census()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.census;


INSERT INTO dim.census(
    date,
    admissionid,
    residentid,
    bedid,
    issecondperson,
    tenant
)
SELECT DISTINCT
    dt.date,
    x.admissionid,
    x.residentid,
    x.bedid,
    x.issecondperson,
    'ACM'
FROM (
    SELECT
        ads.admissiondate,
        ads.dischargedate,
        ads.admissionid,
        ads.residentid,
        b.bedid,
        b.issecondperson
    FROM source_pcc.census_item AS c
    INNER JOIN dim.bed AS b ON c.bed_id = b.sourceid
    RIGHT JOIN dim.admission AS ads ON b.sourceid = ads.bed_id
    INNER JOIN source_pcc.ar_common_code AS acc ON c.discharge_status = acc.item_id AND acc.is_discharge = 'Y'
) AS x
INNER JOIN dim.datetable AS dt ON dt.date BETWEEN x.admissiondate AND coalesce(x.dischargedate, '9999-12-31'::date)
;



END;
$$
