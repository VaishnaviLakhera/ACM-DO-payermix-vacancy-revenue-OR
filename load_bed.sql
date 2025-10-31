CREATE OR REPLACE PROCEDURE dim.load_bed()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.bed;


INSERT INTO dim.bed(
    fromdate,
    todate,
    bedname,
    bedshortname,
    beddescription,
    deleted,
    issecondperson,
    roomid,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT DISTINCT
    b.created_date::date            AS fromdate,
    CASE
        WHEN b.deleted = 'Y' THEN b.deleted_date::date
        else '9999-12-31'::date
    END                             AS todate,
    b.bed_desc                      AS bedname,
    b.bed_desc                      AS bedshortname,
    b.bed_desc                      AS beddescription,
    b.deleted                       AS deleted,
    CASE
        WHEN loc.levelofcareabbreviation IN ('AL', 'IL') AND b.bed_desc = 'A' THEN 0
        WHEN loc.levelofcareabbreviation = 'SNF' THEN 0
        else 1
    END                             AS issecondperson,
    r.roomid                        AS roomid,
    b.bed_id                        AS sourceid,
    'bed_id'                        AS sourcecolumn,
    'bed'                           AS sourcetable,
    'source_pcc'                    AS sourcesystem,
    'acm'                           AS tenant
FROM source_pcc.bed AS b
INNER JOIN dim.room AS r ON b.room_id = r.sourceid
INNER JOIN dim.levelofcare AS loc ON b.fac_id = loc.sourceid
;



END;
$$
