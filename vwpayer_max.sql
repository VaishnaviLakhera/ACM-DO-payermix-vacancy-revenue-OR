CREATE
OR REPLACE VIEW "dim"."vwpayer_max" AS WITH ranked_data AS (
    SELECT
        client_payer_info_id,
        census_id AS censusid,
        c.fac_id,
        c.client_id,
        c.payer_id,
        ci.primary_payer_id AS census_payerid,
        c.effective_date,
        -- Cast to DATE
        planname,
        payername,
        c.revision_date,
        -- Cast to DATE
        ROW_NUMBER() OVER (
            PARTITION BY c.client_id
            ORDER BY
                CAST(c.revision_date AS TIMESTAMP) DESC -- Cast to DATE
        ) AS rn
    FROM
        source_pcc.ar_client_payer_info c
        INNER JOIN dim.payerPlan pp ON pp.payerid = c.payer_id
        left JOIN dim.payer p ON p.payerid = pp.payerid
        INNER JOIN source_pcc.census_item ci ON c.fac_id = ci.fac_id
        AND c.client_id = ci.client_id --AND CAST(c.effective_date AS DATE) = CAST(ci.effective_date AS DATE) -- Cast for comparison
    WHERE
        --    c.client_id IN (404069) --   139734 , 113316 -- census_id
        --     AND
        c.DELETED != 'Y'
        AND CAST(ci.effective_date AS DATE) is not null
)
SELECT
    client_payer_info_id,
    censusid,
    fac_id,
    client_id,
    payer_id,
    census_payerid,
    COALESCE(payer_id, census_payerid) AS primary_payer_id,
    effective_date,
    planname,
    payername,
    revision_date
FROM
    ranked_data
WHERE
    rn = 1 WITH NO SCHEMA BINDING;
