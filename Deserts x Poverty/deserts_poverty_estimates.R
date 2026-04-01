## PERCENT OF KIDS IN POVERTY IN DESERTS, NATIONAL ESTIMATE
library(tidyverse)
library(dplyr)
library(readr)
library(sf)
library(tigris)   # downloads census tract shapefiles
options(tigris_use_cache = TRUE)

## SET THRESHOLD
desert_threshold <- 0.33

## JOIN THE CHILD CARE ACCESS DATA WITH POVERTY DATA
  ## CAME FROM CLEANED CENSUS DATA, SAVED IN DRIVE AS poverty_total_and_under5_clean.csv

childcare <- read_csv("cap_ccaccess_2025_revised_02282026.csv")
poverty_kids   <- read_csv("poverty_total_and_under5_clean.csv")

## ===================================================================
## DOWNLOAD SHAPE FILES TO AGGREGATE LAT/LONG IN CHILD CARE DATA TO CENSUS TRACT
cat("Downloading census tract boundaries (this may take a moment)...\n")
tracts_sf <- tracts(state = NULL, cb = TRUE, year = 2020) %>%
  select(GEOID, geometry)

## ===================================================================
## SPATIALLY JOIN CHILD CARE POINTS TO CENSUS TRACTS
  # Convert child care points to sf, then st_join to find which tract each point falls in.
childcare_sf <- childcare %>%
  filter(!is.na(longitude), !is.na(latitude)) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
  st_transform(crs = st_crs(tracts_sf))

within_join <- st_join(childcare_sf, tracts_sf, join = st_within)
## snap any unmatched points to nearest tract
unmatched    <- within_join %>% filter(is.na(GEOID))
matched      <- within_join %>% filter(!is.na(GEOID))

if (nrow(unmatched) > 0) {
  nearest_idx  <- st_nearest_feature(unmatched, tracts_sf)
  unmatched$GEOID <- tracts_sf$GEOID[nearest_idx]
}

childcare_with_tract <- bind_rows(matched, unmatched) %>%
  st_drop_geometry()

childcare_with_tract <- st_join(childcare_sf, tracts_sf, join = st_within) %>%
  st_drop_geometry()

## ===================================================================
## JOIN POVERTY DATA BY CENSUS TRACT GEOID
poverty_clean <- poverty %>%
  mutate(GEOID = as.character(GEOID))

childcare_with_poverty <- childcare_with_tract %>%
  mutate(GEOID = as.character(GEOID)) %>%
  left_join(poverty_clean %>% select(GEOID, pct_poverty_under5),
            by = "GEOID") %>%
  rename(avg_pct_poverty_under5 = pct_poverty_under5)

## ===================================================================
## DIAGNOSTIC - CHECK FOR UNMATCHED POINTS
n_total          <- nrow(childcare_with_poverty)
n_no_supply      <- sum(is.na(childcare_with_poverty$adj_supply))
n_no_poverty     <- sum(is.na(childcare_with_poverty$avg_pct_poverty_under5))
n_both_missing   <- sum(is.na(childcare_with_poverty$adj_supply) | is.na(childcare_with_poverty$avg_pct_poverty_under5))
n_usable         <- n_total - n_both_missing

cat("\n--- DIAGNOSTIC ---\n")
cat(sprintf("Total child care points:              %d\n", n_total))
cat(sprintf("Missing adj_supply:                   %d\n", n_no_supply))
cat(sprintf("Missing poverty data (no tract match):%d\n", n_no_poverty))
cat(sprintf("Dropped by filter (either missing):   %d\n", n_both_missing))
cat(sprintf("Points used in final estimate:        %d\n", n_usable))
cat(sprintf("Coverage:                             %.1f%%\n", n_usable / n_total * 100))
cat("------------------\n\n")

## ===================================================================
## NATIONAL ESTIMATE
national_poverty_desert <- childcare_with_poverty %>%
  filter(!is.na(adj_supply), !is.na(avg_pct_poverty_under5)) %>%
  mutate(
    eligible_children = 10 * (avg_pct_poverty_under5 / 100),
    desert            = adj_supply <= desert_threshold
  ) %>%
  summarise(
    total_eligible_children  = sum(eligible_children),
    desert_eligible_children = sum(eligible_children[desert]),
    pct_in_desert            = round(desert_eligible_children / total_eligible_children * 100, 1)
  )

cat("======================================\n")
cat("NATIONAL RESULTS\n")
cat("======================================\n")
cat(sprintf("Total children in poverty (est.):       %s\n",
            formatC(national_poverty_desert$total_eligible_children,  format = "f", digits = 0, big.mark = ",")))
cat(sprintf("In poverty & in a child care desert:    %s\n",
            formatC(national_poverty_desert$desert_eligible_children, format = "f", digits = 0, big.mark = ",")))
cat(sprintf("Percent in a child care desert:         %.1f%%\n",
            national_poverty_desert$pct_in_desert))
cat("======================================\n")

print(national_poverty_desert)

## OPTIONAL, STATE LEVEL BREAKDOWN
by_state <- childcare_with_poverty %>%
  filter(!is.na(adj_supply), !is.na(avg_pct_poverty_under5)) %>%
  mutate(
    eligible_children = 10 * (avg_pct_poverty_under5 / 100),
    desert            = adj_supply <= desert_threshold
  ) %>%
  group_by(state_name, state_abbrv) %>%
  summarise(
    total_eligible_children  = sum(eligible_children),
    desert_eligible_children = sum(eligible_children[desert]),
    pct_in_desert            = round(desert_eligible_children / total_eligible_children * 100, 1),
    .groups = "drop"
  ) %>%
  arrange(desc(pct_in_desert))

print(by_state)
write_csv(by_state, "childcare_desert_poverty_by_state.csv")
cat("\nState-level results saved to: childcare_desert_poverty_by_state.csv\n")

##========================================================================
##========================================================================
### DO NOT USE THIS, JUST LEAVING FOR POSTERITY, MIND THE COARSER JOIN
## ORIGINAL SCRIPT APPLIED POVERTY RATE AT EQUAL RATES ACROSS ALL TRACTS, INFLATING ESTIMATES LIKELY FROM SMALL, RURAL AREAS
desert_threshold <- 0.33
national_poverty_desert <- childcare_with_poverty %>%
  filter(!is.na(adj_supply), !is.na(avg_pct_poverty_under5)) %>%
  mutate(
    eligible_children = 10 * (avg_pct_poverty_under5 / 100),
    desert = adj_supply <= desert_threshold
  ) %>%
  summarise(
    total_eligible_children  = sum(eligible_children),
    desert_eligible_children = sum(eligible_children[desert]),
    pct_in_desert            = round(desert_eligible_children / total_eligible_children * 100, 1)
  )
##========================================================================
##========================================================================