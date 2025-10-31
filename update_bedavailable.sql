CREATE OR REPLACE PROCEDURE dim.update_bedavailable()
 LANGUAGE plpgsql
AS $$
/* 
select 
    sum(case when ba.available = true then 1 else 0 end)
from dim.bedavailable_Springhill ba
    inner join dim.vwBed2 v on v.bedId = ba.bedId 
where ba.available = true
and ba.date = '2024-08-01' 
and v.campusabbreviation = 'AMV'
and v.levelofcareabbreviation = 'SNF'
*/

BEGIN


    drop table if exists bs ;

    create temp table bs as
    select 
        title							    CampusName
        , levelofcare					    LevelOfCareAbbreviation
        , Unit							    UnitName
        , roomName
        , bedName
        , cast(inServiceStartDate as date)	StartDate
        , case 
            when inServiceEndDate is null then '9999-12-01'
            when ltrim(rtrim(inServiceEndDate)) = '' then '9999-12-31'
            else cast(inServiceEndDate as date)	
            end EndDate
    from source_sharepoint.bedservicedates
    where ltrim(rtrim(title)) != ''
    ;


    drop table if exists mbs ;

    create temp table mbs as
    select
        v.bedID
        , min(bs.startDate) startDate 
        , cast(getDate() as date) endDate 
    from bs
        left outer join dim.vwBed v on v.CampusName = bs.campusName
            and v.LevelOfCareAbbreviation = bs.LevelOfCareAbbreviation
            and v.RoomName = bs.RoomName
    group by 
        v.BedID
    ;


    drop table if exists allBeds ;

    create temp table allBeds as
    select 
        dt.date
        , mbs.bedID
        , 0	Available 
    from mbs
        inner join dim.dateTable dt on dt.date >= mbs.StartDate
            and dt.date <= mbs.EndDate
    where mbs.BedID is not null
    ;


    drop table if exists available ;

    create temp table available as
    select 
        dt.date
        , v.BedID
        , 1 Available
    From bs
        inner join dim.vwBed v on v.CampusName = bs.campusName
            and v.LevelOfCareAbbreviation = bs.LevelOfCareAbbreviation
            and v.RoomName = bs.RoomName
            and v.BedName = bs.BedName
        inner join dim.dateTable dt on dt.date >= bs.StartDate
            and dt.date <= bs.EndDate
    where bs.StartDate != bs.endDate
    ;


    update allBeds  
        set Available = a.available 
    from allBeds ab
        inner join available a on ab.bedID = a.bedID 
            and a.date = ab.date
    ;


    update dim.bedavailable
        set available =    
            case 
                when ab.Available = 1 then true
                else false
                end  
    from dim.bedavailable ba
        inner join allBeds ab on ab.BedID = ba.BedID
            and ab.Date = ba.date
    ;


    update dim.bedAvailable
    set available = 0 
    where available = 1
    and date >= '2024-12-06'
    and bedId in (
        select bedid
        from dim.vwbed v 
        where v.campusAbbreviation = 'RW'
        and v.levelofCareAbbreviation = 'SNF'
    )
    ;


END;
$$
