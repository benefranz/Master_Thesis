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
	reshape wide `var', i(date) j(treat)

	graph twoway line `var'* date, sort name(group_means, replace) ///
	legend(label(1 "Control (France)") label(2 "Treatment (Germany)"))	///
	xline(22097, lcolor(red) lpattern(dash))	///
	graphregion(color(white)) ///
	bgcolor(white) xtitle("Dates", height(6))	///
	ytitle("Ln of Price € per liter" , height(6))
	graph export "$graphs/parallel_trends_`var'.pdf", replace as(pdf)

	restore
}



*-----	  3.1.2 Price Plot for Comparison (full and zero pass-through)	  -----*

foreach var of varlist e5 e10 diesel{
	
	preserve
	
	keep `var' treat date

	collapse (mean) `var', by (date treat) 

	twoway  (line `var' date if treat==1 , lcolor(navy) msymbol(O) msize(medsmall) mcolor(navy) lwidth(medthick)), /// 
	xline(22097, lcolor(red) lpattern(dash)) ///
	graphregion(color(white)) bgcolor(white) xtitle("Dates", height(6))  ///
	ytitle("Price € per liter" , height(6))  ///	

	graph export "$graphs/`var'_germany.pdf", replace as(pdf)
	
	restore
}

