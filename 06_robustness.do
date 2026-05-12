/* ==========================================================================
   06_robustness.do
   ==========================================================================
   Runs robustness checks for the baseline MMQR model for NO2 and Germany
   and produces the associated figures and summary tables for:

       Bjørndal, Bjørndal, Hovdahl & Tselika (2026)
       "European market integration and price convergence:
        A panel quantile regression analysis of NordLink"
       Energy Policy

   Three checks are run for NO2 and two for Germany, each replacing one
   element of the baseline specification:
     Check 1: Coal price instead of gas price
     Check 2: Seven-day lagged price instead of one-day lag
     Check 3: Actual reservoir filling rate instead of below-median dummy
              (NO2 only)

   Figures produced (Appendix)
   ----------------
   App. Fig A3 : figA3_robustness_no2_coal.png       )
                 figA3_robustness_no2_pricelag7.png   )  NordLink quantile
                 figA3_robustness_no2_reservoir.png   )  effects, NO2
   App. Fig A4 : figA4_robustness_de_coal.png         )  NordLink quantile
                 figA4_robustness_de_pricelag7.png    )  effects, Germany


   Input data
   ----------
   data_NO2.dta : panel data for NO2
   data_DE.dta  : panel data for Germany

   Required packages (install once, lines commented out after first use)
   -----------------------------------------------------------------------
   *ssc install mmqreg
   *ssc install hdfe
   *ssc install ftools
   ========================================================================== */


/* --------------------------------------------------------------------------
   Setup
   -------------------------------------------------------------------------- */
clear all
set seed 1234

* Set working directory to the folder containing this do-file and the data
* Edit this path before running
cd "EDIT_THIS_PATH"


/* --------------------------------------------------------------------------
   Helper program: plot_quantile_coef
   --------------------------------------------------------------------------
   Extracts quantile coefficients and standard errors for one variable from
   the most recently stored mmqreg results and saves a quantile plot.

   Arguments
   ---------
   1  varname    : Stata name of the coefficient to plot, e.g. "1.nordlink"
   2  outpath    : full path for the exported .png file
   3  ytitle     : y-axis label string (quoted internally)
   4  plotlabel  : title shown on the graph, e.g. "NO2: NordLink"
   5  yscale     : yscale() option, e.g. "r(-5 6.5)"  -- pass "none" to omit
   6  lowtext_y  : y-coordinate of the "Low-price hours" annotation
   7  hightext_y : y-coordinate of the "High-price hours" annotation
   -------------------------------------------------------------------------- */
program define plot_quantile_coef
    args varname outpath plotlabel yscale lowtext_y hightext_y

    local nq = 9
    local quantiles "10 20 30 40 50 60 70 80 90"

    preserve
        clear
        set obs `nq'
        gen quantile = .
        gen coef     = .
        gen se       = .
        gen ub       = .
        gen lb       = .

        local i = 1
        foreach q of local quantiles {
            replace quantile = `q'              in `i'
            replace coef     = _b[qtile_`q':`varname']  in `i'
            replace se       = _se[qtile_`q':`varname'] in `i'
            replace ub       = coef + 1.96*se   in `i'
            replace lb       = coef - 1.96*se   in `i'
            local i = `i' + 1
        }

        * Build optional yscale option
        if "`yscale'" != "none" {
            local yscale_opt "yscale(`yscale')"
        }
        else {
            local yscale_opt ""
        }

        twoway ///
            (rarea ub lb quantile, color(gs14%60) lwidth(none))        ///
            (line coef quantile,   lcolor(navy) lwidth(medthick))      ///
            (function y=0, range(10 90) lcolor(black) lpattern(dash)   ///
                lwidth(thin)),                                          ///
            ytitle("EUR/MWh") xtitle("Quantile")                       ///
            title("`plotlabel'")                                        ///
            xlabel(10(10)90) xscale(r(8 92))                           ///
            `yscale_opt'                                                ///
            text(`lowtext_y'  15 "Low-price"  "hours",                 ///
                 size(small) color(gs6))                                ///
            text(`hightext_y' 85 "High-price" "hours",                 ///
                 size(small) color(gs6))                                ///
            ysize(10) xsize(12)                                        ///
            legend(off)

        graph export "`outpath'", replace
    restore
end


/* ==========================================================================
   PART 1: NO2
   ========================================================================== */

use data/data_NO2.dta, clear

encode date, gen(date1)
xtset hour date1


/* --------------------------------------------------------------------------
   Check 1: Coal price instead of gas price, NO2
   -------------------------------------------------------------------------- */
mmqreg price i.nordlink c.load c.wind i.belowmedian ///
    c.coallag1 c.eualag1 c.pricelag1 ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)

plot_quantile_coef                                          ///
    "1.nordlink"                                            ///
    "output/graphs/figA3_robustness_no2_coal.png"           ///
    "NO2: NordLink"                                         ///
    "none"                                                  ///
    -4.3   2.5


/* --------------------------------------------------------------------------
   Check 2: Seven-day lagged price added, NO2
   -------------------------------------------------------------------------- */
mmqreg price i.nordlink c.load c.wind i.belowmedian ///
    c.gaslag1 c.eualag1 c.pricelag1 c.pricelag7 ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)

plot_quantile_coef                                          ///
    "1.nordlink"                                            ///
    "output/graphs/figA3_robustness_no2_pricelag7.png"      ///
    "NO2: NordLink"                                         ///
    "none"                                                  ///
    -4.3   2.5


/* --------------------------------------------------------------------------
   Check 3: Actual reservoir filling rate instead of below-median dummy, NO2
   -------------------------------------------------------------------------- */
mmqreg price i.nordlink c.load c.wind c.reservoir ///
    c.gaslag1 c.eualag1 c.pricelag1 ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)

plot_quantile_coef                                          ///
    "1.nordlink"                                            ///
    "output/graphs/figA3_robustness_no2_reservoir.png"      ///
    "NO2: NordLink"                                         ///
    "none"                                                  ///
    -2.7   4.0


/* ==========================================================================
   PART 2: Germany
   ========================================================================== */

use data/data_DE.dta, clear

encode date, gen(date1)
xtset hour date1


/* --------------------------------------------------------------------------
   Check 1: Coal price instead of gas price, Germany
   -------------------------------------------------------------------------- */
mmqreg price i.nordlink c.load c.wind c.solar ///
    c.coallag1 c.eualag1 c.pricelag1 ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)

plot_quantile_coef                                          ///
    "1.nordlink"                                            ///
    "output/graphs/figA4_robustness_de_coal.png"            ///
    "Germany: NordLink"                                     ///
    "none"                                                  ///
    -1.0  -2.1


/* --------------------------------------------------------------------------
   Check 2: Seven-day lagged price added, Germany
   -------------------------------------------------------------------------- */
mmqreg price i.nordlink c.load c.wind c.solar ///
    c.gaslag1 c.eualag1 c.pricelag1 c.pricelag7 ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)

plot_quantile_coef                                          ///
    "1.nordlink"                                            ///
    "output/graphs/figA4_robustness_de_pricelag7.png"       ///
    "Germany: NordLink"                                     ///
    "none"                                                  ///
    -1.5  -2.9

