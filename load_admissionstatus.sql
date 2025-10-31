CREATE OR REPLACE PROCEDURE dim.load_admissionstatus()
 LANGUAGE plpgsql
AS $$
BEGIN

    /*
    call dim.load_admissionstatus()
    select * from source_pcc.census_codes
    select * from dim.admissionstatus
    */

    TRUNCATE TABLE dim.admissionstatus;

    insert into dim.admissionstatus (
        statuscode,
        statusdescription,
        sourceid,
        sourcecolumn,
        sourcetable,    
        sourcesystem,
        tenant
    )
    select
        short_desc      statuscode
        ,long_desc      statusdescription
        ,item_id        sourceid
        ,'item_id'      sourcecolumn
        ,'census_codes' sourcetable,    
        'PCC'           sourcesystem,
        'ACM'           tenant
    from source_pcc.census_codes ac
    where ac.table_code = 'SC'
	and ac.deleted = 'N'
;



END;
$$
