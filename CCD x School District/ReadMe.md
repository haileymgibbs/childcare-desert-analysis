# Child Care Desert Estimates by School District

This repository estimates the prevalence of "child care deserts" — areas where the
supply of licensed child care is too low relative to the number of children who need
it — at the national, state, and school district level, using synthetic point-level
child care access data.

The core analysis lives in [`ccd_by_school_district.Rmd`](./ccd_by_school_district.Rmd).

## Data

Each row in this file represents a lat/long point corresponding to **10 synthetic
children**, along with an `adj_supply` value (adjusted child care supply relative to
demand at that point) and care-type-specific supply columns:

- `adj_supply_hs` — Head Start
- `adj_supply_prek` — Pre-K
- `adj_supply_fcc` — Family Child Care
- `adj_supply_ccc` — Child Care Center

School districts are identified by the combination of `state_name`,
`schooldistrict_code`, and `sd_name`, since district codes are only guaranteed to be
unique *within* a state, not nationally.

> **Note:** This data file is not included in the repository and on file with the author

## Methodology

### Desert definition

A point is classified as a "child care desert" when its adjusted supply falls at or
below a threshold:

```r
desert_threshold <- 0.33
```

This threshold is a parameter set at the top of the script and can be adjusted.

### Scaling to children

Because each row represents 10 synthetic children, all child counts in the analysis
multiply row counts by 10 (`n() * 10`) rather than counting rows directly.

### Low-sample flagging

District-level estimates built from a small number of underlying lat/long points are
statistically less reliable. Districts with fewer than a set number of points are
flagged rather than dropped:

```r
low_sample_n_points <- 5   # districts with fewer than this many lat/long points
                            # (i.e. < 50 synthetic children) are flagged as low_sample
```

Both district-level output tables include an `n_points` column and a `low_sample`
boolean flag so these districts remain visible. Whether to exclude, footnote, or
otherwise treat `low_sample == TRUE` rows is left to the downstream use case (e.g. a
public-facing map vs. an internal table).

### Population-weighted roll-ups

District-level `percent_in_desert` and care-type figures are already
population-correct *within* each district (every row = 10 children). However, naively
averaging district-level percentages up to the state or national level would give a
tiny district equal weight to a large one, inflating estimates because small/rural
districts skew toward higher desert rates.

To address this, the script rolls district-level estimates up to the state and
national level two ways:

- **Weighted** (`pct_desert_weighted`) — weighted by each district's total children;
  this is the correct summary statistic.
- **Unweighted** (`pct_desert_unweighted`) — a plain average across districts,
  included only to illustrate the size of the distortion versus the weighted figure.

The weighted national/state roll-ups computed from the district-level file are also
used as a consistency check against the estimates computed directly from the raw
point-level data.

## Analysis sections

The R Markdown file proceeds through the following sections, in order:

1. **Setup** — loads libraries, sets the desert threshold and low-sample cutoff, and
   reads the input data.
2. **National / Overall Estimates** — total children, children in a desert, and the
   overall national desert rate.
3. **State Estimates**
   - Desert rate by state.
   - A comparison of desert rate against zero-supply and low-supply (<0.1) rates by
     state, exported to `deserts_comparison.csv`.
4. **Deserts by Care Type** — national desert rates broken out by Head Start, Pre-K,
   Family Child Care, and Child Care Center supply, in addition to the overall rate.
5. **School District Estimates**
   - Desert rate by school district (with `n_points` / `low_sample`), exported to
     `deserts_by_district.csv`.
   - Desert rate by care type, by school district, exported to
     `deserts_by_district_caretype.csv`.
   - Population-weighted national and state roll-ups computed from the district-level
     tables (both overall and by care type), with the state roll-up exported to
     `deserts_by_state_from_districts.csv`.

## Output files

Running the full R Markdown file produces the following CSVs in the project root:

| File | Description |
|---|---|
| `deserts_by_district.csv` | District-level desert rates, sample size, and low-sample flag |
| `deserts_by_district_caretype.csv` | District-level desert rates by care type |
| `deserts_by_state_from_districts.csv` | State-level roll-ups (weighted and unweighted) built from district estimates |

## Requirements

- R with the [tidyverse](https://www.tidyverse.org/) package installed.
- The input CSV (`cap_ccaccess_2025_revised_02282026.csv`) placed in the project root.

## Usage

Open `ccd_by_school_district.Rmd` in RStudio (or another R Markdown-capable editor)
and knit to HTML, or run from the command line:

```r
rmarkdown::render("ccd_by_school_district.Rmd")
```

## Author

Hailey Gibbs, August 2026
