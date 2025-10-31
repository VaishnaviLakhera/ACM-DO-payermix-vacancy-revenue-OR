CREATE OR REPLACE PROCEDURE dim.load_bedavailable()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.bedavailable;


INSERT INTO dim.bedavailable(
    date,
    bedid,
    bedname,
    available
)
SELECT DISTINCT
    dt.date,
    a.bedid,
    a.bedname,
    0 AS available
FROM dim.bed AS a
CROSS JOIN dim.datetable dt
INNER JOIN dim.vwbed AS v ON a.bedid = v.bedid
INNER JOIN dim.campusactivedates AS c ON v.entityid = c.entityid
WHERE (
    dt.date BETWEEN
    (select GREATEST('2024-01-01'::date, c.startdate))
	and 
	(select LEAST(dateadd(d, -1, current_date), c.enddate))
);


UPDATE dim.bedavailable
SET
    available = 1
FROM dim.bedavailable AS ba
INNER JOIN dim.bed AS b ON ba.bedid = b.bedid
INNER JOIN source_pcc.ods_bed_status AS oi ON oi.bed_id::int = b.sourceid::int
    AND oi.status_type = 'A'
    AND oi.effective_date <> coalesce(oi.ineffective_date, '')
    AND oi.effective_date::date <= ba.date
    AND (ba.date <= CASE WHEN coalesce(oi.ineffective_date, '') = '' THEN '9999-12-31'::date ELSE oi.ineffective_date::date end)
;


UPDATE dim.bedavailable
SET
    available = 1
FROM dim.bedavailable AS ba
    INNER JOIN dim.bed AS b ON ba.bedid = b.bedid
    INNER JOIN (
        SELECT 
            obs.fac_id
            , obs.bed_id
            , obs.ineffective_date  effective_date
            , NULL  ineffective_date
            , obs.status_type
        FROM source_pcc.ods_bed_status AS obs
            INNER JOIN (
                SELECT *
                FROM (
                    SELECT 
                        bed_id
                        , CASE 
                            WHEN max(ineffective_date::date) > max(effective_date::date) THEN  max(ineffective_date)
                            END ineffective_date 
                    FROM source_pcc.ods_bed_status AS obs
                    WHERE obs.status_type = 'I'
                    GROUP BY bed_id 
                ) x 
                WHERE x.ineffective_date IS NOT NULL
            ) maxobs ON maxobs.bed_id = obs.bed_id
                AND maxobs.ineffective_date = obs.ineffective_date
    ) AS oi
    ON oi.bed_id::int = b.sourceid::int
    AND oi.status_type = 'I'
    AND oi.effective_date <> coalesce(oi.ineffective_date, '')
    AND oi.effective_date::date <= ba.date
    AND (ba.date <= CASE WHEN coalesce(oi.ineffective_date, '') = '' THEN '9999-12-31'::date ELSE oi.ineffective_date::date end)
;



END;
$$
