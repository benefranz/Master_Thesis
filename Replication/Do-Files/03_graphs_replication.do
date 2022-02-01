*------------------------------------------------------------*
*----				3. GRAPHS AND TABLES				-----*
*------------------------------------------------------------*

graph set window fontface "Garamond"

use "$final/00_final_weighted.dta", clear

*------------------------------------------------------------------------------*
*----							3.1 Graphs								  -----*
*------------------------------------------------------------------------------*

*-----			 		3.1.1 Parallel Trend Assumption		 			  -----*

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



*add overall coeffcients
cap drop vat17
gen vat17 = post*treat
foreach var of varlist ln_e5 ln_e10 ln_diesel{
quietly areg `var' treat i.date vat17, a(id) 
local b_`var'=round(_b[vat17],0.00000001)
display `b_`var''
local se_ln_diesel=round(e(V)[1,1],0.00000001)
display `se_`var''
}
local lln_e5 "E5"
local lln_e10 "E10"
local lln_diesel "Diesel"

foreach var of varlist ln_e5 ln_e10 ln_diesel {
local ypath `var'

preserve

*dummy for days
forvalues i=22081/22127 {
gen d_`i'=(date==`i')

}
*baseline
drop d_22097 //yh(2002,2) as reference 
*regression
areg `var' treat d_22*, a(id) noomitted 

*effects
gen ball=0 if date==22097
gen upall=. if date==22097
gen lowall=. if date==22097

*pre
forvalues y=22081/22096 {
replace ball=_b[d_`y'] if date==`y' 
replace upall=_b[d_`y']+1.96*_se[d_`y'] if date==`y' 
replace lowall=_b[d_`y']-1.96*_se[d_`y'] if date==`y' 
}
*post
forvalues y=22098/22127 {
replace ball=_b[d_`y'] if date==`y' 
replace upall=_b[d_`y']+1.96*_se[d_`y'] if date==`y' 
replace lowall=_b[d_`y']-1.96*_se[d_`y'] if date==`y' 
}

by date , so: gen n=_n
keep if n==1

so date

*Plot 
twoway  (scatter ball date , msize(vsmall) lcolor(navy) mcolor(navy) lpattern(solid) lwidth(medthin)) ///
(rcap upall lowall date, lcolor(navy) mcolor(navy) lpattern(solid)), ///
graphregion(color(white)) bgcolor(white) xtitle("Dates",height(6)) yline(0, lcolor(black)) //yscale(range(-0.15 0.15)) ylabel(-0.15 (0.05) 0.15) ///
//ytitle(Effect on `l`ypath'', height(6)) xline(85.5, lcolor(red) lpattern(dash)) xlabel(83(1)91) ////
//legend(off) ///
//text(0.10 88.5 "b=`b_`var'' (`se_`var'')", size(medsmall))
*caption("Treat: Age 50-54;" "Half yearly difference-in-differences coeffcients for the period 2001h2 to 2005h2 using 2002h2 as base." "The vertical bars show 95% confidence intervals based on standard errors clustered at the department and half year level.""Only including regions with Unemployment rate above 12% in last half year.""Balanced sample: Regions Caribe, Pacifica, Bogota D.C.""Y=`ypath'" , size(small) margin(t=3))
graph export "$graphs/pt_`var'", replace as(pdf)

*test (d_83_t=0) (d_84_t=0)

restore
}







*-----	  3.1.2 Price Plot for Comparison (full and zero pass-through)	  -----*

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

