/* ==========================================================================
   04_estimation_interactions.do
   ==========================================================================
   Estimates the linear panel regression model with NordLink interaction
   terms for NO2 and Germany, and exports the results table for:

       Bjørndal, Bjørndal, Hovdahl & Tselika (2026)
       "European market integration and price convergence:
        A panel quantile regression analysis of NordLink"
       Energy Policy

   Tables produced
   ---------------
   Table 4 : tab04_interactions.tex  -- Baseline and interaction model
                                        estimates for NO2 and Germany,
                                        corresponding to columns (1)-(4)
                                        in the paper.


   Input data
   ----------
   data_NO2.dta  : panel data for NO2
   data_DE.dta   : panel data for Germany

   Required packages (install once, lines commented out after first use)
   -----------------------------------------------------------------------
   *ssc install estout
   ========================================================================== */


/* --------------------------------------------------------------------------
   Setup
   -------------------------------------------------------------------------- */
clear all
set seed 1234

* Set working directory to the folder containing this do-file and the data
* Edit this path before running
cd "EDIT_THIS_PATH"


/* ==========================================================================
   PART 1: NO2
   ========================================================================== */

use data/data_NO2.dta, clear

encode date, gen(date1)
xtset hour date1


/* --------------------------------------------------------------------------
   Model (1): Baseline -- no interaction terms, NO2
   Eq. (2) without interactions: corresponds to column (1) in Table 4
   -------------------------------------------------------------------------- */
xtreg price i.nordlink c.load c.wind i.belowmedian ///
    c.gaslag1 c.eualag1 c.pricelag1 ///
    i.weekend i.month, ///
    fe cluster(hour)

estimates store no2_baseline


/* --------------------------------------------------------------------------
   Model (2): Interactions -- NordLink interacted with all covariates, NO2
   Eq. (2): corresponds to column (2) in Table 4
   -------------------------------------------------------------------------- */
xtreg price ///
    i.nordlink##c.load        ///
    i.nordlink##c.wind        ///
    i.nordlink##i.belowmedian ///
    i.nordlink##c.gaslag1     ///
    i.nordlink##c.eualag1     ///
    i.nordlink##c.pricelag1   ///
    i.weekend i.month, ///
    fe cluster(hour)

estimates store no2_interactions


/* ==========================================================================
   PART 2: Germany
   ========================================================================== */

use data/data_DE.dta, clear

encode date, gen(date1)
xtset hour date1


/* --------------------------------------------------------------------------
   Model (3): Baseline -- no interaction terms, Germany
   Eq. (2) without interactions: corresponds to column (3) in Table 4
   -------------------------------------------------------------------------- */
xtreg price i.nordlink c.load c.wind c.solar ///
    c.gaslag1 c.eualag1 c.pricelag1 ///
    i.weekend i.month, ///
    fe cluster(hour)

estimates store de_baseline


/* --------------------------------------------------------------------------
   Model (4): Interactions -- NordLink interacted with all covariates, Germany
   Eq. (2): corresponds to column (4) in Table 4
   -------------------------------------------------------------------------- */
xtreg price ///
    i.nordlink##c.load    ///
    i.nordlink##c.wind    ///
    i.nordlink##c.solar   ///
    i.nordlink##c.gaslag1 ///
    i.nordlink##c.eualag1 ///
    i.nordlink##c.pricelag1 ///
    i.weekend i.month, ///
    fe cluster(hour)

estimates store de_interactions


/* ==========================================================================
   PART 3: Table 4
   ========================================================================== */

/* --------------------------------------------------------------------------
   Export all four models side by side as columns (1)-(4).
   keep() lists only the substantive variables, omitting weekend and month
   dummies to match the paper's table layout.
   -------------------------------------------------------------------------- */
esttab no2_baseline no2_interactions de_baseline de_interactions ///
    using "output/tables/tab04_interactions.tex",                 ///
    se booktabs replace                                           ///
    mgroups("NO2" "Germany",                                      ///
        pattern(1 0 1 0)                                          ///
        prefix(\multicolumn{2}{c}{) suffix(})                     ///
        span erepeat(\cmidrule(lr){@span}))                       ///
    keep(1.nordlink load wind 1.belowmedian solar                 ///
         gaslag1 eualag1 pricelag1                                ///
         1.nordlink#c.load 1.nordlink#c.wind                      ///
         1.nordlink#1.belowmedian 1.nordlink#c.solar              ///
         1.nordlink#c.gaslag1 1.nordlink#c.eualag1                ///
         1.nordlink#c.pricelag1)                                  ///
    varlabels(1.nordlink          "NordLink"                      ///
              load                "Load"                          ///
              wind                "Wind"                          ///
              1.belowmedian       "Reservoir"                     ///
              solar               "Solar"                         ///
              gaslag1             "Gas"                           ///
              eualag1             "EUA"                           ///
              pricelag1           "PriceLag1"                     ///
              1.nordlink#c.load         "Load x NordLink"         ///
              1.nordlink#c.wind         "Wind x NordLink"         ///
              1.nordlink#1.belowmedian  "Reservoir x NordLink"    ///
              1.nordlink#c.solar        "Solar x NordLink"        ///
              1.nordlink#c.gaslag1      "Gas x NordLink"          ///
              1.nordlink#c.eualag1      "EUA x NordLink"          ///
              1.nordlink#c.pricelag1    "PriceLag1 x NordLink")   ///
    star(* 0.1 ** 0.05 *** 0.01)                                  ///
    nogap
