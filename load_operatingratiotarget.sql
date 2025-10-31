CREATE OR REPLACE PROCEDURE dim.load_operatingratiotarget()
 LANGUAGE plpgsql
AS $$
BEGIN
    -- Truncate the target table before loading data
    TRUNCATE TABLE dim.OperatingRatiotarget;

    -- Insert the transformed data
    INSERT INTO dim.OperatingRatiotarget (Year, operatingratiotarget)
    SELECT DISTINCT
        title AS year,
        "or target" AS operatingratiotarget
    FROM"source_sharepoint"."operating_ratio_total_target";


END;
$$
