CREATE OR REPLACE PROCEDURE dim.master()
 LANGUAGE plpgsql
AS $$
/*

alter table dim.mastertimelog
add column pccbk_longname varchar(50);


call dim.master()

select * from dim.mastertimelog order by 1 desc

*/


DECLARE  
    c DATE;
    a TIMESTAMP;  -- Start time UTC
    b TIMESTAMP;  -- End time UTC
    a_est TIMESTAMP; -- Start time EST
    b_est TIMESTAMP; -- End time EST
    v_pccbk_file_datetime TIMESTAMP;
    v_pccbk_shortname varchar(50);    

BEGIN
    -- Capture start time
    a := CURRENT_TIMESTAMP;
    c := CURRENT_DATE;

    -- Convert to EST/EDT (handles Daylight Saving automatically)
    a_est := convert_timezone('UTC', 'US/Eastern', a);

    -- pcc backup TIMESTAMP
    SELECT 
        "file_datetime"
        , shortname
    into v_pccbk_file_datetime, v_pccbk_shortname 
    from source_pcc.logbackupfiles_asbury
    order by backupfiles desc limit 1;


    call dim.load_datetable();
    call dim.load_entity();
    call dim.load_facility();
    call dim.load_campus();
    call dim.load_campusactivedates();
    call dim.load_levelofcare();
    call dim.load_building();
    call dim.load_unit();
    call dim.load_room();
    call dim.load_bed();
    call dim.load_resident();
    call dim.load_admissionaction();
    call dim.load_admissionstatus();
    call dim.load_admission();
    call dim.load_payer() ;
    call dim.load_payerplan();
    call dim.load_budgetplandays() ;
    call dim.load_bedoccupied();
    call dim.load_bedavailable();
    call dim.update_bedavailable();
    call dim.load_bedoccupancy();
    call dim.load_census();
    Call dim.load_bedprice() ;

    ----NHPPD----------------
    --call dim.load_lineofbusiness() ; -- static file no run
    call dim.load_datetablefuture();
    call dim.load_department() ; 
    call dim.load_pbjjobcode(); 
    --call dim.load_hrjobcodefixedvariable() ;
    call dim.load_job(); 
    call dim.load_payrollbudget(); 
    call dim.load_payperiod(); 
    call dim.load_associate();
    call dim.load_payrollsecurity();
    call dim.load_paytype();
    CALL dim.load_associatepaydetail();   
    call dim.load_nhppdbudget();

    --------------OR--------------
    call dim.load_operatingratio();
    call dim.load_entityoperatingratiotarget();
    call dim.load_entityoperatingratiomontlytarget();
    call dim.load_entityoperatingratio();
    call dim.load_entityoperatingratiotarget();
    call dim.load_entitygroup2();
    call dim.load_entitygroupmember2();


    -- -----------Reporting----------
    call dim.master_reporting();
    call dim.load_CMI_PMPD_PA();

    -- Capture end time
    b := CURRENT_TIMESTAMP;
    b_est := convert_timezone('UTC', 'US/Eastern', b);

    

    -- Insert into logging table with UTC + EST
    INSERT INTO dim.mastertimelog (
        date,
        starttime_utc,
        endtime_utc,
        starttime_est,
        endtime_est,
        duration_minutes,
        pccbk_file_datetime,
        pccbk_shortname,
        pccbk_longname
    )
    SELECT
        c,
        a,
        b,
        a_est,
        b_est,
        EXTRACT(EPOCH FROM b - a) / 60.0,  -- Duration in minutes 
        v_pccbk_file_datetime, 
        v_pccbk_shortname,  
        TO_CHAR(TO_TIMESTAMP(v_pccbk_shortname, 'YYYYMMDDHH24'), 'Mon DD, YYYY – HH12 AM') 
    ;

END;
$$
