with county_devices as (

  select device_desc
    , county
    , count(county) as n_rows
    , count(distinct county) as n_counties
  from dim.cdot_device_inventory
  group by 1, 2
  order by 3 desc
 
)

select adf.measure_date
  , adf.measure_date - lag(measure_date, 1) over (partition by location_id order by adf.measure_date asc) as day_diff
  , adf.road_type
  , adf.measure_day_of_week
  , adf.measure_day_category
  , adf.road
  , adf.device
--  , cd.device_desc
  , cd.county
  , adf.location_id
  , adf.daily_total_volume
--  rinse, repeat for each measure, show_lagX_diff just to highlight issue case when is mitigating
  , (adf.measure_date - lag(measure_date, 7) over (partition by location_id order by adf.measure_date asc))::integer as show_lag7_diff
  , case when (adf.measure_date - lag(measure_date, 7) over (partition by location_id order by adf.measure_date asc))::integer = 7::integer
         then lag(adf.daily_total_volume, 7) over (partition by location_id order by adf.measure_date asc)
         else null
    end as d7_total_volume
  , (adf.measure_date - lag(measure_date, 14) over (partition by location_id order by adf.measure_date asc))::integer as show_lag14_diff
  , case when (adf.measure_date - lag(measure_date, 14) over (partition by location_id order by adf.measure_date asc))::integer = 14::integer
         then lag(adf.daily_total_volume, 14) over (partition by location_id order by adf.measure_date asc)
         else null
    end as d14_total_volume
   , (adf.measure_date - lag(measure_date, 28) over (partition by location_id order by adf.measure_date asc))::integer as show_lag29_diff
  , case when (adf.measure_date - lag(measure_date, 28) over (partition by location_id order by adf.measure_date asc))::integer = 28::integer
         then lag(adf.daily_total_volume, 28) over (partition by location_id order by adf.measure_date asc)
         else null
    end as d28_total_volume
from dim.cdot_atr_daily_fact as adf
  left join county_devices as cd on adf.device = cd.device_desc
order by location_id 
  , adf.measure_date asc