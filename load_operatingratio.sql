CREATE OR REPLACE PROCEDURE dim.load_operatingratio()
 LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dim.operatingRatio;

    INSERT INTO dim.operatingRatio (
        year,
        month,
        operatingExpense,
        operatingRevenue,
        variance
    )
    SELECT DISTINCT
        year,
        month,
        "operating expense",
        "operating revenue",
        variance
    FROM source_sharepoint.operating_ratio;

END;
$$
