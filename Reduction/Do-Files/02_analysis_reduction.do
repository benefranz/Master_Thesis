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
	eststo baseline_ln_`var': quietly areg ln_`var' i.date 1.treat#1.post, cluster(id) a(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	eststo controls_ln_`var': quietly areg ln_`var' i.date 1.treat#1.post retail_recreation workplace, cluster(id) a(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	eststo autobahn_ln_`var': quietly areg ln_`var' i.highway##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	eststo comp1_ln_`var': quietly areg ln_`var' i.comp_within1##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	estadd scalar pt = _b[1.treat#1.post]/(-0.03/1.19)*100
	
	* Result output
	esttab using "$tables/reg_rep_`var'_unbalanced.tex", /// 
	keep(_cons workplace retail_recreation 1.treat#1.post 1.highway#1.treat#1.post 1.comp_within1#1.treat#1.post) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.6fc)) se(par) ci(par)) nonumbers brackets ///
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
e5 e10 diesel retail_recreation workplace highway within1 within2 within5 within_postal if treat == 1 & post == 0
count if nvals & treat==1 & post==0
estadd scalar station = r(N)

* Germany after
eststo ga: quietly estpost summarize ///
e5 e10 diesel retail_recreation workplace highway within1 within2 within5 within_postal if treat == 1 & post == 1
count if nvals & treat==1 & post==1
estadd scalar station = r(N)

* France before
eststo fb: quietly estpost summarize ///
e5 e10 diesel retail_recreation workplace highway within1 within2 within5 within_postal if treat == 0 & post == 0
count if nvals & treat==0 & post==0
estadd scalar station = r(N)

* France after
eststo fa: quietly estpost summarize ///
e5 e10 diesel retail_recreation workplace highway within1 within2 within5 within_postal if treat == 0 & post == 1
count if nvals & treat==0 & post==1
estadd scalar station = r(N)

/*	
esttab gb ga fb fa using "$tables/sum_red_overall.tex", redlace ///
mtitles("\textbf{\emph{Germany before}}" "\textbf{\emph{Germany after}}" "\textbf{\emph{France before}}" "\textbf{\emph{France after}}") ///
refcat(e5 "\textbf{\emph{Prices}}" retail_recreation "\textbf{\emph{Mobility}}" within1 "\textbf{\emph{Competition}}", nolabel) ///
cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") ///
label
*/

esttab gb ga fb fa using "$tables/sum_red_overall.tex", replace booktabs cell(p(fmt(%6.3f)) & mean(fmt(%6.2f)) sd(fmt(%6.4f) par)) label nostar nonumbers nogap ///
mgroups("\textbf{Germany}" "\textbf{France}",  pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) ///
span erepeat(\cmidrule(lr){@span})) ///
mtitles("Before" "After" "Before" "After") ///
stats(station N,labels("Stations" "Observations") fmt(%9.0fc)) ///
collabels(none)

* Drop
drop nvals
