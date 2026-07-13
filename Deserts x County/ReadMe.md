# Child Care Deserts × Counties
- Author: Hailey Gibbs
- Last updated: May 2026

This folder contains the code and output data for a county-level analysis of licensed child care deserts across the United States, using the Center for American Progress's child care access dataset.

---

The analysis classifies census points as being in a **child care desert** if their adjusted supply score (`adj_supply`) is at or below 0.33 — meaning there are at least three children for every available licensed child care slot in that area. 
- It then aggregates those points to the county level to estimate how many young children live in a child care desert in each county.
- Connecticut is handled separately. Because Connecticut replaced its eight counties with nine planning regions as official county-equivalents in 2022, this analysis uses a spatial join to assign data points to the correct planning regions rather than the deprecated county boundaries.
- Puerto Rico and U.S. territories are excluded from all summary statistics and map outputs.

**The national headline figures from this analysis:**
| Affected Children | Statistic |
|---|---|
| Total children represented | 22,681,150
| Children in child care deserts | 10,342,090
| Share in a child care desert | 45.6%

---

**Files in This Folder**
childcare_desert_analysis.Rmd | R Markdown file containing the full analysis: county aggregation, CT planning region fix, national summary statistics, and the interactive leaflet map |
ccd_by_counties.csv | Output table with desert estimates for every county and CT planning region |
cap_ccaccess_2025_revised_02282026.csv` | Source data from the Center for American Progress (CCD full file) |

## ⚠️ Large File Notice
joined_rural.csv exceeds GitHub's file size limit and is **not included in this repository**. It can be downloaded here:
🔗 [joined_rural.csv on Google Drive](https://drive.google.com/file/d/17-cLCuDMT-M9Iujmw4yHfhYeasQr7J7R/view?usp=sharing)

**Data Source**

Center for American Progress — *Child Care Access Dataset*, 2025 revision (February 2026). This file also exceeds GitHub's size limit and is linked in the ReadMe in #main.
Each row in the source data represents approximately 10 children. Desert status is determined at the point level and then aggregated to the county or planning region level.
