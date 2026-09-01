# America's Licensed Child Care Deserts in 2025

- **Authors:** Hailey Gibbs and Casey Peeks
- **Organization:** Center for American Progress
- **Published:** April 29, 2026
- **Collaborators:** W.E. Upjohn Institute for Employment Research; Stanford University
- **Researchers**: Aaron Sojourner, Gabrielle Pepin, Katharine Sadowski, Won F. Lee

---

## Overview

This project provides a nationwide analysis of licensed child care supply in the United States as of 2025, updating CAP's original child care deserts methodology first developed in 2016. 
A **child care desert** is defined as any location where more than 3 local young children (under age 6) exist per local licensed child care slot — meaning families have effectively no realistic access to licensed care.

The analysis combines data on licensed provider locations and capacities across all 50 states and Washington, D.C. with population data from the U.S. Census Bureau's American Community Survey. 
Unlike earlier versions of this analysis, which used area-based geographic boundaries (zip codes, counties), this version uses continuous distance-based measures between families and providers to more accurately reflect real-world child care markets.

---

## Key Findings

- **46%** of America's children aged 6 and younger live in a child care desert in 2025, slightly down from 51% in 2018.
- **70%** of children in remote rural areas live in a child care desert — a worsening from 2018 and significantly above the national average.
- An estimated **43.5%** of children under age 6 living in poverty reside in a child care desert, likely due to the impact of means-tested programs geared toward low-income families.
- Desert prevalence ranges from roughly **5%** of young children in Washington, D.C. to **96%** in Alaska.

---

## Data Sources

| Dataset | Source | Notes |
|---|---|---|
| Licensed child care provider locations and capacities | State licensing agencies (all 50 states + D.C.) | Collected 2025 |
| Child population (ages 0–5) | U.S. Census Bureau, American Community Survey 2019–2023 5-Year Estimates | Tract-level |
| Rurality classification | CDC/NCHS Urban-Rural Classification Scheme for Counties | County-level |
| Head Start slot data | HHS Administration for Children and Families | Federal poverty level used to identify eligible children |
| Analysis data (tables and figures) | Authors' analysis, on file with authors | See `data-files` folder |

> **Note:** State licensing thresholds vary considerably — some states require registration for providers caring for even one non-family child, while others allow up to three.
> These differences directly affect which providers appear in state licensing data and influence desert designations. Cross-state comparisons should be made with caution; within-state comparisons are more reliable.


---

## Methodology

Access to child care is measured using **continuous distance** between family residential locations and licensed provider locations, rather than area-based boundaries. A family is counted as living in a child care desert if the ratio of nearby young children to nearby licensed slots exceeds 3:1, weighted by distance.
This approach avoids the arbitrary fragmentation introduced by zip code or county boundaries, which can split local child care markets. The 3:1 threshold is consistent with the definition used in CAP's 2016, 2018, and prior analyses.
Data collection approaches differ slightly between the 2018 and 2025 analyses, and the two analyses reflect different Census periods. Shifts in population and in the licensed provider landscape affect access measures across time. Time-series comparisons should be made with caution.
For full methodology details, see the Appendix of the report.

---

### Requirements

```
tidyverse
dplyr
readr
sf
tigris
```
> **Note:** You will also need to generate a Census API key to make direct edits to tables in R Studio

### Getting the Data

Raw licensing data was collected directly from state licensing agencies and is not redistributed here due to data use considerations. 
To reproduce the analysis, you will need to obtain provider data from each state separately or contact the authors for access to the processed dataset.
Census data can be downloaded from the [Census Bureau ACS 5-Year Estimates](https://www.census.gov/programs-surveys/acs).

### Running the Analysis
- External partners geocoded and analyzed the provider access data, generating access measures for CCC, FCC, preK, and HS (raw data file not available)
- The full data set with the adjusted supply measures is available on the ECP Shared Drive [request access]
- Analyses can be conducted using materials in [data-files]; separate R scripts for each analysis available in [R-scripts]
- The computational threshold for a child care desert is <-0.33

**The report contains the results of these analyses:**
- Child care deserts among Black, non-Hispanic and Hispanic communities
- Head Start deserts (+ breakdowns by rurality)
- Child care deserts in rural communities
- Overal deserts + prevalence rates and scarcity by state
---

## Prior Reports in This Series

- Rasheed Malik and Katie Hamm, [*Mapping America's Child Care Deserts*](https://www.americanprogress.org/article/mapping-americas-child-care-deserts/) (CAP, 2017)
- Early Childhood Policy Team, [*America's Child Care Deserts in 2018*](https://www.americanprogress.org/article/americas-child-care-deserts-2018/) (CAP, 2018)
- Topics page: [*Child Care Deserts Topics Page*](https://www.americanprogress.org/series/child-care-deserts/)

---

## Citations

- Hailey Gibbs and Casey Peeks, "America's Licensed Child Care Deserts" (Washington: Center for American Progress, April 2026), available at https://www.americanprogress.org/article/americas-licensed-child-care-deserts/
- Hailey Gibbs and Casey Peeks, "Executive Summary: America’s Licensed Child Care Deserts," Center for American Progress, April 29, 2026, available at https://www.americanprogress.org/article/executive-summary-americas-licensed-child-care-deserts/
- Hailey Gibbs, Won F. Lee, Gabrielle Pepin, Katharine Sadowski, and Aaron Sojourner, "Measuring America's Licensed Child Care Supply" (Washington, Center for American Progress: 2026), available at https://www.americanprogress.org/article/measuring-americas-licensed-child-care-supply/

---

- View Interactive Web Map: https://www.americanprogress.org/feature/child-care-deserts/

---

## Contact

For questions about the data or methodology, contact the Center for American Progress Early Childhood Policy team.
[Early Childhood Policy @ Center for American Progress](https://www.americanprogress.org/team/early-childhood-policy/)
