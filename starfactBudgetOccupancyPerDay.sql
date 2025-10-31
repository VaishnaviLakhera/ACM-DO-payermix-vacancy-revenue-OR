CREATE
OR REPLACE VIEW dim.starfactBudgetOccupancyPerDay AS
SELECT
    dt.Date,
    e.entityid,
    e.entitycode,
    e.entityname,
    loc.facilitycode,
    loc.levelofcareid,
    loc.levelofcareabbreviation,
    bld.buildingid,
    bld.buildingname,
    sbo.budgetavailableperday,
    sbo.budgetresidentdaysperday

FROM
    source_static.budget_occupancy sbo
    INNER JOIN dim.building AS bld ON sbo.mappedbuildingname_pcc = bld.buildingname
    INNER JOIN dim.levelofcare AS loc ON bld.levelofcareid = loc.levelofcareid
    INNER JOIN dim.entity AS e ON loc.entityid = e.entityid
    -- INNER JOIN dim.datetable dt ON dt.date BETWEEN TO_DATE(sbo.startdate, 'DD/MM/YYYY')
    -- AND TO_DATE(sbo.enddate, 'DD/MM/YYYY')
    inner join dim.datetable dt on dt.date >= sbo.startdate
        and dt.date <= sbo.endDate 

WHERE
    dt.date < (
        SELECT
            MAX(date)
        FROM
            dim.datetable
    )
    AND bld.buildingid IS NOT NULL WITH NO SCHEMA BINDING;
