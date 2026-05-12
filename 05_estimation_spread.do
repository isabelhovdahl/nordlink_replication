/* ==========================================================================
   05_estimation_spread.do
   ==========================================================================
   Estimates the MMQR model for the hourly Germany-NO2 price spread as a
   robustness check, and produces the associated table and figure for:

       Bjørndal, Bjørndal, Hovdahl & Tselika (2026)
       "European market integration and price convergence:
        A panel quantile regression analysis of NordLink"
       Energy Policy

   The spread model tests whether price convergence occurred within the same
   hours. The price spread is defined as the Germany minus NO2 day-ahead
   price. For variables observed in both zones (load, wind), the hourly
   cross-zonal difference is used. Variables observed in only one zone
   (solar for Germany, reservoir level for NO2) are included in levels.

   Tables produced
   ---------------
   App. Table A4 : tabA4_spread.tex  -- Location and scale effects and full
                                        quantile estimates for the spread
                                        model (same layout as tab_mmqr_no2
                                        and tab_mmqr_de from script 03).

   Figures produced
   ----------------
   Figure 6 (spread panel) : fig06_nordlink_spread.png
                             Quantile effect of the NordLink dummy from the
                             spread model, shown alongside the zone-specific
                             baseline plots from Figure 3 in the paper.


   Input data
   ----------
   data_spread.dta  : panel data for the Germany-NO2 price spread

   Required packages (install once, lines commented out after first use)
   -----------------------------------------------------------------------
   *ssc install mmqreg
   *ssc install hdfe
   *ssc install ftools
   *ssc install outreg2
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


/* --------------------------------------------------------------------------
   Data and panel structure
   -------------------------------------------------------------------------- */
use data/data_spread.dta, clear

encode date, gen(date1)
xtset hour date1


/* --------------------------------------------------------------------------
   Spread model
   price_diff    : Germany minus NO2 day-ahead price (EUR/MWh)
   load_diff     : Germany minus NO2 load forecast (GWh)
   wind_diff     : Germany minus NO2 wind generation forecast (GWh)
   solar         : Germany solar generation forecast (GWh, levels)
   belowmedian   : dummy for NO2 reservoir below median (levels)
   gaslag1       : lagged gas price, common to both zones (EUR/MWh)
   eualag1       : lagged EUA price, common to both zones (EUR/tCO2)
   pricelag1_diff: one-day lag of the price spread
   -------------------------------------------------------------------------- */
mmqreg price_diff i.nordlink c.load_diff c.wind_diff c.solar ///
    i.belowmedian c.gaslag1 c.eualag1 c.pricelag1_diff ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)


/* --------------------------------------------------------------------------
   Figure 6 (spread panel) -- Quantile effect of NordLink, spread model
   -------------------------------------------------------------------------- */
plot_quantile_coef                                  ///
    "1.nordlink"                                    ///
    "output/graphs/fig06_nordlink_spread.png"       ///
    "Germany-NO2 spread: NordLink"                  ///
    "none"                                          ///
    -3.2  -1.1


/* --------------------------------------------------------------------------
   Appendix Table A4 -- Location/scale effects and full quantile estimates
   -------------------------------------------------------------------------- */
outreg2 using "output/tables/tabA4_spread.tex", ///
    tex(fragment) bdec(3) replace
