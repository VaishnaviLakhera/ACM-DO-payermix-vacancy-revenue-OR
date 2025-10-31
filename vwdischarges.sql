CREATE
OR REPLACE VIEW "qlik"."vwdischarges" AS with cte as (
    SELECT
        DISTINCT a.admissionactionid,
        a.admissionid,
        a.admissionname,
        a.sourceid,
        a.effectivedate,
        COALESCE(NULLIF(a.bed_id, -1), MAX(b.bed_id)) AS resolved_bedid,
        a.residentid,
        a.entityid,
        a.campusid,
        a.levelofcareid,
        a.fac_id
    FROM
        dim.admission a
        LEFT JOIN dim.admission b ON a.admissionname = b.admissionname
        AND a.sourceid = b.sourceid
        AND a.admissionid <> b.admissionid
    GROUP BY
        a.bed_id,
        a.admissionactionid,
        a.admissionid,
        a.admissionname,
        a.sourceid,
        a.effectivedate,
        a.residentid,
        a.entityid,
        a.campusid,
        a.levelofcareid,
        a.fac_id
),
cte2 as (
    select
        a.*,
        ac.actioncode
    from
        cte as a
        INNER JOIN dim.admissionaction ac ON ac.admissionactionid = a.admissionactionid
    WHERE
        ac.actioncode IN ('DH', 'DE', 'DD')
)
select
    DISTINCT a.*,
    vw.campusabbreviation,
    vw.levelofcareabbreviation,
    vw.buildingname,
    vw.roomname,
    vw.bedname,
    a.effectivedate:: date AS date,
    (
        to_char(
            a.effectivedate:: timestamp without time zone,
            'MM/DD/YYYY':: character varying:: text
        ) || vw.buildingid:: character varying:: text
    ) || vw.buildingid:: character varying:: text AS datebuildingkey,
    CASE
    WHEN vw.levelofcareabbreviation = 'SNF'
    AND a.actioncode IN ('DH', 'DE', 'DD') THEN 1
    ELSE 0 END AS dischargessnf,
    CASE
    WHEN vw.levelofcareabbreviation = 'AL'
    AND a.actioncode IN ('DH', 'DE', 'DD') THEN 1
    ELSE 0 END AS dischargesal,
    CASE
    WHEN vw.levelofcareabbreviation = 'IL'
    AND a.actioncode IN ('DH', 'DE', 'DD') THEN 1
    ELSE 0 END AS dischargesil,
    a.effectivedate:: date AS dischargedate
from
    cte2 a
    join dim.bed vb on vb.sourceid = a.resolved_bedid
    join dim.vwbed vw on vw.bedid = vb.bedid with no schema binding;
