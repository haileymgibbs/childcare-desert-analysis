## RURAL DESERTS ANALYSIS

## Read in necessary libraries
library(tidyverse)
library(magrittr)
library(readr)
library(readxl)
library(ggplot2)
library(ggthemes)
library(collections)
library(zoo)
library(maps)

## Set path and load child care data
path = '/Users/hgibbs/Downloads/'
childcare_data<- read_csv(paste0(path,"cap_ccaccess_2025_revised_02282026.csv")) # load data pasting your path to file name

# Dataframe attributes
colnames(childcare_data)
unique(childcare_data$state_name)

##================ LOAD FORHP DATA SET
## Download Rural Health Areas Data Set from HRSA https://www.hrsa.gov/rural-health/about-us/what-is-rural/data-files 
forhp_df<-read_excel(paste0(path, 'rural-health-areas-data-set.xlsx'), sheet=3)

## Data checks
colnames(forhp_df) ## should read [1] "FIPS_2023" "State" "State_FIPS" "County_2023"  "County_Name_2023"  [6] "County_Eligibility"

# Number counties classified as rural, Nationwide
length(forhp_df$County_Name_2023[forhp_df$County_Eligibility == 'Not Fully FORHP Rural']) ## should be 923
length(forhp_df$County_Name_2023[forhp_df$County_Eligibility == 'Fully FORHP Rural']) ## should be [1] 2316

# NUMBER OF COUNTIES CLASSIFIED AS RURAL, BY STATE
state_filter = 'XX'  ### Change 'XX' to state abbrv of interest ###
length(forhp_df$County_Name_2023[(forhp_df$State == state_filter) & (forhp_df$County_Eligibility == 'Not Fully FORHP Rural')]) # XXX not fully rural counties in state XX
length(forhp_df$County_Name_2023[(forhp_df$State == state_filter) & (forhp_df$County_Eligibility == 'Fully FORHP Rural')]) # XXX fully rural counties in state XX

### MERGE DATASETS
## Join HRSA data with child care df
joined_rural <- childcare_data%>% # In doing the merge and doing a data check, found mishandling of special characters for NM and PR
  mutate(county_name = str_replace_all(county_name, 'Ã±', "ñ"))%>% # fixed for the one instance required for NM county
  filter(state_abbrv != 'PR') # filtered out Puerto Rico County as it doesn't exist in cap_ccaccess data

joined_rural <- left_join(childcare_data, forhp_df, by= c('county_fips' = 'FIPS_2023', 'state_abbrv' = 'State', 'county_name' = 'County_Name_2023'))
unique(joined_rural$County_Eligibility) ## double-checking no NAs created by merge
## should read [1] "Not Fully FORHP Rural" "Fully FORHP Rural"     NA                     

## creates rural binary
joined_rural %<>%
  mutate(rural = ifelse(County_Eligibility == 'Fully FORHP Rural', 1,0))

### descriptive stats ###
rural <- length(joined_rural$rural[joined_rural$rural == 1]) # 35,7998 synth families in fully rural county
not_rural <- length(joined_rural$rural[joined_rural$rural == 0]) # 1,927,168 synth families in not fully rural county
rural/length(joined_rural$county_name)*100 ## should read [1] 15.69383
not_rural/length(joined_rural$county_name)*100 ## should read [1] 84.48271

# By Rurality, Nationwide
cap_ccaccess_grpd_rural <- joined_rural%>%
  group_by(rural, state_name)%>%
  summarize(avg_adj_supply = mean(adj_supply),
            avg_adj_supply_fcc = mean(adj_supply_fcc),
            avg_adj_supply_ccc = mean(adj_supply_ccc),
            avg_adj_supply_hs = mean(adj_supply_hs),
            avg_adj_supply_prek = mean(adj_supply_prek))
view(cap_ccaccess_grpd_rural)

# By Rurality, by state
cap_ccaccess_grpd_rural <- joined_rural%>%
  group_by(rural, state_name)%>%
  summarize(avg_adj_supply = mean(adj_supply),
            avg_adj_supply_fcc = mean(adj_supply_fcc),
            avg_adj_supply_ccc = mean(adj_supply_ccc),
            avg_adj_supply_hs = mean(adj_supply_hs),
            avg_adj_supply_prek = mean(adj_supply_prek))

##======================================================================
## Load NCHS rural levels classification to see breakdown by urban/rural type
nchs_df <- read_csv(paste0(path, "data-table.csv"))

nchs_df %<>%
  separate_wider_delim(`2023 Code`, ' - ', names = c('urb_code', 'urb_category'))%>%
  mutate(urb_code = as.numeric(urb_code))

joined_rural <- left_join(joined_rural, nchs_df, by= c('county_fips' = 'Location', 'state_abbrv' = 'State'))
unique(joined_rural$urb_category) ## should read [1] "Medium metro"        "Small metro"         "Micropolitan"        "Large fringe metro" [5] "Noncore" "Large central metro" NA

# Clean master df of clutter columns
joined_rural %<>%
  select(-c('State_FIPS', 'County_2023', 'FullGeoName', 'County_name'))

joined_rural %<>%
  select(-c('state_fips', 'County_2023', 'FullGeoName', 'County_name'))

### Descriptive Statistics, NCHS rurality ###
large_central <- length(joined_rural$urb_code[joined_rural$urb_code == 1]) # 735,718 synth families in large metro counties
large_fringe <- length(joined_rural$urb_code[joined_rural$urb_code == 2]) # 580,173
med_metro <- length(joined_rural$urb_code[joined_rural$urb_code == 3]) # 497,703
small_metro <- length(joined_rural$urb_code[joined_rural$urb_code == 4]) # 208,113
micro <- length(joined_rural$urb_code[joined_rural$urb_code == 5]) # 197,688
noncore <- length(joined_rural$urb_code[joined_rural$urb_code == 6]) # 126,864

large_central/length(joined_rural$county_name)*100 ## should read [1] 32.25222
large_fringe/length(joined_rural$county_name)*100  ## should read [1] 25.43348
med_metro/length(cap_ccaccess_joined$county_name)*100 ## should read [1] 21.81818
small_metro/length(cap_ccaccess_joined$county_name)*100 ## should read [1] 9.123206
micro/length(cap_ccaccess_joined$county_name)*100 ## should read [1] 8.666197
noncore/length(cap_ccaccess_joined$county_name)*100 ## should read [1] 5.561432

# By Rurality, Nationwide
cap_ccaccess_grpd_urb <- joined_rural%>%
  group_by(urb_code)%>%
  summarize(avg_adj_supply = mean(adj_supply),
            avg_adj_supply_fcc = mean(adj_supply_fcc),
            avg_adj_supply_ccc = mean(adj_supply_ccc),
            avg_adj_supply_hs = mean(adj_supply_hs),
            avg_adj_supply_prek = mean(adj_supply_prek))

# By Rurality, by state
cap_ccaccess_grpd_rural <- joined_rural%>%
  group_by(urb_code, state_name)%>%
  summarize(avg_adj_supply = mean(adj_supply),
            avg_adj_supply_fcc = mean(adj_supply_fcc),
            avg_adj_supply_ccc = mean(adj_supply_ccc),
            avg_adj_supply_hs = mean(adj_supply_hs),
            avg_adj_supply_prek = mean(adj_supply_prek))

## See joined data by pct desert, by rural/urban type, using the 0.33 threshold
joined_rural%>%
  group_by(urb_code, urb_category) %>%
  summarise(
    total_obs = n(),
    desert_count = sum(adj_supply < 0.33, na.rm = TRUE),
    pct_desert = (desert_count / total_obs) * 100
  )

## BREAKDOWN BY STATE, URB CATEGORY
joined_rural%>%
  filter(!is.na(urb_code)) %>%
  group_by(state_name, urb_code, urb_category) %>%
  summarise(
    total_obs = n(),
    desert_count = sum(adj_supply < 0.33, na.rm = TRUE),
    pct_desert = (desert_count / total_obs) * 100,
    .groups = "drop"
  ) %>%
  arrange(state_name, urb_code)

## PREVIEW TABLE =======================================================
##urb_code urb_category        total_obs      desert_count  pct_desert
# 1        1 Large central metro    722694       251585       34.8
# 2        2 Large fringe metro     567149       250285       44.1
# 3        3 Medium metro           484679       234698       48.4
# 4        4 Small metro            195089       105313       54.0
# 5        5 Micropolitan           184664       111709       60.5
# 6        6 Noncore                113840        80619       70.8
# 7        NA NA                    13024        13024       100  
## PREVIEW TABLE =======================================================

## =====================================================================
## =====================================================================

# Use below function to filter data set to look at individual state by either FORHP or NCHS classification
## Reclassify the urban code and group supply type by state
classification = 'urb_code' # change to either:
## 'rural' = FORHP classification
## 'urb_code' = NCHS classification

filt_state_code <- function(df,state='', classification='') {
  if(length(state) > 0) {
    df <- df %>%
      filter(state_name == state)
  } else{
      
    }
  agg_df <- df %>%
    group_by(.data[[code]], state_name)%>%
    summarize(syn_families = n(), # number of synth families in state by classification
              avg_adj_supply = mean(adj_supply),
              avg_adj_supply_fcc = mean(adj_supply_fcc),
              avg_adj_supply_ccc = mean(adj_supply_ccc),
              avg_adj_supply_hs = mean(adj_supply_hs),
              avg_adj_supply_prek = mean(adj_supply_prek))
  return(agg_df)
  }
  
## =====================================================================
## =====================================================================