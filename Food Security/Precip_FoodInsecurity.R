library(dplyr)
library(ggplot2)
library(reshape2)
detach("package:raster", unload=TRUE)

setwd('D:/Documents and Settings/mcooper/GitHub/vitalsigns-analysis/Food Security')

source('../production_connection.R')
#source('../local_connection.R')

con <- src_postgres(dbname = dbname, host = host, port = port, user = user, password = password)

df <- tbl(con, 'flagging__household_secI') %>% data.frame

df1 <- df %>% select(Country, Landscape.., Round,
            jan=hh_i09_2012_1,
            feb=hh_i09_2012_2, 
            mar=hh_i09_2012_3,
            apr=hh_i09_2012_4,
            may=hh_i09_2012_5,
            jun=hh_i09_2012_6, 
            jul=hh_i09_2012_7,
            aug=hh_i09_2012_8, 
            sep=hh_i09_2012_9, 
            oct=hh_i09_2012_10,
            nov=hh_i09_2012_11, 
            dec=hh_i09_2012_12)

df2 <-  df %>% select(Country, Landscape.., Round,
            jan=hh_i09_2013_1,
            feb=hh_i09_2013_2,
            mar=hh_i09_2013_3,
            apr=hh_i09_2013_4,
            may=hh_i09_2013_5,
            jun=hh_i09_2013_6,
            jul=hh_i09_2013_7,
            aug=hh_i09_2013_8,
            sep=hh_i09_2013_9,
            oct=hh_i09_2013_10,
            nov=hh_i09_2013_11,
            dec=hh_i09_2013_12)

df3 <- bind_rows(df1, df2)

mean2 <- function(v){
  sum(v, na.rm=T)/length(v)
}

dfsum <- df3 %>% group_by(Country, Landscape.., Round) %>%
  summarize(jan=mean2(jan), feb=mean2(feb),
            mar=mean2(mar), apr=mean2(apr),
            may=mean2(may), jun=mean2(jun),
            jul=mean2(jul), aug=mean2(aug),
            sep=mean2(sep), oct=mean2(oct),
            nov=mean2(nov), dec=mean2(dec)) %>%
  melt(id.vars=c('Country', 'Landscape..', 'Round'))
  
df_ls <- tbl(con, 'landscape') %>%
  select(Country=country, Landscape..=landscape_no,
         x=centerpoint_longitude, y=centerpoint_latitude) %>%
  merge(dfsum, all.y=T)


##Get climate data
library(raster)

r <- stack(paste0('precip/', list.files('precip/', pattern='.bil')))
names(r) <- c('jan', 'oct', 'nov', 'dec', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep')

ls <- df_ls[ , c('Country', 'Landscape..', 'x', 'y')] %>% unique
ls_sp <- SpatialPointsDataFrame(coords = ls[ , c('x', 'y')], data=ls)

ls_sp_m <- extract(r, ls_sp, sp=T)@data

months <- c('jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec')

#Just normalize months
ls_sp_m$max <- apply(X = ls_sp_m[ , months],
                        FUN = max, MARGIN = 1)

ls_sp_m[ , months] <- ls_sp_m[ , months]/ls_sp_m$max

ls_m <- melt(ls_sp_m[ , c('Country', 'Landscape..', months)], id.vars=c('Country', 'Landscape..'))

df_m <- merge(ls_m, df_ls, by=c('Country', 'Landscape..', 'variable'))

df_m$variable <- as.numeric(df_m$variable)

ggplot(df_m) + 
  geom_line(aes(variable, value.x), color='blue') + 
  geom_bar(aes(variable, value.y), stat='identity') + 
  facet_grid(paste0(Country, Landscape.., Round) ~ .)
ggsave('Insecurity_Months_PrecipLine.png', width=5, height=18)


ggplot(df_m %>% filter(Country == 'UGA')) + 
  geom_line(aes(variable, value.x), color='blue') + 
  geom_bar(aes(variable, value.y), stat='identity') + 
  facet_grid(paste0(Landscape..) ~ .)

ggsave('Insecuritys_Precip_Uganda.png')

#Do it again but with the raw precip data.  plot lines and bars













