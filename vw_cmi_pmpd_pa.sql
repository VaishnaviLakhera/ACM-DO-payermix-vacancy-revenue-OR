CREATE
OR REPLACE VIEW "qlik"."vw_cmi_pmpd_pa" AS 
/*
 select * from qlik.vw_CMI_PMPD_PA ;
 
 */
select
    dt.date,
    c.admissionName,
    c.residentID,
    c.dischargeDate,
    c.assessdate:: date as assessdate,
    c.nextassessdate,
    c.assessid,
    c.assessemntstatus,
    c.NursingCmi,
    c.NursingGroup,
    case
    when c.NursingGroup = 'CDE1' then c.NursingCmi end CDE1,
    case
    when c.NursingGroup = 'CBC1' then c.NursingCmi end CBC1,
    case
    when c.NursingGroup = 'LDE1' then c.NursingCmi end LDE1,
    case
    when c.NursingGroup = 'PDE2' then c.NursingCmi end PDE2,
    case
    when c.NursingGroup = 'PDE1' then c.NursingCmi end PDE1,
    case
    when c.NursingGroup = 'BAB1' then c.NursingCmi end BAB1,
    case
    when c.NursingGroup = 'PBC1' then c.NursingCmi end PBC1,
    v.campusname,
    c.NursingFunctionScore,
    v.campusAbbreviation,
    v.levelofcareAbbreviation,
    'PA' State,
    null CMIGoal --,c.bedid
    --,c.admissionID
    --,c.payerPlanID
    --,c.assesstypecode
    --,c.A0310B
    --,c.Hipps
    --,c.StateHipps
from
    dim.CMI_PMPD_PA c
    inner join dim.vwBed v on v.bedid = c.bedid
    inner join dim.datetable dt on dt.date >= c.assessdate:: date
    and dt.date < isnull(c.nextassessdate:: date, CURRENT_DATE) WITH NO SCHEMA BINDING;
