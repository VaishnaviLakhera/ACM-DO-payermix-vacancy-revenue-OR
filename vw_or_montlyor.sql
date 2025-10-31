CREATE
OR REPLACE VIEW "qlik"."vw_or_montlyor" AS
SELECT
   DISTINCT c.entityid,
   ero1.entitycode,
   date_add(
      'day':: character varying:: text,
      - 1:: bigint,
      date_add(
         'month':: character varying:: text,
         1:: bigint,
         to_date(
            (
               (
                  ero1."year":: character varying:: text || '-':: character varying:: text
               ) || lpad(
                  ero1."month":: character varying:: text,
                  2,
                  '0':: character varying:: text
               )
            ) || '-01':: character varying:: text,
            'YYYY-MM-DD':: character varying:: text
         ):: timestamp without time zone
      )
   ):: date AS monthenddate,
   ero1.ytdoperatingrevenue - COALESCE(
      ero2.ytdoperatingrevenue,
      0:: numeric:: numeric(18, 0)
   ) AS operatingrevenue,
   ero1.ytdoperatingexpense - COALESCE(
      ero2.ytdoperatingexpense,
      0:: numeric:: numeric(18, 0)
   ) AS operatingexpense,
   ero1.ytdoperatingrevenue,
   ero1.ytdoperatingexpense,
   em.targetoperatingrevenue AS budgetmonthlyoperatingrevenue,
   em.targetoperatingexpenses AS budgetmonthlyoperatingexpense
FROM
   dim.entityoperatingratio ero1
   LEFT JOIN dim.entityoperatingratio ero2 ON ero1."year" = ero2."year"
   AND ero1.entitycode:: text = ero2.entitycode:: text
   AND (ero1."month" - 1) = ero2."month"
   LEFT JOIN dim.entityoperatingratiomonthlytarget em ON em.entitycode:: text = ero1.entitycode:: text
   AND em."month":: text = ero1."month":: character varying:: text
   AND em."year":: text = ero1."year":: character varying:: text
   LEFT JOIN dim.entity c ON c.entitycode:: text = ero1.entitycode:: text
WHERE
   ero1.entitycode IS NOT NULL
   AND date_add(
      'day':: character varying:: text,
      - 1:: bigint,
      date_add(
         'month':: character varying:: text,
         1:: bigint,
         to_date(
            (
               (
                  ero1."year":: character varying:: text || '-':: character varying:: text
               ) || lpad(
                  ero1."month":: character varying:: text,
                  2,
                  '0':: character varying:: text
               )
            ) || '-01':: character varying:: text,
            'YYYY-MM-DD':: character varying:: text
         ):: timestamp without time zone
      )
   ):: date < 'now':: character varying:: date;
