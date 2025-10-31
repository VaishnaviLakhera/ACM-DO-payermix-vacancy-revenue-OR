CREATE
OR REPLACE VIEW "qlik"."vw_or_facilitylevelofcare" AS
SELECT
   DISTINCT e.entityname,
   e.entitycode,
   f.entityid,
   f.facilitycode,
   f.facilityid,
   COALESCE(
      loc.levelofcareabbreviation,
      aloc.levelofcareabbreviation
   ) AS levelofcareabbreviation
FROM
   dim.facility f
   JOIN dim.entity e ON e.entityid = f.entityid
   LEFT JOIN dim.vwbuilding bu ON bu.facilityid = f.facilityid
   LEFT JOIN dim.levelofcare loc ON loc.levelofcareid = bu.levelofcareid
   LEFT JOIN (
      SELECT
         aloc_data.entitycode,
         aloc_data.facilityname,
         aloc_data.levelofcareabbreviation
      FROM
         (
            (
               (
                  (
                     (
                        (
                           (
                              (
                                 SELECT
                                    '840':: character varying AS entitycode,
                                    'Apartment A':: character varying AS facilityname,
                                    'IL':: character varying AS levelofcareabbreviation
                                 UNION ALL
                                 SELECT
                                    '840':: character varying AS "varchar",
                                    'Assisted Living A':: character varying AS "varchar",
                                    'AL':: character varying AS "varchar"
                              )
                              UNION ALL
                              SELECT
                                 '840':: character varying AS "varchar",
                                 'Assisted Living B':: character varying AS "varchar",
                                 'AL':: character varying AS "varchar"
                           )
                           UNION ALL
                           SELECT
                              '840':: character varying AS "varchar",
                              'Skilled Nursing Facility':: character varying AS "varchar",
                              'SNF':: character varying AS "varchar"
                        )
                        UNION ALL
                        SELECT
                           '840':: character varying AS "varchar",
                           'Villas/Cottages':: character varying AS "varchar",
                           'IL':: character varying AS "varchar"
                     )
                     UNION ALL
                     SELECT
                        '835':: character varying AS "varchar",
                        'Apartment A':: character varying AS "varchar",
                        'IL':: character varying AS "varchar"
                  )
                  UNION ALL
                  SELECT
                     '835':: character varying AS "varchar",
                     'Assisted Living A':: character varying AS "varchar",
                     'AL':: character varying AS "varchar"
               )
               UNION ALL
               SELECT
                  '835':: character varying AS "varchar",
                  'Skilled Nursing Facility':: character varying AS "varchar",
                  'SNF':: character varying AS "varchar"
            )
            UNION ALL
            SELECT
               '835':: character varying AS "varchar",
               'Villas/Cottages':: character varying AS "varchar",
               'IL':: character varying AS "varchar"
         ) aloc_data
   ) aloc ON aloc.facilityname:: text = f.facilityname:: text
   AND aloc.entitycode:: text = e.entitycode:: text
WHERE
   loc.levelofcareabbreviation IS NOT NULL
   OR aloc.levelofcareabbreviation IS NOT NULL;
