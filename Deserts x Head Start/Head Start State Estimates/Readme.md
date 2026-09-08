# Head Start Access Where Other Licensed Care Is Entirely Absent

Analysis of Head Start's role in serving poverty-eligible children under age 6 in U.S. communities where all other forms of licensed child care — family child care (FCC), center-based care (CCC), and Pre-K — are completely absent, broken out by state and rurality.

**Author:** Hailey Gibbs
**File:** `Head Start Alone x State x Rurality.Rmd`
**Output format:** `html_document`

## Overview

Standard child care "desert" measures typically ask whether *any* licensed option — including Head Start — is available. This analysis instead isolates the population for whom Head Start is doing genuinely unique work: poverty-eligible children who live somewhere with **zero** supply of FCC, CCC, and Pre-K, and asks what share of them are reached by Head Start anyway. Results are weighted by an estimated county-level poverty-eligibility rate rather than counted as raw geographic points, and are reported nationally, by state, and by state × rurality.

## Required Input Files

The script expects three CSVs in the working directory (not included in this repo unless you add them):

| File | Contents |
|---|---|
| `poverty_total_and_under5_clean.csv` | Tract-level poverty data. Must include `GEOID` (read as character, to preserve leading zeros) and `pct_poverty_under5`. An under-5 population column (e.g. `total_under5`) is used as a weight if present. |
| childcare_data | Point-level licensed child care access data, on file with the author|
| `joined_rural.csv` | `longitude`, `latitude`, and a `rural` indicator (0/1) for the same point grid. |

## Methodology

**1. County-level poverty rate.** Tract-level `pct_poverty_under5` is aggregated to the county (`county_fips`, first 5 digits of `GEOID`) as a population-weighted mean, using whichever under-5 population column is found in the poverty file. If no such column is found, the script falls back to an unweighted mean and prints a warning — check the console output if you see this, since it means eligibility estimates are not population-weighted for that run.

**2. Merging rurality and poverty onto the access data.** Coordinates are normalized (`((lon + 180) %% 360) - 180`, rounded to 5 decimals) before joining, to protect against longitude sign mismatches near the antimeridian (relevant for Alaska). Poverty rates are merged on zero-padded `county_fips`. Row counts before/after each join are printed so any drop in match rate is visible immediately. Checks performed on AK and HI because of drastic supply shortages, see data note below.

**3. Sample construction.** Puerto Rico (`state_fips` 72) is excluded, along with any row missing a supply value, a matched county poverty rate, or a matched rurality status. A row-count cascade is printed showing exactly how many rows are dropped at each step.

**4. Eligible children and access flags.**
- `eligible_children = 10 × (avg_pct_poverty_under5 / 100)` — each row represents 10 children (per the underlying ACS block-group data), scaled by the estimated county poverty rate.
- `other_all_zero` — TRUE where FCC, CCC, and Pre-K supply are all exactly 0.
- `hs_any` — TRUE where Head Start supply is greater than 0 (this is an *any supply* threshold, not the ≥0.33 "adequate supply" threshold used in earlier versions of this analysis — the two are not interchangeable).
- `hs_any_others_zero` — TRUE where both of the above hold: some Head Start supply, and zero supply of everything else.

**5. Metrics.** Two percentages are reported throughout, and they answer different questions:
- **`pct_of_all_eligible`** — share of *all* poverty-eligible children (regardless of their care situation) who have Head Start-only access. This is the smaller, headline "how common is this overall" number.
- **`pct_of_other_zero_eligible`** — share of poverty-eligible children *already living in a total care desert* who are reached by Head Start. This is the more literal "Head Start rescue rate," and is only defined where `eligible_in_other_zero > 0`.

## Outputs

- Summary tables (printed in the knitted document, and optionally exported as CSV in Section 15): national, by state, by rurality, and by state × rurality.
- Two horizontal bar charts: percentage by state, and percentage by state split by rurality.
- A written interpretation section (Section 14) with the national top-line figures and the highest/lowest states.

## Data Note: Alaska and Hawaii

Non-rural points in Alaska and Hawaii show far more uniform zero supply across all licensed modalities than any other state/rurality group in the country (see Section 6's diagnostic table). This was investigated and ruled out as a coordinate-matching or join artifact — the pattern is present in the raw `adj_supply_*` values themselves. Both states are reported **at face value with no exclusion or special-casing**, on the assessment that this reflects genuine conditions (dispersed, low-infrastructure communities that register as "non-rural" under Census density-based classification without functioning like a mainland urban area, combined with documented child care access constraints specific to both states) rather than a data error. Section 6 is retained purely as informational context for readers evaluating these two states' headline numbers.

## Requirements

R packages: `tidyverse`, `knitr`, `scales`.

# Large File Notice
joined_rural is not loaded into this repository because it exceeds GitHub's file size limit. The underlying file for childcare_data is also not loaded here because the data are proprietary and the file exceeds the size limit.
