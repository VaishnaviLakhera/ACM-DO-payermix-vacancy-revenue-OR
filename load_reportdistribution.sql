CREATE OR REPLACE PROCEDURE dim.load_reportdistribution()
 LANGUAGE plpgsql
AS $$
BEGIN
/*
-- alter table dim.reportdistribution
-- drop column sourceid;

-- alter table dim.reportdistribution
-- add sourceid varchar(255);

call dim.load_reportdistribution();
select * from dim.reportdistribution ;
*/

 IF EXISTS (SELECT 1 FROM source_sharepoint.qlikreportdistribution  LIMIT 1)
     
    THEN
        -- Truncate the target table before inserting new data
        TRUNCATE TABLE  dim.reportdistribution;



        insert into dim.reportdistribution (      
            reportname ,
            username, 
            campusabbr,   
            entityabbr, 
            entitycode , 
            groupname ,
            sourceid ,
            sourcecolumn ,
            sourcetable
        ) 
        select 
            title reportname ,
            username,
            campusabbr,
            entityabbr,
            entitycode ,
            groupname,
            title + '|'  + username + '|' + campusabbr as sourceid ,
            'title|username|campusabbr'  as sourcecolumn ,
            ' source_sharepoint.qlikreportdistribution' as sourcetable
        FROM source_sharepoint.qlikreportdistribution 
        ;

            

    ELSE
        -- Log error if source tables are missing data
        INSERT INTO dim.error_load (storedprocedure_name, error_datetime, error_message)
        VALUES ('dim.load_reportdistribution', GETDATE(), 'Source tables missing data');

        RAISE NOTICE 'No data found: dim.load_reportdistribution()';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- Catch-all for unexpected errors
        INSERT INTO dim.error_load (storedprocedure_name, error_datetime, error_message)
        VALUES ('dim.load_reportdistribution', GETDATE(), SQLERRM);

        RAISE NOTICE 'Error with stored procedure: dim.load_reportdistribution %', SQLERRM;
END;
$$
