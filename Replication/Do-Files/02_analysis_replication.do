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

	* Regressions and pass-through calculations
	eststo clear
	eststo baseline_ln_`var': quietly areg ln_`var' i.date 1.treat#1.post, cluster(id) a(id)
	estadd scalar pt = _b[1.treat#1.post]/-0.0252*100
	eststo controls_ln_`var': quietly areg ln_`var' i.date 1.treat#1.post retail_recreation workplace, cluster(id) a(id)
	estadd scalar pt = _b[1.treat#1.post]/-0.0252*100
	eststo autobahn_ln_`var': quietly areg ln_`var' i.street_type##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/-0.0252*100
	eststo comp1_ln_`var': quietly areg ln_`var' i.comp_within1##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/-0.0252*100
	
	* Result output
	esttab using "$tables/reg_rep_`var'_unbalanced.tex", /// 
	keep(_cons workplace retail_recreation 1.treat#1.post 1.street_type#1.treat#1.post 1.comp_within1#1.treat#1.post) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.6fc)) se(par) ci(par)) nonumbers brackets ///
	stats(pt N r2,labels("Pass-Through (in \%)" "Observations" "R-squared") fmt(%9.2fc %9.0fc %9.4fc)) ///
	mtitles("Baseline" "Controls" "Highway (+ Controls)" "Competition (+ Controls)") ///
	label booktabs replace nogap collabels(none) nonotes
}


*-----							2.1.2 Balanced							  -----*

* Load data
use "$final/00_final_weighted_balanced.dta", clear


foreach var of varlist e5 e10 diesel{

	* Regressions and pass-through calculations
	eststo clear
	eststo baseline_ln_`var': quietly areg ln_`var' i.date 1.treat#1.post, cluster(id) a(id)
	estadd scalar pt = _b[1.treat#1.post]/-0.0252*100
	eststo controls_ln_`var': quietly areg ln_`var' i.date 1.treat#1.post retail_recreation workplace, cluster(id) a(id)
	estadd scalar pt = _b[1.treat#1.post]/-0.0252*100
	eststo autobahn_ln_`var': quietly areg ln_`var' i.street_type##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/-0.0252*100
	eststo comp1_ln_`var': quietly areg ln_`var' i.comp_within1##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/-0.0252*100
	
	* Result output
	esttab using "$tables/reg_rep_`var'_unbalanced.tex", /// 
	keep(_cons workplace retail_recreation 1.treat#1.post 1.street_type#1.treat#1.post 1.comp_within1#1.treat#1.post) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.6fc)) se(par) ci(par)) nonumbers brackets ///
	stats(pt N r2,labels("Pass-Through (in \%)" "Observations" "R-squared") fmt(%9.2fc %9.0fc %9.4fc)) ///
	mtitles("Baseline" "Controls" "Highway (+ Controls)" "Competition (+ Controls)") ///
	label booktabs replace nogap collabels(none) nonotes
}
