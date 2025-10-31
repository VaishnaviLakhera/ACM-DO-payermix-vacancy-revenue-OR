CREATE
OR REPLACE VIEW dim.vwcensus AS WITH census AS (
    SELECT
        ci.census_id AS CensusID,
        ci.fac_id AS FacilityID,
        ci.client_id AS PatientID,
        ci.bed_id AS BedID,
        ci.effective_date AS BeginEffectiveDate,
        ci.ineffective_date AS EndEffectiveDate,
        ci.primary_payer_id,
        COALESCE(
            ci.primary_payer_id,
            LAG(ci.primary_payer_id) OVER (
                PARTITION BY ci.client_id,
                ci.fac_id
                ORDER BY
                    ci.effective_date
            )
        ) AS FilledPrimaryPayerID,
        -- Fill missing primary_payer_id
        COALESCE(
            ci.bed_id,
            LAG(ci.bed_id) OVER (
                PARTITION BY ci.client_id,
                ci.fac_id
                ORDER BY
                    ci.effective_date
            )
        ) AS FilledBedID,
        -- Fill missing BedID
        ci.rugs_code AS CareLevelCode,
        ci.alternate_care_level AS AlternateCareLevelCode,
        ci.status_code_id AS StatusCodeID,
        ci.action_code_id AS ActionCodeID,
        ci.Created_date AS CreatedDate,
        ci.revision_date AS RevisionDate,
        ci.outpatient_status AS OutPatientStatus,
        cc.item_description AS AdmitDischargeLocationType,
        ci.hospital_stay_from AS HospitalStayFrom,
        ci.hospital_stay_to AS HospitalStayTo,
        ci.adt_tofrom_loc_id as AdmitToFromID,
        ci.admission_type as AdmissionType,
        ci.admission_source as AdmissionSource,
        ci.prior_medicare_days AS PriorMedicareDays,
        CASE
        WHEN (
            case
            when adt_tofrom_loc_id is NULL then 0
            else adt_tofrom_loc_id end
        ) < 0 THEN (
            case
            when adt_tofrom_loc_id is NULL then 0
            else adt_tofrom_loc_id end
        ) * -1
        ELSE (
            case
            when adt_tofrom_loc_id is NULL then 0
            else adt_tofrom_loc_id end
        ) END AS AdmitDischargeLocationID,
        CASE
        WHEN (
            case
            when adt_tofrom_loc_id is NULL then 0
            else adt_tofrom_loc_id end
        ) < 0 THEN eef.name
        ELSE cc1.item_description END AS AdmitDischargeLocation
    FROM
        source_pcc.census_item ci --     LEFT JOIN source_pcc.census_payer_info cp2 ON cp2.census_id = ci.census_id
        -- AND cp2.payer_rank = 2
        -- LEFT JOIN source_pcc.census_payer_info cp3 ON cp3.census_id = ci.census_id
        -- AND cp3.payer_rank = 3
        -- LEFT JOIN source_pcc.census_payer_info cp4 ON cp4.census_id = ci.census_id
        -- AND cp4.payer_rank = 4
        -- LEFT JOIN source_pcc.census_payer_info cp5 ON cp5.census_id = ci.census_id
        -- AND cp5.payer_rank = 5
        LEFT JOIN source_pcc.common_code cc ON cc.item_id = ci.adt_tofrom_id
        AND cc.item_code = 'admit'
        LEFT JOIN source_pcc.common_code cc1 ON cc1.item_id = ci.adt_tofrom_loc_id
        LEFT JOIN source_pcc.emc_ext_facilities eef ON (
            (
                case
                when adt_tofrom_loc_id is NULL then 0
                else adt_tofrom_loc_id end
            ) * -1
        ) = eef.ext_fac_id
    WHERE
        (
            ci.deleted IS NULL
            OR ci.deleted = 'N'
        ) -- AND ci.client_id = 217282
        -- AND ci.fac_id = '6'
        -- and CAST(ci.Effective_Date AS DATE) between '2024-11-01' and '2024-12-31'
)
SELECT
    CensusID,
    FacilityID,
    PatientID,
    COALESCE(primary_payer_id, FilledPrimaryPayerID) AS PayerID,
    COALESCE(bedid, FilledBedID) AS BedID,
    BeginEffectiveDate,
    EndEffectiveDate,
    CreatedDate,
    RevisionDate,
    CareLevelCode,
    AlternateCareLevelCode,
    StatusCodeID,
    ActionCodeID,
    AdmitDischargeLocationID,
    AdmitDischargeLocation,
    AdmitDischargeLocationType,
    CreatedDate,
    Revisiondate,
    OutPatientStatus,
    HospitalStayFrom,
    HospitalStayTo,
    AdmitToFromID,
    AdmissionType,
    AdmissionSource,
    PriorMedicareDays
FROM
    census WITH NO SCHEMA BINDING;
