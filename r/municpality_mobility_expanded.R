library(tidyverse)
library(lubridate)
library(tsibble)

sql_mmx <- read_file("~/Documents/repos/coceasci/sql/municipality_mobility_expanded.sql")

conn <- fouu::connect_coce()

d_mmx <- DBI::dbGetQuery(conn, sql_mmx)

DBI::dbDisconnect(conn)

glimpse(d_mmx)

count(d_mmx, county) %>% print(n = 36)

d_mmx %>% 
  group_by(county, municipality) %>% 
  summarize(n_null = sum(is.na(median_distance_traveled_km))) %>% 
  print(n = 36)


x_day <- d_mmx %>% 
  group_by(date) %>% 
  summarize(n_rows = n(),
            n_counties = n_distinct(county),
            n_municipalities = n_distinct(county),
            n_fips = n_distinct(fips),
            median_km_null = mean(is.na(median_distance_traveled_km))) 

print(x_day, n = 40)

x_day %>% 
  filter(between(date, ymd("2020-03-03"), ymd("2020-03-31"))) %>% 
  ggplot(aes(x = date,
             y = median_km_null)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(labels = scales::percent_format(accuracy = 2)) +
  scale_x_date(date_labels = "%Y-%m-%d") +
  expand_limits(y = 0) +
  labs(y = "percent null",
       title = "unreviewed, municipality mobility data missing per day",
       subtitle = "expanded municipality_mobility: 1 row per county per municipality per day") +
  theme_classic()

##  example
# d_mmx %>% 
#   filter(between(date, ymd("2020-03-14"), ymd("2020-03-18")) 
#          & county == "Denver" 
#          & municipality == "Denver") %>% 
#   select(date, median_distance_traveled_km, delta_median_distance_traveled_km)

counties <- unique(pull(d_mmx, county))

plot_x_county <- function(df = d_mmx, x = "Adams") {
  
  d_county <- filter(df, county == x)
  
  n_palities <- n_distinct(pull(d_county, municipality))
  
  if (n_palities > 6) {
    
    six_randos <- d_county %>% 
      pull(municipality) %>% 
      unique() %>% 
      sample(6)
    
    d_plot <- d_county %>% 
      filter(municipality %in% six_randos)
    
    } else {
    
    d_plot <- d_county
    
    }
  
  p <- d_plot %>% 
      ggplot(aes(x = date,
                 y = median_distance_traveled_km,
                 # linetype = municipality,
                 shape = municipality)) +
      geom_point(size = 3,
                alpha = I(2/3),
                na.rm = TRUE) +
      geom_line(linetype = 3, na.rm = TRUE) +
      geom_vline(xintercept = ymd("2020-03-13"),
                 colour = "orangered",
                 linetype = 2) +
      scale_x_date(date_labels = "%m-%d") +
      labs(title = paste0(x, " municipality mobility, unreviewed"),
           subtitle = "if >6 municipalities, random 6 municipalities used") +
      theme_linedraw() +
      theme(legend.position = "bottom")
    
  return(p)
}


plot_x_county(x = "Boulder")

plot_x_county(x = "Denver")

plot_x_county()

counties %>% 
  sample(4) %>% 
  map(~plot_x_county(x = .x))
  

# source("~/get_census_api.R")
# tidycensus::census_api_key(my_api_key)
# d_tracts <- tidycensus::get_acs(geography = "tract",
#                                  ## table for concept == "SEX BY AGE"
#                                  table = "B01001", 
#                                  state = "CO", 
#                                  geometry = TRUE)
