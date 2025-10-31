CREATE
OR REPLACE VIEW qlik.vw_vrevenue_FacilityBudgetOccpancy AS
SELECT
  TO_CHAR(bo.Date, 'MM/DD/YYYY') || CAST(bo.BuildingID AS VARCHAR) AS DateBuildingKey,
  BudgetResidentDaysPerDay AS ResidentDaysBudget,
  BudgetAvailablePerDay AS InServiceDaysBudget
FROM
  dim.starfactbudgetoccupancyperday bo
WHERE
  EXTRACT(
    YEAR
    FROM
      bo.Date
  ) >= 2024
  AND bo.Date < CURRENT_DATE WITH NO SCHEMA BINDING;
