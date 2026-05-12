/* ==========================================================================
   03_estimation_mmqr.do
   ==========================================================================
   Runs the baseline MMQR model (Machado & Santos Silva, 2019) for NO2 and
   Germany and produces all associated tables and figures for:

       Bjørndal, Bjørndal, Hovdahl & Tselika (2026)
       "European market integration and price convergence:
        A panel quantile regression analysis of NordLink"
       Energy Policy

   Tables produced
   ---------------
   Table 3 and App. Table A3 are both contained in the two files below.
   Each file has one column per set of estimates (q10, q20, ..., q90,
   location, scale) and one row per variable. Table 3 (location and scale)
   and Appendix Table A3 (quantile estimates) correspond to subsets of
   columns from these files.

   tab_mmqr_no2.tex  : all quantile + location/scale estimates for NO2
   tab_mmqr_de.tex   : all quantile + location/scale estimates for Germany


   Figures produced
   ----------------
   Figure 3 : fig03_nordlink_quantiles_no2.png  )  Quantile effects of NordLink
              fig03_nordlink_quantiles_de.png   )
   Figure 4 : fig04_load_no2.png                )
              fig04_load_de.png                 )
              fig04_wind_no2.png                )
              fig04_wind_de.png                 )  Quantile effects of load,
              fig04_belowmedian_no2.png         )  wind, solar, and reservoir
              fig04_solar_de.png                )
   Figure 5 : fig05_gas_no2.png                 )
              fig05_gas_de.png                  )  Quantile effects of gas
              fig05_eua_no2.png                 )  and EUA prices
              fig05_eua_de.png                  )


   Input data
   ----------
   data_NO2.dta  : panel data for NO2
   data_DE.dta   : panel data for Germany

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

* Output directories (create manually if they do not exist)
* output/tables/
* output/graphs/


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

* Panel structure: hours as cross-sectional units, days as time dimension
encode date, gen(date1)
xtset hour date1


/* --------------------------------------------------------------------------
   Baseline MMQR model -- NO2
   Eq. (1): price ~ NordLink + load + wind + belowmedian + gas(t-1) +
            eua(t-1) + price(t-1) + weekend + month FE | hour FE
   -------------------------------------------------------------------------- */
mmqreg price i.nordlink c.load c.wind i.belowmedian ///
    c.gaslag1 c.eualag1 c.pricelag1 ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)

estimates store mmqr_no2


/* --------------------------------------------------------------------------
   Figure 3 -- Quantile effect of NordLink dummy, NO2
   -------------------------------------------------------------------------- */
plot_quantile_coef                              ///
    "1.nordlink"                                ///
    "output/graphs/fig03_nordlink_quantiles_no2.png" ///
    "NO2: NordLink"                             ///
    "r(-5 6.5)"                                 ///
    -4.5   5.5


/* --------------------------------------------------------------------------
   Figure 4 -- Quantile effects of load, wind, and reservoir level, NO2
   -------------------------------------------------------------------------- */
plot_quantile_coef                              ///
    "load"                                      ///
    "output/graphs/fig04_load_no2.png"          ///
    "NO2: Load"                                 ///
    "r(-3 5.5)"                                 ///
    -2.5   5.0

plot_quantile_coef                              ///
    "wind"                                      ///
    "output/graphs/fig04_wind_no2.png"          ///
    "NO2: Wind"                                 ///
    "none"                                      ///
    -5.9  -6.7

plot_quantile_coef                              ///
    "1.belowmedian"                             ///
    "output/graphs/fig04_belowmedian_no2.png"   ///
    "NO2: Reservoir (below median dummy)"       ///
    "r(-1 3)"                                   ///
    1.5    0.2


/* --------------------------------------------------------------------------
   Figure 5 -- Quantile effects of gas and EUA prices, NO2
   -------------------------------------------------------------------------- */
plot_quantile_coef                              ///
    "gaslag1"                                   ///
    "output/graphs/fig05_gas_no2.png"           ///
    "NO2: Gas price"                            ///
    "r(0 0.4)"                                  ///
    0.12   0.35

plot_quantile_coef                              ///
    "eualag1"                                   ///
    "output/graphs/fig05_eua_no2.png"           ///
    "NO2: EUA price"                            ///
    "r(0 0.15)"                                 ///
    0.07   0.055


/* ==========================================================================
   PART 2: Germany
   ========================================================================== */

use data/data_DE.dta, clear

encode date, gen(date1)
xtset hour date1


/* --------------------------------------------------------------------------
   Baseline MMQR model -- Germany
   Eq. (1): price ~ NordLink + load + wind + solar + gas(t-1) +
            eua(t-1) + price(t-1) + weekend + month FE | hour FE
   -------------------------------------------------------------------------- */
mmqreg price i.nordlink c.load c.wind c.solar ///
    c.gaslag1 c.eualag1 c.pricelag1 ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)

estimates store mmqr_de


/* --------------------------------------------------------------------------
   Figure 3 -- Quantile effect of NordLink dummy, Germany
   -------------------------------------------------------------------------- */
plot_quantile_coef                              ///
    "1.nordlink"                                ///
    "output/graphs/fig03_nordlink_quantiles_de.png" ///
    "Germany: NordLink"                         ///
    "r(-4 1)"                                   ///
    -0.7  -2.5


/* --------------------------------------------------------------------------
   Figure 4 -- Quantile effects of load, wind, and solar, Germany
   -------------------------------------------------------------------------- */
plot_quantile_coef                              ///
    "load"                                      ///
    "output/graphs/fig04_load_de.png"           ///
    "Germany: Load"                             ///
    "none"                                      ///
    1.25   1.15

plot_quantile_coef                              ///
    "wind"                                      ///
    "output/graphs/fig04_wind_de.png"           ///
    "Germany: Wind"                             ///
    "none"                                      ///
    -1.4  -0.8

plot_quantile_coef                              ///
    "solar"                                     ///
    "output/graphs/fig04_solar_de.png"          ///
    "Germany: Solar"                            ///
    "none"                                      ///
    -1.4  -0.9


/* --------------------------------------------------------------------------
   Figure 5 -- Quantile effects of gas and EUA prices, Germany
   -------------------------------------------------------------------------- */
plot_quantile_coef                              ///
    "gaslag1"                                   ///
    "output/graphs/fig05_gas_de.png"            ///
    "Germany: Gas price"                        ///
    "none"                                      ///
    0.5    1.4

plot_quantile_coef                              ///
    "eualag1"                                   ///
    "output/graphs/fig05_eua_de.png"            ///
    "Germany: EUA price"                        ///
    "none"                                      ///
    0.3    0.6



/* ==========================================================================
   PART 3: Tables
   ========================================================================== */

/* --------------------------------------------------------------------------
   Tables 3 and A3 -- Location/scale effects and full quantile estimates
   --------------------------------------------------------------------------
   mmqreg with q(10(10)90) automatically computes and stores all quantile
   estimates alongside the location and scale effects. outreg2 applied
   directly after mmqreg exports these as a .tex fragment where each column
   is one set of estimates (q10, q20, ..., q90, location, scale) and each
   row is one variable -- matching the layout mmqreg stores internally.

   One file is produced per market. These correspond to Table 3 (location
   and scale columns) and Appendix Table A3 (quantile columns) in the paper;
   both sets of results are contained in the same output file.
   -------------------------------------------------------------------------- */

* -- NO2 --
use data/data_NO2.dta, clear
encode date, gen(date1)
xtset hour date1

mmqreg price i.nordlink c.load c.wind i.belowmedian ///
    c.gaslag1 c.eualag1 c.pricelag1 ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)

outreg2 using "output/tables/tab_mmqr_no2.tex", ///
    tex(fragment) bdec(3) replace

* -- Germany --
use data/data_DE.dta, clear
encode date, gen(date1)
xtset hour date1

mmqreg price i.nordlink c.load c.wind c.solar ///
    c.gaslag1 c.eualag1 c.pricelag1 ///
    i.weekend i.month, ///
    abs(hour) cluster(hour) q(10(10)90)

outreg2 using "output/tables/tab_mmqr_de.tex", ///
    tex(fragment) bdec(3) replace
