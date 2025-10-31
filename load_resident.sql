CREATE OR REPLACE PROCEDURE dim.load_resident()
 LANGUAGE plpgsql
AS $$
BEGIN



TRUNCATE TABLE dim.resident;


INSERT INTO dim.resident(
    firstname,
    preferredname,
    middlename,
    lastname,
    fullname,
    sex,
    birthdate,
    maritalstatustype,
    ethnicitytype,
    racetype,
    primarylanguagetype,
    secondarylanguagetype,
    educationtype,
    religiontype,
    birthplace,
    occupation,
    maidenname,
    fromdate,
    todate,
    firstadmissiondate,
    emailaddress,
    phonehome,
    phonecell,
    mrn,
    deceaseddate,
    sourceid,
    sourcecolumn,
    sourcetable,
    sourcesystem,
    tenant
)
SELECT DISTINCT
    m.first_name                        AS firstname,
  --  m.preferred_name                    AS preferredname,
    cl.nickname                          AS preferredname,
    m.middle_name                       AS middlename,
    m.last_name                         AS lastname,
    replace(
        coalesce(m.last_name || ', ', '') || 
        coalesce(m.first_name || ' ', '') || 
        coalesce(m.middle_name || ' ', ''),
        '  ', ' '
    )                                   AS fullname,
    m.sex                               AS sex,
    CASE
        WHEN m.date_of_birth IS NULL OR m.date_of_birth = '' THEN NULL
        ELSE cast(m.date_of_birth AS timestamp)
    END                                 AS birthdate,
    m.marital_status_id                 AS maritalstatustype,
    m.ethnicity_id                      AS ethnicitytype,
    m.race_id                           AS racetype,
    m.primary_lang_id                   AS primarylanguagetype,
    m.secondary_lang_id                 AS secondarylanguagetype,
    m.education_id                      AS educationtype,
    m.religion_id                       AS religiontype,
    m.place_of_birth                    AS birthplace,
    m.occupations                       AS occupation,
    m.maiden_name                       AS maidenname,
    current_date                        AS fromdate,
    '9999-12-31'::date                  AS todate,
    CASE
        WHEN cl.original_admission_date IS NULL OR cl.original_admission_date = '' THEN null::date
        ELSE cl.original_admission_date::date
    END                                 AS firstadmissiondate,
    m.email_address                     AS emailaddress,
    m.phone_home                        AS phonehome,
    m.phone_cell                        AS phonecell,
    cid.client_id_number                AS mrn,
    m.deceased_date::date               AS deceaseddate,
    m.mpi_id                            AS sourceid,
    'mpi_id'                            AS sourcecolumn,
    'mpi'                               AS sourcetable,
    'source_pcc'                        AS sourcesystem,
    'acm'                               AS tenant
FROM source_pcc.mpi AS m                                                     
LEFT JOIN (
    SELECT DISTINCT
        mpi_id,
        nickname,
        min(original_admission_date) AS original_admission_date
    FROM source_pcc.clients
    GROUP BY mpi_id,nickname
) cl ON m.mpi_id = cl.mpi_id
LEFT JOIN (
    SELECT mpi_id, client_id_number
    FROM (
        SELECT
            dense_rank() over(partition BY mpi_id ORDER BY admission_date desc, client_id desc) AS r,
            *
        FROM source_pcc.clients
    ) AS x
    WHERE x.r = 1
) AS cid ON m.mpi_id = cid.mpi_id
;



END;
$$
