CREATE OR REPLACE PROCEDURE dim.load_datetable()
 LANGUAGE plpgsql
AS $$

DECLARE
 
reload BOOLEAN;
LAST_UPDATED Date;
LAST_UPDATED_BI bigint;
R_COUNT INT;

FIRST_DATE date;
LAST_DATE date;
START_DATE date;
END_DATE date;
LOW_DATE date;
start_no int;
end_no int;
exist_rows int;
cr varchar(2);

rows_needed	int;
rows_needed_root int;
iso_start_year int;
iso_end_year int;
DEfault_Date date;


BEGIN

reload := TRUE; --


IF reload THEN
    TRUNCATE TABLE "dim".datetable;
ELSE
    RAISE INFO 'NO Reload';
END IF;


DROP TABLE IF EXISTS  ISO_WEEK;
DROP TABLE IF EXISTS  num1;
DROP TABLE IF EXISTS  num2;
DROP TABLE IF EXISTS  num3;
DROP TABLE IF EXISTS  aa;

create temp table num1 (NUMBER int not null primary key);
create temp table num2  (NUMBER int not null primary key);
create temp table num3  (NUMBER int not null primary key );
create temp table aa(dateid int , date date);

DEfault_Date=cast('1900-01-01' as date);



FIRST_DATE = GETDATE();
LAST_DATE = GETDATE();

SELECT COUNT(*) INTO exist_rows FROM dim.datetable limit 1;

IF exist_rows = 0 THEN -- if date table is empty set default date
    FIRST_DATE = '1875-01-01';
ELSE -- if date table is not empty slect the last inserted date as start date
    SELECT date INTO FIRST_DATE FROM dim.datetable order by date desc limit 1;
END IF;


select  dateadd(day,datediff(day,DEfault_Date,FIRST_DATE),DEfault_Date) into START_DATE;
select dateadd(day,datediff(day,DEfault_Date,LAST_DATE),DEfault_Date) into END_DATE ;
select convert(datetime,'17530101') into LOW_DATE;

select	 datediff(day,LOW_DATE,START_DATE) into start_no;
select 	 datediff(day,LOW_DATE,END_DATE) into end_no;



create temp table ISO_WEEK (
    ISO_WEEK_YEAR int not null primary key ,
    ISO_WEEK_YEAR_START_DATE date not null,
    ISO_WEEK_YEAR_END_DATE	Date not null
);



select  end_no - start_no + 1 into rows_needed;
select  
		case
		when rows_needed < 10
		then 10
		else rows_needed
		end into rows_needed ;

select convert(int,ceiling(sqrt(rows_needed))) into rows_needed_root;


insert into num1 (NUMBER) values (0), (1), (2),(3), (4), (5),(6), (7), (8),(9), (10), (11),(12), (13), (14),(15);


insert into num2 (NUMBER)
select
	 a.NUMBER+(16*b.NUMBER)+(256*c.NUMBER) NUMBER
from
	num1 a cross join num1 b cross join num1 c
where
	a.NUMBER+(16*b.NUMBER)+(256*c.NUMBER) <
	rows_needed_root
order by
	1;




insert into num3 (NUMBER)
select
	 a.NUMBER+(rows_needed_root*b.NUMBER) NUMBER
from
	num2 a
	cross join
	num2 b
where
	a.NUMBER+(rows_needed_root*b.NUMBER) < rows_needed
order by
	1;


select	datepart(year,dateadd(year,-1,start_date)) into iso_start_year;
select	 datepart(year,dateadd(year,1,end_date)) into iso_end_year;



insert into ISO_WEEK
	(
	ISO_WEEK_YEAR,
	ISO_WEEK_YEAR_START_DATE,
	ISO_WEEK_YEAR_END_DATE
	)
select
	a.NUMBER,
		dateadd(day,(datediff(day,LOW_DATE,
		dateadd(day,3,dateadd(year,a.NUMBER-1900,DEfault_Date))
		)/7)*7,LOW_DATE),
		dateadd(day,-1,dateadd(day,(datediff(day,LOW_DATE,
		dateadd(day,3,dateadd(year,a.NUMBER+1-1900,DEfault_Date))
		)/7)*7,LOW_DATE))
from
	(
	select
		NUMBER+iso_start_year NUMBER 
	from
		num3
	where
		NUMBER+iso_start_year <= iso_end_year
	) a
order by
	a.NUMBER;


insert into aa
select 
		 NUMBER+start_no DateId,
		dateadd(day,NUMBER+start_no,LOW_DATE) DATE 
		from num3
		where NUMBER+start_no <= end_no AND NOT EXISTS (
			SELECT 1
    		FROM dim.datetable
    		WHERE date = dateadd(day,NUMBER+start_no,LOW_DATE)
		)
	    order by NUMBER;


insert into  dim.datetable
select
	aa.DateId ,
	aa.DATE ,
	dateadd(day,1,aa.DATE),
		datepart(year,aa.DATE) ,
	10*datepart(year,aa.DATE)+datepart(quarter,aa.DATE) ,
	100*datepart(year,aa.DATE)+datepart(month,aa.DATE),
	1000*datepart(year,aa.DATE)+ datediff(day,dateadd(year,datediff(year,DEfault_Date,aa.DATE),DEfault_Date),aa.DATE)+1,
	datepart(quarter,aa.DATE),
	datepart(month,aa.DATE),
	datediff(day,dateadd(year,datediff(year,DEfault_Date,aa.DATE),DEfault_Date),aa.DATE)+1,
	datepart(day,aa.DATE) ,
	(datediff(day,'17530107',aa.DATE)%7)+1,
	datepart(year,aa.DATE),
	cast(datepart(year,aa.DATE) as char(255)) || cast(' Q' as char(255)) || cast(datepart(quarter,aa.DATE) as char(255)),
	cast(datepart(year,aa.DATE) as char(255))|| cast(' 'as char(255))|| cast(left(datepart(month,aa.DATE),3)as char(255)) ,
	cast(datepart(year,aa.DATE) as char(255)) ||cast(' 'as char(255)) ||cast(datepart(month,aa.DATE)as char(255)),
	case 
			when datepart(week, Date) > 52 then CONVERT(varchar(4), datepart(year, Date) +1) || '01'
			else CONVERT(varchar(4), datepart(year, Date)) || right('00' || convert(varchar(2), datepart(week, Date)), 2)
		end,
	'Q' || cast(datepart(quarter,aa.DATE) as char(255)),
	left(datepart(month,aa.DATE),3) ,
	datepart(month,aa.DATE) ,
	left(datepart(weekday,aa.DATE),3) ,
	datepart(dow,aa.DATE),
	dateadd(year,datediff(year,DEfault_Date,aa.DATE),DEfault_Date) ,
	dateadd(day,-1,dateadd(year,datediff(year,DEfault_Date,aa.DATE)+1,DEfault_Date)) ,
	dateadd(quarter,datediff(quarter,DEfault_Date,aa.DATE),DEfault_Date) ,
	dateadd(day,-1,dateadd(quarter,datediff(quarter,DEfault_Date,aa.DATE)+1,DEfault_Date)) ,
	dateadd(month,datediff(month,DEfault_Date,aa.DATE),DEfault_Date) ,
	dateadd(day,-1,dateadd(month,datediff(month,DEfault_Date,aa.DATE)+1,DEfault_Date)),
	datediff(quarter,LOW_DATE,aa.DATE),
	datediff(month,LOW_DATE,aa.DATE),
 	datepart(year,aa.DATE) ,
	(datepart(year,aa.DATE))+ (cast((datepart(month,aa.DATE)/100.00) as decimal (2,2))),
	(datepart(year,aa.DATE)+ cast((datediff(day,dateadd(year,datediff(year,DEfault_Date,aa.DATE),DEfault_Date),aa.DATE)+1)/1000.00 as numeric (3,3))),
 'ml',
  case 
 when datepart(quarter,aa.DATE) <= 2 then 1
 else 2
 end,
datepart(quarter,aa.DATE),
	datepart(month,aa.DATE) ,
	datediff(day,dateadd(year,datediff(year,DEfault_Date,aa.DATE),DEfault_Date),aa.DATE)+1 ,
	datepart(day,aa.DATE) ,
	 0, --cast(datepart(month,aa.DATE) as char(2)) + '.0' ,
	dateadd(year,datediff(year,DEfault_Date,aa.DATE),DEfault_Date) ,
	dateadd(day,-1,dateadd(year,datediff(year,DEfault_Date,aa.DATE)+1,DEfault_Date)) ,
	dateadd(month,datediff(month,DEfault_Date,aa.DATE),DEfault_Date) ,
	dateadd(day,-1,dateadd(month,datediff(month,DEfault_Date,aa.DATE)+1,DEfault_Date)),
	replace(convert(char(10),aa.DATE),'/','-'),
	(100*b.ISO_WEEK_YEAR)+	(datediff(day,b.ISO_WEEK_YEAR_START_DATE,aa.DATE)/7)+1 ,
	(datediff(day,b.ISO_WEEK_YEAR_START_DATE,aa.DATE)/7)+1 ,
	(datediff(day,LOW_DATE,aa.DATE)%7)+1  ,
	convert(varchar(4),b.ISO_WEEK_YEAR)+'-W'+ right('00'+convert(varchar(2),(datediff(day,b.ISO_WEEK_YEAR_START_DATE,aa.DATE)/7)+1),2) ,
		convert(varchar(4),b.ISO_WEEK_YEAR)+'-W'+
		right('00'+convert(varchar(2),(datediff(day,b.ISO_WEEK_YEAR_START_DATE,aa.DATE)/7)+1),2) +
		'-'+convert(varchar(1),(datediff(day,LOW_DATE,aa.DATE)%7)+1),
		convert(char(10),aa.DATE) ,
	convert(varchar(10), convert(varchar(4),datepart(year,aa.DATE)) ||'/'|| convert(varchar(2),datepart(day,aa.DATE))||'/'|| convert(varchar(2),datepart(month,aa.DATE))),
	convert(char(10),aa.DATE) ,
	convert(varchar(10), convert(varchar(2),datepart(month,aa.DATE))||'/'|| convert(varchar(2),datepart(day,aa.DATE))||'/' || convert(varchar(4),datepart(year,aa.DATE))),
	convert(varchar(12),left(datepart(month,aa.DATE),3) ||' '|| convert(varchar(2),datepart(day,aa.DATE))||', '|| convert(varchar(4),datepart(year,aa.DATE))),
	convert(varchar(18),datepart(month,aa.DATE)||' '|| convert(varchar(2),datepart(day,aa.DATE))||', '|| convert(varchar(4),datepart(year,aa.DATE))),
	convert(char(8),aa.DATE) ,
	convert(varchar(8), convert(varchar(2),datepart(month,aa.DATE))+'/'+ convert(varchar(2),datepart(day,aa.DATE))+'/'+ right(convert(varchar(4),datepart(year,aa.DATE)),2)),
  CASE WHEN ((datediff(day,'17530107',aa.DATE)%7)+1 ) IN (1, 7) THEN 'No Work' ELSE 'Work Day' END,
  CASE WHEN ((datediff(day,'17530107',aa.DATE)%7)+1 ) IN (1, 7) THEN 0 ELSE 1 END,
  'ACM'
from aa
	join ISO_WEEK as b
	on aa.DATE between b.ISO_WEEK_YEAR_START_DATE and  b.ISO_WEEK_YEAR_END_DATE
order by
	aa.DateId;

Update dim.datetable
Set DateID = cast(replace(Date,'-','') as int)
FROM dim.datetable TST;

UPDATE dim.datetable
SET month_name = TO_CHAR(TO_DATE(calendarmonth::text, 'MM'), 'Mon')
where month_name is null;




END;
$$
