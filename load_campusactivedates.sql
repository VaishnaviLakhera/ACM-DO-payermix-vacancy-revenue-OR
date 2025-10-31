CREATE OR REPLACE PROCEDURE dim.load_campusactivedates()
 LANGUAGE plpgsql
AS $$
BEGIN

TRUNCATE TABLE dim.campusactivedates;


INSERT INTO dim.campusactivedates(
	startdate,
    enddate,
    entityid,
	campusid,
    campusname,
    cmsstartdate,
    cmsenddate,
    sourcesystem,
    tenant
)
SELECT
	startdate::date,
	enddate::date,
    entityid,
	campusid,
    campusname,
    startdate::date,
    enddate::date,
    sourcesystem,
    tenant
FROM (
	SELECT
		CASE
			WHEN lower(campusname)=lower('Asbury Grace Park') THEN '2024-11-01'
			WHEN lower(campusname)=lower('Asbury Ivy Gables') THEN '2024-11-01'
			WHEN lower(campusname)=lower('Asbury Methodist Village') THEN '2024-08-01'
			WHEN lower(campusname)=lower('Asbury Solomons') THEN '2024-02-01'
			WHEN lower(campusname)=lower('Bethany Village') THEN '2024-04-01'
			WHEN lower(campusname)=lower('Chandler Estate') THEN '2024-08-01'
			WHEN lower(campusname)=lower('Normandie Ridge') THEN '2024-04-01'
			WHEN lower(campusname)=lower('Riverwoods') THEN '2024-06-01'
			WHEN lower(campusname)=lower('Springhill') THEN '2024-06-01'
			ELSE '9999-12-31'
		END AS startdate, 
		CASE
			WHEN lower(campusname)=lower('Asbury Grace Park') THEN '9999-12-31'
			WHEN lower(campusname)=lower('Asbury Ivy Gables') THEN '9999-12-31'
			WHEN lower(campusname)=lower('Asbury Methodist Village') THEN '9999-12-31'
			WHEN lower(campusname)=lower('Asbury Solomons') THEN '9999-12-31'
			WHEN lower(campusname)=lower('Bethany Village') THEN '9999-12-31'
			WHEN lower(campusname)=lower('Chandler Estate') THEN '9999-12-31'
			WHEN lower(campusname)=lower('Normandie Ridge') THEN '9999-12-31'
			WHEN lower(campusname)=lower('Riverwoods') THEN '9999-12-31'
			WHEN lower(campusname)=lower('Springhill') THEN '9999-12-31'
			ELSE '9999-12-31'
		END AS enddate,
		entityid,
		campusid,
		campusname,
		'PCC' as sourcesystem,
		'ACM' as tenant
	FROM dim.campus
);



END;
$$
