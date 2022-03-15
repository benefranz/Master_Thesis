*** French Petrol Station Investigation

**# Weekly

foreach y in 2019 2020 2021{
* Load data
import delimited "$data_in/PrixCarburants_annuel_`y'.csv", numericcols(9) encoding("utf-8") clear

* Keep necessary variables
keep v1 v6 v8 v9

* Format date
gen double time = clock(v6, "YMD#hms")
format time %tcDD_Mon_CCYY_HH:MM:SS
drop v6
gen date = dofc(time)
gen week = wofd(date)
drop time date

* Rename Variables
rename v1 id
rename v8 fuel
rename v9 price

* Drop unnecessary variables
drop if fuel == "E85"
drop if fuel == "GPLc"

* Convert to euros
replace price = price/1000

* Reshape 
gen diesel = price if fuel == "Gazole"	
gen e10 = price if fuel == "E10"
gen e5 = price if fuel == "SP95"
drop price fuel

* One price per station and date	
collapse (mean) e5 e10 diesel, by(week id)

* One price per date	
collapse (count) id, by(week)

* Drop missing
drop if week == .

* Format
format week %tw

* Save
save "$intermediate/99_france_`y'_weekly.dta", replace
}


* Graph 2019

use "$intermediate/99_france_2019_weekly.dta", clear

graph twoway connected id week, mcolor(navy) msize(small) lcolor(navy) lwidth(medthick) ///
xline(3092.5, lcolor(gs8) lpattern(dash)) ///
graphregion(color(white)) ///
ytitle("") ylabel(4000(1000)10000, angle(horizontal))	///
xtitle("") xlabel(3068(4)3119, angle(vertical)) ///
saving("$graphs/2019_weekly", replace)



* Graph 2020

use "$intermediate/99_france_2020_weekly.dta", clear

graph twoway connected id week, mcolor(navy) msize(small) lcolor(navy) lwidth(medthick) ///
xline(3145.5, lcolor(gs8) lpattern(dash)) ///
graphregion(color(white)) ///
ytitle("") ylabel(4000(1000)10000, angle(horizontal))	///
xtitle("") xlabel(3120(4)3171, angle(vertical)) ///
saving("$graphs/2020_weekly", replace)

* Graph 2021

use "$intermediate/99_france_2021_weekly.dta", clear

graph twoway connected id week, mcolor(navy) msize(small) lcolor(navy) lwidth(medthick) ///
xline(3196.5, lcolor(gs8) lpattern(dash)) ///
graphregion(color(white)) ///
ytitle("") ylabel(4000(1000)10000, angle(horizontal))	///
xtitle("") xlabel(3172(4)3223, angle(vertical)) ///
saving("$graphs/2021_weekly", replace)

graph combine "$graphs/2019_weekly.gph" "$graphs/2020_weekly.gph" "$graphs/2021_weekly.gph", col(1) iscale(0.6)
	
graph export "$graphs/station_count_weekly.pdf", replace as(pdf)




**# Monthly

foreach y in 2019 2020 2021{
* Load data
import delimited "$data_in/PrixCarburants_annuel_`y'.csv", numericcols(9) encoding("utf-8") clear

* Keep necessary variables
keep v1 v6 v8 v9

* Format date
gen double time = clock(v6, "YMD#hms")
format time %tcDD_Mon_CCYY_HH:MM:SS
drop v6
gen date = dofc(time)
gen month = mofd(date)
drop time date

* Rename Variables
rename v1 id
rename v8 fuel
rename v9 price

* Drop unnecessary variables
drop if fuel == "E85"
drop if fuel == "GPLc"

* Convert to euros
replace price = price/1000

* Reshape 
gen diesel = price if fuel == "Gazole"	
gen e10 = price if fuel == "E10"
gen e5 = price if fuel == "SP95"
drop price fuel

* One price per station and date	
collapse (mean) e5 e10 diesel, by(month id)

* One price per date	
collapse (count) id, by(month)

* Drop missing
drop if month == .

* Format
format month %tm

* Save
save "$intermediate/99_france_`y'_monthly.dta", replace
}


* Graph 2019

use "$intermediate/99_france_2019_monthly.dta", clear

graph twoway connected id month, mcolor(navy) msize(small) lcolor(navy) lwidth(medthick) ///
xline(713.5, lcolor(gs8) lpattern(dash)) ///
graphregion(color(white)) ///
ytitle("") ylabel(8000(500)10000, angle(horizontal))	///
xtitle("") xlabel(708(1)719, angle(vertical)) ///
saving("$graphs/2019_monthly", replace)



* Graph 2020

use "$intermediate/99_france_2020_monthly.dta", clear

graph twoway connected id month, mcolor(navy) msize(small) lcolor(navy) lwidth(medthick) ///
xline(725.5, lcolor(gs8) lpattern(dash)) ///
graphregion(color(white)) ///
ytitle("") ylabel(8000(500)10000, angle(horizontal))	///
xtitle("") xlabel(720(1)731, angle(vertical)) ///
saving("$graphs/2020_monthly", replace)

* Graph 2021

use "$intermediate/99_france_2021_monthly.dta", clear

graph twoway connected id month, mcolor(navy) msize(small) lcolor(navy) lwidth(medthick) ///
xline(737.5, lcolor(gs8) lpattern(dash)) ///
graphregion(color(white)) ///
ytitle("") ylabel(8000(500)10000, angle(horizontal))	///
xtitle("") xlabel(732(1)743, angle(vertical)) ///
saving("$graphs/2021_monthly", replace)

graph combine "$graphs/2019_monthly.gph" "$graphs/2020_monthly.gph" "$graphs/2021_monthly.gph", col(1) iscale(0.6)
	
graph export "$graphs/station_count_monthly.pdf", replace as(pdf)




**# Further Investigation
foreach y in 2019 2020 2021{
* Load data
import delimited "$data_in/PrixCarburants_annuel_`y'.csv", numericcols(9) encoding("utf-8") clear

* Keep necessary variables
keep v1

* Rename 
rename v1 id

* Generate year
gen year = `y'

* Save
save "$intermediate/99_france_`y'_yearly.dta", replace
}

use "$intermediate/99_france_2019_yearly.dta", clear
append using "$intermediate/99_france_2020_yearly.dta"
append using "$intermediate/99_france_2021_yearly.dta"


duplicates drop id year, force
duplicates report id
