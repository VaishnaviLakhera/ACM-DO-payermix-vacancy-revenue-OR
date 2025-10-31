CREATE
OR REPLACE VIEW qlik.vw_or_YEBudgetOccupancy AS
SELECT
    e.EntityID AS entityid,
    e.entitycode,
    -- f.FacilityID AS facilityid,
    -- l.levelofcareid AS levelofcare,
    extract(
        year
        from
            bo.CalendarEndOfMonthDate
    ) as YEYear,
    sum(BudgetResidentDaysMTD) as YEBudgetResidentDays,
    sum(BudgetAvailableDaysMTD) as YEBudgetInServiceDays
from
    dim.starfactBudgetMonthlyOccupancy bo -- inner join dim.vwBuilding bu on bu.BuildingID = bo.BuildingID
    -- inner join dim.levelofcare l ON l.levelofcareid = bu.levelofcareid
    -- and bu.BuildingName not in ('IL APKBVL', 'IL APKB', 'Cottages') -- AKP Duplicate buildings
    -- Left join dim.facility f on f.FacilityID = bo.FacilityID
    inner join dim.Entity e on e.Entitycode = bo.Entitycode
    inner join (
        select
            MIN(
                DATE_TRUNC(
                    'MONTH',
                    CAST(eor.Year || '-' || eor.Month || '-01' AS DATE)
                )
            ) AS minDate,
            MAX(
                DATE_TRUNC(
                    'MONTH',
                    CAST(eor.Year || '-' || eor.Month || '-01' AS DATE)
                )
            ) AS maxDate
        from
            dim.EntityOperatingRatio eor
    ) eor on bo.CalendarEndOfMonthDate >= eor.minDate
group by
    e.EntityID,
    e.entitycode,
    -- f.FacilityID,
    -- l.levelofcareid,
    extract(
        year
        from
            bo.CalendarEndOfMonthDate
    ) WITH NO SCHEMA BINDING;
