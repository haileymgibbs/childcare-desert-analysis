# **Child Care Deserts × Head Start Eligibility**
- Authors: Hailey Gibbs and Evan Yi  
- Last updated April 2026

This folder contains the code and input data for an analysis of Head Start child care deserts, with a focus on how desert status varies by rurality.

---

**What This Analysis Does**
The analysis estimates what share of Head Start-eligible children — defined as children under five living in poverty — live in a **Head Start child care desert**, meaning their area has an adjusted Head Start supply score (`adj_supply_hs`) at or below 0.33.

It proceeds in three steps:

1. National eligibility estimate: Calculates the total number of poverty-eligible children and the share living in a Head Start desert across all areas with complete data.

2. Breakdown by rurality: Repeats the eligibility estimate separately for rural and non-rural areas, given that desert rates for Head Start are notably high overall.

3. Degree of scarcity by rurality: Examines the distribution of supply more granularly, distinguishing between areas with no Head Start supply at all, areas with some supply that still qualify as deserts, and areas that are not deserts — broken down by rural status.

Poverty eligibility is estimated by applying each county's share of children under five living in poverty to the synthetic population represented in the child care access data (each row represents approximately 10 children). Rurality is joined to the child care data by geographic coordinates using `joined_rural.csv`.

---

| Files in This Folder | Input Data |
| CCD_x_Head_Start_Analyses.Rmd | R Markdown file containing the full analysis |
| cap_ccaccess_2025_revised_02282026.csv | Child care access data from the Center for American Progress (CCD full file, 2025 revision) | 
| poverty_total_and_under5_clean.csv | County-level poverty rates for children under five, used to estimate Head Start eligibility |

# ⚠️ Large File Notice

`joined_rural.csv` exceeds GitHub's file size limit and is **not included in this repository**. It can be downloaded here:
🔗 [joined_rural.csv on Google Drive](https://drive.google.com/file/d/17-cLCuDMT-M9Iujmw4yHfhYeasQr7J7R/view?usp=sharing)

**Data Sources**
Center for American Progress — Child Care Access Dataset, 2025 revision (February 2026). Each row represents approximately 10 children.
⚠️ Large File Notice | this file also exceeds GitHub's file size limit and is **not included in this repository**. It can be downloaded from the Drive (link in the #main)
U.S. Census Bureau — Poverty estimates for children under five, cleaned and compiled in `poverty_total_and_under5_clean.csv`.
Rurality classifications — Joined by geographic coordinates via `joined_rural.csv`.
