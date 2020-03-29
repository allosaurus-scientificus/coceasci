library(tidyverse)

sql_cdot <- read_file("~/Documents/repos/coced2/sql/cdot_daily_county.sql")

conn <- fouu::connect_coce()

d_cdot <- DBI::dbGetQuery(conn, sql_cdot)

DBI::dbDisconnect(conn)

rm(conn)

glimpse(d_cdot)

