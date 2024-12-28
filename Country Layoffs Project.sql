-- *Data Cleaning* -- 

select *
from layoffs;

-- 1. Remove Duplicates 
-- 2. Standardize Data
-- 3. Null Values or Blank Values
-- 4. Remove Any Columns

create table layoffs_staging
like layoffs ;

select *
from layoffs_staging;

insert layoffs_staging
select *
from layoffs;

-- Removing Duplicates 

select
	*
    ,row_number () over(partition by 
							company
							,location
                            ,industry
                            ,total_laid_off
                            ,percentage_laid_off
                            ,`date`
                            ,stage
                            ,country
                            ,funds_raised_millions) as row_num
from
	layoffs_staging
;

with duplicate_cte as (
	select
	*
    ,row_number () over(partition by 
							company
							, location
                            , industry
                            , total_laid_off
                            , percentage_laid_off
                            , `date`
                            , stage
                            , country
                            , funds_raised_millions) as row_num
from
	layoffs_staging
    )
select
	*
from
	duplicate_cte
where
	row_num > 1
;

-- no duplicates, if did, create table/insert data that has row_num and delete where row_num > 1

-- 1. create table 
-- CREATE TABLE `layoffs_staging2`
-- `company` text,
-- `location` text,
-- `industry` text,
-- `total_laid_off` int DEFAULT NULL,
-- `percentage_laid_off` text,
-- `date` text,
-- `stage` text,
-- `country` text,
-- `funds_raised_millions` int DEFAULT NULL
-- `row_num` int
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. insert data
-- insert into layoffs_staging2 
-- select *
-- ,row_number () over(partition by company, location, industry , total_laid_off
--                                , percentage_laid_off, `date` , stage
--                                , country, funds_raised_millions) as row_num
-- from layoffs_staging

-- 3. delete duplicates
-- delete *
-- from layoffs_staging2
-- where row_num > 1

-- Standardize Data

select
	company
    , trim(company)
from 
	layoffs_staging
;

update
	layoffs_staging
set 
	company = trim(company)
;

select
	distinct industry
from
	layoffs_staging
order by 
	industry
;

-- only have blank and nulls need to update
-- if needed to standardize spelling then: 
-- update layoffs_staging
-- set industry = 'Crypto'
-- where like 'Crypto%'

update layoffs_staging
set country = 'United States'
where country like 'United States%';

select
	distinct location
from 
	layoffs_staging
order by
	1
; -- all good, no changes needed

select
	`date`
    , str_to_date(`date`, '%m/%d/%Y')
from
	layoffs_staging
;

update
	layoffs_staging
set
	`date` = str_to_date(`date`, '%m/%d/%Y')
;

alter table
	layoffs_staging
modify column
	`date` date
;

select *
from layoffs_staging;


-- Null and Blank Values

select
	*
from
	layoffs_staging
where
	industry is null
    or industry = ''
;

update 
	layoffs_staging
set
	industry = null
where
	industry = ''
;
select 
	*
from
	layoffs_staging
where
	company = 'Airbnb'
; -- doesn't show but other data set shows Airbnb is travel industry 

select
	t1.industry
    , t2.industry
from
	layoffs_staging t1
		join layoffs_staging t2
			on t1.company = t2.company
			where 
             (t1.industry is null)
             AND 
             t2.industry is not null;
 -- joining tables to see if other columns have the values
 
 update
	layoffs_staging t1
		join layoffs_staging t2
			on t1.company = t2.company
set 
	t1.industry = t2.industry
where
	t1.industry is null
	AND 
	t2.industry is not null
; -- would be fixed if had full data set

update 
	layoffs_staging
set
	industry = 'Travel'
where
	company = 'Airbnb'
; -- the quick fix because do not have full data set

select
	*
from
	layoffs_staging
where
	company like 'Bally%'
;

-- cannot populate any other data because do not have other data to calculate or replace null values

-- Remove Columns and Rows That Are Not Needed

select
	*
from
	layoffs_staging
where 
	percentage_laid_off is null
	and
	total_laid_off is null
; -- don't really need. this data because doesn't add to story of layoffs, outliers with no data

delete
from
	layoffs_staging
where 
	percentage_laid_off is null
	and
	total_laid_off is null
;

alter table layoffs_staging
drop column row_num
; -- this is what to do if there were those duplicates and had created this column 


-- *Exploratory Data Analysis* -- 

select *
from layoffs_staging;

select
	max(total_laid_off)
    , max(percentage_laid_off)
from
	layoffs_staging
;

select
	*
from
	layoffs_staging
where 
	percentage_laid_off = 1 -- whole company was laid off
order by
	total_laid_off desc
;

select
	company
	, sum(total_laid_off)
from
	layoffs_staging
group by
	company
order by 
	2 desc
; -- companies like Google, Microsoft, Ericsson, and Amazon were top 4 in total layoffs

select
	min(`date`)
    , max(`date`)
from
	layoffs_staging 
; -- a 2022 to 2023 year range, potentially post covid changes

select
	industry
	, sum(total_laid_off)
from
	layoffs_staging
group by
	industry 
order by 
	2 desc
; -- consumer and retail were top, makes sense with shops closing down

select
	country
	, sum(total_laid_off)
from
	layoffs_staging
group by
	country 
order by 
	2 desc
;  -- US top by close to 80000, suprisingly, Sweden and Netherlands were 2nd and 3rd

select
	year(`date`)
	, sum(total_laid_off)
from
	layoffs_staging
group by
	year(`date`)
order by 
	1 desc
; -- increase in layoffs over the years with most recent year 2023 being the highest for layoffs

select
	stage
	, sum(total_laid_off)
from
	layoffs_staging
group by
	stage
order by 
	2 desc
; -- Post-IPO with the most total lay offs, makes sense since these companies are the biggest often

with rolling_total as (
	select
		substring(`date`,1,7) as `month`
		, sum(total_laid_off) as total_off
	from
		layoffs_staging
	group by
		`month`
	order by 
		1 desc
)
select
	`month`
    , total_off
	, sum(total_off) over (order by `month`) as rolling_total
from
	rolling_total
; -- beginning of 2023 was a big hit for layoffs, looks to have gotten better end of Q1

-- Let's look at how many individuals each company was laying off each year.

select
	company
    , year(`date`)
	, sum(total_laid_off)
from
	layoffs_staging
group by
	company
    , year(`date`)
order by 
	company asc
;

-- Now rank the companies in order of who had the highest layoffs each year.

with company_year as (
	select
		company
		, year(`date`) as years
		, sum(total_laid_off) as total_laid_off
	from
		layoffs_staging
	group by
		company
		, year(`date`)
	order by 
		company asc
)
, company_year_ranking as (
	select
		*
		, dense_rank() over(partition by years order by total_laid_off desc) as ranking
	from 
		company_year
	order by
		ranking asc
)
select
	*
from
	company_year_ranking
where
	ranking <= 5
order by
	years
; -- to see only top 5 each year

-- Let's dig into the data more by seeing the total employees in the company at the time of the layoff. 

select
	*
    , round((total_laid_off / percentage_laid_off),0) as total_employees 
			-- total laid off / total employee = perc laid off so total laid/perc = total emp
from 
	layoffs_staging
;

-- Let's add that column now

alter table layoffs_staging
add total_employees int;

update layoffs_staging
set total_employees = round((total_laid_off / percentage_laid_off),0)
;

select *
from layoffs_staging -- a check
where country = 'United States'
and total_employees is not null;

-- We know that the US had the most layoffs and it seems the biggest companies did.
-- Let's see how the average company size in US compares to the average size of all companies

with average_employees as (
	select
		country
		, round(avg(total_employees),0) as avg_employees
	from
		layoffs_staging
	where
		total_employees is not null
	group by
		country
)
, widespread_average as (
	select
        round(avg(total_employees),0) as widespread_avg
	from
		layoffs_staging
)
select
	ae.country
    , ae.avg_employees
    , wa.widespread_avg
from 
	average_employees ae
    cross join
		widespread_average wa
order by
	ae.avg_employees desc 
; -- even though Sweden and Netherlands were the next two countries to have the most layoffs, 
-- the companies located they average a way higher number of employees
-- this shows for such a smaller employee average, the US has a lot higher percentage of layoffs.
-- we can confirm by looking at percentage laid off too.

-- Lets look into those companies in Sweden and Netherlands to confirm

select
	*
from
	layoffs_staging
where
	country = 'Sweden'
    or country = 'Netherlands'
; -- the percentages are all around 5 and 15%, only one is 30% , but we do not have total laid off or empl

-- Let's check those percentage laid off between US, Sweden, and Netherlands

select
	country
    , round(avg(percentage_laid_off),2)
from
	layoffs_staging
where
	country in ('United States', 'Sweden', 'Netherlands')
group by 
	country
; -- US actually didn't have that high of a average perc compared to netherlands (0.19 vs .16)
-- therefore, those null values really do make the above statement a bit inconclusive 

select *
from layoffs_staging;

-- We know we needd to look into the US though as they are a big area with large layoffs. Lets look into 
-- each location and see the average total laid off, average perc laid off and avg total employees. 

select
	location
    , round(avg(total_laid_off),0) as avg_laid_off
    , round(avg(percentage_laid_off),2) as avg_perc_laid_off
    , round(avg(total_employees),0) as avg_employees
from
	layoffs_staging
where
	country = 'United States'
group by
	location
order by
	avg_perc_laid_off desc
; -- can see from this there are some places with wrong locations to the US ie Tokyo, Brisbane..
-- Let's fix this:

select
	*
from
	layoffs_staging
where
	location = 'Tel Aviv'
;

update
	layoffs_staging
set 
	country = 'Japan'
where
	location = 'Tokyo'
;
update
	layoffs_staging
set 
	country = 'Australia'
where
	location = 'Brisbane'
;
update
	layoffs_staging
set 
	country = 'Mexico'
where
	location = 'Mexico City'
;
update
	layoffs_staging
set 
	country = 'United Kingdom'
where
	location = 'Oxford'
;
update
	layoffs_staging
set 
	country = 'Singapore'
where
	location = 'Singapore'
;
update
	layoffs_staging
set 
	country = 'Sweden'
where
	location = 'Stockholm'
;
update
	layoffs_staging
set 
	country = 'Israel'
where
	location = 'Tel Aviv'
;
update
	layoffs_staging
set 
	country = 'India'
where
	location = 'Chennai'
;
update
	layoffs_staging
set 
	country = 'Canada'
where
	location = 'Vancouver'
;
update
	layoffs_staging
set 
	country = 'Germany'
where
	location = 'Berlin'
;

-- completed all fixes and can see from our US locations that in the Northeast and North Midwest have
-- undergone a large perc of layoffs. ie Grand Rapids MI, Pittsburgh PA, Nashville TN (more west)
-- and places like Albany NY, Baltimore MA, Philadelphia PA, Boston MA, and Columbus OH. 
-- The only two outliers from that are San Diego CA and Las Vegas NA. 

-- I want to dig into and see what the count of each industry these locations have. Well order by perc laid off

with us_location_avgs as (
	select
		location
		, round(avg(total_laid_off),0) as avg_laid_off
		, round(avg(percentage_laid_off),2) as avg_perc_laid_off
		, round(avg(total_employees),0) as avg_employees
	from
		layoffs_staging
	where
		country = 'United States'
	group by
		location
	order by
		avg_perc_laid_off desc
)
, us_industry_count as (
	select
		location
		, count(distinct industry) as industry_count
	from
		layoffs_staging
	where
		country = 'United States'
	group by
		location
	order by
		industry_count
)
select
	us.location
    , us.avg_perc_laid_off
    , ic.industry_count 
from
	us_location_avgs us
		join us_industry_count ic
				on us.location = ic.location
order by
	avg_perc_laid_off desc
;
-- Majority of these actually do not have a lot of industries except for Boston, lets idenfiy these

select
	distinct industry
    , location
    , total_laid_off
    , percentage_laid_off
from
	layoffs_staging
where
	location in ('Pittsburgh'
				,'Grand Rapids'
				, 'Nashville'
				, 'San Diego'
				, 'Las Vegas'
				,'Albany'
				, 'Baltimore'
				,'Philadelphia')
order by
	percentage_laid_off desc
; -- retail, transportation, and consumer industries were the highest with layoffs
-- there is not a lot to gather about the total laid off as a lot of those top values are null. 
-- So while these industries may have had a high percentage, it may not have contributed much to the total.
-- Whereas Healthcare has a definitive higher amount of. total laid off

-- How does that compare to other countries? Take Sweden and Netherlands for example.

select
	distinct industry
    , location
    , company
    , percentage_laid_off
    , total_laid_off
from
	layoffs_staging
where
	country = 'Sweden'
order by
	percentage_laid_off desc
; -- transportation matches here, the others are pretty insignificant in terms of perc.
-- however, 'Other' had a lot higher amount of physical employees laid off in Sweden
-- but not relative to the huge countries (this was Ericsson)

select
	distinct industry
    , location
    , company
    , percentage_laid_off
    , total_laid_off
from
	layoffs_staging
where
	country = 'Netherlands'
order by
	percentage_laid_off desc
; -- again, the null values make the data hard to read as 'Other' has a high percentage of laid off
-- but we do not know the total.
-- Healthcare in Netherlands is also showing a high total (the highest for the country) in total laid off.

-- Based on seeing how Healthcare is a big part of these layoffs even with null values,
-- lets finally look into how Healthcare's min, max, and average lay offs compare to other industries across all countries

select
	industry
    , country
    , min(total_laid_off) as min_layoffs
    , max(total_laid_off) as max_layoffs
    , round(avg(total_laid_off),0) as avg_layoffs
    , round(avg(percentage_laid_off),2) as avg_perc_layoffs
from
	layoffs_staging
group by
	industry
    , country
order by
	avg_perc_layoffs desc
; -- hardware is a surprising number of avg layoffs vs. others, let's edit this to also add perc layoffs
-- analysis really needs to be on country level as the results are not consistent across the world
-- edited to group by country. alter

select
	*
from
	layoffs_staging
where
	(industry = 'Healthcare' and country = 'Austrailia')
    or	
    (industry = 'Other' and country = 'Israel')
    or
    (industry = 'Transportation' and country = 'Austrailia')
    or
    (industry = 'Transportation' and country = 'United Kingdom')
;




    

    

