CREATE
OR REPLACE VIEW qlik.vwfacilitybudgetoccupancy AS
SELECT
    TO_CHAR(sbo.date, 'MM/DD/YYYY') || sbo.buildingid || sbo.buildingid AS datebuildingkey,
    sbo.date,
    sbo.buildingid,
    sbo.budgetresidentdaysperday AS ResidentDaysBudget,
    sbo.budgetavailableperday AS InServiceDaysBudget,
    COALESCE(sbo.buildingname, 'missing ') || '-' || CAST(sbo.buildingid AS VARCHAR) AS BuildingDescription,
    ca.campusname AS CampusName,
    sbo.entitycode,
    sbo.levelofcareabbreviation AS LevelOfCare,
    sbo.facilitycode,
    sbo.buildingname
FROM
    dim.starfactBudgetOccupancyPerDay AS sbo
    INNER JOIN dim.campusactivedates AS ca ON sbo.entityid = ca.entityid
    AND sbo.date BETWEEN ca.startdate
    AND ca.enddate
WHERE
    EXTRACT(
        YEAR
        FROM
            sbo.date
    ) >= 2024
    AND sbo.date <= CAST(GETDATE() AS date) WITH NO SCHEMA BINDING;
