library(tidyverse)
library(lubridate)
library(tsibble)

sql_cdot <- read_file("~/Documents/repos/coceasci/sql/cdot_daily_county.sql")
sql_cdot_adj <- read_file("~/Documents/repos/coceasci/sql/cdot_daily_county_adj.sql")

conn <- fouu::connect_coce()

d_cdot <- DBI::dbGetQuery(conn, sql_cdot)
# d_cdot_adj <- DBI::dbGetQuery(conn, sql_cdot_adj)

DBI::dbDisconnect(conn)

rm(conn)

glimpse(d_cdot)
glimpse(d_cdot_adj)

##  nulls
d_cdot %>% 
  filter(date < Sys.Date() & date >= "2020-02-01" & is.na(d1_total)) %>% 
  select(date, d1_total) %>% 
  group_by(date) %>% 
  summarize(d1_null = n()) %>% 
  ungroup() %>% 
  filter() %>% 
  ggplot(aes(x = date, 
             y = d1_null)) +
  geom_line() +
  geom_point() +
  scale_x_date(date_labels = "%m-%d",
               date_breaks = "3 days") +
  theme_linedraw()


d_d1 <- d_cdot %>%
  filter(date < Sys.Date()) %>% 
  as_tibble() %>% 
  mutate(weekend = wday(date) %in% c(1, 7),
         measure_month = floor_date(date, "month")) %>% 
  select(county, measure_month, date, weekend, d1_total, d1_car, d1_truck)
  
d_medians <- d_d1 %>% 
  group_by(county, measure_month, weekend) %>% 
  summarize(d1_median = as.integer(floor(median(d1_total, na.rm = TRUE))))
  # summarize(d1_median = as.integer(floor(median(d1_truck, na.rm = TRUE))))

##  if null, replace with median
d_d1_adj <- d_d1 %>% 
  left_join(d_medians, 
            by = c("county" = "county",
                   "measure_month" = "measure_month", 
                   "weekend" = "weekend")) %>% 
  mutate(d1_diff = d1_total - d1_median,
         d1_adj = coalesce(d1_total, d1_median))

d_d1_adj %>% 
  filter(county == "Adams") %>% 
  print(n = 300)

d_d1_adj_agg <- d_d1_adj%>% 
  group_by(date) %>% 
  summarize(d1_raw = sum(d1_total, na.rm = TRUE),
            # d1_raw = sum(d1_truck, na.rm = TRUE),
            d1_adj = sum(d1_adj, na.rm = TRUE))

d_d1_adj_agg %>% 
  filter(date >= "2019-07-01") %>% 
  gather(key = measure, value = d1_totals, -date) %>% 
  ggplot(aes(x = date,
             y = d1_totals,
             linetype = measure)) +
  geom_line() +
  # geom_vline(xintercept = ymd("2020-03-26"),
  #            colour = "steelblue4",
  #            linetype = 4) +
  # annotate("text",
  #          x = ymd("2020-03-26"),
  #          y = 4 * 10^5,
  #          colour = "steelblue4",
  #          label = paste0("3/26 stay in place"),
  #          hjust = "right") +
  scale_x_date(date_labels = "%Y-%m-%d") +
  scale_y_continuous(labels = scales::comma) +
  labs(x = "measure date",
       y = "volume totals",
       linetype = "raw or adjusted",
       colour = "raw or adjusted",
       title = "unreviewed, sum of unadjusted (d1_raw) and median imputed (d1_adj) daily volume from cdot",
       subtitle = "date aggregated by device to county for all counties") +
  theme_classic() +
  theme(legend.position = "bottom")


ts_adj <- d_d1_adj_agg %>% 
  as_tsibble(index = "date")

ts_adj %>% 
  mutate(d7_adj = slide_dbl(.x = d1_adj, .f = mean, .size = 7),
         d14_adj = slide_dbl(.x = d1_adj, .f = mean, .size = 14),
         d28_adj = slide_dbl(.x = d1_adj, .f = mean, .size = 28)) %>% 
  gather(key = period, value = moving_avg, d7_adj, d14_adj, d28_adj) %>% 
  mutate(period = fct_relevel(period, "d28_adj", "d14_adj")) %>% 
  ggplot(aes(x = date,
             y = moving_avg,
             colour = period,
             linetype = period)) + 
  geom_line(na.rm = TRUE) +
  scale_x_date(date_labels = "%Y-%m-%d") +
  scale_y_continuous(labels = scales::comma) +
  scale_colour_manual(values = c("black", "steelblue4", "steelblue2")) +
  # scale_linetype_manual(values = c(1, 3, 2)) +
  expand_limits(y = 0) +
  labs(x = "measure date",
       y = "volume totals (moving avg.)",
       linetype = "period of moving average",
       colour = "period of moving average",
       title = "unreviewed, moving averages of median imputed daily volume totals",
       subtitle = "date aggregated by device to county for all counties") +
  theme_classic() +
  theme(legend.position = "bottom")




