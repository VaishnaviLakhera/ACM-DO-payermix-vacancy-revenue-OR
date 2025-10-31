CREATE
OR REPLACE VIEW dim.starfactBudgetMonthlyOccupancy AS
SELECT
    dt.CalendarYear,
    dt.CalendarMonth,
    dt.CalendarEndOfMonthDate,
    e.entitycode,
    f.EntityId,
    f.FacilityId,
    bld.BuildingId,
    sum(sbo.BudgetAvailablePerDay) as BudgetAvailableDaysMTD,
    sum(sbo.BudgetResidentDaysPerDay) as BudgetResidentDaysMTD
FROM
    source_static.budget_occupancy sbo
    JOIN dim.levelofcare AS loc ON loc.entitycode = sbo.entitycode
    INNER JOIN dim.building AS bld ON sbo.mappedbuildingname_pcc = bld.buildingname
    left JOIN dim.facility AS f ON bld.facilityid = f.facilityid
    INNER JOIN dim.entity AS e ON sbo.entitycode = e.entitycode -- INNER JOIN dim.campus e ON e.entitycode = sbo.entitycode
    inner join dim.dateTablefuture dt on dt.date between sbo.startDate
    and sbo.endDate
group by
    dt.CalendarYear,
    dt.CalendarMonth,
    dt.CalendarEndOfMonthDate,
    e.entitycode,
    f.EntityId,
    f.FacilityId,
    bld.BuildingId WITH NO SCHEMA BINDING;
