*------------------------------------------------------------*
*----					3. GRAPHS						-----*
*------------------------------------------------------------*

graph set window fontface "Garamond"

use "$final/00_final_weighted_unbalanced.dta", clear

*------------------------------------------------------------------------------*
**#								3.1 Parallel Trends						  	 #**
*------------------------------------------------------------------------------*

*-----				 		3.1.1 Simple Version			 			  -----*

foreach var of varlist ln_e5 ln_e10 ln_diesel{

	preserve

	collapse (mean) `var', by(date treat)
	
	local lln_e5 "E5"
	local lln_e10 "E10"
	local lln_diesel "Diesel"
	
	graph twoway ///
	(line `var' date if treat==0 , lcolor(navy) lwidth(medthick)) ///
	(line `var' date if treat==1 , lcolor(dkorange) lwidth(medthick)), ///
	legend(label(1 "Control (France)") label(2 "Treatment (Germany)"))	///
	xline(22097, lcolor(gs8) lpattern(dash))	///
	graphregion(color(white)) ///
	bgcolor(white) xtitle("Dates", height(6))	///
	ytitle("Ln of `l`var'' Price € per liter" , height(6))
	graph export "$graphs/parallel_trends_`var'.pdf", replace as(pdf)

	restore
}



*------------------------------------------------------------------------------*
**#							3.2 Descriptive Analysis					  	 #**
*------------------------------------------------------------------------------*

* Load data
use "$final/00_final_weighted_unbalanced.dta", clear

* Drop unnecessary variables
keep date e5 e10 diesel treat post

* Collapse daily
foreach var of varlist e5 e10 diesel{
	bysort treat date: egen `var'_mean = mean(`var')
	drop `var'
	rename `var'_mean `var'
}

* Drop duplicates
duplicates drop treat date, force

* Demeaned prices
foreach var of varlist e5 e10 diesel{
	quietly: summarize `var' if treat == 1 & post == 0
	local pre_`var'_ger = r(mean)
	quietly: summarize `var' if treat == 0 & post == 0
	local pre_`var'_fra = r(mean)
	
	generate demeaned_`var'_ger = `var' - `pre_`var'_ger' if treat == 1
	generate demeaned_`var'_fra = `var' - `pre_`var'_fra' if treat == 0
	
	sort date treat
	
	replace demeaned_`var'_ger = demeaned_`var'_ger[_n+1] if demeaned_`var'_ger == .
	replace demeaned_`var'_fra = demeaned_`var'_fra[_n-1] if demeaned_`var'_fra == .
}

* Collapse
keep date demeaned*
duplicates drop date, force

* Generate descriptive pass-through
generate pt_e5 = (demeaned_e5_ger - demeaned_e5_fra)/0.10
generate pt_e10 = (demeaned_e10_ger - demeaned_e10_fra)/0.10
generate pt_diesel = (demeaned_diesel_ger - demeaned_diesel_fra)/0.11

* Graph	
graph twoway ///
(line pt_e5 date) ///
(line pt_e10 date) ///
(line pt_diesel date), ///
ytitle("Share of total tax change") ///
xtitle("") ///
yline(1, lcolor(gs8) lpattern(dash))	///
xline(22264, lcolor(gs8) lpattern(dash))	///
xline(22280.5, lcolor(gs8) lpattern(solid))	///
graphregion(color(white)) bgcolor(white) ///
legend(label(1 "E5") label(2 "E10") label(3 "Diesel") rows(1))

* Save
graph export "$graphs/desc_pt_inc.pdf", replace as(pdf)



*------------------------------------------------------------------------------*
**#							3.3 Distributions							  	 #**
*------------------------------------------------------------------------------*

*----- 		3.3.1 Price Distributions (pre outlier management)			  -----*

* Load data
use "$final/merged_weighted.dta", clear

* Negative values as missing
foreach var of varlist e5 e10 diesel{
	replace `var'=. if `var'<0
}

* Graph Kernel Density
foreach var of varlist e5 e10 diesel{
	
	local le5 "E5"
	local le10 "E10"
	local ldiesel "Diesel"	
	
	twoway (kdensity `var' if country == "France", lcolor(navy) lwidth(medthick)) ///
	(kdensity `var' if country == "Germany", lcolor(dkorange) lwidth(medthick)), ///
	legend(label(1 "Control (France)") label(2 "Treatment (Germany)")) ///	
	/*lcolor(navy) lwidth(medthick)*/ ///
	graphregion(color(white)) bgcolor(white) ///
	ytitle(Kernel Density) ///
	xtitle("`l`var'' Prices") xlabel(0(0.5)3.5)
	
	graph export "$graphs/distr_inc_`var'.pdf", replace as(pdf)
}



*-----			 		3.3.2 Competition Distributions		 			  -----*

* Load data
use "$intermediate/06_competition_radius.dta", clear

* Graph
foreach var of varlist within1 within2 within5{
	
	local lwithin1 "1"
	local lwithin2 "2"
	local lwithin5 "5"		
	
	twoway histogram `var', fraction ///
	color(navy) ///
	graphregion(color(white)) bgcolor(white) ///
	xtitle("Petrol Stations within `l`var''km")

	graph export "$graphs/distr_comp_inc_`var'.pdf", replace as(pdf)	
}
