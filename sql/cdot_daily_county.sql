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
  from county_devices
    cross join date_range
  where county_devices.county is not null
  order by 1, 2

),

--  aggregate to county days as counties can have > device, location_id
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

--  create 7 day interval lags for each mesaure
select cxd.county as county
  , cxd.measure_date as date
  , d1_total
--  totals
  , lag(cd.d1_total, 7) over (partition by cxd.county order by cxd.measure_date asc) as d7_total
  , lag(cd.d1_total, 14) over (partition by cxd.county order by cxd.measure_date asc) as d14_total
  , lag(cd.d1_total, 28) over (partition by cxd.county order by cxd.measure_date asc) as d28_total
--  cars
  , lag(cd.d1_car, 7) over (partition by cxd.county order by cxd.measure_date asc) as d7_car
  , lag(cd.d1_car, 14) over (partition by cxd.county order by cxd.measure_date asc) as d14_car
  , lag(cd.d1_car, 28) over (partition by cxd.county order by cxd.measure_date asc) as d28_car
--  trucks
  , lag(cd.d1_truck, 7) over (partition by cxd.county order by cxd.measure_date asc) as d7_truck
  , lag(cd.d1_truck, 14) over (partition by cxd.county order by cxd.measure_date asc) as d14_truck
  , lag(cd.d1_truck, 28) over (partition by cxd.county order by cxd.measure_date asc) as d28_truck
--  unbinned
  , lag(cd.d1_unbinned, 7) over (partition by cxd.county order by cxd.measure_date asc) as d7_unbinned
  , lag(cd.d1_unbinned, 14) over (partition by cxd.county order by cxd.measure_date asc) as d14_unbinned
  , lag(cd.d1_unbinned, 28) over (partition by cxd.county order by cxd.measure_date asc) as d28_unbinned
/*  old mitigation
  , (cxd.measure_date - lag(cxd.measure_date, 7) over (partition by cxd.county order by cxd.measure_date asc))::integer as show_lag7_diff
  , case when (cxd.measure_date - lag(cxd.measure_date, 7) over (partition by cxd.county order by cxd.measure_date asc))::integer = 7::integer
         then lag(cd.d1_total, 7) over (partition by cxd.county order by cxd.measure_date asc)
         else null
    end as d7_total_sql
*/

from counties_x_dates as cxd
  left join county_days as cd on (cxd.county = cd.county and cxd.measure_date = cd.measure_date)
--  where cxd.county = 'Adams'

order by 1, 2


/*  testing, confirming adams has no cars or trucks but things that go

select * 
  from dim.cdot_atr_daily_fact
    inner join dim.cdot_device_inventory on dim.cdot_atr_daily_fact.device = dim.cdot_device_inventory.device_desc
where dim.cdot_device_inventory.county = 'Adams'

*/