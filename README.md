# Replication package

**[European market integration and price convergence: A panel quantile regression analysis of NordLink](https://www.sciencedirect.com/science/article/pii/S0301421526002958)**

Bjørndal, Bjørndal, Hovdahl & Tselika (2026), *Energy Policy*

---

## Overview

This repository contains the code used to produce all tables and figures in the paper. The analysis estimates the impact of NordLink — a subsea cable connecting southern Norway (NO2) to Germany — on the distribution of hourly electricity prices in both markets, using the Method of Moments Quantile Regression (MMQR) of Machado & Santos Silva (2019).

The repository does not include the data. See `DATA_GUIDE.md` for a description of the data sources and how the datasets were constructed. Most
data are freely available from ENTSO-E and NVE; the gas and EUA price series require a paid Bloomberg subscription.

---

## Repository structure

```
├── README.md
├── DATA_GUIDE.md                  ← Data sources and variable construction
│
├── 01_figures_timeseries.py       ← Fig 1, Fig 2, App. Fig A1, App. Fig A2
├── 02_tables_descriptive.py       ← Table 1, App. Table A2
├── 03_estimation_mmqr.do          ← Table 3, App. Table A3, Fig 3, Fig 4, Fig 5
├── 04_estimation_interactions.do  ← Table 4
├── 05_estimation_spread.do        ← App. Table A4, Fig 6 (spread panel)
├── 06_robustness.do               ← App. Fig A3, App. Fig A4
├── 07_diagnostics.do              ← App. Table A1
│
├── data/                          ← Place data_NO2.dta, data_DE.dta, data_spread.dta here
│                                     
└── output/
    ├── tables/                    ← Generated tables (.tex, .log)
    └── graphs/                    ← Generated figures (.png)
```

---

## Requirements

### Python

The two Python scripts require Python 3 with the following libraries: `pandas`, `matplotlib`, and `scipy`. All are available via `pip` or `conda`.

### Stata

The do files were written for Stata 16 or later. The following user-written packages are required and can be installed from SSC:

```stata
ssc install mmqreg
ssc install hdfe
ssc install ftools
ssc install outreg2
ssc install estout
ssc install xtcdf
```

---

## How to run

1. Clone the repository and place the three datasets (`data_NO2.dta`, `data_DE.dta`, `data_spread.dta`) in the `data/` folder. See `DATA_GUIDE.md` for instructions on how to construct these files.

2. Create the output directories if they do not exist: `output/tables/` and `output/graphs/`.

3. In each do file, set the working directory by editing the line:
   ```stata
   cd "EDIT_THIS_PATH"
   ```

4. The Python scripts can be run independently:
   ```
   python 01_figures_timeseries.py
   python 02_tables_descriptive.py
   ```

---

## Output files

| Script | Output file | Paper location |
|---|---|---|
| `01_figures_timeseries.py` | `fig01_price_plot.png` | Figure 1 |
| `01_figures_timeseries.py` | `fig02_drivers.png` | Figure 2 |
| `01_figures_timeseries.py` | `figA1_fundamentals_no2.png` | App. Figure A1 |
| `01_figures_timeseries.py` | `figA2_fundamentals_de.png` | App. Figure A2 |
| `02_tables_descriptive.py` | `tab01_stats_price.tex` | Table 1 |
| `02_tables_descriptive.py` | `tabA2_mean_values.tex` | App. Table A2 |
| `03_estimation_mmqr.do` | `tab_mmqr_no2.tex` | Table 3, App. Table A3 (NO2) |
| `03_estimation_mmqr.do` | `tab_mmqr_de.tex` | Table 3, App. Table A3 (Germany) |
| `03_estimation_mmqr.do` | `fig03_nordlink_quantiles_no2.png` | Figure 3 (left) |
| `03_estimation_mmqr.do` | `fig03_nordlink_quantiles_de.png` | Figure 3 (right) |
| `03_estimation_mmqr.do` | `fig04_*.png` | Figure 4 |
| `03_estimation_mmqr.do` | `fig05_*.png` | Figure 5 |
| `04_estimation_interactions.do` | `tab04_interactions.tex` | Table 4 |
| `05_estimation_spread.do` | `tabA4_spread.tex` | App. Table A4 |
| `05_estimation_spread.do` | `fig06_nordlink_spread.png` | Figure 6 (right panel) |
| `06_robustness.do` | `figA3_robustness_no2_*.png` | App. Figure A3 |
| `06_robustness.do` | `figA4_robustness_de_*.png` | App. Figure A4 |
| `07_diagnostics.do` | `tabA1_diagnostics.log` | App. Table A1 |

---

## Reference

Machado, J.A.F. & Santos Silva, J.M.C. (2019). Quantiles via moments. *Journal of Econometrics*, 213(1), 145–173.
