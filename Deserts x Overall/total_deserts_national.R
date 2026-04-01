## CALCULATING TOTAL DESERTS, NATIONAL
library(tidyverse)
desert_threshold<-0.33
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