CREATE OR REPLACE PROCEDURE dim.load_bedoccupancy()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.bedoccupancy;


INSERT INTO dim.bedoccupancy(
    date,
    bedid,
    admissionid,
    payerplanid,
    primary_payer_id,
    occupied,
    available,
    isadmitted,
    isreadmitted,
    isrental,
    tenant
)
SELECT 
    a.date                          AS date,
    a.bedid                         AS bedid,
    b.admissionid                   AS admissionid,
    b.payerplanid                   AS payerplanid,
    b.primary_payer_id              AS primary_payer_id,
    coalesce(b.occupied, 0)         AS occupied,
    a.available                     AS available,
    coalesce(b.isadmitted, 0)       AS isadmitted,
    NULL                            AS isreadmitted,
    0                               AS isrental,
    'ACM'                           AS tenant
FROM dim.bedavailable AS a
LEFT JOIN dim.bedoccupied AS b ON a.date = b.date
AND a.bedid = b.bedid
;


DELETE FROM dim.bedoccupancy
USING source_pcc.bed_date_range,
    dim.bed,
    dim.datetable
WHERE dim.bedoccupancy.bedid = dim.bed.bedid
    AND dim.bed.sourceid = source_pcc.bed_date_range.bed_id
    AND source_pcc.bed_date_range.deleted = 'Y'
    AND (
        dim.datetable.date BETWEEN cast(source_pcc.bed_date_range.effective_date AS date)
        AND CASE
            WHEN source_pcc.bed_date_range.ineffective_date = '' THEN current_date
            WHEN source_pcc.bed_date_range.ineffective_date IS NULL THEN current_date
            ELSE cast(source_pcc.bed_date_range.ineffective_date AS date)
        END
    )
    AND dim.bedoccupancy.date = dim.datetable.date
    AND dim.bedoccupancy.occupied = 0
;







UPDATE dim.bedoccupancy
SET
    vacant = x.vacant,
    occupancydays = x.occupancydays,
    vacancydays = x.vacancydays,
    outofservicedays = x.outofservicedays
FROM dim.bedoccupancy bo
INNER JOIN (
    SELECT
        date,
        bo.bedid,
        admissionid,
        bo.occupied,
        bo.available,
        CASE WHEN bo.occupied = 0 AND bo.available = 1 THEN 1 ELSE 0 END AS vacant,
        sum(bo.occupied) over (partition BY bo.bedid, bo.grouping ORDER BY date rows BETWEEN unbounded preceding AND current row) AS occupancydays,
        sum(case WHEN bo.occupied = 0 AND bo.available = 1 THEN 1 ELSE 0 end) over (partition BY bo.bedid, bo.grouping ORDER BY date rows BETWEEN unbounded preceding AND current row) AS vacancydays,
        sum(case WHEN bo.available = 0 THEN 1 ELSE 0 end) over (partition BY bo.bedid, bo.grouping ORDER BY date rows BETWEEN unbounded preceding AND current row) AS outofservicedays
    FROM (
        SELECT
            date,
            bedid,
            admissionid,
            occupied,
            available,  
            dense_rank() over (order BY grp) AS grouping
        FROM (
            SELECT
                t.*,
                min(date) over (partition BY bedid, admissionid, available, occupied, seqnum - seqnum_iv) AS grp
            FROM (
                SELECT
                    bo.date,
                    bo.bedid,
                    bo.admissionid,
                    bo.occupied,
                    bo.available,
                    row_number() over (partition BY bo.bedid ORDER BY bo.date, bo.bedid) AS seqnum,
                    row_number() over (partition BY bo.bedid, bo.available, bo.admissionid ORDER BY bo.date, bo.bedid) AS seqnum_iv
                FROM dim.bedoccupancy bo      

            ) t
        ) t
    ) bo
) x ON x.date = bo.date
AND x.bedid = bo.bedid;



END;
$$
