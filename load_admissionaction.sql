CREATE OR REPLACE PROCEDURE dim.load_admissionaction()
 LANGUAGE plpgsql
AS $$
BEGIN

    /*
    call dim.load_admissionaction()
    select * from source_pcc.census_codes
    select * from dim.admissionaction
    */

    TRUNCATE TABLE dim.admissionaction;

    insert into dim.admissionaction (
        actioncode,
        actiondescription,
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
    where ac.table_code = 'ACT'
	and ac.deleted = 'N'
;



END;
$$
