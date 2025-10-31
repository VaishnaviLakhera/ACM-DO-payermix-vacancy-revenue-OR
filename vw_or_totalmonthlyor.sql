CREATE
OR REPLACE VIEW "qlik"."vw_or_totalmonthlyor" AS
SELECT
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
   ero1.operatingexpense - COALESCE(ero2.operatingexpense, 0:: numeric:: numeric(18, 0)) AS operatingexpense,
   ero1.operatingrevenue - COALESCE(ero2.operatingrevenue, 0:: numeric:: numeric(18, 0)) AS operatingrevenue,
   ero1.operatingexpense AS ytdoperatingexpense,
   ero1.operatingrevenue AS ytdoperatingrevenue,
   COALESCE(ero1.variance, 0:: numeric:: numeric(18, 0)) AS variance,
   COALESCE(
      ert.operatingratiotarget,
      0:: numeric:: numeric(18, 0)
   ) AS operatingratiotarget
FROM
   dim.operatingratio ero1
   LEFT JOIN dim.operatingratio ero2 ON ero1."year" = ero2."year"
   AND (ero1."month" - 1) = ero2."month"
   LEFT JOIN dim.operatingratiotarget ert ON ert."year" = ero1."year"
WHERE
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
   ) >= '2017-01-01 00:00:00':: timestamp without time zone;
