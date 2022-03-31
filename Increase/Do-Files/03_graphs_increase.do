*------------------------------------------------------------*
*----					3. GRAPHS						-----*
*------------------------------------------------------------*

graph set window fontface "Garamond"



*------------------------------------------------------------------------------*
**#							3.1 Descriptive Analysis					  	 #**
*------------------------------------------------------------------------------*

* Load data
use "$final/00_final_weighted_unbalanced.dta", clear

* Drop unnecessary variables
keep date e5 e10 diesel treat post

* Collapse daily
foreach var of varlist e5 e10 diesel{
	bysort treat date: egen `var'_mean = mean(`var')
	drop `var'
	rename `var'_mean `var'
}

* Drop duplicates
duplicates drop treat date, force

* Demeaned prices
foreach var of varlist e5 e10 diesel{
	quietly: summarize `var' if treat == 1 & post == 0
	local pre_`var'_ger = r(mean)
	quietly: summarize `var' if treat == 0 & post == 0
	local pre_`var'_fra = r(mean)
	
	generate demeaned_`var'_ger = `var' - `pre_`var'_ger' if treat == 1
	generate demeaned_`var'_fra = `var' - `pre_`var'_fra' if treat == 0
	
	sort date treat
	
	replace demeaned_`var'_ger = demeaned_`var'_ger[_n+1] if demeaned_`var'_ger == .
	replace demeaned_`var'_fra = demeaned_`var'_fra[_n-1] if demeaned_`var'_fra == .
}

* Collapse
keep date demeaned*
duplicates drop date, force

* Generate descriptive pass-through
generate pt_e5 = (demeaned_e5_ger - demeaned_e5_fra)/0.10
generate pt_e10 = (demeaned_e10_ger - demeaned_e10_fra)/0.10
generate pt_diesel = (demeaned_diesel_ger - demeaned_diesel_fra)/0.11

* Graph	
graph twoway ///
(line pt_e5 date, color("255 165 77")) ///
(line pt_e10 date, color("5 174 185")) ///
(line pt_diesel date, color("0 66 108")), ///
ytitle("Share of total tax change", size(small)) ///
ylabel(,labsize(vsmall)) ///
xtitle("") ///
xlabel(,labsize(vsmall)) ///
yline(1, lcolor(gs8) lpattern(dash))	///
yline(0, lcolor(gs8) lpattern(solid))	///
tline(15dec2020, lcolor(gs8) lpattern(dash))	///
tlabel(15dec2020, add) ///
xline(22280.5, lcolor(gs8) lpattern(solid))	///
graphregion(color(white)) bgcolor(white) ///
legend(label(1 "E5") label(2 "E10") label(3 "Diesel") rows(1) size(small))

* Save
graph export "$graphs/desc_pt_inc.pdf", replace as(pdf)


*------------------------------------------------------------------------------*
**#								3.2 Parallel Trends						  	 #**
*------------------------------------------------------------------------------*

* Load data
use "$final/00_final_weighted_unbalanced.dta", clear

* Drop unnecessary variables
keep date e5 e10 diesel treat post oil id

* Drop 16.12.2020 to 31.12.2020
drop if date>date("15dec2020","DMY") & date<=date("31dec2020","DMY")

* Generate week variable
generate week=0

replace week = 1 if date>=date("01nov2020","DMY") & date<=date("08nov2020","DMY")
replace week = 2 if date>=date("09nov2020","DMY") & date<=date("15nov2020","DMY")
replace week = 3 if date>=date("16nov2020","DMY") & date<=date("23nov2020","DMY")
replace week = 4 if date>=date("24nov2020","DMY") & date<=date("30nov2020","DMY")
replace week = 5 if date>=date("01dec2020","DMY") & date<=date("08dec2020","DMY")
replace week = 6 if date>=date("09dec2020","DMY") & date<=date("15dec2020","DMY")
replace week = 7 if date>=date("16dec2020","DMY") & date<=date("24dec2020","DMY")
replace week = 8 if date>=date("25dec2020","DMY") & date<=date("31dec2020","DMY")
replace week = 9 if date>=date("01jan2021","DMY") & date<=date("08jan2021","DMY")
replace week = 10 if date>=date("09jan2021","DMY") & date<=date("15jan2021","DMY")
replace week = 11 if date>=date("16jan2021","DMY") & date<=date("23jan2021","DMY")
replace week = 12 if date>=date("24jan2021","DMY") & date<=date("31jan2021","DMY")
replace week = 13 if date>=date("01feb2021","DMY") & date<=date("07feb2021","DMY")
replace week = 14 if date>=date("08feb2021","DMY") & date<=date("14feb2021","DMY")
replace week = 15 if date>=date("15feb2021","DMY") & date<=date("21feb2021","DMY")
replace week = 16 if date>=date("22feb2021","DMY") & date<=date("28feb2021","DMY")


* Generate weekly means
foreach var of varlist e5 e10 diesel{
	bysort id week: egen `var'_mean = mean(`var')
	drop `var'
	rename `var'_mean `var'
}
/*
* Generate oil mean
egen oil_mean = mean(oil), by(week)
drop oil
rename oil_mean oil
*/
* Drop unnecessary variable
drop date

* Collapse via duplicates drop
duplicates drop id week, force

* Sort
sort id week

* Generate ln
foreach var of varlist e5 e10 diesel{
	gen ln_`var' = ln(`var')
}

* Graph
eststo clear
eststo e5: quietly areg ln_e5 ib6.week##c.treat, a(id) cluster(id)
eststo e10: quietly areg ln_e10 ib6.week##c.treat, a(id) cluster(id)
eststo diesel: quietly areg ln_diesel ib6.week##c.treat, a(id) cluster(id)

coefplot ///
(e5, color("255 165 77") msize(small) ciopts(lcolor("255 165 77"))) ///
(e10, color("5 174 185") msize(small) ciopts(lcolor("5 174 185"))) ///
(diesel, color("0 66 108") msize(small) ciopts(lcolor("0 66 108"))), ///
keep(*week#*) recast(connected) base omitted vertical nooffsets ///
xline(6.5, lcolor(gs8)) ///
yline(0, lcolor(gs8)) ///
xlabel(1 "1-8 Nov" 2 "9-15 Nov" 3 "16-23 Nov" 4 "24-30 Nov" 5 "1-8 Dec" 6 "9-15 Dec" 7 "1-8 Jan" 8 "9-15 Jan" 9 "16-23 Jan" 10 "24-31 Jan" 11 "1-7 Feb" 12 "8-14 Feb" 13 "15-21 Feb" 14 "22-28 Feb", angle(vertical) labsize(vsmall)) ///
ytitle("Price Changes in Log", size(small)) ///
ylabel(-0.02(0.02)0.1, labsize(vsmall)) ///
graphregion(color(white)) bgcolor(white) ///
legend(label(2 "E5") label(4 "E10") label(6 "Diesel") rows(1) size(small))

graph export "$graphs/reg_pt_inc.pdf", replace as(pdf)



*------------------------------------------------------------------------------*
**#							3.3 Distributions							  	 #**
*------------------------------------------------------------------------------*

*----- 		3.3.1 Price Distributions (pre outlier management)			  -----*

* Load data
use "$final/merged_weighted.dta", clear

* Negative values as missing
foreach var of varlist e5 e10 diesel{
	replace `var'=. if `var'<0
}

* Graph Kernel Density
foreach var of varlist e5 e10 diesel{
	
	local le5 "E5"
	local le10 "E10"
	local ldiesel "Diesel"	
	
	twoway (kdensity `var' if country == "France", lcolor(navy) lwidth(medthick)) ///
	(kdensity `var' if country == "Germany", lcolor(dkorange) lwidth(medthick)), ///
	legend(label(1 "Control (France)") label(2 "Treatment (Germany)")) ///	
	/*lcolor(navy) lwidth(medthick)*/ ///
	graphregion(color(white)) bgcolor(white) ///
	ytitle(Kernel Density) ///
	xtitle("`l`var'' Prices") xlabel(0(0.5)3.5)
	
	graph export "$graphs/distr_inc_`var'.pdf", replace as(pdf)
}



*-----			 		3.3.2 Competition Distributions		 			  -----*

* Load data
use "$intermediate/06_competition_radius.dta", clear

* Graph
foreach var of varlist within1 within2 within5{
	
	local lwithin1 "1"
	local lwithin2 "2"
	local lwithin5 "5"		
	
	twoway histogram `var', fraction ///
	color(navy) ///
	graphregion(color(white)) bgcolor(white) ///
	xtitle("Petrol Stations within `l`var''km")

	graph export "$graphs/distr_comp_inc_`var'.pdf", replace as(pdf)	
}
