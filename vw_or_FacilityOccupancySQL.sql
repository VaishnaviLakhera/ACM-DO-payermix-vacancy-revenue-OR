CREATE
OR REPLACE VIEW qlik.vw_or_FacilityOccupancySQL AS
SELECT
    a.EntityID,
    a.EntityCode,
    a.EntityName,
    a.EntityAbbreviation,
    a.FacilityID,
    a.FacilityCode,
    a.FacilityName,
    a.MonthEndDate:: date MonthEndDate,
    a.ResidentDays,
    a.InServiceDays,
    a.BudgetResidentDays,
    a.BudgetInServiceDays,
    sum(o.ResidentDays) as ResidentDaysYTD,
    sum(o.InServiceDays) as InServiceDaysYTD,
    sum(o.BudgetResidentDays) as BudgetResidentDaysYTD,
    sum(o.BudgetInServiceDays) as BudgetInServiceDaysYTD -- exclude Inverness
,
    case
    when a.EntityCode = '610' then 0
    else a.ResidentDays end ResidentDaysExclude,
    case
    when a.EntityCode = '610' then 0
    else a.InServiceDays end InServiceDaysExclude,
    case
    when a.EntityCode = '610' then 0
    else a.BudgetResidentDays end BudgetResidentDaysExclude,
    case
    when a.EntityCode = '610' then 0
    else a.BudgetInServiceDays end BudgetInServiceDaysExclude,
    sum(
        case
        when a.EntityCode = '610' then 0
        else o.ResidentDays end
    ) ResidentDaysYTDExclude,
    sum(
        case
        when a.EntityCode = '610' then 0
        else o.InServiceDays end
    ) InServiceDaysYTDExclude,
    sum(
        case
        when a.EntityCode = '610' then 0
        else o.BudgetResidentDays end
    ) BudgetResidentDaysYTDExclude,
    sum(
        case
        when a.EntityCode = '610' then 0
        else o.BudgetInServiceDays end
    ) BudgetInServiceDaysYTDExclude
from
    (
        SELECT
            bmo.EntityId,
            bmo.EntityCode,
            bmo.EntityName,
            bmo.EntityAbbreviation,
            bmo.FacilityID,
            bmo.FacilityCode,
            coalesce(bmo.EntityAbbreviation, '') + ' - ' + coalesce(bmo.FacilityName, '') facilityName,
            bmo.Year,
            bmo.Month -- , dateadd(d, -1, DATEADD(m, 1, DATEFROMPARTS(bmo.Year, bmo.Month, 1))) as MonthEndDate
            -- DATEADD(day, -1, DATEADD(month, 1, TO_DATE(CONCAT(bmo.Year, '-', bmo.Month, '-01'), 'YYYY-MM-DD'))) AS MonthEndDate
,
            DATEADD(
                day,
                -1,
                DATEADD(
                    month,
                    1,
                    TO_DATE(bmo.Year || '-' || bmo.Month || '-01', 'YYYY-MM-DD')
                )
            ) AS MonthEndDate,
            case
            when mo.EntityId is not null then mo.ResidentDays
            else isnull(vmo.ResidentDays, 0) end as ResidentDays,
            case
            when mo.EntityId is not null then mo.InServiceDays
            else isnull(vmo.InServiceDays, 0) end as InServiceDays,
            isnull(bmo.MonthlyBudgetInUse, 0) as BudgetResidentDays,
            isnull(bmo.MonthlyBudgetInService, 0) as BudgetInServiceDays -- into #Occupancy_CTE
        from
            (
                SELECT
                    distinct e.EntityID,
                    e.EntityCode,
                    e.EntityAbbreviation,
                    e.EntityName,
                    f.FacilityID,
                    f.FacilityCode,
                    f.FacilityAbbreviation,
                    f.FacilityName,
                    bo.CalendarEndOfMonthDate as MonthEndDate,
                    extract(
                        year
                        from
                            bo.CalendarEndOfMonthDate
                    ) as Year,
                    extract(
                        month
                        from
                            bo.CalendarEndOfMonthDate
                    ) as month,
                    sum(BudgetResidentDaysMTD) as MonthlyBudgetInUse,
                    sum(BudgetAvailableDaysMTD) as MonthlyBudgetInService
                from
                    dim.starfactBudgetMonthlyOccupancy bo
                    inner join dim.Building bu on bu.BuildingID = bo.BuildingID
                    and bu.BuildingName not in ('IL APKBVL', 'IL APKB', 'Cottages') -- AKP Duplicate buildings
                    inner join dim.facility f on f.FacilityID = bu.FacilityID -- match OR date data
                    inner join dim.Entity e on e.Entityid = f.Entityid
                    inner join (
                        SELECT
                            distinct last_day(CAST(eor.Year || '-' || eor.Month || '-01' AS DATE)) date --     ,DATE_TRUNC(
                            --     'MONTH',
                            --     CAST(eor.Year || '-' || eor.Month || '-01' AS DATE)
                            -- ):: date AS date
                        from
                            dim.EntityOperatingRatio eor
                    ) eor on eor.Date = bo.CalendarEndOfMonthDate
                group by
                    e.EntityID,
                    e.EntityCode,
                    e.EntityAbbreviation,
                    e.EntityName,
                    f.FacilityID,
                    f.FacilityCode,
                    f.FacilityName,
                    f.FacilityAbbreviation,
                    bo.CalendarEndOfMonthDate,
                    extract(
                        year
                        from
                            bo.CalendarEndOfMonthDate
                    ),
                    extract(
                        month
                        from
                            bo.CalendarEndOfMonthDate
                    )
            ) bmo -- SharePoint Override Monthly Occupancy
            left join (
                SELECT
                    mo.EntityId,
                    f.FacilityID,
                    mo.entitycode,
                    mo.Year,
                    mo.Month,
                    sum(mo.ResidentDays) as ResidentDays,
                    sum(mo.InServiceDays) as InServiceDays
                from
                    (
                        select
                            m1.*,
                            f.entityid,
                            e.entitycode,
                            f.facilityid,
                            "resident_days" as residentdays,
                            "inservice_days" as inservicedays
                        from
                            (
                                select
                                    case
                                    when SUBSTRING(
                                        m.entity
                                        from
                                            position(' ' in m.entity) + 1
                                    ) = 'Riverwoods' then 'RiverWoods'
                                    else SUBSTRING(
                                        m.entity
                                        from
                                            position(' ' in m.entity) + 1
                                    ) end as en,
                                    SUBSTRING(
                                        m.facility
                                        from
                                            position(' ' in m.facility) + 1
                                    ) as fa,
                                    m.*
                                from
                                    source_sharepoint.monthly_occupancy as m
                                    inner join dim.campusactivedates as cad on (
                                        case
                                        when SUBSTRING(
                                            m.entity
                                            from
                                                position(' ' in m.entity) + 1
                                        ) = 'Riverwoods' then 'RiverWoods'
                                        else SUBSTRING(
                                            m.entity
                                            from
                                                position(' ' in m.entity) + 1
                                        ) end
                                    ) = cad.campusname
                                    and m.year:: int >= extract(
                                        year
                                        from
                                            cad.startdate
                                    )
                                    and m.month:: int >= extract(
                                        month
                                        from
                                            cad.startdate
                                    )
                            ) as m1
                            inner join dim.facility f on f.facilityname = (
                                case
                                when m1.en = 'Asbury Solomons'
                                and m1.fa = 'Skilled Nursing Facility' then 'Asbury Solomons Healthcare Center'
                                else (m1.en || ' ' || m1.fa) end
                            )
                            inner join dim.Entity e on e.Entityid = f.Entityid
                    ) as mo
                    inner join dim.Entity e on e.Entityid = mo.Entityid
                    inner join dim.facility f on f.FacilityId = mo.FacilityId
                    left join dim.LineOfBusiness l on l.LineOfBusinessID = e.LineOfBusinessID
                group by
                    mo.EntityId,
                    mo.entitycode,
                    mo.Year,
                    mo.Month,
                    f.FacilityID
            ) mo on mo.entityid = bmo.entityid --mo.EntityID = bmo.EntityId
            and mo.FacilityID = bmo.FacilityID
            and mo.Month = bmo.Month
            and mo.Year = bmo.Year -- Vision Monthly Occupancy
            left join (
                SELECT
                    vb.EntityID,
                    e.entitycode,
                    f.FacilityID,
                    extract(
                        year
                        from
                            bo.Date
                    ) as Year,
                    extract(
                        month
                        from
                            bo.Date
                    ) as Month,
                    sum(bo.residentdays) as ResidentDays,
                    sum(bo.inservicedays) as InServiceDays
                from
                    qlik.vwBedOccupancy bo -- inner join dim.Bed bd on bd.BedID = bo.BedID
                    -- and bd.IsSecondPerson = 0
                    -- inner join dim.vwBed b on b.BedID = bo.BedID
                    -- inner join dim.Entity e on e.EntityID = b.EntityID
                    -- inner join dim.vwBuilding bu on bu.BuildingID = b.BuildingID
                    -- and bu.BuildingName not in ('IL APKBVL', 'IL APKB', 'Cottages') -- AKP Duplicate buildings
                    -- inner join dim.facility f on f.FacilityID = bu.FacilityID
                    JOIN dim.bed b ON b.bedid = bo.bedid
                    JOIN dim.vwbed vb ON vb.bedid = bo.bedid
                    JOIN dim.levelofcare lc ON lc.levelofcareid = vb.levelofcareid
                    JOIN dim.building bu ON bu.buildingid = vb.buildingid
                    AND bu.buildingname:: text <> 'IL APKBVL':: character varying:: text
                    AND bu.buildingname:: text <> 'IL APKB':: character varying:: text
                    AND bu.buildingname:: text <> 'Cottages':: character varying:: text
                    JOIN dim.facility f ON f.facilityid = bu.facilityid
                    JOIN dim.entity e ON e.entityid = f.entityid
                    JOIN dim.campusactivedates ca ON vb.entityid:: character varying:: text = ca.entityid:: character varying:: text
                    AND bo.date >= ca.startdate
                    AND bo.date <= ca.enddate
                group by
                    vb.EntityID,
                    e.entitycode,
                    f.FacilityID,
                    extract(
                        month
                        from
                            bo.Date
                    ),
                    extract(
                        year
                        from
                            bo.Date
                    )
            ) vmo on vmo.EntityID = bmo.EntityId
            and vmo.FacilityID = bmo.FacilityID
            and vmo.Month = bmo.Month
            and vmo.Year = bmo.Year
    ) a
    inner join (
        SELECT
            bmo.EntityId,
            bmo.EntityCode,
            bmo.EntityName,
            bmo.EntityAbbreviation,
            bmo.FacilityID,
            bmo.FacilityCode,
            isnull(bmo.EntityAbbreviation, '') + ' - ' + isnull(bmo.FacilityName, '') facilityName,
            bmo.Year,
            bmo.Month -- , dateadd(d, -1, DATEADD(m, 1, DATEFROMPARTS(bmo.Year, bmo.Month, 1))) as MonthEndDate
            -- DATEADD(day, -1, DATEADD(month, 1, TO_DATE(CONCAT(bmo.Year, '-', bmo.Month, '-01'), 'YYYY-MM-DD'))) AS MonthEndDate
,
            DATEADD(
                day,
                -1,
                DATEADD(
                    month,
                    1,
                    TO_DATE(bmo.Year || '-' || bmo.Month || '-01', 'YYYY-MM-DD')
                )
            ) AS MonthEndDate,
            case
            when mo.EntityId is not null then mo.ResidentDays
            else isnull(vmo.ResidentDays, 0) end as ResidentDays,
            case
            when mo.EntityId is not null then mo.InServiceDays
            else isnull(vmo.InServiceDays, 0) end as InServiceDays,
            isnull(bmo.MonthlyBudgetInUse, 0) as BudgetResidentDays,
            isnull(bmo.MonthlyBudgetInService, 0) as BudgetInServiceDays -- into #Occupancy_CTE
        from
            (
                SELECT
                    distinct e.EntityID,
                    e.EntityCode,
                    e.EntityAbbreviation,
                    e.EntityName,
                    f.FacilityID,
                    f.FacilityCode,
                    f.FacilityAbbreviation,
                    f.FacilityName,
                    bo.CalendarEndOfMonthDate as MonthEndDate,
                    extract(
                        year
                        from
                            bo.CalendarEndOfMonthDate
                    ) as Year,
                    extract(
                        month
                        from
                            bo.CalendarEndOfMonthDate
                    ) as month,
                    sum(BudgetResidentDaysMTD) as MonthlyBudgetInUse,
                    sum(BudgetAvailableDaysMTD) as MonthlyBudgetInService
                from
                    dim.starfactBudgetMonthlyOccupancy bo
                    inner join dim.Building bu on bu.BuildingID = bo.BuildingID
                    and bu.BuildingName not in ('IL APKBVL', 'IL APKB', 'Cottages') -- AKP Duplicate buildings
                    inner join dim.facility f on f.FacilityID = bu.FacilityID -- match OR date data
                    inner join dim.Entity e on e.EntityID = f.EntityID
                    inner join (
                        SELECT
                            distinct last_day(CAST(eor.Year || '-' || eor.Month || '-01' AS DATE)) date --     ,DATE_TRUNC(
                            --     'MONTH',
                            --     CAST(eor.Year || '-' || eor.Month || '-01' AS DATE)
                            -- ):: date AS date
                        from
                            dim.EntityOperatingRatio eor
                    ) eor on eor.Date = bo.CalendarEndOfMonthDate
                group by
                    e.EntityID,
                    e.EntityCode,
                    e.EntityAbbreviation,
                    e.EntityName,
                    f.FacilityID,
                    f.FacilityCode,
                    f.FacilityName,
                    f.FacilityAbbreviation,
                    bo.CalendarEndOfMonthDate,
                    extract(
                        year
                        from
                            bo.CalendarEndOfMonthDate
                    ),
                    extract(
                        month
                        from
                            bo.CalendarEndOfMonthDate
                    )
            ) bmo -- SharePoint Override Monthly Occupancy
            left join (
                SELECT
                    mo.EntityId,
                    mo.entitycode,
                    f.FacilityID,
                    mo.Year,
                    mo.Month,
                    sum(mo.ResidentDays) as ResidentDays,
                    sum(mo.InServiceDays) as InServiceDays
                from
                    (
                        select
                            m1.*,
                            f.entityid,
                            e.entitycode,
                            f.facilityid,
                            "resident_days" as residentdays,
                            "inservice_days" as inservicedays
                        from
                            (
                                select
                                    case
                                    when SUBSTRING(
                                        m.entity
                                        from
                                            position(' ' in m.entity) + 1
                                    ) = 'Riverwoods' then 'RiverWoods'
                                    else SUBSTRING(
                                        m.entity
                                        from
                                            position(' ' in m.entity) + 1
                                    ) end as en,
                                    SUBSTRING(
                                        m.facility
                                        from
                                            position(' ' in m.facility) + 1
                                    ) as fa,
                                    m.*
                                from
                                    source_sharepoint.monthly_occupancy as m
                                    inner join dim.campusactivedates as cad on (
                                        case
                                        when SUBSTRING(
                                            m.entity
                                            from
                                                position(' ' in m.entity) + 1
                                        ) = 'Riverwoods' then 'RiverWoods'
                                        else SUBSTRING(
                                            m.entity
                                            from
                                                position(' ' in m.entity) + 1
                                        ) end
                                    ) = cad.campusname
                                    and m.year:: int >= extract(
                                        year
                                        from
                                            cad.startdate
                                    )
                                    and m.month:: int >= extract(
                                        month
                                        from
                                            cad.startdate
                                    )
                            ) as m1
                            inner join dim.facility f on f.facilityname = (
                                case
                                when m1.en = 'Asbury Solomons'
                                and m1.fa = 'Skilled Nursing Facility' then 'Asbury Solomons Healthcare Center'
                                else (m1.en || ' ' || m1.fa) end
                            )
                            inner join dim.Entity e on e.Entityid = f.Entityid
                    ) as mo --inner join dim.Entity e on e.EntityID = mo.EntityID
                    INNER JOIN dim.entity e on e.entitycode = mo.entitycode
                    inner join dim.facility f on f.FacilityId = mo.FacilityId
                    left join dim.LineOfBusiness l on l.LineOfBusinessID = e.LineOfBusinessID
                group by
                    mo.EntityId,
                    mo.entitycode,
                    mo.Year,
                    mo.Month,
                    f.FacilityID
            ) mo on mo.EntityID = bmo.EntityId
            and mo.FacilityID = bmo.FacilityID
            and mo.Month = bmo.Month
            and mo.Year = bmo.Year -- Vision Monthly Occupancy
            left join (
                SELECT
                    vb.EntityID,
                    f.FacilityID,
                    extract(
                        year
                        from
                            bo.Date
                    ) as Year,
                    extract(
                        month
                        from
                            bo.Date
                    ) as Month,
                    sum(bo.residentdays) as ResidentDays,
                    sum(bo.inservicedays) as InServiceDays
                from
                    qlik.vwBedOccupancy bo -- inner join dim.Bed bd on bd.BedID = bo.BedID
                    -- and bd.IsSecondPerson = 0
                    -- inner join dim.vwBed b on b.BedID = bo.BedID
                    -- inner join dim.Entity e on e.EntityID = b.EntityID
                    -- inner join dim.vwBuilding bu on bu.BuildingID = b.BuildingID
                    -- and bu.BuildingName not in ('IL APKBVL', 'IL APKB', 'Cottages') -- AKP Duplicate buildings
                    -- inner join dim.facility f on f.FacilityID = bu.FacilityID
                    JOIN dim.bed b ON b.bedid = bo.bedid
                    JOIN dim.vwbed vb ON vb.bedid = bo.bedid
                    JOIN dim.levelofcare lc ON lc.levelofcareid = vb.levelofcareid
                    JOIN dim.building bu ON bu.buildingid = vb.buildingid
                    AND bu.buildingname:: text <> 'IL APKBVL':: character varying:: text
                    AND bu.buildingname:: text <> 'IL APKB':: character varying:: text
                    AND bu.buildingname:: text <> 'Cottages':: character varying:: text
                    JOIN dim.facility f ON f.facilityid = bu.facilityid
                    JOIN dim.entity e ON e.entitycode = f.entitycode
                    JOIN dim.campusactivedates ca ON vb.entityid:: character varying:: text = ca.entityid:: character varying:: text
                    AND bo.date >= ca.startdate
                    AND bo.date <= ca.enddate
                group by
                    vb.EntityID,
                    f.FacilityID,
                    extract(
                        month
                        from
                            bo.Date
                    ),
                    extract(
                        year
                        from
                            bo.Date
                    )
            ) vmo on vmo.EntityID = bmo.EntityId
            and vmo.FacilityID = bmo.FacilityID
            and vmo.Month = bmo.Month
            and vmo.Year = bmo.Year
    ) o on a.EntityID = o.EntityID
    and a.FacilityID = o.FacilityID
    and a.Year = o.Year
    and o.Month <= a.Month
where
    a.ResidentDays > 0
group by
    a.EntityID,
    a.EntityCode,
    a.EntityName,
    a.EntityAbbreviation,
    a.FacilityID,
    a.FacilityCode,
    a.FacilityName,
    a.MonthEndDate,
    a.ResidentDays,
    a.InServiceDays,
    a.BudgetResidentDays,
    a.BudgetInServiceDays WITH NO SCHEMA BINDING;
