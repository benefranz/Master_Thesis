*------------------------------------------------------------------------------*
*-----						   	2. ANALYSIS								  -----*
*------------------------------------------------------------------------------*



*------------------------------------------------------------------------------*
**#								2.1 Regressions								 #**
*------------------------------------------------------------------------------*

*-----							2.1.1 Unbalanced						  -----*

* Load data
use "$final/00_final_weighted_unbalanced.dta", clear


foreach var of varlist e5 e10 diesel{

	* Regressions and pass-through calculations
	eststo clear
	eststo baseline_ln_`var': quietly areg ln_`var' i.date oil_de 1.treat#1.post, cluster(id) a(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	eststo controls_ln_`var': quietly areg ln_`var' i.date oil_de 1.treat#1.post retail_recreation workplace, cluster(id) a(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	eststo autobahn_ln_`var': quietly areg ln_`var' i.date oil_de i.highway##i.treat##i.post retail_recreation workplace, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	eststo comp1_ln_`var': quietly areg ln_`var' i.date oil_de i.within5_quart##i.treat##i.post retail_recreation workplace, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	
	* Result output
	esttab using "$tables/reg_red_`var'_oil_comp5_unbalanced.tex", /// 
	keep(_cons workplace retail_recreation 1.treat#1.post 1.highway#1.treat#1.post 1.within5_quart#1.treat#1.post 2.within5_quart#1.treat#1.post 3.within5_quart#1.treat#1.post 4.within5_quart#1.treat#1.post) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.6fc)) se(par) ci(par)) nonumbers brackets ///
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
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	eststo controls_ln_`var': quietly areg ln_`var' i.date 1.treat#1.post retail_recreation workplace, cluster(id) a(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	eststo autobahn_ln_`var': quietly areg ln_`var' i.highway##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	eststo comp1_ln_`var': quietly areg ln_`var' i.comp_within1##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	
	* Result output
	esttab using "$tables/reg_red_`var'_balanced.tex", /// 
	keep(_cons workplace retail_recreation 1.treat#1.post 1.highway#1.treat#1.post 1.comp_within1#1.treat#1.post) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.6fc)) se(par) ci(par)) nonumbers brackets ///
	stats(pt N r2,labels("Pass-Through (in \%)" "Observations" "R-squared") fmt(%9.2fc %9.0fc %9.4fc)) ///
	mtitles("Baseline" "Controls" "Highway (+ Controls)" "Competition (+ Controls)") ///
	label booktabs replace nogap collabels(none) nonotes
}



*------------------------------------------------------------------------------*
**#							2.2 Summary Statistics							 #**
*------------------------------------------------------------------------------*

*-----							2.1.1 Unbalanced						  -----*

* Load data
use "$final/00_final_weighted_unbalanced.dta", clear

* Create variable to count stations
by post id, sort: gen nvals = _n == 1

* Clear
eststo clear

* Germany before
eststo gb: quietly estpost summarize ///
e5 e10 diesel oil retail_recreation workplace highway if treat == 1 & post == 0
quietly count if nvals & treat==1 & post==0
quietly estadd scalar station = r(N)
quietly summarize within5 if treat == 1 & post == 0, detail
quietly estadd scalar within5_med = r(p50)

* Germany after
eststo ga: quietly estpost summarize ///
e5 e10 diesel oil retail_recreation workplace highway if treat == 1 & post == 1
quietly count if nvals & treat==1 & post==1
quietly estadd scalar station = r(N)
quietly summarize within5 if treat == 1 & post == 1, detail
quietly estadd scalar within5_med = r(p50)

* France before
eststo fb: quietly estpost summarize ///
e5 e10 diesel oil retail_recreation workplace highway if treat == 0 & post == 0
quietly count if nvals & treat==0 & post==0
quietly estadd scalar station = r(N)
quietly summarize within5 if treat == 0 & post == 0, detail
quietly estadd scalar within5_med = r(p50)

* France after
eststo fa: quietly estpost summarize ///
e5 e10 diesel oil retail_recreation workplace highway if treat == 0 & post == 1
quietly count if nvals & treat==0 & post==1
quietly estadd scalar station = r(N)
quietly summarize within5 if treat == 0 & post == 1, detail
quietly estadd scalar within5_med = r(p50)

* Create latex table
esttab gb ga fb fa using "$tables/sum_red_overall.tex", replace ///
booktabs cell(p(fmt(%6.3f)) & mean(fmt(%6.2f)) sd(fmt(%6.4f) par)) ///
label nostar nonumbers nogap ///
mgroups("\textbf{Germany}" "\textbf{France}",  pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) ///
span erepeat(\cmidrule(lr){@span})) ///
mtitles("Before" "After" "Before" "After") ///
stats(station within5_med N,labels("Stations" "Median Stations within 5km" "Observations") fmt(%9.0fc)) ///
collabels(none)

* Drop
drop nvals
