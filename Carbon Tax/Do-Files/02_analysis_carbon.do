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
	eststo baseline_`var': areg `var' i.date 1.treat#1.post, cluster(id) a(id) 
	eststo controls_`var': areg `var' i.date 1.treat#1.post retail_recreation workplace, cluster(id) a(id)
	eststo autobahn_`var': areg `var' i.street_type##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	eststo comp1_`var': areg `var' i.comp_within1##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
	quietly summarize `var' if  date <= date("31dec2021", "DMY") & treat == 1
	quietly estadd scalar mean = r(mean) 
	
	* Result output
	esttab using "$tables/reg_carb_`var'_unbalanced.tex", /// 
	keep(_cons workplace retail_recreation 1.treat#1.post 1.street_type#1.treat#1.post 1.comp_within1#1.treat#1.post) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.6fc)) se(par) ci(par)) nonumbers brackets ///
	stats(mean N r2,labels("Mean (Pre-reform)" "Observations" "R-squared") fmt(%9.3fc %9.0fc %9.3fc)) ///
	mtitles("Baseline" "Controls" "Highway (+ Controls)" "Competition (+ Controls)") ///
	label booktabs replace nogap collabels(none) nonotes
}


preserve

	collapse (mean) diesel, by(date treat)
	
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

restore


*-----							2.1.2 Balanced							  -----*

* Load data
use "$final/00_final_weighted_balanced.dta", clear


foreach var of varlist e5 e10 diesel{

	* Regressions
	eststo clear
	eststo baseline_`var': areg `var' i.date 1.treat#1.post, cluster(id) a(id) 
	eststo controls_`var': areg `var' i.date 1.treat#1.post retail_recreation workplace, cluster(id) a(id)
	eststo autobahn_`var': areg `var' i.street_type##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id) 
	quietly summarize `var' if  date <= date("31dec2021", "DMY") & treat == 1
	quietly estadd scalar mean = r(mean) 
	
	* Result output
	esttab using "$tables/reg_carb_`var'_balanced.tex", /// 
	keep(_cons workplace retail_recreation 1.treat#1.post 1.street_type#1.treat#1.post) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.4fc)) se(par) ci(par)) nonumbers brackets ///
	stats(mean N r2,labels("Mean (Pre-reform)" "Observations" "R-squared") fmt(%9.3fc %9.0fc %9.3fc)) ///
	mtitles("Baseline" "Controls" "Highway (+ Controls)") ///
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
e5 e10 diesel retail_recreation workplace within1 within2 within5 within_postal if treat == 1 & post == 0
count if nvals & treat==1 & post==0
estadd scalar station = r(N)

* Germany after
eststo ga: quietly estpost summarize ///
e5 e10 diesel retail_recreation workplace within1 within2 within5 within_postal if treat == 1 & post == 1
count if nvals & treat==1 & post==1
estadd scalar station = r(N)

* France before
eststo fb: quietly estpost summarize ///
e5 e10 diesel retail_recreation workplace within1 within2 within5 within_postal if treat == 0 & post == 0
count if nvals & treat==0 & post==0
estadd scalar station = r(N)

* France after
eststo fa: quietly estpost summarize ///
e5 e10 diesel retail_recreation workplace within1 within2 within5 within_postal if treat == 0 & post == 1
count if nvals & treat==0 & post==1
estadd scalar station = r(N)

/*	
esttab gb ga fb fa using "$tables/sum_rep_overall.tex", replace ///
mtitles("\textbf{\emph{Germany before}}" "\textbf{\emph{Germany after}}" "\textbf{\emph{France before}}" "\textbf{\emph{France after}}") ///
refcat(e5 "\textbf{\emph{Prices}}" retail_recreation "\textbf{\emph{Mobility}}" within1 "\textbf{\emph{Competition}}", nolabel) ///
cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") ///
label
*/

esttab gb ga fb fa using "$tables/sum_carb_overall.tex", replace booktabs cell(p(fmt(%6.3f)) & mean(fmt(%6.2f)) sd(fmt(%6.4f) par)) label nostar nonumbers nogap ///
mgroups("\textbf{Germany}" "\textbf{France}",  pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) ///
span erepeat(\cmidrule(lr){@span})) ///
mtitles("Before" "After" "Before" "After") ///
stats(station N,labels("Stations" "Observations") fmt(%9.0fc)) ///
collabels(none)

* Drop
drop nvals


