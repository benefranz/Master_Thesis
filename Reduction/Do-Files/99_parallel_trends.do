*------------------------------------------------------------------------------*
*-----						 9. Parallel Trends							  -----*
*------------------------------------------------------------------------------*



*------------------------------------------------------------------------------*
**#								1.1 Germany							  	 	 #**
*------------------------------------------------------------------------------*

foreach y in 2019 2020 2021{
* February
forvalues ii=01/28{
	local i : di %02.0f `ii'
	import delimited "$data_in/`y'/02/`y'-02-`i'-prices.csv", varnames(1) encoding("utf-8") clear
	
	rename station_uuid id
	
	gen double time = clock(date, "YMDhms#")
	format time %tcDD_Mon_CCYY_HH:MM:SS
	drop date dieselchange e5change e10change

	gen date = dofc(time)
	
	collapse (mean) e5 e10 diesel, by(date id)
	
	collapse (mean) e5 e10 diesel, by(date)
	
	save "$source/Prices_Germany/Parallel_Trends/`y'-02-`i'-prices.dta", replace
}

* Months with 30 days (April, June, September, November)
foreach mm in 04 06 09 11{
	local m : di %02.0f `mm'
	forvalues ii=01/30{
		local i : di %02.0f `ii'
		import delimited "$data_in/`y'/`m'/`y'-`m'-`i'-prices.csv", varnames(1) encoding("utf-8") clear
			
		rename station_uuid id
			
		gen double time = clock(date, "YMDhms#")
		format time %tcDD_Mon_CCYY_HH:MM:SS
		drop date dieselchange e5change e10change

		gen date = dofc(time)

		collapse (mean) e5 e10 diesel, by(date id)
	
		collapse (mean) e5 e10 diesel, by(date)
			
		save "$source//Prices_Germany/Parallel_Trends/`y'-`m'-`i'-prices.dta", replace
	}
}

* Months with 31 days (January, March, May, July, August, October, December)
foreach mm in 01 03 05 07 08 10 12{
	local m : di %02.0f `mm'
	forvalues ii=01/31{
		local i : di %02.0f `ii'
		import delimited "$data_in/`y'/`m'/`y'-`m'-`i'-prices.csv", varnames(1) encoding("utf-8") clear
		
		rename station_uuid id
		
		gen double time = clock(date, "YMDhms#")
		format time %tcDD_Mon_CCYY_HH:MM:SS
		drop date dieselchange e5change e10change

		gen date = dofc(time)
		
		collapse (mean) e5 e10 diesel, by(date id)
	
		collapse (mean) e5 e10 diesel, by(date)
		
		save "$source//Prices_Germany/Parallel_Trends/`y'-`m'-`i'-prices.dta", replace
	}
}
}



* Apend Data
foreach y in 2019 2020 2021{
	use "$source//Prices_Germany/Parallel_Trends/`y'-01-01-prices.dta", clear
	forvalues ii = 02/31 {
		local i : di %02.0f `ii'	
		append using "$source//Prices_Germany/Parallel_Trends/`y'-01-`i'-prices.dta"
	}
	forvalues ii = 01/28{ 
		local i : di %02.0f `ii'	
		append using "$source//Prices_Germany/Parallel_Trends/`y'-02-`i'-prices.dta"
	}
	foreach mm in 04 06 09 11{
		local m : di %02.0f `mm'
		forvalues ii = 01/30 {
			local i : di %02.0f `ii'	
			append using "$source//Prices_Germany/Parallel_Trends/`y'-`m'-`i'-prices.dta"
		}
	}
	foreach mm in 03 05 07 08 10 12{
		local m : di %02.0f `mm'
		forvalues ii = 01/31 {
			local i : di %02.0f `ii'	
			append using "$source//Prices_Germany/Parallel_Trends/`y'-`m'-`i'-prices.dta"
		}
	}

	* Country
	generate treat = 1

	* Save
	save "$intermediate/99_germany_`y'_daily.dta", replace
}


*** Schaltjahr adjustment


* Load data for 29.02.2020
import delimited "$data_in/2020/02/2020-02-29-prices.csv", varnames(1) encoding("utf-8") clear
	
	rename station_uuid id
	
	gen double time = clock(date, "YMDhms#")
	format time %tcDD_Mon_CCYY_HH:MM:SS
	drop date dieselchange e5change e10change

	gen date = dofc(time)
	
	collapse (mean) e5 e10 diesel, by(date id)
	
	collapse (mean) e5 e10 diesel, by(date)
	
	generate treat = 1
	
	save "$source/Prices_Germany/Parallel_Trends/2020-02-29-prices.dta", replace
	

* Add to data from 2020
use "$intermediate/99_germany_2020_daily.dta", clear
append using "$source/Prices_Germany/Parallel_Trends/2020-02-29-prices"
save "$intermediate/99_germany_2020_daily.dta", replace

*------------------------------------------------------------------------------*
**#								1.2 France							  	 	 #**
*------------------------------------------------------------------------------*

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
drop time

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
collapse (mean) e5 e10 diesel, by(date id)

* One price per date	
collapse (mean) e5 e10 diesel, by(date)

* Country
generate treat = 0

* Drop missing
drop if date == .

* Save
save "$intermediate/99_france_`y'_daily.dta", replace
}


*------------------------------------------------------------------------------*
**#							1.3 Append + Graph						  	 	 #**
*------------------------------------------------------------------------------*

*** Germany

* Append
use "$intermediate/99_germany_2019_daily.dta", clear
append using "$intermediate/99_germany_2020_daily.dta"
append using "$intermediate/99_germany_2021_daily.dta"

* Time series
tsset date treat
format date %td
sort treat date

* Weekly 
gen week = wofd(date)
format week %tw
foreach var of varlist e5 e10 diesel {
	bysort week treat: egen `var'_week = mean(`var')
	generate `var'_wi = 100 * `var'_week/`var'_week[1]
}

* Monthly
gen month = mofd(date)
format month %tm
foreach var of varlist e5 e10 diesel {
	bysort month treat: egen `var'_month = mean(`var')
	generate `var'_mi = 100 * `var'_month/`var'_month[1], 
}

* Format
format week %twWW/CCYY
format month %tmMon_CCYY

* Save
save "$intermediate/99_germany_daily.dta", replace



*** France 

* Append
use "$intermediate/99_france_2019_daily.dta", clear
append using "$intermediate/99_france_2020_daily.dta"
append using "$intermediate/99_france_2021_daily.dta"

* Drop missing
drop if date==.

* Time series
tsset date treat
format date %td
sort treat date

* Weekly 
gen week = wofd(date)
format week %tw
foreach var of varlist e5 e10 diesel {
	bysort week treat: egen `var'_week = mean(`var')
	generate `var'_wi = 100 * `var'_week/`var'_week[1]
}

* Monthly
gen month = mofd(date)
format month %tm
foreach var of varlist e5 e10 diesel {
	bysort month treat: egen `var'_month = mean(`var')
	generate `var'_mi = 100 * `var'_month/`var'_month[1], 
}

* Format
format week %twWW/CCYY
format month %tmMon_CCYY

* Save
save "$intermediate/99_france_daily.dta", replace




* Append Germany and France
use "$intermediate/99_germany_daily.dta", clear
append using "$intermediate/99_france_daily.dta"

* Locals for Loop
local le5 "E5"
local le10 "E10"
local ldiesel "Diesel"

* Looped Graphs
foreach var of varlist e5 e10 diesel{
	graph twoway ///
	(connected `var'_mi month if treat==0, mcolor(navy) msize(small) lcolor(navy) lwidth(medthick)) ///
	(connected `var'_mi month if treat==1, mcolor(dkorange) msize(small) lcolor(dkorange) lwidth(medthick)), ///
	xline(725.5, lcolor(gs8) lpattern(dash))	/// * (line between Jun and Jul 2020)
	xline(731.5, lcolor(gs8) lpattern(dash))	/// * (line between Dec 2020 and Jan 2021)
	legend(label(1 "France") label(2 "Germany"))	///
	graphregion(color(white)) ///
	ytitle("`l`var'' Price Index (01/2019 = 100, monthly averages)") ylabel(80(10)130)	///
	xtitle("") xlabel(708(6)743) ///
	

	graph export "$graphs/trend_`var'.pdf", replace as(pdf)
}

