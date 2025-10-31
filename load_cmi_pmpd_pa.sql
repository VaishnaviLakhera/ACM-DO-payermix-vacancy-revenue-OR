CREATE OR REPLACE PROCEDURE dim.load_cmi_pmpd_pa()
 LANGUAGE plpgsql
AS $$
BEGIN

/*
-- drop PROCEDURE dim.load_CMI_PMPD_PA;

call dim.load_CMI_PMPD_PA();

select * 
from dim.CMI_PMPD_PA
where assessdate >= '2025-08-02'
and assessdate <= '2025-11-04'

-- drop table dim.CMI_PMPD_PA
*/
If exists (Select 1 from source_pcc.as_assessment limit 1)
Then
    truncate table dim.CMI_PMPD_PA;

    insert into dim.CMI_PMPD_PA ( 
        admissionName
        ,residentID 
        ,dischargeDate
        ,assessdate  
        ,nextassessdate
        ,bedid
        ,admissionID
        ,payerPlanID
        ,assessid                   
        ,assesstypecode            
        ,assessemntstatus 
        ,A0310B
        ,Hipps                     
        ,NursingCmi               
        ,NursingGroup             
        ,NursingFunctionScore    
        ,StateHipps   
        ,sourceid
        ,sourceTable
    )
    select
        x.admissionName
        ,x.residentID 
        ,anew.dischargeDate
        ,x.assess_date  as assessdate
        ,isnull(anew.dischargeDate::date,  x.next_assess_date::date) as nextassessdate
        ,x.bedid
        ,x.admissionID
        ,x.payerPlanID
        ,x.assess_id            as assessid                   
        ,x.assess_type_code     as assesstypecode            
        ,x.assessemntstatus 
        ,x.A0310B
        ,x.Hipps                     
        ,x.NursingCmi               
        ,x.NursingGroup             
        ,x.NursingFunctionScore    
        ,x.StateHipps   
        ,x.sourceid
        ,x.sourceTable
  -- into dim.CMI_PMPD_PA
    from (
    SELECT
            bo.bedid
            , bo.admissionID
            , ad.residentID 
            , ad.admissionName
        -- , aa.statuscode
            , bo.payerPlanID
            ,a.assess_id                   
            ,a.assess_type_code            
            ,a.assess_date                 
            , LEAD(a.assess_date) OVER (
                PARTITION BY ad.residentid 
                ORDER BY a.assess_date
            ) AS next_assess_date        
            ,a.status                    as assessemntstatus 
            ,r.item_value                as  A0310B
            ,hipps                       As  Hipps                     
            ,nursing_cmi::float          As  NursingCmi               
            ,nursing_group               As  NursingGroup             
            ,nursing_function_score      As  NursingFunctionScore    
            ,state_hipps                 As  StateHipps   
            ,a.assess_id                  as sourceid
            ,'as_assessment'            as sourceTable      
            
        -- select *
        --into #a 
        FROM           source_pcc.as_assessment      a 
            inner join source_pcc.clients            c on c.client_id = a.client_id
            inner join source_pcc.mpi                m on c.mpi_id = m.mpi_id
            inner join source_pcc.as_response        r on a.assess_id = r.assess_id 
                and r.question_key = 'A0310B'
            inner  join source_pcc.as_assessment_pdpm p on p.assess_id = a.assess_id
            inner join source_pcc.facility f on f.fac_id =a.fac_id
            inner join dim.admission ad on ad.sourceid = a.client_id 
            inner join dim.bedoccupancy bo on bo.admissionid = ad.admissionid
                and bo.date = a.assess_date::date 
            inner join source_pcc.as_response sr on sr.assess_id = a.assess_id
                and sr.question_key = 'S9080A'
                and sr.item_value = 1

            
        where a.std_assess_id = 11
        and p.state_hipps <> '-'
        and a.assess_date >= '2025-01-01'
        -- and a.assess_date >= '2025-05-03'
        -- and a.assess_date <= '2025-08-02'
        --and f.name = 'Bethany Village Healthcare Center'
        --and statuscode !='A'
        --and ad.residentid = 3079818
    ) x 
        left outer join (
            select
                a.admissionName
                , a.effectiveDate::date  as dischargeDate
            from dim.admission a
                inner join dim.admissionstatus aa on aa.admissionstatusid= a.admissionstatusid
            where aa.statuscode = 'D'
        ) as  anew on anew.admissionName = x.admissionName 
            and anew.dischargedate >= x.assess_date 
            and anew.dischargedate <= isnull(x.next_assess_date::date, CURRENT_DATE::date)

;
ELSE
        INSERT INTO dim.error_load (storedprocedure_name, error_datetime, error_message)
        VALUES ('dim.load_CMI_PMPD_PA', GETDATE(), 'Source tables missing data');

        RAISE NOTICE 'No data found: dim.load_CMI_PMPD_PA()'; 
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO dim.error_load (storedprocedure_name, error_datetime, error_message)
        VALUES ('dim.load_CMI_PMPD_PA', GETDATE(), SQLERRM);

        RAISE NOTICE 'Error with stored procedure: dim.load_CMI_PMPD_PA() %', SQLERRM;


END;
$$
