## State Tests for Rurality
### NOTE -- APPLIED AFTER FULL RURAL SCRIPT HAS BEEN RUN
desert_by_state <- joined_rural %>%
  filter(!is.na(urb_code)) %>%
  group_by(state_name, urb_code, urb_category) %>%
  summarise(
    total_obs = n(),
    desert_count = sum(adj_supply < 0.33, na.rm = TRUE),
    pct_desert = (desert_count / total_obs) * 100,
    .groups = "drop"
    ) %>%
  arrange(state_name, urb_code)

write_csv(desert_by_state, "desert_by_state.csv")