Create
or replace view qlik.vw_admission_discharge AS
Select
    distinct dt.date,
    ci.client_id,
    m.first_name as firstname,
    m.last_name as lastname,
    cl.client_id_number As residentnumber,
    loc.facilityname AS facilityname,
    loc.entitycode AS entitycode,
    loc.levelofcareabbreviation AS levelofcare,
    loc.campusid AS campusid,
    ci.effective_date:: date AS admissiondate,
    cc.short_desc as action_code,
    ci.ineffective_date AS dischargedate,
    bd.bedname AS bedname,
    to_char(dt.date, 'MM/DD/YYYY') || vb.buildingid || vb.buildingid AS datebuildingkey,
    -- (
    --     to_char(
    --         ci.effective_date:: timestamp without time zone,
    --         'MM/DD/YYYY':: character varying:: text
    --     ) || vb.buildingid:: character varying:: text
    -- ) || vb.buildingid:: character varying:: text AS datebuildingkey,
    CASE
    WHEN dt.date:: timestamp without time zone = admissiondate
    AND loc.levelofcareabbreviation:: text = 'AL':: character varying:: text
    AND action_code IN('AA') THEN 1
    ELSE 0 END AS admissionsal,
    CASE
    WHEN dt.date:: timestamp without time zone = admissiondate
    AND loc.levelofcareabbreviation:: text = 'IL':: character varying:: text
    AND action_code IN('AA') THEN 1
    ELSE 0 END AS admissionsil,
    CASE
    WHEN dt.date:: timestamp without time zone = admissiondate
    AND loc.levelofcareabbreviation:: text = 'SNF':: character varying:: text
    AND action_code IN('AA') THEN 1
    ELSE 0 END AS admissionssnf -- CASE
    -- WHEN dt.date = ci.ineffective_date:: date
    -- AND loc.levelofcareabbreviation = 'AL' THEN 1
    -- ELSE 0 END AS dischargesal,
    -- CASE
    -- WHEN dt.date = ci.ineffective_date:: date
    -- AND loc.levelofcareabbreviation = 'IL' THEN 1
    -- ELSE 0 END AS dischargesil,
    -- CASE
    -- WHEN dt.date = ci.ineffective_date:: date
    -- AND loc.levelofcareabbreviation = 'SNF' THEN 1
    -- ELSE 0 END AS dischargessnf
from
    source_pcc.census_item ci
    left JOIN source_pcc.census_codes cc ON ci.action_code_id = cc.item_id
    JOIN source_pcc.clients cl ON cl.client_id = ci.client_id
    JOIN source_pcc.mpi m ON m.mpi_id = cl.mpi_id
    left JOIN dim.levelofcare AS loc ON ci.fac_id = loc.sourceid
    left JOIN dim.bed AS bd ON ci.bed_id = bd.sourceid
    left join dim.vwbed vb on vb.bedid = bd.bedid --left JOIN dim.building AS bld ON rm.buildingid = bld.buildingid
    left JOIN dim.datetable dt ON dt.date = ci.effective_date:: date
Where
    ci.effective_date:: date IS NOT NULL
    and ci.deleted = 'N'
    and bd.bedname is not null
    and extract (
        year
        from
            ci.effective_date:: date
    ) >= '2024' WITH NO SCHEMA BINDING;
