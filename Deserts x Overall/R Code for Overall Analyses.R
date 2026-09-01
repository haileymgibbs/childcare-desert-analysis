# Child Care Desert Estimates
# Hailey Gibbs
# May 2026

# ---- Setup ----

library(tidyverse)

desert_threshold <- 0.33

childcare_data <- read_csv("cap_ccaccess_2025_revised_02282026.csv")

# ---- National / Overall Estimates ----

national_desert_rate <- childcare_data %>%
  filter(!is.na(adj_supply)) %>%
  mutate(
    desert = adj_supply <= desert_threshold
  ) %>%
  summarise(
    total_children  = n() * 10,
    desert_children = sum(desert) * 10,
    pct_desert      = round(mean(desert) * 100, 1)
  )

print(national_desert_rate)

# ---- State Estimates ----

# -- Desert Rate by State --

desert_by_state <- childcare_data %>%
  mutate(in_desert = adj_supply <= desert_threshold) %>%  # Fixed: was < 0.33
  group_by(state_name) %>%
  summarise(
    total_children     = n(),
    children_in_desert = sum(in_desert, na.rm = TRUE),
    percent_in_desert  = (children_in_desert / total_children) * 100,
    mean_adj_supply    = mean(adj_supply, na.rm = TRUE)
  ) %>%
  arrange(desc(percent_in_desert))

view(desert_by_state)

# -- Desert and Low Supply Comparison by State --

desert_comparison <- childcare_data %>%
  group_by(state_name) %>%
  summarise(
    total_children  = n(),
    pct_zero_supply = (sum(adj_supply == 0,    na.rm = TRUE) / n()) * 100,
    pct_low_supply  = (sum(adj_supply <  0.1,  na.rm = TRUE) / n()) * 100,
    pct_desert      = (sum(adj_supply <= 0.33, na.rm = TRUE) / n()) * 100,  # Fixed: was < 0.33
    mean_supply     = mean(adj_supply, na.rm = TRUE)
  ) %>%
  arrange(desc(pct_desert))

view(desert_comparison)
write_csv(desert_comparison, "deserts_comparison.csv")  # Fixed: was write_csv(df, ...)

# ---- Deserts by Care Type ----

national_desert_rates <- childcare_data %>%
  mutate(
    desert_hs   = adj_supply_hs   <= desert_threshold,
    desert_prek = adj_supply_prek <= desert_threshold,
    desert_fcc  = adj_supply_fcc  <= desert_threshold,
    desert_ccc  = adj_supply_ccc  <= desert_threshold,
    desert_any  = adj_supply      <= desert_threshold
  ) %>%
  summarise(
    total_children      = n() * 10,
    `Overall`           = round(mean(desert_any,  na.rm = TRUE) * 100, 1),
    `Head Start`        = round(mean(desert_hs,   na.rm = TRUE) * 100, 1),
    `Pre-K`             = round(mean(desert_prek, na.rm = TRUE) * 100, 1),
    `Family Child Care` = round(mean(desert_fcc,  na.rm = TRUE) * 100, 1),
    `Child Care Center` = round(mean(desert_ccc,  na.rm = TRUE) * 100, 1)
  )

print(national_desert_rates)
