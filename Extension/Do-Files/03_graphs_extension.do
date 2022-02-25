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
**#					3.2 Full/Zero Pass-Through Comparison				  	 #**
*------------------------------------------------------------------------------*

foreach var of varlist e5 e10 diesel{
	
	preserve
	
	keep `var' treat date

	collapse (mean) `var', by (date treat) 

	twoway  (line `var' date if treat==1 , lcolor(navy) lwidth(medthick)), /// 
	xline(22097, lcolor(gs8) lpattern(dash)) ///
	graphregion(color(white)) bgcolor(white) xtitle("Dates", height(6))  ///
	ytitle("Price € per liter" , height(6))  ///	

	graph export "$graphs/ext_`var'_germany.pdf", replace as(pdf)
	
	restore
}



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
	
	twoway (kdensity `var' if country=="France", lcolor(navy) lwidth(medthick)) ///
	(kdensity `var' if country=="Germany", lcolor(dkorange) lwidth(medthick)), ///
	legend(label(1 "Control (France)") label(2 "Treatment (Germany)")) ///	
	/*lcolor(navy) lwidth(medthick)*/ ///
	graphregion(color(white)) bgcolor(white) ///
	ytitle(Kernel Density) ///
	xtitle("`l`var'' Prices") xlabel(0(0.5)3.5)
	
	graph export "$graphs/distr_ext_`var'.pdf", replace as(pdf)
}

* Graph Boxplot
foreach var of varlist e5 e10 diesel{
	
	local le5 "E5"
	local le10 "E10"
	local ldiesel "Diesel"	
	
	graph box `var', over(country) ///
	graphregion(color(white)) bgcolor(white) ///
	ytitle("`l`var'' Prices")
	
	graph export "$graphs/box_ext_`var'.pdf", replace as(pdf)
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

	graph export "$graphs/distr_comp_ext_`var'.pdf", replace as(pdf)	
}
