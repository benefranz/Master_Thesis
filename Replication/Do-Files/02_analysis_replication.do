*------------------------------------------------------------------------------*
*-----						   	2. ANALYSIS								  -----*
*------------------------------------------------------------------------------*



*------------------------------------------------------------------------------*
*-----							2.1 Baseline							 ------*
*------------------------------------------------------------------------------*

*-----								2.1.1 Daily							  -----*

* Load data
use "$final/final_daily.dta", clear

* Dif-in-Dif
xtdidregress (ln_diesel) (vat), group(id) time(date)
xtdidregress (ln_e5) (vat), group(id) time(date)
xtdidregress (ln_e10) (vat), group(id) time(date)


* Load data
use "$final/00_final_weighted.dta", clear

/*
* Test
bysort id : egen frombeginning = count(date)
drop if frombeginning<47
*/

* Dif-in-Dif
xtdidregress (ln_diesel) (vat), group(id) time(date)
xtdidregress (ln_e5) (vat), group(id) time(date)
xtdidregress (ln_e10) (vat), group(id) time(date)



*----- 	 						 2.1.2 Hourly							  -----*

* Load data
use "$final/final_hourly.dta", clear

* Dif-in-Dif
xtdidregress (ln_diesel) (vat), group(id) time(time)
xtdidregress (ln_e5) (vat), group(id) time(time)
xtdidregress (ln_e10) (vat), group(id) time(time)



*------------------------------------------------------------------------------*
*-----							2.2 Covariates							 ------*
*------------------------------------------------------------------------------*

*-----								2.2.1 Daily							  -----*
 
* Load data
use "$final/00_final_weighted.dta", clear

* Dif-in-Dif
xtdidregress (ln_diesel retail_and_recreation_percent_ch workplaces_percent_change_from_b) (vat), group(id) time(date)
xtdidregress (ln_e5 retail_and_recreation_percent_ch workplaces_percent_change_from_b) (vat), group(id) time(date)
xtdidregress (ln_e10 retail_and_recreation_percent_ch workplaces_percent_change_from_b) (vat), group(id) time(date)



*------------------------------------------------------------------------------*
*-----							2.3 Interactions						 ------*
*------------------------------------------------------------------------------*

*-----								2.3.1 Daily							  -----*

* Load data
use "$final/00_final_weighted.dta", clear

* Dif-in-Dif







