## DESERTS BY STATE
desert_threshold <- 0.33
desert_by_state <- childcare_data %>%
  mutate(in_desert = adj_supply < desert_threshold) %>%
  group_by(state_name) %>%
  summarise(
    total_children = n(),
    children_in_desert = sum(in_desert, na.rm = TRUE),
    percent_in_desert = (children_in_desert / total_children) * 100,
    mean_adj_supply = mean(adj_supply, na.rm = TRUE)
    ) %>%
  arrange(desc(percent_in_desert))
view(desert_by_state)

## DESERTS / LOW SUPPLY BY STATE
desert_comparison<-childcare_data%>%
  group_by(state_name)%>%
  summarise(
    total_children=n(),
    pct_zero_supply=(sum(adj_supply==0,na.rm=TRUE)/n())*100,
    pct_low_supply=(sum(adj_supply<0.1,na.rm=TRUE)/n())*100,
    pct_desert=(sum(adj_supply<0.33,na.rm=TRUE)/n())*100,
    mean_supply=mean(adj_supply,na.rm=TRUE)
    )%>%
  arrange(desc(pct_desert))
view(desert_comparison)
write_csv(df, "deserts_comparison.csv")