## NATIONAL DESERT RATES BY CARE TYPE
library(tidyverse)
desert_threshold<-0.33
national_desert_rates <- childcare_data %>%
  mutate(
    desert_hs   = adj_supply_hs   <= desert_threshold,
    desert_prek = adj_supply_prek <= desert_threshold,
    desert_fcc  = adj_supply_fcc  <= desert_threshold,
    desert_ccc  = adj_supply_ccc  <= desert_threshold,
    desert_any  = adj_supply      <= desert_threshold
    ) %>%
  summarise(
    total_children         = n() * 10,
    `Overall`              = round(mean(desert_any,  na.rm = TRUE) * 100, 1),
    `Head Start`           = round(mean(desert_hs,   na.rm = TRUE) * 100, 1),
    `Pre-K`                = round(mean(desert_prek, na.rm = TRUE) * 100, 1),
    `Family Child Care`    = round(mean(desert_fcc,  na.rm = TRUE) * 100, 1),
    `Child Care Center`    = round(mean(desert_ccc,  na.rm = TRUE) * 100, 1)
    )
print(national_desert_rates)