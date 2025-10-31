CREATE OR REPLACE PROCEDURE dim.load_admission()
 LANGUAGE plpgsql
AS $$
BEGIN
 
    TRUNCATE TABLE dim.admission;
 
    INSERT INTO dim.admission
    (
        admissionname,
        admissiondate,
        admissiontime,
        admissionfromlocationid,
        admissionlocationtypeid,
        residentid,
        dischargedate,
        dischargetime,
        dischargetolocationid,
        dischargelocationtypeid,
        admitdischargelocation,
        admitdischargelocationtype,
        effectivedate,
        ineffectivedate,
        entityid,
        campusid,
        levelofcareid,
        buildingid,
        fromdate,
        todate,
        fac_id,
        bed_id,
        census_id,
        primary_payer_id,
        admissionactionid,
        admissionstatusid,
        sourceid,
        sourcecolumn,
        sourcetable,    
        sourcesystem,
        tenant
    )
    WITH numbered_admissions AS (
        SELECT DISTINCT
            pc.*,
            c.client_id_number,
            c.client_id,
            c.mpi_id,
            SUM(CASE WHEN pc.actioncodeid = 1 THEN 1 ELSE 0 END) OVER (
                PARTITION BY pc.patientid
                ORDER BY pc.begineffectivedate
                ROWS UNBOUNDED PRECEDING
            ) AS admission_episode
        FROM dim.vwcensus pc
        JOIN source_pcc.clients c 
            ON pc.patientid = c.client_id
        WHERE pc.begineffectivedate IS NOT NULL
          AND c.deleted = 'N'
    ),
    episode_dates AS (
        SELECT DISTINCT
            admission_episode,
            patientid,
            MIN(begineffectivedate) AS episode_admission_date,
            MAX(begineffectivedate) AS episode_discharge_date
        FROM numbered_admissions
        GROUP BY admission_episode, patientid
    )
    SELECT DISTINCT
        na.client_id_number                  AS admissionname,
        ed.episode_admission_date::timestamp AS admissiondate,
        ed.episode_admission_date::time      AS admissiontime,
        na.admittofromid                     AS admissionfromlocationid,
        na.admittofromid                     AS admissionlocationtypeid,
        FIRST_VALUE(r.residentid) OVER (PARTITION BY na.censusid) AS residentid,
        -- CASE 
        --     WHEN na.endeffectivedate IS NOT NULL AND ac.statuscode = 'D' 
        --         THEN na.endeffectivedate::timestamp
        --     ELSE na.endeffectivedate::timestamp
        -- END AS dischargedate,
        na.endeffectivedate::timestamp       AS dischargedate,
        na.endeffectivedate::time            AS dischargetime,
        na.admitdischargelocationid          AS dischargetolocationid,
        na.admitdischargelocationid          AS dischargelocationtypeid,
        na.admitdischargelocation            AS admitdischargelocation,
        na.admitdischargelocationtype        AS admitdischargelocationtype,
        na.begineffectivedate::timestamp     AS effectivedate,
        na.endeffectivedate::timestamp       AS ineffectivedate,
        loc.entityid                         AS entityid,
        loc.campusid                         AS campusid,
        loc.levelofcareid                    AS levelofcareid,
        bld.buildingid                       AS buildingid,
        current_date                         AS fromdate,
        '9999-12-31'::date                   AS todate,
        na.facilityid                        AS fac_id,
        na.bedid                             AS bed_id,
        na.censusid                          AS census_id,
        COALESCE(na.PayerID, p.primary_payer_id) AS primary_payer_id,
        aa.admissionactionid                 AS admissionactionid,
        ac.admissionstatusid                 AS admissionstatusid,
        na.client_id                         AS sourceid,
        'client_id'                          AS sourcecolumn,
        'clients'                            AS sourcetable,
        'source_pcc'                         AS sourcesystem,
        'acm'                                AS tenant
    FROM numbered_admissions na
    JOIN episode_dates ed 
        ON na.admission_episode = ed.admission_episode 
       AND na.patientid = ed.patientid
    INNER JOIN dim.resident r 
        ON r.sourceid = na.mpi_id
    LEFT JOIN dim.vwpayer AS p 
        ON na.client_id = p.client_id
    INNER JOIN dim.levelofcare AS loc 
        ON na.facilityid = loc.sourceid                
    LEFT JOIN dim.bed AS bd 
        ON na.bedid = bd.sourceid
    LEFT JOIN dim.room AS rm 
        ON bd.roomid = rm.roomid
    LEFT JOIN dim.building AS bld 
        ON rm.buildingid = bld.buildingid
    INNER JOIN dim.admissionaction aa 
        ON aa.sourceid = na.actioncodeid
    INNER JOIN dim.admissionstatus ac 
        ON ac.sourceid = na.statuscodeid
    GROUP BY na.client_id_number,
             r.residentid,
             na.admitdischargelocationid,
             na.admitdischargelocationtype,
             loc.entityid,
             loc.campusid,
             bld.buildingid,
             ed.episode_admission_date,
             na.admittofromid,
             na.admitdischargelocation,
             na.begineffectivedate,
             na.endeffectivedate,
             loc.levelofcareid,
             na.facilityid,
             na.bedid,
             na.censusid,
             na.payerid,
             p.primary_payer_id,
             aa.admissionactionid,
             ac.admissionstatusid,
             na.client_id,
             ac.statuscode;

END;
$$
