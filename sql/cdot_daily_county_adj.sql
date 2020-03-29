--  gaps in record so need all dates
with date_range as (

  select ds::date as measure_date
  from generate_series('2019-05-01'::timestamp, (current_date - interval '1 day')::date, '1 day'::interval) as ds

),

--  device description is only way match up with county
county_devices as (

  select device_desc
    , county
    , count(county) as n_rows
    , count(distinct county) as n_counties
  from dim.cdot_device_inventory
  group by 1, 2
  order by 3 desc
 
),

--  need all combination of counties and dates
counties_x_dates as (

  select distinct county_devices.county as county
    , date_range.measure_date
    , date_trunc('month', date_range.measure_date)::date as measure_month
    , extract(dow from date_range.measure_date) in (0, 6) as weekend
  from county_devices
    cross join date_range
  where county_devices.county is not null
  order by 1, 2

),

--  aggregate to county days as counties can have > device, location_id
county_days as (
 
  select cd.county
    , adf.measure_date::date as measure_date
    , sum(adf.daily_total_volume)::integer as d1_total
    , sum(adf.daily_car_volume)::integer as d1_car
    , sum(adf.daily_truck_volume)::integer as d1_truck
    , sum(adf.daily_unbinned_volume)::integer as d1_unbinned
  from dim.cdot_atr_daily_fact as adf
    left join county_devices as cd on adf.device = cd.device_desc
  group by 1, 2
  order by 1, 2
  
),

--  one way of estimating missing values by county, month, weekend
medians as (
  
  select county
    , date_trunc('month', measure_date)::date as measure_month
    , extract(dow from measure_date) in (0, 6) as weekend
    , percentile_disc(0.5) within group (order by d1_total)::integer as d1_total_p50
    , percentile_disc(0.5) within group (order by d1_car)::integer as d1_car_p50
    , percentile_disc(0.5) within group (order by d1_truck)::integer as d1_truck_p50
    , percentile_disc(0.5) within group (order by d1_unbinned)::integer as d1_unbinned_p50
  from county_days  
  group by 1, 2, 3

)


select cxd.county as county
  , cxd.measure_date as date
  , cxd.measure_month 
  , cxd.weekend
--  if value missing, used median estimate by county, month, weekend
  , cd.d1_total
  , coalesce(cd.d1_total, m.d1_total_p50) as d1_total_adj
--  totals
  , lag(coalesce(cd.d1_total, m.d1_total_p50), 7) over (partition by cxd.county order by cxd.measure_date asc) as d7_total_adj
  , lag(coalesce(cd.d1_total, m.d1_total_p50), 14) over (partition by cxd.county order by cxd.measure_date asc) as d14_total_adj
  , lag(coalesce(cd.d1_total, m.d1_total_p50), 28) over (partition by cxd.county order by cxd.measure_date asc) as d28_total_adj
--  cars
  , cd.d1_car
  , coalesce(cd.d1_car, m.d1_car_p50) as d1_car_adj
  , lag(coalesce(cd.d1_car, m.d1_car_p50), 7) over (partition by cxd.county order by cxd.measure_date asc) as d7_car_adj
  , lag(coalesce(cd.d1_car, m.d1_car_p50), 14) over (partition by cxd.county order by cxd.measure_date asc) as d14_car_adj
  , lag(coalesce(cd.d1_car, m.d1_car_p50), 28) over (partition by cxd.county order by cxd.measure_date asc) as d28_car_adj
--  trucks
  , cd.d1_truck
  , coalesce(cd.d1_truck, m.d1_truck_p50) as d1_car_adj
  , lag(coalesce(cd.d1_truck, m.d1_truck_p50), 7) over (partition by cxd.county order by cxd.measure_date asc) as d7_truck_adj
  , lag(coalesce(cd.d1_truck, m.d1_truck_p50), 14) over (partition by cxd.county order by cxd.measure_date asc) as d14_truck_adj
  , lag(coalesce(cd.d1_truck, m.d1_truck_p50), 28) over (partition by cxd.county order by cxd.measure_date asc) as d28_truck_adj
--  unbinned
  , cd.d1_unbinned
  , coalesce(cd.d1_unbinned, m.d1_unbinned_p50) as d1_unbinned_adj
  , lag(coalesce(cd.d1_unbinned, m.d1_unbinned_p50), 7) over (partition by cxd.county order by cxd.measure_date asc) as d7_unbinned_adj
  , lag(coalesce(cd.d1_unbinned, m.d1_unbinned_p50), 14) over (partition by cxd.county order by cxd.measure_date asc) as d14_unbinned_adj
  , lag(coalesce(cd.d1_unbinned, m.d1_unbinned_p50), 28) over (partition by cxd.county order by cxd.measure_date asc) as d28_unbinned_adj

from counties_x_dates as cxd
  left join county_days as cd on (cxd.county = cd.county and cxd.measure_date = cd.measure_date)
  left join medians as m on (cxd.county = m.county and cxd.measure_month = m.measure_month and cxd.weekend = m.weekend)
--  where cxd.county = 'Adams'

order by 1, 2
