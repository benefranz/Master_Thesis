*------------------------------------------------------------------------------*
*-----						   	2. ANALYSIS								  -----*
*------------------------------------------------------------------------------*



*------------------------------------------------------------------------------*
*-----							2.1 Baseline							 ------*
*------------------------------------------------------------------------------*

*-----								2.1.1 Daily							  -----*
/*
* Load data
use "$final/final_daily.dta", clear

* Dif-in-Dif
xtdidregress (ln_diesel) (vat), group(id) time(date)
xtdidregress (ln_e5) (vat), group(id) time(date)
xtdidregress (ln_e10) (vat), group(id) time(date)
*/

* Load data
use "$final/00_final_weighted.dta", clear

* Dif-in-Dif
foreach var of varlist ln_e5 ln_e10 ln_diesel{
		quietly xtdidregress (`var') (vat), group(id) time(date)
		eststo baseline_`var'
}

* Result output
esttab using "$tables/reg_baseline.tex", /// 
drop(*.date) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(%9.4fc)) se(par) ci(par)) nonumbers brackets ///
stats(mean N r2,labels("Mean (Pre-reform)" "Observations" "R-squared") fmt(%9.3fc %9.0fc %9.3fc)) ///
mtitles("E5" "E10" "Diesel") ///
label booktabs replace nogap collabels(none) nonotes




*----- 	 						 2.1.2 Hourly							  -----*
/*
* Load data
use "$final/final_hourly.dta", clear

* Dif-in-Dif
xtdidregress (ln_diesel) (vat), group(id) time(time)
xtdidregress (ln_e5) (vat), group(id) time(time)
xtdidregress (ln_e10) (vat), group(id) time(time)
*/


*------------------------------------------------------------------------------*
*-----							2.2 Covariates							 ------*
*------------------------------------------------------------------------------*

*-----								2.2.1 Daily							  -----*
 
* Load data
use "$final/00_final_weighted.dta", clear

* Dif-in-Dif
foreach var of varlist ln_e5 ln_e10 ln_diesel{
		quietly xtdidregress (`var' retail_recreation workplace) (vat), group(id) time(date)
		*eststo controls_`var'
}



*------------------------------------------------------------------------------*
*-----							2.3 Interactions						 ------*
*------------------------------------------------------------------------------*

*-----								2.3.1 Daily							  -----*

* Load data
use "$final/00_final_weighted.dta", clear

* Dif-in-Dif
foreach var of varlist ln_e5 ln_e10 ln_diesel{
	areg `var' i.street_type##i.treat##i.post retail_recreation workplace i.date, absorb(id) cluster(id)
}







