*-----					1.1.1 Tankerkönig (Germany)						  -----*


* Load data
use "$intermediate/01_germany_weighted.dta", clear


* Add weeks
gen week = wofd(date)

* Generate means
foreach var of varlist e5 e10 diesel{
	bysort id week: egen `var'_mean = mean(`var')
}

* Drop unnecessary variables
drop e5 e10 diesel date

* Rename variables
rename diesel_mean diesel
rename e5_mean e5
rename e10_mean e10

* Collapse via duplicates drop
duplicates drop id week, force

* Sort
sort id week

* Save
save "$intermediate/01_germany_weekly.dta", replace



*-----			 	  1.1.3 Le Prix Des Carburants (France)		   		  -----*

* Load data 
use "$intermediate/02_france_daily.dta", clear

* Add weeks
gen week = wofd(date)

* Generate means
foreach var of varlist e5 e10 diesel{
	bysort id week: egen `var'_mean = mean(`var')
}

* Drop unnecessary variables
drop e5 e10 diesel date

* Rename variables
rename diesel_mean diesel
rename e5_mean e5
rename e10_mean e10

* Collapse via duplicates drop
duplicates drop id week, force

* Sort
sort id week

* Save
save "$intermediate/02_france_weekly.dta", replace



*-----					1.2 Append German and French Data				  -----*

* Weekly
use "$intermediate/02_france_weekly.dta", clear
append using "$intermediate/01_germany_weekly.dta"

* Save
save "$final/appended_weekly.dta", replace



*-----			1.3.1 Generate Treat, Post, and Dif-in-Dif Variable		  -----*

* Treat
generate treat = 1
replace treat = 0 if country == "France"

* Post
generate post = 1
replace post = 0 if week < wofd(date("01jul2020","DMY"))

* Dif-in-Dif
generate vat = treat * post 



*-----	 						1.3.2 Ln Prices							  -----*

* Load data
foreach var of varlist e5 e10 diesel{
	gen ln_`var' = ln(`var')
}


* Format
format week %tw

* Save
save "$final/00_final_weekly.dta", replace



*-----			 		3.1.1 Parallel Trend Assumption		 			  -----*
*** Weekly (Treatment week 3146 (2020w27))

* Load data
use "$final/00_final_weekly.dta", clear

* Add overall coeffcients
cap drop vat4
gen vat4 = post*treat
foreach var of varlist ln_e5 ln_e10 ln_diesel{
	quietly areg `var' treat i.week vat4, cluster(id) a(id) 
	local b_`var'=round(_b[vat4],0.00000001)
	display `b_`var''
	local se_`var'=round(_se[vat4],0.00000001)
	display `se_`var''
}
local lln_e5 "E5"
local lln_e10 "E10"
local lln_diesel "Diesel"

foreach var of varlist ln_e5 ln_e10 ln_diesel {
local ypath `var'

preserve

* Dummy for weeks
forvalues i=3143/3150 {
gen d_`i'=(week==`i')
gen d_`i'_t=(week==`i' & treat==1)
}
*baseline
drop d_3146 d_3146_t //2020w27 as reference 
*regression
areg `var' treat d_31*, cluster(id) a(id) noomitted 

*effects
gen ball_t=0 if week==3146
gen upall_t=. if week==3146
gen lowall_t=. if week==3146

*pre
forvalues y=3143/3145 {
replace ball_t=_b[d_`y'] if week==`y' 
replace upall_t=_b[d_`y']+1.96*_se[d_`y'] if week==`y' 
replace lowall_t=_b[d_`y']-1.96*_se[d_`y'] if week==`y' 
}
*post
forvalues y=3147/3150 {
replace ball_t=_b[d_`y'] if week==`y' 
replace upall_t=_b[d_`y']+1.96*_se[d_`y'] if week==`y' 
replace lowall_t=_b[d_`y']-1.96*_se[d_`y'] if week==`y' 
}

by week , so: gen n=_n
keep if n==1

so week

*Plot 
twoway  (scatter ball_t week , msize(vsmall) lcolor(navy) mcolor(navy) lpattern(solid) lwidth(medthin)) ///
(rcap upall_t lowall_t week, lcolor(navy) mcolor(navy) lpattern(solid)), ///
graphregion(color(white)) bgcolor(white) xtitle("Weeks",height(6)) yline(0, lcolor(black)) yscale(range(-0.03 0.03)) ylabel(-0.03 (0.01) 0.03) ///
ytitle(Effect on `l`ypath'', height(6)) xline(3146.5, lcolor(red) lpattern(dash)) xlabel(3143(1)3150) ////
legend(off) ///
text(0.02 3148.5 "b=`b_`var'' (`se_`var'')", size(medsmall))
*caption("Treat: Age 50-54;" "Half yearly difference-in-differences coeffcients for the period 2001h2 to 2005h2 using 2002h2 as base." "The vertical bars show 95% confidence intervals based on standard errors clustered at the department and half year level.""Only including regions with Unemployment rate above 12% in last half year.""Balanced sample: Regions Caribe, Pacifica, Bogota D.C.""Y=`ypath'" , size(small) margin(t=3))
graph export "$graphs/pt_w_`var'.pdf", replace as(pdf)

forvalues y=3143/3145 {
	test (d_`y'_t=0)
}

test (d_3143_t=0) (d_3144_t=0) (d_3145_t=0)

restore
}


