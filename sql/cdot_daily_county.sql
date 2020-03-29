with county_devices as (

  select device_desc
    , county
    , count(county) as n_rows
    , count(distinct county) as n_counties
  from dim.cdot_device_inventory
  group by 1, 2
  order by 3 desc
 
),

county_days as (
 
  select cd.county
    , adf.measure_date
    , sum(adf.daily_total_volume)::integer as d1_total
    , sum(adf.daily_car_volume)::integer as d1_car
    , sum(adf.daily_truck_volume)::integer as d1_truck
    , sum(adf.daily_unbinned_volume)::integer as d1_unbinned
  from dim.cdot_atr_daily_fact as adf
    left join county_devices as cd on adf.device = cd.device_desc
  group by 1, 2
  order by 1, 2
  
  )
  
select cd.county
  , cd.measure_date
  , d1_total
--  rinse, repeat for each measure, show_lagX_diff just to highlight issue case when is mitigating
  , (cd.measure_date - lag(cd.measure_date, 7) over (partition by cd.county order by cd.measure_date asc))::integer as show_lag7_diff
  , case when (cd.measure_date - lag(cd.measure_date, 7) over (partition by cd.county order by cd.measure_date asc))::integer = 7::integer
         then lag(cd.d1_total, 7) over (partition by cd.county order by cd.measure_date asc)
         else null
    end as d7_total_sql
  , (cd.measure_date - lag(cd.measure_date, 14) over (partition by cd.county order by cd.measure_date asc))::integer as show_lag14_diff
  , case when (cd.measure_date - lag(cd.measure_date, 14) over (partition by cd.county order by cd.measure_date asc))::integer = 14::integer
         then lag(cd.d1_total, 14) over (partition by cd.county order by cd.measure_date asc)
         else null
    end as d14_total_sql
  , (cd.measure_date - lag(cd.measure_date, 28) over (partition by cd.county order by cd.measure_date asc))::integer as show_lag28_diff
  , case when (cd.measure_date - lag(cd.measure_date, 28) over (partition by cd.county order by cd.measure_date asc))::integer = 28::integer
         then lag(cd.d1_total, 28) over (partition by cd.county order by cd.measure_date asc)
         else null
    end as d28_total_sql
  , (cd.measure_date - lag(cd.measure_date, 42) over (partition by cd.county order by cd.measure_date asc))::integer as show_lag42_diff   
  , case when (cd.measure_date - lag(cd.measure_date, 42) over (partition by cd.county order by cd.measure_date asc))::integer = 42::integer
         then lag(cd.d1_total, 42) over (partition by cd.county order by cd.measure_date asc)
         else null
    end as d42_total_sql
from county_days as cd