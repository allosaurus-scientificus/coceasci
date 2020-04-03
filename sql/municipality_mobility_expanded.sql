--  gaps in record so need all dates
with date_range as (

  select ds::date as date
  from generate_series('2020-03-01'::timestamp, (current_date - interval '1 day')::date, '1 day'::interval) as ds

),

--  all combos of counties and municipalities
counties_municipalities as (

  select replace(county, ' County', '')::text as county
    , municipality
    , count(county) as n_rows
  from descartes.municipality_mobility
  group by 1, 2
  order by 2 desc
 
),

--  need all combination of counties, municpalities, and dates
counties_municipalities_dates as (

  select distinct counties_municipalities.county
    , counties_municipalities.municipality
    , date_range.date
  from counties_municipalities
    cross join date_range
  order by 1, 2

),

municipality_mobility as (
  
  select date
    , country
    , state
    , replace(county, ' County', '')::text as county
    , municipality
    , fips
    , median_distance_traveled_km
    , delta_median_distance_traveled_km
    , mobility_index
    , delta_mobility_index 
  from descartes.municipality_mobility

)

select *
from counties_municipalities_dates as cmd 
  left join municipality_mobility as mm 
    on (cmd.county = mm.county and cmd.municipality = mm.municipality and cmd.date = mm.date)