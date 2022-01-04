*------------------------------------------------------------------------------*
*-----						   	2. ANALYSIS								  -----*
*------------------------------------------------------------------------------*



*------------------------------------------------------------------------------*
*-----							2.1 Baseline							 ------*
*------------------------------------------------------------------------------*

*----- 	 						 2.1.1 Hourly							  -----*

*** Load data
use "$data_out/final_hourly.dta", clear

*** Setup panel
xtset id time

*** Dif-in-Dif
xtreg ln_e5 vat, fe
xtreg ln_e10 vat, fe
xtreg ln_diesel vat, fe



*-----								2.1.1 Daily							  -----*

*** Load data
use "$data_out/final_daily.dta", clear

*** Setup panel
xtset id date

*** Dif-in-Dif
xtreg ln_e5 vat, fe
xtreg ln_e10 vat, fe
xtreg ln_diesel vat, fe


*** Load data
use "$data_out/final_weighted.dta", clear

*** Setup panel
xtset id date

*** Dif-in-Dif
xtreg ln_e5 vat, fe
xtreg ln_e10 vat, fe
xtreg ln_diesel vat, fe
