####################################################
## ChildCare Deserts x Congressional District (CD)
## Hailey Gibbs // Apr 2026
###################################################

#Load child care data: CCD full file
childcare_data<-read.csv("cap_ccaccess_2025_revised_02282026.csv") #saved in Drive, linked in GitHub

#Load libraries
library(tidyverse)
library(sf)
library(tigris)

options(tigris_use_cache = TRUE)

##Download CD shapefile
cd_shapes_119 <- congressional_districts(cb = TRUE, year = 2024)

# Check what year tigris actually returned
attr(cd_shapes_119, "tigris")   # confirms the vintage
names(cd_shapes_119)

# How many districts?
nrow(cd_shapes_119)             # should be 435 + territories (441)

cd_shapes_119_filtered <- cd_shapes_119 %>%
  filter(STATEFP %in% c(sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56)), "11"))
nrow(cd_shapes_119_filtered)   # should be 436 (50 states + DC)

# Transform CD shapes to WGS84
cd_shapes <- st_transform(cd_shapes_119_filtered, crs = 4326)

##Convert to SF
df_sf <- childcare_data %>%
  filter(state_abbrv != "PR") %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# SPATIAL JOIN
df_joined <- st_join(df_sf, cd_shapes[, c("GEOID", "NAMELSAD", "STATEFP", "CD119FP")],
                     join = st_within)

#Check for unmatched points (fell outside district boundaries)
st_crs(df_sf) == st_crs(cd_shapes)   # should return TRUE
sum(is.na(df_joined$GEOID)) 
#should be 600 -- these are 0.027% of total data, but we can apply a nearest join function to keep these in the set

# Isolate unmatched points
unmatched <- df_joined %>% filter(is.na(GEOID))

# Find the nearest CD for each unmatched point
nearest_idx <- st_nearest_feature(unmatched, cd_shapes)

# Assign the nearest CD attributes to those points
unmatched_fixed <- unmatched %>%
  mutate(
    GEOID    = cd_shapes$GEOID[nearest_idx],
    NAMELSAD = cd_shapes$NAMELSAD[nearest_idx],
    STATEFP  = cd_shapes$STATEFP[nearest_idx],
    CD118FP  = cd_shapes$CD118FP[nearest_idx]
  )

# Recombine with matched points
df_joined_clean <- df_joined %>%
  filter(!is.na(GEOID)) %>%
  bind_rows(unmatched_fixed)

# Verify no NAs remain
sum(is.na(df_joined_clean$GEOID))   # should be 0

######## CALCULATING DESERTS BY CD
cd_desert_estimates <- df_joined_clean %>%
  st_drop_geometry() %>%
  mutate(is_desert = adj_supply <= 0.33) %>%
  group_by(GEOID, NAMELSAD, STATEFP) %>%
  summarise(
    total_children  = n() * 10,
    desert_children = sum(is_desert) * 10,
    pct_in_desert   = desert_children / total_children * 100,
    .groups = "drop"
  ) %>%
  arrange(desc(pct_in_desert))

# Quick sanity checks
nrow(cd_desert_estimates)          # should be ~435 (435 CDs + some territories)
summary(cd_desert_estimates$pct_in_desert)
head(cd_desert_estimates, 10)      # highest desert districts
tail(cd_desert_estimates, 10)      # lowest desert districts

### IF PR LEFT IN ######### SHOULD HAVE BEEN FILTERED OUT ABOVE, BUT RUNNING A CHECK
# Check for duplicate GEOIDs
cd_desert_estimates %>%
  count(GEOID) %>%
  filter(n > 1)

# Check for any unexpected state abbreviations
sort(unique(cd_desert_estimates$STATEFP))

cd_desert_estimates <- cd_desert_estimates %>%
  filter(STATEFP != "72")

# Verify
nrow(cd_desert_estimates)                    # should be 436
sort(unique(cd_desert_estimates$STATEFP))    # confirm 72 is gone
############

## CHANGING STATE FP TO STATE ABBRV
state_lookup <- childcare_data %>%
  distinct(state_fips, state_abbrv) %>%
  mutate(STATEFP = sprintf("%02d", state_fips))  # pad to match STATEFP format

# Join abbreviations into final results
cd_desert_estimates <- cd_desert_estimates %>%
  left_join(state_lookup, by = "STATEFP") %>%
  select(GEOID, NAMELSAD, state_abbrv, total_children, desert_children, pct_in_desert) %>%
  arrange(desc(pct_in_desert))

## EXPORT TO CSV
write.csv(cd_desert_estimates, "cd_desert_estimates.csv", row.names = FALSE)

##################################
## CREATE CHOROPLETH MAP BY CD
##################################

install.packages("ggplot2")  # skip if already installed
library(ggplot2)

# Join estimates to spatial shapes
cd_map <- cd_shapes_119_filtered %>%
  left_join(cd_desert_estimates, by = "GEOID")

# Plot
ggplot(cd_map) +
  geom_sf(aes(fill = pct_in_desert), color = NA) +
  scale_fill_viridis_c(
    option    = "magma",
    direction = -1,
    name      = "% Children\nin Desert",
    limits    = c(0, 100),
    breaks    = seq(0, 100, by = 25)
  ) +
  labs(
    title    = "Children Under 6 Living in Child Care Deserts",
    subtitle = "By Congressional District (119th Congress)",
    caption  = "A child care desert is defined as adj_supply ≤ 0.33"
  ) +
  theme_void() +
  theme(
    plot.title    = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    plot.caption  = element_text(size = 8, hjust = 0.5),
    legend.position = "bottom",
    legend.key.width = unit(2, "cm")
  )

# Save the map
ggsave("cd_desert_map.png", width = 12, height = 7, dpi = 300)

######### ######### ######### ######### ######### ######### ######### ######### 
######### MAP TINY, REFORMATTING WITH TOOLTIPS ####
install.packages(c("leaflet", "leaflet.extras"))
library(leaflet)
library(leaflet.extras)

# Step 1: Join estimates back to spatial shapes
cd_map <- cd_shapes_119_filtered %>%
  left_join(
    cd_desert_estimates %>% select(-NAMELSAD),
    by = "GEOID"
  ) %>%
  filter(STATEFP != "72")

# Step 2: Define color palette
pal <- colorNumeric(
  palette = "magma",
  domain  = c(0, 100),
  reverse = TRUE
)

# Step 3: Build tooltip text
cd_map <- cd_map %>%
  mutate(tooltip = paste0(
    "<b>", NAMELSAD, "</b><br>",
    "State: ", state_abbrv, "<br>",
    "% in Desert: ", round(pct_in_desert, 1), "%<br>",
    "Children in Desert: ", scales::comma(desert_children), "<br>",
    "Total Children: ", scales::comma(total_children)
  ))

# Verify columns look clean
names(cd_map)
nrow(cd_map)  # should be 436

#### GO BACK AND RE-RUN TOOLTIP FUNCTION
cd_map <- st_transform(cd_map, crs = 4326)

# Step 4: Build the map
leaflet(cd_map) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor   = ~pal(pct_in_desert),
    fillOpacity = 0.8,
    color       = "white",
    weight      = 0.5,
    opacity     = 1,
    label       = lapply(cd_map$tooltip, htmltools::HTML),
    labelOptions = labelOptions(
      style     = list("font-weight" = "normal", padding = "3px 8px"),
      textsize  = "13px",
      direction = "auto"
    ),
    highlightOptions = highlightOptions(
      weight      = 2,
      color       = "#666",
      fillOpacity = 0.9,
      bringToFront = TRUE
    )
  ) %>%
  addLegend(
    pal      = pal,
    values   = ~pct_in_desert,
    opacity  = 0.8,
    title    = "% Children<br>in Desert",
    position = "bottomright"
  ) %>%
  setView(lng = -96, lat = 37.8, zoom = 4)  # centered on contiguous US

#################################
### TO EXPORT WITH TOOLTIP FEATURE 
################################

install.packages("htmlwidgets")  # skip if already installed
library(htmlwidgets)

# Assign the leaflet map to a variable
map <- leaflet(cd_map) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor   = ~pal(pct_in_desert),
    fillOpacity = 0.8,
    color       = "white",
    weight      = 0.5,
    opacity     = 1,
    label       = lapply(cd_map$tooltip, htmltools::HTML),
    labelOptions = labelOptions(
      style     = list("font-weight" = "normal", padding = "3px 8px"),
      textsize  = "13px",
      direction = "auto"
    ),
    highlightOptions = highlightOptions(
      weight       = 2,
      color        = "#666",
      fillOpacity  = 0.9,
      bringToFront = TRUE
    )
  ) %>%
  addLegend(
    pal      = pal,
    values   = ~pct_in_desert,
    opacity  = 0.8,
    title    = "% Children<br>in Desert",
    position = "bottomright"
  ) %>%
  setView(lng = -96, lat = 37.8, zoom = 4)

# Export as self-contained HTML
saveWidget(map, "cd_desert_map.html", selfcontained = TRUE)
