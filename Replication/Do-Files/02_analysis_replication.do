*------------------------------------------------------------------------------*
*-----						   	2. ANALYSIS								  -----*
*------------------------------------------------------------------------------*



*------------------------------------------------------------------------------*
*-----							2.1 Regressions							 ------*
*------------------------------------------------------------------------------*

*-----							2.1.1 Unbalanced						  -----*

* Load data
use "$final/00_final_weighted_unbalanced.dta", clear


foreach var of varlist e5 e10 diesel{

	* Regressions
	eststo clear
	eststo baseline_ln_`var': areg ln_`var' i.date 1.treat#1.post, cluster(id) a(id) 
	eststo controls_ln_`var': areg ln_`var' i.date 1.treat#1.post retail_recreation workplace, cluster(id) a(id)
	eststo autobahn_ln_`var': areg ln_`var' i.street_type##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id) 
	quietly summarize `var' if  date <= date("30jun2020", "DMY") & treat == 1
	quietly estadd scalar mean = r(mean) 
	
	* Result output
	esttab using "$tables/reg_`var'_unbalanced.tex", /// 
	keep(_cons workplace retail_recreation 1.treat#1.post 1.street_type#1.treat#1.post) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.4fc)) se(par) ci(par)) nonumbers brackets ///
	stats(mean N r2,labels("Mean (Pre-reform)" "Observations" "R-squared") fmt(%9.3fc %9.0fc %9.3fc)) ///
	mtitles("Baseline" "Controls" "Highway (+ Controls)") ///
	label booktabs replace nogap collabels(none) nonotes
}


*-----							2.1.2 Balanced							  -----*

* Load data
use "$final/00_final_weighted_balanced.dta", clear


foreach var of varlist e5 e10 diesel{

	* Regressions
	eststo clear
	eststo baseline_ln_`var': areg ln_`var' i.date 1.treat#1.post, cluster(id) a(id) 
	eststo controls_ln_`var': areg ln_`var' i.date 1.treat#1.post retail_recreation workplace, cluster(id) a(id)
	eststo autobahn_ln_`var': areg ln_`var' i.street_type##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id) 
	quietly summarize `var' if  date <= date("30jun2020", "DMY") & treat == 1
	quietly estadd scalar mean = r(mean) 
	
	* Result output
	esttab using "$tables/reg_`var'_balanced.tex", /// 
	keep(_cons workplace retail_recreation 1.treat#1.post 1.street_type#1.treat#1.post) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.4fc)) se(par) ci(par)) nonumbers brackets ///
	stats(mean N r2,labels("Mean (Pre-reform)" "Observations" "R-squared") fmt(%9.3fc %9.0fc %9.3fc)) ///
	mtitles("Baseline" "Controls" "Highway (+ Controls)") ///
	label booktabs replace nogap collabels(none) nonotes
}
