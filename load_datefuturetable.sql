CREATE OR REPLACE PROCEDURE dim.load_datefuturetable()
 LANGUAGE plpgsql
AS $$
DECLARE
    first_date DATE := '2010-01-01';
    last_date DATE := (CURRENT_DATE + INTERVAL '1 year');
BEGIN
    -- Drop the table if it already exists
    DROP TABLE IF EXISTS dim.DateTableFuture CASCADE;

    -- Create the DateTableFuture table
    CREATE TABLE dim.DateTableFuture
    (
        DateId INT NOT NULL DEFAULT nextval('dim.datetablefuture_dateid_seq'),
        Date DATE NOT NULL UNIQUE,
        NextDayDate DATE NOT NULL,
        CalendarYear SMALLINT NOT NULL,
        CalendarYearQuarter INT NOT NULL,
        CalendarYearMonth INT NOT NULL,
        CalendarYearDayOfYear INT NOT NULL,
        CalendarQuarter SMALLINT NOT NULL,
        CalendarMonth SMALLINT NOT NULL,
        CalendarDayOfYear SMALLINT NOT NULL,
        CalendarDayOfMonth SMALLINT NOT NULL,
        CalendarDayOfWeek SMALLINT NOT NULL,
        CalendarYearName VARCHAR(4) NOT NULL,
        CalendarYearQuarterName VARCHAR(7) NOT NULL,
        CalendarYearMonthName VARCHAR(8) NOT NULL,
        CalendarYearMonthNameLong VARCHAR(14) NOT NULL,
        CalendarYearWeek VARCHAR(6) NOT NULL,
        CalendarQuarterName VARCHAR(2) NOT NULL,
        CalendarMonthName VARCHAR(3) NOT NULL,
        CalendarMonthNameLong VARCHAR(9) NOT NULL,
        WeekdayName VARCHAR(3) NOT NULL,
        WeekdayNameLong VARCHAR(9) NOT NULL,
        CalendarStartOfYearDate DATE NOT NULL,
        CalendarEndOfYearDate DATE NOT NULL,
        CalendarStartOfQuarterDate DATE NOT NULL,
        CalendarEndOfQuarterDate DATE NOT NULL,
        CalendarStartOfMonthDate DATE NOT NULL,
        CalendarEndOfMonthDate DATE NOT NULL,
        QuarterSeqNo INT NOT NULL,
        MonthSeqNo INT NOT NULL,
        PRIMARY KEY (DateId)
    );

    -- Insert date records and attributes
    INSERT INTO dim.DateTableFuture (
        Date, NextDayDate, CalendarYear, CalendarYearQuarter,
        CalendarYearMonth, CalendarYearDayOfYear, CalendarQuarter,
        CalendarMonth, CalendarDayOfYear, CalendarDayOfMonth,
        CalendarDayOfWeek, CalendarYearName, CalendarYearQuarterName,
        CalendarYearMonthName, CalendarYearMonthNameLong, CalendarYearWeek,
        CalendarQuarterName, CalendarMonthName, CalendarMonthNameLong,
        WeekdayName, WeekdayNameLong, CalendarStartOfYearDate, CalendarEndOfYearDate,
        CalendarStartOfQuarterDate, CalendarEndOfQuarterDate, CalendarStartOfMonthDate,
        CalendarEndOfMonthDate, QuarterSeqNo, MonthSeqNo
    )
    SELECT
        d.Date::DATE,
        d.Date + INTERVAL '1 day' AS NextDayDate,
        EXTRACT(YEAR FROM d.Date)::SMALLINT AS CalendarYear,
        (EXTRACT(YEAR FROM d.Date) * 10 + EXTRACT(QUARTER FROM d.Date))::INT AS CalendarYearQuarter,
        (EXTRACT(YEAR FROM d.Date) * 100 + EXTRACT(MONTH FROM d.Date))::INT AS CalendarYearMonth,
        (EXTRACT(YEAR FROM d.Date) * 1000 + EXTRACT(DOY FROM d.Date))::INT AS CalendarYearDayOfYear,
        EXTRACT(QUARTER FROM d.Date)::SMALLINT AS CalendarQuarter,
        EXTRACT(MONTH FROM d.Date)::SMALLINT AS CalendarMonth,
        EXTRACT(DOY FROM d.Date)::SMALLINT AS CalendarDayOfYear,
        EXTRACT(DAY FROM d.Date)::SMALLINT AS CalendarDayOfMonth,
        EXTRACT(ISODOW FROM d.Date)::SMALLINT AS CalendarDayOfWeek,
        TO_CHAR(d.Date, 'YYYY') AS CalendarYearName,
        TO_CHAR(d.Date, 'YYYY') || ' Q' || EXTRACT(QUARTER FROM d.Date)::TEXT AS CalendarYearQuarterName,
        TO_CHAR(d.Date, 'YYYY') || ' ' || TO_CHAR(d.Date, 'Mon') AS CalendarYearMonthName,
        TO_CHAR(d.Date, 'YYYY') || ' ' || TO_CHAR(d.Date, 'Month') AS CalendarYearMonthNameLong,
        TO_CHAR(d.Date, 'IYYY-IW') AS CalendarYearWeek,
        'Q' || EXTRACT(QUARTER FROM d.Date)::TEXT AS CalendarQuarterName,
        TO_CHAR(d.Date, 'Mon') AS CalendarMonthName,
        TO_CHAR(d.Date, 'Month') AS CalendarMonthNameLong,
        TO_CHAR(d.Date, 'Dy') AS WeekdayName,
        TO_CHAR(d.Date, 'Day') AS WeekdayNameLong,
        DATE_TRUNC('year', d.Date)::DATE AS CalendarStartOfYearDate,
        (DATE_TRUNC('year', d.Date) + INTERVAL '1 year - 1 day')::DATE AS CalendarEndOfYearDate,
        DATE_TRUNC('quarter', d.Date)::DATE AS CalendarStartOfQuarterDate,
        (DATE_TRUNC('quarter', d.Date) + INTERVAL '3 months - 1 day')::DATE AS CalendarEndOfQuarterDate,
        DATE_TRUNC('month', d.Date)::DATE AS CalendarStartOfMonthDate,
        (DATE_TRUNC('month', d.Date) + INTERVAL '1 month - 1 day')::DATE AS CalendarEndOfMonthDate,
        EXTRACT(QUARTER FROM d.Date) + (EXTRACT(YEAR FROM d.Date) - EXTRACT(YEAR FROM first_date)) * 4 AS QuarterSeqNo,
        EXTRACT(MONTH FROM d.Date) + (EXTRACT(YEAR FROM d.Date) - EXTRACT(YEAR FROM first_date)) * 12 AS MonthSeqNo
    FROM
        GENERATE_SERIES(first_date::timestamp, last_date::timestamp, INTERVAL '1 day') AS d(Date);
END;
$$
