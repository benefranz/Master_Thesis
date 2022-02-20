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

*-----				 		3.1.1 Complex Version			 			  -----*
/*
*** Daily

* Add overall coeffcients
cap drop vat17
gen vat17 = post*treat
foreach var of varlist ln_e5 ln_e10 ln_diesel{
quietly areg `var' treat i.date vat17, cluster(id) a(id)
local b_`var'=round(_b[vat17],0.00000001)
display `b_`var''
local se_`var'=round(_se[vat17],0.00000001)
display `se_`var''
}
local lln_e5 "E5"
local lln_e10 "E10"
local lln_diesel "Diesel"

foreach var of varlist ln_e5 ln_e10 ln_diesel {
local ypath `var'

preserve

* Dummy for days
forvalues i=22067/22127 {
gen d_`i'=(date==`i')
gen d_`i'_t=(date==`i' & treat==1)
}
* Baseline
drop d_22097 d_22097_t //01.07.20 as reference 

* Regression
areg `var' treat d_22*, cluster(id) a(id) noomitted 

* Effects
gen ball_t=0 if date==22097
gen upall_t=. if date==22097
gen lowall_t=. if date==22097

* Pre
forvalues y=22067/22096 {
replace ball_t=_b[d_`y'_t] if date==`y' 
replace upall_t=_b[d_`y'_t]+1.96*_se[d_`y'_t] if date==`y' 
replace lowall_t=_b[d_`y'_t]-1.96*_se[d_`y'_t] if date==`y'  
}
* Post
forvalues y=22098/22127 {
replace ball_t=_b[d_`y'_t] if date==`y' 
replace upall_t=_b[d_`y'_t]+1.96*_se[d_`y'_t] if date==`y' 
replace lowall_t=_b[d_`y'_t]-1.96*_se[d_`y'_t] if date==`y' 
}

by date , so: gen n=_n
keep if n==1

so date

* Plot 
twoway  (scatter ball date , msize(vsmall) lcolor(navy) mcolor(navy) lpattern(solid) lwidth(medthin)) ///
(rcap upall lowall date, lcolor(navy) mcolor(navy) lpattern(solid)), ///
graphregion(color(white)) bgcolor(white) xtitle("Dates",height(6)) yline(0, lcolor(black)) yscale(range(-0.03 0.03)) ylabel(-0.03 (0.01) 0.03) ///
ytitle(Effect on `l`ypath'', height(6)) xline(22097.5, lcolor(red) lpattern(dash)) xlabel(22067(10)22127) ////
legend(off) ///
text(0.02 22115.5 "b=`b_`var'' (`se_`var'')", size(medsmall))
graph export "$graphs/pt_`var'.pdf", replace as(pdf)

* Test for each pre date
forvalues y=22067/22096 {
test (d_`y'_t=0)
}

* Test for all pre dates together
test (d_22081_t=0) (d_22082_t=0) (d_22083_t=0) (d_22084_t=0) (d_22085_t=0) (d_22086_t=0) (d_22087_t=0) (d_22088_t=0) (d_22089_t=0) (d_22090_t=0) (d_22091_t=0) (d_22092_t=0) (d_22093_t=0) (d_22094_t=0) (d_22095_t=0) (d_22096_t=0)

restore
}
*/

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

	graph export "$graphs/`var'_germany.pdf", replace as(pdf)
	
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
	
	graph export "$graphs/distr_`var'.pdf", replace as(pdf)
}

* Graph Boxplot
foreach var of varlist e5 e10 diesel{
	
	local le5 "E5"
	local le10 "E10"
	local ldiesel "Diesel"	
	
	graph box `var', over(country) ///
	graphregion(color(white)) bgcolor(white) ///
	ytitle("`l`var'' Prices")
	
	graph export "$graphs/box_`var'.pdf", replace as(pdf)
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

	graph export "$graphs/distr_`var'.pdf", replace as(pdf)	
}
