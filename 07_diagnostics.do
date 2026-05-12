/* ==========================================================================
   07_diagnostics.do
   ==========================================================================
   Runs cross-sectional dependence and panel unit root tests for all
   variables used in the baseline model, reported in Appendix Table A1 of:

       Bjørndal, Bjørndal, Hovdahl & Tselika (2026)
       "European market integration and price convergence:
        A panel quantile regression analysis of NordLink"
       Energy Policy

   Tests conducted
   ---------------
   Cross-sectional dependence : Pesaran (2004) CD test via xtcdf
   Panel unit root            : Breitung & Das (2005) test via xtunitroot,
                                with 5 lags and robust standard errors

   Output
   ------
   The test statistics are printed to the Stata console and saved to:
   output/tables/tabA1_diagnostics.log

   Read the statistics from the log file to populate Appendix Table A1.
   The table in the paper was assembled manually from the console output;
   no automated table export is produced as the test commands do not
   support direct export to .tex.


   Input data
   ----------
   data_NO2.dta : panel data for NO2
   data_DE.dta  : panel data for Germany

   Required packages (install once, lines commented out after first use)
   -----------------------------------------------------------------------
   *ssc install xtcdf
   ========================================================================== */


/* --------------------------------------------------------------------------
   Setup
   -------------------------------------------------------------------------- */
clear all

* Set working directory to the folder containing this do-file and the data
* Edit this path before running
cd "EDIT_THIS_PATH"

* Open log file to capture all test output
log using "output/tables/tabA1_diagnostics.log", replace text


/* ==========================================================================
   PART 1: NO2
   ========================================================================== */

use data/data_NO2.dta, clear

/* Note: wind has three missing observations (one per year at the hour when
   clocks go back: 2018-10-28 01:00, 2019-10-27 01:00, 2020-10-25 01:00).
   The Breitung & Das unit root test requires a strongly balanced panel, so
   all observations on these three dates are dropped before running any test.
   This affects 72 observations (3 dates x 24 hours). */
drop if inlist(date, "2018-10-28", "2019-10-27", "2020-10-25")

encode date, gen(date1)
xtset hour date1


/* --------------------------------------------------------------------------
   Cross-sectional dependence tests, NO2
   H0: cross-section independence
   -------------------------------------------------------------------------- */
display as text _newline "=== NO2: Cross-sectional dependence (Pesaran 2004 CD) ==="

xtcdf price
xtcdf load
xtcdf wind


/* --------------------------------------------------------------------------
   Panel unit root tests, NO2
   H0: panels contain unit roots (non-stationary)
   -------------------------------------------------------------------------- */
display as text _newline "=== NO2: Panel unit root (Breitung & Das 2005), 5 lags ==="

xtunitroot breitung price, lags(5) robust
xtunitroot breitung load,  lags(5) robust
xtunitroot breitung wind,  lags(5) robust


/* ==========================================================================
   PART 2: Germany
   ========================================================================== */

use data/data_DE.dta, clear

/* Note: load has one missing observation (2018-10-28 01:00, when clocks go
   back). The Breitung & Das test requires a strongly balanced panel, so all
   observations on this date are dropped before running any test. This
   affects 24 observations. */
drop if date == "2018-10-28"

encode date, gen(date1)
xtset hour date1


/* --------------------------------------------------------------------------
   Cross-sectional dependence tests, Germany
   H0: cross-section independence
   -------------------------------------------------------------------------- */
display as text _newline "=== Germany: Cross-sectional dependence (Pesaran 2004 CD) ==="

xtcdf price
xtcdf load
xtcdf wind
xtcdf solar
xtcdf gas    // requires Bloomberg data
xtcdf eua    // requires Bloomberg data


/* --------------------------------------------------------------------------
   Panel unit root tests, Germany
   H0: panels contain unit roots (non-stationary)
   -------------------------------------------------------------------------- */
display as text _newline "=== Germany: Panel unit root (Breitung & Das 2005), 5 lags ==="

xtunitroot breitung price, lags(5) robust
xtunitroot breitung load,  lags(5) robust
xtunitroot breitung wind,  lags(5) robust
xtunitroot breitung solar, lags(5) robust
xtunitroot breitung gas,   lags(5) robust    // requires Bloomberg data
xtunitroot breitung eua,   lags(5) robust    // requires Bloomberg data


/* --------------------------------------------------------------------------
   Close log
   -------------------------------------------------------------------------- */
log close
