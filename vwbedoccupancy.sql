CREATE
OR REPLACE VIEW "qlik"."vwbedoccupancy" AS
SELECT
    dt.dateid,
    bo.date,
    vb.campusname,
    e.entitycode,
    loc.levelofcareabbreviation AS levelofcare,
    loc.facilitycode,
    vb.buildingname,
    vb.buildingid,
    (
        to_char(
            bo.date:: timestamp without time zone,
            'MM/DD/YYYY':: character varying:: text
        ) || vb.buildingid:: character varying:: text
    ) || vb.buildingid:: character varying:: text AS datebuildingkey,
    vb.unitname,
    vb.roomid,
    vb.roomname,
    vb.bedname,
    vb.bedid,
    bo.occupied AS residentdays,
    bo.available AS inservicedays,
    bo.vacant,
    bo.occupancydays,
    bo.vacancydays,
    bo.outofservicedays,
    CASE
    WHEN bo.available = 1 THEN 0
    ELSE 1 END AS outofservice,
    0 AS secondperson,
    CASE
    WHEN bo.date:: timestamp without time zone = a.admissiondate
    AND loc.levelofcareabbreviation:: text = 'AL':: character varying:: text THEN 1
    ELSE 0 END AS admissionsal,
    CASE
    WHEN bo.date:: timestamp without time zone = a.admissiondate
    AND loc.levelofcareabbreviation:: text = 'IL':: character varying:: text THEN 1
    ELSE 0 END AS admissionsil,
    CASE
    WHEN bo.date:: timestamp without time zone = a.admissiondate
    AND loc.levelofcareabbreviation:: text = 'SNF':: character varying:: text THEN 1
    ELSE 0 END AS admissionssnf
FROM
    dim.bedoccupancy bo
    JOIN dim.bed b ON b.bedid = bo.bedid
    JOIN dim.vwbed vb ON vb.bedid = bo.bedid
    JOIN dim.building bld ON bld.buildingid = vb.buildingid
    JOIN dim.levelofcare loc ON loc.levelofcareid = vb.levelofcareid
    JOIN dim.entity e ON e.entityid = vb.entityid
    JOIN dim.datetable dt ON dt.date = bo.date
    LEFT JOIN dim.admission a ON a.admissionid = bo.admissionid
WHERE
    "date_part"('year':: character varying:: text, bo.date) >= 2024
    AND b.issecondperson = 0;
