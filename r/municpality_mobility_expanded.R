library(tidyverse)
library(lubridate)
library(tsibble)

sql_mmx <- read_file("~/Documents/repos/coceasci/sql/municipality_mobility_expanded.sql")

conn <- fouu::connect_coce()

d_mmx <- DBI::dbGetQuery(conn, sql_mmx)

DBI::dbDisconnect(conn)

glimpse(d_mmx)

source("~/get_census_api.R")
tidycensus::census_api_key(my_api_key)
d_tracts <- tidycensus::get_acs(geography = "tract",
                                 ## table for concept == "SEX BY AGE"
                                 table = "B01001", 
                                 state = "CO", 
                                 geometry = TRUE)
