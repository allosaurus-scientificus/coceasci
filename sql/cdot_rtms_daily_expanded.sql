--  gaps in record so need all dates
with date_range as (

  select ds::date as measure_date
  from generate_series('2020-01-01'::timestamp, (current_date - interval '1 day')::date, '1 day'::interval) as ds

),

--  get distinct devices by county
county_devices as (

  select device_id
    , county
    , count(county) as n_rows
    , count(distinct county) as n_counties
  from dim.cdot_rtms_daily_fact
  group by 1, 2
  order by 3 desc
 
),

--  need all combination of counties, devices, dates
county_device_dates as (

  select distinct county_devices.county as county
    , county_devices.device_id
    , date_range.measure_date
  from county_devices
    cross join date_range
  where county_devices.county is not null
  order by 1, 2

),
 
--  row per device per day
select cdd.county
    , cdd.device_id
    , cdd.measure_date
    , rtms.latitude
    , rtms.longitude
    , rtms.total_daily_volume
from county_device_dates as cdd
  left join dim.cdot_rtms_daily_fact as rtms 
    on (cdd.measure_date = rtms.measure_date and cdd.device_id = rtms.device_id)
order by 1, 2, 3