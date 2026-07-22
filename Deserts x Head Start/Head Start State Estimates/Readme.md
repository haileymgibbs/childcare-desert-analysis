# Head Start Deserts and No-Supply Areas by State and Rurality

This repository contains an R Markdown analysis that identifies **Head Start "deserts"** (areas with very low Head Start supply relative to need, as determined by child poverty status) and **no-supply areas** (areas with zero Head Start capacity), broken out nationally, by state, and by rural/urban status.

## Overview

The analysis combines child poverty data, Head Start childcare access data, and rurality classifications at the county level to estimate the share of poverty-eligible children under age 5 who live in a Head Start desert or in an area with no Head Start supply at all.

A **Head Start desert** is defined as a county where adjusted Head Start supply (`adj_supply_hs`) is at or below a threshold of **0.33** relative to qualifying young children by federal poverty status. A **no-supply area** is a county where adjusted supply is exactly **0**.

## Data Sources

| File | Description |
|---|---|
| `poverty_total_and_under5_clean.csv` | Tract-level poverty data, including percent of children under 5 in poverty (`pct_poverty_under5`), aggregated to county level for this analysis. |
| `cap_ccaccess_2025_revised_02282026.csv` | County-level Head Start / childcare access data, including adjusted Head Start supply (`adj_supply_hs`) and state identifiers (`state_name`, `state_abbrv`). |
| `joined_rural.csv` | Latitude/longitude-based lookup used to classify each location as rural or urban (`rural`). |

> **Note:** Each row in the childcare access data represents a synthetic cohort of 10 children. `eligible_children` scales that cohort by the county's under-5 poverty rate to estimate poverty-eligible children per row.

## Methodology

1. **Load data** — Read in poverty, childcare access, and rurality datasets.
2. **Clean poverty data** — Aggregate tract-level poverty rates up to the county level (via 5-digit county FIPS).
3. **Join datasets** — Merge childcare access data with county-level poverty rates and with rurality classification (matched on latitude/longitude).
4. **Compute flags** — Drop rows with missing supply, poverty, or rurality data, then compute:
   - `eligible_children`: estimated poverty-eligible children under 5 per row
   - `hs_desert`: flag for Head Start desert (`adj_supply_hs <= 0.33`)
   - `hs_no_access`: flag for zero Head Start supply (`adj_supply_hs == 0`)
5. **Restrict to 50 states + DC** — Filter out U.S. territories using a state FIPS crosswalk (used only to validate FIPS codes, since `state_name`/`state_abbrv` already exist in the source data).
6. **Summarize** — Build three summary tables (see below).
7. **Export** — Write summary tables out to CSV.

## Outputs

The analysis produces three summary tables, each exported as a CSV:

| Table | Grouping | Output File |
|---|---|---|
| Table 1 | National, by rurality (Rural vs. Urban) | `hs_national_by_rurality.csv` |
| Table 2 | By state (alphabetical) | `hs_by_state.csv` |
| Table 3 | By state and rurality | `hs_by_state_rurality.csv` |

Each table reports, per group:
- `total_eligible_children` — total estimated poverty-eligible children under 5
- `desert_eligible_children` — eligible children living in a Head Start desert
- `no_access_eligible_children` — eligible children with zero Head Start supply
- `pct_eligible_in_desert` — % of eligible children in a Head Start desert
- `pct_eligible_no_access` — % of eligible children with no Head Start access

## Large File Alert
- joined_rural.csv and cap_ccaccess_2025_revised_02282026.csv exceed GitHub's file size limit and are not available in this repository.

## Repository Structure

```
.
├── head_start_deserts.Rmd          # Main analysis
├── poverty_total_and_under5_clean.csv
├── cap_ccaccess_2025_revised_02282026.csv
├── joined_rural.csv
├── hs_national_by_rurality.csv     # Output
├── hs_by_state.csv                 # Output
├── hs_by_state_rurality.csv        # Output
└── README.md
```

## Notes & Caveats

- The `desert_threshold` (0.33) is a configurable parameter set at the top of the R Markdown file and can be adjusted to test different definitions of a "desert."
- Rows missing supply, poverty, or rurality data are dropped prior to analysis; the script prints diagnostic counts of matched vs. unmatched rows during the rural join step.
- Only the 50 states and the District of Columbia are included; U.S. territories are excluded.
