CREATE
OR REPLACE VIEW "qlik"."vw_pm_payerplan" AS
SELECT
   DISTINCT pp.payerplanid,
   p.payerid,
   pp.planname,
   p.payername
FROM
   dim.payerplan pp
   LEFT JOIN dim.payer p ON p.payerid = pp.payerid
UNION
SELECT
   0 AS payerplanid,
   0 AS payerid,
   '*Unknown' AS planname,
   '*Unknown' AS payername;
