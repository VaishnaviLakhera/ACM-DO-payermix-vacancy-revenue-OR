CREATE OR REPLACE PROCEDURE dim.load_room()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.room;


INSERT INTO dim.room(
    fromdate,
    todate,
    roomname,
    roomshortname,
    roomdescription,
    buildingid,
    unitid,
    fac_id,
    floor_id,
    unit_id,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT DISTINCT
    current_date                AS fromdate,
    '9999-12-31'::date          AS todate,
    r.room_desc                 AS roomname,
    r.room_desc                 AS roomshortname,
    r.room_desc                 AS roomdescription,
    u.buildingid                AS buildingid,
    u.unitid                    AS unitid,
    r.fac_id                    AS fac_id,
    r.floor_id                  AS floor_id,
    r.unit_id                   AS unit_id,
    r.room_id                   AS sourceid,
    'room_id'                   AS sourcecolumn,
    'room'                      AS sourcetable,
    'source_pcc'                AS sourcesystem,
    'acm'                       AS tenant

FROM dim.levelofcare AS loc
INNER JOIN dim.unit AS u ON loc.sourceid = u.fac_id
INNER JOIN source_pcc.room AS r ON loc.sourceid = r.fac_id
AND u.floor_id = r.floor_id
AND u.sourceid = r.unit_id;


END;
$$
