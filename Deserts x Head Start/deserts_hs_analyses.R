library(tidyverse)
desert_threshold<-0.33
poverty_data <- read_csv("poverty_total_and_under5_clean.csv")

poverty_county <- poverty_data %>%
  # Extract 5-digit county FIPS from the 11-digit GEOID
  mutate(county_fips = str_sub(GEOID, 1, 5)) %>%
  filter(!is.na(pct_poverty_under5)) %>%
  group_by(county_fips) %>%
  summarise(
    avg_pct_poverty_under5 = mean(pct_poverty_under5, na.rm = TRUE),
    .groups = "drop"
  )

childcare_with_poverty <- childcare_data %>%
  # Ensure county_fips is a 5-character string with leading zeros
  mutate(county_fips = str_pad(as.character(county_fips), width = 5, pad = "0")) %>%
  left_join(poverty_county, by = "county_fips")

hs_eligible_desert <- childcare_with_poverty %>%
  filter(!is.na(adj_supply_hs), !is.na(avg_pct_poverty_under5)) %>%
  mutate(
    # Estimated eligible (poverty) children per row out of 10 synthetic children
    eligible_children = 10 * (avg_pct_poverty_under5 / 100),
    # Desert indicator for Head Start
    hs_desert = adj_supply_hs <= desert_threshold
  ) %>%
  summarise(
    total_eligible_children  = sum(eligible_children),
    desert_eligible_children = sum(eligible_children[hs_desert]),
    pct_eligible_in_desert   = round((desert_eligible_children / total_eligible_children) * 100, 1)
  )

print(hs_eligible_desert)

## SEEMED REALLY, REALLY HIGH - WANTED TO BREAK THIS DOWN FURTHER BY RURALITY
library(tidyverse)
desert_threshold <- 0.33
rural_lookup <- joined_rural %>%
  select(longitude, latitude, rural) %>%
  distinct()

childcare_with_poverty <- childcare_data %>%
  mutate(county_fips = str_pad(as.character(county_fips), width = 5, pad = "0")) %>%
  left_join(poverty_county, by = "county_fips") %>%
  left_join(rural_lookup, by = c("longitude", "latitude"))

cat("Rows with rural status:", sum(!is.na(childcare_with_poverty$rural)), "\n")
cat("Rows missing rural status:", sum(is.na(childcare_with_poverty$rural)), "\n")

hs_eligible_desert_by_rural <- childcare_with_poverty %>%
  filter(!is.na(adj_supply_hs), !is.na(avg_pct_poverty_under5), !is.na(rural)) %>%
  mutate(
    eligible_children = 10 * (avg_pct_poverty_under5 / 100),
    hs_desert = adj_supply_hs <= desert_threshold
  ) %>%
  group_by(rural) %>%
  summarise(
    total_eligible_children  = sum(eligible_children),
    desert_eligible_children = sum(eligible_children[hs_desert]),
    .groups = "drop"
  ) %>%
  mutate(
    pct_eligible_in_desert = round((desert_eligible_children / total_eligible_children) * 100, 1)
  ) %>%
  arrange(rural)

print(hs_eligible_desert_by_rural)

## STILL SEEMED REALLY, REALLY HIGH; WANTED TO BREAK THIS DOWN FURTHER TO CHECK FOR DEGREE OF SCARCITY, AND CONFIRM PARAMETERS
childcare_with_poverty %>%
  filter(!is.na(adj_supply_hs), !is.na(avg_pct_poverty_under5), !is.na(rural)) %>%
  mutate(eligible_children = 10 * (avg_pct_poverty_under5 / 100)) %>%
  group_by(rural) %>%
  summarise(
    weighted_mean_supply = round(
      weighted.mean(adj_supply_hs, w = eligible_children, na.rm = TRUE), 4
    ),
    median_supply = round(median(adj_supply_hs), 4),
    .groups = "drop"
  )

## NEXT, BROKE DOWN THE SHARE OF AREAS WITH SOME SUPPLY BY RURALITY
childcare_with_poverty %>%
  filter(!is.na(adj_supply_hs), !is.na(rural)) %>%
  mutate(
    supply_category = case_when(
      adj_supply_hs == 0              ~ "No supply",
      adj_supply_hs <= desert_threshold ~ "Some supply, still a desert",
      TRUE                            ~ "Not a desert"
    )
  ) %>%
  group_by(rural, supply_category) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(rural) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  arrange(rural, supply_category)