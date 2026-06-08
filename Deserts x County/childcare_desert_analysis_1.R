# =============================================================================
#### Child Care Desert: Poverty & Desert Access in Rural Counties
# Hailey Gibbs, Center for American Progress (May 2026)
# =============================================================================
#
# Data sources:
#   - childcare_data  : lat/long points representing synthetic families from Census; adj_supply measure as the deserts input
#   - forhp_df        : HRSA FORHP rural county eligibility (pre-loaded)
#   - NCHS data-table : urban-rural classification scheme; rural subtypes only (Micropolitan + Noncore)
#   - ACS 2023 5-Year : pulled via tidycensus
#       Tract-level   : B17001 — poverty status by sex by age (spatial join)
#       County-level  : B17001, B19013, B23025, B01003 (regression controls)
#
# Key definitions:
#   Child care desert     : adj_supply <= 0.33
#   Rural county          : "Fully FORHP Rural" (HRSA) AND NCHS code 5 or 6
#     NCHS Micropolitan   : urb_code == 5
#     NCHS Noncore        : urb_code == 6
#   Poverty tract         : >= 20% of children under 6 below poverty (ACS) threshold consistent with USDA ERS classification
#   Extreme poverty tract : >= 40% of children under 6 below poverty (ACS)
# =============================================================================

## Libraries
library(tidyverse)
library(magrittr)
library(tidycensus)
library(sf)
library(tigris)
library(scales)

options(tigris_use_cache = TRUE)

path <- "/Users/hgibbs/Downloads/"

# NOTE: census_api_key() with install = TRUE writes your key to .Renviron.
# Run once with install = TRUE; thereafter set install = FALSE to avoid
# rewriting .Renviron on every run. Do not share this script with the key
# visible — store the key in .Renviron and call census_api_key() with no
# arguments, or use Sys.getenv("CENSUS_API_KEY").

census_api_key(Sys.getenv("efe9c4d9098021681847e000144aa4b99487cd9c"), install = TRUE)


# DEFINE ACS VARIABLE CODES #
# B17001: Poverty Status in the Past 12 Months by Sex by Age
#
# Children under 6 = "Under 5 years" + "5 years", by sex
# Below poverty level:
#   B17001_004  Male,   Under 5,  below poverty
#   B17001_005  Male,   5 years,  below poverty
#   B17001_018  Female, Under 5,  below poverty
#   B17001_019  Female, 5 years,  below poverty
# At or above poverty level:
#   B17001_033  Male,   Under 5,  above poverty
#   B17001_034  Male,   5 years,  above poverty
#   B17001_047  Female, Under 5,  above poverty
#   B17001_048  Female, 5 years,  above poverty

poverty_vars <- c(
  below_male_u5  = "B17001_004",
  below_male_5yr = "B17001_005",
  below_fem_u5   = "B17001_018",
  below_fem_5yr  = "B17001_019",
  above_male_u5  = "B17001_033",
  above_male_5yr = "B17001_034",
  above_fem_u5   = "B17001_047",
  above_fem_5yr  = "B17001_048"
)

control_vars <- c(
  median_income = "B19013_001",  # Median household income (dollars)
  labor_force   = "B23025_003",  # Civilian labor force
  unemployed    = "B23025_005",  # Unemployed (civilian)
  total_pop     = "B01003_001"   # Total population
)


# Identify rural counties
# 2a. HRSA FORHP: fully rural counties
rural_fips_hrsa <- forhp_df %>%
  filter(County_Eligibility == "Fully FORHP Rural") %>%
  mutate(county_fips = str_pad(as.character(FIPS_2023), width = 5, pad = "0")) %>%
  pull(county_fips)

# 2b. NCHS: load and process urban-rural classification
#     Restrict to codes 5 (Micropolitan) and 6 (Noncore)
nchs_df <- read_csv(paste0(path, "data-table.csv")) %>%
  separate_wider_delim(`2023 Code`, delim = " - ",
                       names = c("urb_code", "urb_category")) %>%
  mutate(
    urb_code    = as.numeric(urb_code),
    county_fips = str_pad(as.character(Location), width = 5, pad = "0")
  ) %>%
  filter(urb_code %in% c(5, 6)) %>%
  select(county_fips, State, urb_code, urb_category)

rural_fips_nchs <- nchs_df %>% pull(county_fips)

# 2c. Intersection: counties meeting BOTH criteria
# The NCHS classification is the binding constraint — all 1,958 NCHS rural
# counties fall within the HRSA designation. The 358-county difference
# (HRSA rural but NCHS metro) is excluded; these counties have ambiguous
# rural status across federal classification systems.
rural_fips <- intersect(rural_fips_hrsa, rural_fips_nchs)

cat("HRSA Fully FORHP Rural counties     :", length(rural_fips_hrsa), "\n") ## should read 2316
cat("NCHS Micropolitan + Noncore counties:", length(rural_fips_nchs), "\n") ## should read 1958
cat("Counties meeting both criteria       :", length(rural_fips), "\n") ## should read 1958


## LOAD CHILD CARE DATA
childcare_data <- read.csv(
  paste0(path, "cap_ccaccess_2025_revised_02282026.csv"),
  fileEncoding = "UTF-8"
) %>%
  mutate(county_name = sapply(county_name, function(x) {
    rawToChar(as.raw(utf8ToInt(x)))
  }))

childcare_rural <- childcare_data %>%
  mutate(county_fips = str_pad(as.character(county_fips), width = 5, pad = "0")) %>%
  filter(county_fips %in% rural_fips)

cat("Rural counties in childcare_data    :", n_distinct(childcare_rural$county_fips), "\n") ## should read 1949
cat("Total data points in rural counties :", nrow(childcare_rural), "\n") ## should read 298504


# Pull ACS Tract-Level Poverty Data
# All 50 states + DC are pulled explicitly via a hardcoded FIPS list. Deriving
# state FIPS from childcare_rural would silently exclude any state with no
# matched rural childcare points, creating gaps in the spatial join.
#
# Note: FIPS codes 03, 07, 14, 43, 52 do not exist.

all_state_fips <- c(
  "01","02","04","05","06","08","09","10","11","12","13",
  "15","16","17","18","19","20","21","22","23","24","25",
  "26","27","28","29","30","31","32","33","34","35","36",
  "37","38","39","40","41","42","44","45","46","47","48",
  "49","50","51","53","54","55","56"
)

cat("\nPulling ACS tract-level poverty estimates for all",
    length(all_state_fips), "states + DC...\n")

## MAIN LOOP
tract_list <- list()

for (s in all_state_fips) {
  cat("  ACS estimates — state:", s, "\n")
  tract_list[[s]] <- get_acs(
    geography   = "tract",
    variables   = poverty_vars,
    state       = s,
    year        = 2023,
    survey      = "acs5",
    geometry    = FALSE,
    output      = "wide",
    cache_table = FALSE
  )
}

tract_data <- bind_rows(tract_list)
cat("Tracts pulled in main loop:", nrow(tract_data), "\n")

## Missing state recovery
# Check for any states absent from tract_data after the loop
# DC (11), New Jersey (34), and Rhode Island (44) have failed transiently in testing and are pulled individually if missing.

states_in_data <- unique(str_sub(tract_data$GEOID, 1, 2))
missing_states <- setdiff(all_state_fips, states_in_data)

if (length(missing_states) > 0) {
  cat("States missing after main loop — pulling individually:",
      paste(missing_states, collapse = ", "), "\n")

  recovery_list <- list()

  for (s in missing_states) {
    cat("  Recovering state:", s, "\n")
    recovery_list[[s]] <- tryCatch(
      get_acs(
        geography   = "tract",
        variables   = poverty_vars,
        state       = s,
        year        = 2023,
        survey      = "acs5",
        geometry    = FALSE,
        output      = "wide",
        cache_table = FALSE
      ),
      error = function(e) {
        cat("  ERROR on state", s, ":", conditionMessage(e), "\n")
        NULL
      }
    )
    if (!is.null(recovery_list[[s]])) {
      cat("  Tracts returned:", nrow(recovery_list[[s]]), "\n")
    }
  }

  still_missing <- names(which(map_lgl(recovery_list, is.null)))
  if (length(still_missing) > 0) {
    stop(paste(
      "Recovery failed for states:", paste(still_missing, collapse = ", "),
      "\nResolve before proceeding."
    ))
  }

  tract_data <- bind_rows(tract_data, bind_rows(recovery_list)) %>%
    distinct(GEOID, .keep_all = TRUE)
}

# ACS completeness checks

states_final   <- unique(str_sub(tract_data$GEOID, 1, 2))
missing_final  <- setdiff(all_state_fips, states_final)
n_duplicates   <- sum(duplicated(tract_data$GEOID))

cat(sprintf("\n── ACS Pull Diagnostics ──────────────────────────────────────────────\n"))
cat(sprintf("Total tracts pulled              : %d\n",   nrow(tract_data))) ## should read 84400
cat(sprintf("Duplicate GEOIDs                 : %d\n",   n_duplicates)) ## should read 0
cat(sprintf("States represented               : %d / %d\n",
            length(states_final), length(all_state_fips))) ## should read States represented: 51 / 51

if (length(missing_final) > 0) {
  stop(paste("ACS pull still incomplete. Missing states:",
             paste(missing_final, collapse = ", ")))
}
if (n_duplicates > 0) {
  stop("Duplicate GEOIDs detected. Inspect tract_data before proceeding.")
}


# Pull Tract Geometries
# Pulled separately from ACS estimates to avoid the tigris cache conflict.
# Per-state tryCatch with automatic one-time retry before hard stop.
tract_geo_list <- list()

for (s in all_state_fips) {
  cat("  Geometry — state:", s, "\n")
  tract_geo_list[[s]] <- tryCatch(
    tracts(state = s, year = 2023, cb = TRUE) %>%
      select(GEOID, geometry),
    error = function(e) {
      cat("  ERROR on state", s, ":", conditionMessage(e), "\n")
      NULL
    }
  )
}

tract_geo <- bind_rows(tract_geo_list)
cat("Total tract geometries pulled:", nrow(tract_geo), "\n") ## should read 84121

# Pre-Join Coverage Check
# ACS-only GEOIDs (in ACS but not in geometry) fall into known special-tract
# categories with zero population and no poverty data:
#   990xxx — standard water-area tracts
#   991xxx — Hawaii water-area variants (island geography)
#   992xxx — coastal water-area variants
#   980xxx — group quarters / institutional population tracts
#
# The regex 9[89][012]\d{3} catches all confirmed patterns. Any ACS-only GEOID
# that does NOT match this pattern triggers a hard stop for investigation.

n_acs_geoids <- n_distinct(tract_data$GEOID)
n_geo_geoids <- n_distinct(tract_geo$GEOID)
n_matched    <- length(intersect(tract_data$GEOID, tract_geo$GEOID))
n_acs_only   <- length(setdiff(tract_data$GEOID, tract_geo$GEOID))
n_geo_only   <- length(setdiff(tract_geo$GEOID, tract_data$GEOID))

cat(sprintf("\n── Pre-Join Coverage Check ───────────────────────────────────────────\n"))
cat(sprintf("ACS GEOIDs                       : %d\n", n_acs_geoids)) ## should read 84400
cat(sprintf("Geometry GEOIDs                  : %d\n", n_geo_geoids)) ## should read 84121
cat(sprintf("Matched GEOIDs                   : %d\n", n_matched)) ## should read 84106
cat(sprintf("In ACS only (no geometry)        : %d\n", n_acs_only)) ## should read 294
cat(sprintf("In geometry only (no ACS)        : %d\n", n_geo_only)) ## should read 15

if (n_acs_only > 0) {
  unmatched_geoids    <- setdiff(tract_data$GEOID, tract_geo$GEOID)
  special_tract_pat   <- "9[89][012]\\d{3}"
  n_special           <- sum(str_detect(unmatched_geoids, special_tract_pat))
  n_unexplained       <- n_acs_only - n_special

  cat(sprintf("  Special/water/group-quarters   : %d\n", n_special))
  cat(sprintf("  Unexplained (no geometry)      : %d\n", n_unexplained))

  if (n_unexplained > 0) {
    problem_geoids <- unmatched_geoids[!str_detect(unmatched_geoids, special_tract_pat)]
    cat("Unexplained unmatched GEOIDs:\n")
    print(problem_geoids)
    stop(paste(
      n_unexplained,
      "non-special ACS tracts have no matching geometry.",
      "Investigate before proceeding."
    ))
  }

  cat("All ACS-only tracts are water-area, coastal, or group quarters tracts.\n")
  cat("None carry poverty data; none will affect the spatial join. Proceeding.\n")
} ### should read: 
#### Special/water/group-quarters   : 294
#### Unexplained (no geometry)      : 0

# Geometry-only GEOIDs (in geometry but not ACS) are uninhabited/water-area
# tracts with no ACS estimates — expected and not cause for concern.

# Join Estimates to Geometry & Compute Poverty Rate
tract_sf_raw <- tract_geo %>%
  left_join(tract_data, by = "GEOID") %>%
  st_as_sf() %>%
  st_transform(crs = 4326)

cat(sprintf("tract_sf_raw rows                : %d\n", nrow(tract_sf_raw)))

tract_sf <- tract_sf_raw %>%
  mutate(
    children_u6_below = below_male_u5E + below_male_5yrE +
                        below_fem_u5E  + below_fem_5yrE,
    children_u6_above = above_male_u5E + above_male_5yrE +
                        above_fem_u5E  + above_fem_5yrE,
    children_u6_total = children_u6_below + children_u6_above,
    # Continuous poverty rate; NA where tract has no children under 6
    pct_poverty_u6    = if_else(
      children_u6_total > 0,
      children_u6_below / children_u6_total,
      NA_real_
    )
  ) %>%
  select(GEOID, pct_poverty_u6, children_u6_total, geometry) %>%
  st_transform(crs = 4326)

cat(sprintf("tract_sf rows                    : %d\n", nrow(tract_sf))) ## should read 84121

# Pull ACS County-Level Controls
# Pulled for all states to ensure coverage for every county in rural_fips,
# including any state that may have rural counties but sparse childcare points.
county_controls <- get_acs(
  geography = "county",
  variables = c(poverty_vars, control_vars),
  year      = 2023,
  survey    = "acs5",
  geometry  = FALSE,
  output    = "wide"
) %>%
  filter(str_sub(GEOID, 1, 2) %in% all_state_fips) %>%
  mutate(
    county_fips           = GEOID,
    children_u6_below_cty = below_male_u5E + below_male_5yrE +
                            below_fem_u5E  + below_fem_5yrE,
    children_u6_above_cty = above_male_u5E + above_male_5yrE +
                            above_fem_u5E  + above_fem_5yrE,
    children_u6_total_cty = children_u6_below_cty + children_u6_above_cty,
    pct_poverty_u6_county = if_else(
      children_u6_total_cty > 0,
      children_u6_below_cty / children_u6_total_cty,
      NA_real_
    ),
    unemployment_rate = if_else(labor_forceE > 0,
                                unemployedE / labor_forceE,
                                NA_real_),
    median_income     = median_incomeE,
    total_pop         = total_popE
  ) %>%
  select(county_fips, pct_poverty_u6_county, unemployment_rate,
         median_income, total_pop)

cat("County controls pulled:", nrow(county_controls), "counties\n") ## should read 3144

# Convert Childcare Points to sf & Spatial Join
childcare_sf <- childcare_rural %>%
  filter(!is.na(longitude), !is.na(latitude)) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)


# st_within assigns each childcare point the poverty attributes of the census
# tract it falls within. Points on tract boundaries may not match; see
# diagnostic output below.
childcare_with_tract <- st_join(childcare_sf, tract_sf, join = st_within)

# Classify Points: Desert Status & Poverty Tiers
childcare_analysis <- childcare_with_tract %>%
  st_drop_geometry() %>%
  mutate(
    is_desert          = adj_supply <= 0.33,
    is_poverty         = !is.na(pct_poverty_u6) & pct_poverty_u6 >= 0.20,
    is_extreme_poverty = !is.na(pct_poverty_u6) & pct_poverty_u6 >= 0.40
  )

# Diagnostic: unmatched points (water areas, edge effects).
# If unmatched share exceeds ~5%, inspect geographically before proceeding.
n_unmatched <- sum(is.na(childcare_analysis$pct_poverty_u6))
cat(sprintf(
  "\nPoints not matched to a tract: %d (%.1f%% of rural points)\n",
  n_unmatched,
  100 * n_unmatched / nrow(childcare_analysis)
))
childcare_analysis %>%
  filter(is.na(pct_poverty_u6)) %>%
  count(state_name, sort = TRUE) %>%
  print()

# County-Level Aggregation
county_summary <- childcare_analysis %>%
  group_by(county_fips, state_name, state_abbrv) %>%
  summarise(
    total_pts             = n(),
    desert_pts            = sum(is_desert,                      na.rm = TRUE),
    poverty_pts           = sum(is_poverty,                     na.rm = TRUE),
    extreme_poverty_pts   = sum(is_extreme_poverty,             na.rm = TRUE),
    desert_poverty_pts    = sum(is_desert & is_poverty,         na.rm = TRUE),
    desert_extreme_pts    = sum(is_desert & is_extreme_poverty, na.rm = TRUE),
    mean_tract_poverty_u6 = mean(pct_poverty_u6,                na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    pct_desert_all     = desert_pts / total_pts,
    pct_desert_poverty = if_else(poverty_pts > 0,
                                 desert_poverty_pts / poverty_pts,         NA_real_),
    pct_desert_extreme = if_else(extreme_poverty_pts > 0,
                                 desert_extreme_pts / extreme_poverty_pts, NA_real_)
  ) %>%
  left_join(
    nchs_df %>% select(county_fips, urb_code, urb_category),
    by = "county_fips"
  ) %>%
  left_join(county_controls, by = "county_fips")


# Summary Table
# Desert rates are pooled across counties (total desert points / total points)
# to avoid small-county bias. Broken out by NCHS rural type x poverty tier.
build_summary_rows <- function(data, group_label) {
  bind_rows(
    data %>%
      summarise(
        Group         = paste(group_label, "\u2014 All children"),
        N_Counties    = n(),
        Total_Points  = sum(total_pts),
        Desert_Points = sum(desert_pts),
        Pct_In_Desert = Desert_Points / Total_Points
      ),
    data %>%
      filter(poverty_pts > 0) %>%
      summarise(
        Group         = paste(group_label, "\u2014 Poverty tracts (\u226520%)"),
        N_Counties    = n(),
        Total_Points  = sum(poverty_pts),
        Desert_Points = sum(desert_poverty_pts),
        Pct_In_Desert = Desert_Points / Total_Points
      ),
    data %>%
      filter(extreme_poverty_pts > 0) %>%
      summarise(
        Group         = paste(group_label, "\u2014 Extreme poverty tracts (\u226540%)"),
        N_Counties    = n(),
        Total_Points  = sum(extreme_poverty_pts),
        Desert_Points = sum(desert_extreme_pts),
        Pct_In_Desert = Desert_Points / Total_Points
      )
  )
}

summary_table <- bind_rows(
  build_summary_rows(county_summary,                         "All rural (NCHS 5\u20136)"),
  build_summary_rows(filter(county_summary, urb_code == 5), "Micropolitan"),
  build_summary_rows(filter(county_summary, urb_code == 6), "Noncore")
) %>%
  mutate(Pct_In_Desert = percent(Pct_In_Desert, accuracy = 0.1))

print(summary_table)

############################################################################################################
############################################################################################################
### SUMMARY TABLE OUTPUT
## Group                                                N_Counties Total_Points Desert_Points Pct_In_Desert
#  <chr>                                                     <int>        <int>         <int> <chr>        
# 1 All rural (NCHS 5–6) — All children                        1949       298504        192328 64.4%        
# 2 All rural (NCHS 5–6) — Poverty tracts (≥20%)               1574       133530         80936 60.6%        
# 3 All rural (NCHS 5–6) — Extreme poverty tracts (≥40%)       1053        56666         31785 56.1%        
# 4 Micropolitan — All children                                 658       184664        111709 60.5%        
# 5 Micropolitan — Poverty tracts (≥20%)                        608        80885         45284 56.0%        
# 6 Micropolitan — Extreme poverty tracts (≥40%)                475        34601         17577 50.8%        
# 7 Noncore — All children                                     1291       113840         80619 70.8%        
# 8 Noncore — Poverty tracts (≥20%)                             966        52645         35652 67.7%        
# 9 Noncore — Extreme poverty tracts (≥40%)                     578        22065         14208 64.4%        
############################################################################################################
############################################################################################################

# Regression
# Unit of analysis : rural county (HRSA Fully FORHP + NCHS codes 5-6)
# Outcome          : pct_desert_all
# Key predictor    : mean_tract_poverty_u6 (continuous, tract-level)
# Controls         : median_income, unemployment_rate, log(total_pop),
#                    urb_category (Micropolitan = reference),
#                    state fixed effects
# Weights          : total_pts
#
# urb_category rationale: Micropolitan and Noncore counties differ systematically
# in population density and market size — both independently shape child care
# supply. Controlling for rurality type isolates the poverty effect from these
# structural baseline differences.
#
# Model form: pct_desert_all is bounded [0,1]. Weighted OLS (linear probability
# model) coefficients represent percentage-point changes in desert rate per unit
# change in each predictor. A beta regression robustness check is included
# (commented out) for comparison.
#
# Coefficient interpretation:
#   mean_tract_poverty_u6 : A 10 pp increase in tract child poverty rate is
#     associated with a [coef * 10] pp change in county desert rate, holding
#     rurality type, income, unemployment, population, and state constant.
#   urb_categoryNoncore   : Desert rate difference for Noncore vs Micropolitan
#     counties, holding all else constant.

reg_data <- county_summary %>%
  filter(
    !is.na(pct_desert_all),
    !is.na(mean_tract_poverty_u6),
    !is.na(median_income),
    !is.na(unemployment_rate),
    !is.na(total_pop),
    total_pop > 0
  ) %>%
  mutate(
    urb_category  = factor(urb_category, levels = c("Micropolitan", "Noncore")),
    state_name    = as.factor(state_name),
    log_total_pop = log(total_pop)
  )

cat(sprintf("\nRegression sample: %d rural counties\n", nrow(reg_data)))

model_ols <- lm(
  pct_desert_all ~ mean_tract_poverty_u6 +
                   median_income          +
                   unemployment_rate      +
                   log_total_pop          +
                   urb_category           +
                   state_name,
  data    = reg_data,
  weights = total_pts
)

cat("\n\u2500\u2500 OLS Regression Results (Weighted, State Fixed Effects) \u2500\u2500\n")
print(summary(model_ols))

# ── Beta Regression Robustness Check (uncomment to run) ──────────────────────
# Preferable when outcome is a proportion strictly bounded (0, 1).
# Requires small-sample adjustment for counties at exactly 0 or 1.
#
# library(betareg)
#
# reg_data_beta <- reg_data %>%
#   filter(pct_desert_all > 0, pct_desert_all < 1) %>%
#   mutate(
#     pct_desert_adj = (pct_desert_all * (total_pts - 1) + 0.5) / total_pts
#   )
#
# model_beta <- betareg(
#   pct_desert_adj ~ mean_tract_poverty_u6 +
#                    median_income          +
#                    unemployment_rate      +
#                    log_total_pop          +
#                    urb_category           +
#                    state_name,
#   data = reg_data_beta
# )
# summary(model_beta)


# ── 14. Maps ──────────────────────────────────────────────────────────────────
#
# Three county-level choropleths (contiguous US):
#   Map 1 : Desert rate — all children in rural counties
#   Map 2 : Desert rate — children in poverty tracts (>= 20%)
#   Map 3 : Desert rate — children in extreme poverty tracts (>= 40%)
#
# Rural counties (HRSA Fully FORHP + NCHS 5-6) shaded by desert rate.
# Non-rural counties shown in light grey.
# Identical fill scale across all three maps for direct visual comparison.
# AK, HI, and PR excluded from the contiguous US base map.

county_geo <- counties(cb = TRUE, year = 2023, resolution = "5m") %>%
  filter(!STATEFP %in% c("02", "15", "72")) %>%
  mutate(GEOID = str_pad(GEOID, width = 5, pad = "0")) %>%
  select(GEOID, geometry)

map_df <- county_geo %>%
  left_join(county_summary, by = c("GEOID" = "county_fips")) %>%
  mutate(
    pct_desert_all     = if_else(GEOID %in% rural_fips, pct_desert_all,     NA_real_),
    pct_desert_poverty = if_else(GEOID %in% rural_fips, pct_desert_poverty, NA_real_),
    pct_desert_extreme = if_else(GEOID %in% rural_fips, pct_desert_extreme, NA_real_)
  )

map_theme <- theme_void(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 13, hjust = 0.5,
                                 margin = margin(b = 4)),
    plot.subtitle = element_text(size = 9.5, hjust = 0.5, color = "grey40",
                                 margin = margin(b = 8)),
    plot.caption  = element_text(size = 7.5, hjust = 0, color = "grey50",
                                 margin = margin(t = 8)),
    legend.position = "right",
    legend.title    = element_text(size = 9),
    legend.text     = element_text(size = 8),
    plot.margin     = margin(10, 10, 10, 10)
  )

fill_scale <- scale_fill_viridis_c(
  option   = "plasma",
  name     = "% in\nDesert",
  labels   = percent_format(accuracy = 1),
  na.value = "grey92",
  limits   = c(0, 1),
  breaks   = seq(0, 1, 0.25)
)

shared_caption <- paste0(
  "Rural: HRSA Fully FORHP Rural + NCHS Micropolitan (5) or Noncore (6). ",
  "Non-rural counties in light grey.\n",
  "Child care desert: adj_supply \u2264 0.33. ",
  "Sources: Child Care Data, HRSA FORHP, NCHS URCS, ACS 2023 5-Year Estimates."
)

map1 <- ggplot(map_df) +
  geom_sf(aes(fill = pct_desert_all), color = NA, linewidth = 0) +
  fill_scale +
  labs(
    title    = "Child Care Desert Rate in Rural Counties",
    subtitle = "% of children under 6 living in a child care desert \u2014 all rural children",
    caption  = shared_caption
  ) +
  map_theme

map2 <- ggplot(map_df) +
  geom_sf(aes(fill = pct_desert_poverty), color = NA, linewidth = 0) +
  fill_scale +
  labs(
    title    = "Child Care Desert Rate: Children in Poverty Tracts (\u226520%)",
    subtitle = "% of children under 6 in tracts with \u226520% child poverty rate living in a desert",
    caption  = shared_caption
  ) +
  map_theme

map3 <- ggplot(map_df) +
  geom_sf(aes(fill = pct_desert_extreme), color = NA, linewidth = 0) +
  fill_scale +
  labs(
    title    = "Child Care Desert Rate: Children in Extreme Poverty Tracts (\u226540%)",
    subtitle = "% of children under 6 in tracts with \u226540% child poverty rate living in a desert",
    caption  = shared_caption
  ) +
  map_theme

print(map1)
print(map2)
print(map3)

ggsave(paste0(path, "map1_desert_all_rural.png"),
       map1, width = 12, height = 7, dpi = 300)
ggsave(paste0(path, "map2_desert_poverty_rural.png"),
       map2, width = 12, height = 7, dpi = 300)
ggsave(paste0(path, "map3_desert_extreme_rural.png"),
       map3, width = 12, height = 7, dpi = 300)

cat("\nAnalysis complete. Maps saved to", path, "\n")
