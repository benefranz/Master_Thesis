*------------------------------------------------------------------------------*
*-----						   		1. DATA								  -----*
*------------------------------------------------------------------------------*



*------------------------------------------------------------------------------*
*----					1.1 Data Download and Reshaping					  -----*
*------------------------------------------------------------------------------*

*-----				1.1.1 Tankerkönig Stations (Germany)				  -----*

* June
forvalues ii=15/30{
	local i : di %02.0f `ii'
	import delimited "$data_in/06 Stations/2020-06-`i'-stations.csv", varnames(1) encoding("utf-8") clear
	
	gen date = date("2020-06-`i'", "YMD")
	rename uuid id
	rename post_code postal
	
	drop openingtimes_json first_active name brand street house_number city
	
	save "$source/Stations_Germany/2020-06-`i'-stations.dta", replace
}


* July
forvalues ii=01/31{
	local i : di %02.0f `ii'
	import delimited "$data_in/07 Stations/2020-07-`i'-stations.csv", varnames(1) encoding("utf-8") clear
	
	gen date = date("2020-07-`i'", "YMD")
	rename uuid id
	rename post_code postal
	
	drop openingtimes_json first_active name brand street house_number city
	
	save "$source/Stations_Germany/2020-07-`i'-stations.dta", replace
}



*-----					1.1.2 Tankerkönig Prices (Germany)				  -----*

* June
forvalues ii=15/30{
	local i : di %02.0f `ii'	
	import delimited "$data_in/06 Prices/2020-06-`i'-prices.csv", varnames(1) encoding("utf-8") clear
	
	rename station_uuid id
	
	gen double time = clock(date, "YMDhms#")
	format time %tcDD_Mon_CCYY_HH:MM:SS
	drop date dieselchange e5change e10change

	gen date = dofc(time)
	gen hour = hh(time)
	gen datehour = date*24 + hour
	
	save "$source/Prices_Germany/2020-06-`i'-prices.dta", replace
}

* July
forvalues ii=01/31{
	local i : di %02.0f `ii'
	import delimited "$data_in/07 Prices/2020-07-`i'-prices.csv", varnames(1) encoding("utf-8") clear
	
	rename station_uuid id
	
	gen double time = clock(date, "YMDhms#")
	format time %tcDD_Mon_CCYY_HH:MM:SS
	drop date dieselchange e5change e10change

	gen date = dofc(time)
	gen hour = hh(time)
	gen datehour = date*24 + hour
	
	save "$source/Prices_Germany/2020-07-`i'-prices.dta", replace
}

* Merge prices with information stations (June)
forvalues ii=15/30{
	local i : di %02.0f `ii'
	use "$source/Prices_Germany/2020-06-`i'-prices.dta", clear
	
	merge m:1 id date using "$source/Stations_Germany/2020-06-`i'-stations.dta"
	
	keep if _merge == 3
	drop _merge
	
	save "$source/Merged_Germany/2020-06-`i'-merged.dta", replace
}

* Merge prices with information stations (July)
forvalues ii=01/31{
	local i : di %02.0f `ii'
	use "$source/Prices_Germany/2020-07-`i'-prices.dta", clear
	
	merge m:1 id date using "$source/Stations_Germany/2020-07-`i'-stations.dta"
	
	keep if _merge == 3
	drop _merge
	
	save "$source/Merged_Germany/2020-07-`i'-merged.dta", replace
}

* Apend Data
use "$source/Merged_Germany/2020-06-15-merged.dta", clear
forvalues mm = 16/30 {
	local m : di %02.0f `mm'	
	append using "$source/Merged_Germany/2020-06-`m'-merged.dta"
}
forvalues oo = 01/31{ 
	local o : di %02.0f `oo'	
	cap append using "$source/Merged_Germany/2020-07-`o'-merged.dta"
}

* Create numeric ID based on non-numeric ID
egen id_new = group(id)
drop id
rename id_new id

* Replace 0 or missing values with previous prices
foreach var of varlist diesel e5 e10 {
    bys id (time): replace `var' = `var'[_n-1] if `var' == 0 | `var' == .
}

* Expand data
bys id (time): gen exp = cond(_n==_N, td(01-08-2020)*24-datehour, datehour[_n+1]-datehour)
expand exp
bys id (time): replace hour = cond(hour[_n-1]<23, hour[_n-1]+1, 0) if time == time[_n-1]
bys id (time): replace datehour = datehour[_n-1] + 1 if time == time[_n-1]
replace date = (datehour - hour) / 24

* Reformat time
replace time = dhms(date, hour, 0, 0)
format time %tc

* Drop unnecessary variables
drop exp date hour datehour

* Collapse data hourly
foreach var of varlist diesel e5 e10 {
	bysort id time: egen `var'_mean = mean(`var')
}
drop diesel e5 e10
rename diesel_mean diesel
rename e5_mean e5
rename e10_mean e10
duplicates drop

* Generate treatment variable
gen treat = 1

* Generate post variable
gen post = 1
replace post = 0 if time < clock("01jul2020 00:00:00", "DMYhms")

* Destring postal
destring postal, replace

* Correct postal codes
replace postal = 01239 if postal == 01275
replace postal = 06711 if postal == 06727
replace postal = 06909 if postal == 06909		// Error
replace postal = 07334 if postal == 07334		// Error
replace postal = 09557 if postal == 09537
replace postal = 24955 if postal == 24952
replace postal = 25813 if postal == 25875
replace postal = 27637 if postal == 27637		// Error
replace postal = 28857 if postal == 28875
replace postal = 29596 if postal == 29596		// Error
replace postal = 32584 if postal == 32484
replace postal = 35440 if postal == 35446
replace postal = 49448 if postal == 49889
replace postal = 51467 if postal == 51247
replace postal = 59368 if postal == 59386
replace postal = 65205 if postal == 66205
replace postal = 67480 if postal == 67440
replace postal = 73235 if postal == 72335
replace postal = 86753 if postal == 86763
replace postal = 97215 if postal == 91215
replace postal = 94559 if postal == 94595
replace postal = 98739 if postal == 98739		// Error

* Save
save "$intermediate/01_germany_hourly.dta", replace


* Create neccessary time variables
gen date = dofc(time)
gen hour = hh(time)

* Drop observations to replicate opening hours
drop if hour<6
drop if hour>22

* Preserve data to compare weighted with normal mean prices
preserve

* Generate variable with weights
gen fueling_behaviour = 0
replace fueling_behaviour = 0.9 if hour == 6
replace fueling_behaviour = 0.6 if hour == 7
replace fueling_behaviour = 0.8 if hour == 8
replace fueling_behaviour = 1.6 if hour == 9
replace fueling_behaviour = 2.9 if hour == 10
replace fueling_behaviour = 3.3 if hour == 11
replace fueling_behaviour = 2.2 if hour == 12
replace fueling_behaviour = 1.8 if hour == 13
replace fueling_behaviour = 3.6 if hour == 14
replace fueling_behaviour = 4.4 if hour == 15
replace fueling_behaviour = 6.4 if hour == 16
replace fueling_behaviour = 13.7 if hour == 17
replace fueling_behaviour = 15.8 if hour == 18
replace fueling_behaviour = 9.4 if hour == 19
replace fueling_behaviour = 3.2 if hour == 20
replace fueling_behaviour = 1.6 if hour == 21
replace fueling_behaviour = 0.6 if hour == 22

* Generate weighted means
foreach var of varlist diesel e5 e10{
	bysort id date: asgen `var'_mean = `var', weights(fueling_behaviour)
}
* Drop unnecessary variables
drop diesel e5 e10 time hour fueling_behaviour

* Rename variables
rename diesel_mean diesel
rename e5_mean e5
rename e10_mean e10

* Collapse via duplicates drop
duplicates drop

* Save
save "$intermediate/01_germany_weighted.dta", replace


* Restore
restore

* Generate means
foreach var of varlist diesel e5 e10{
	bysort id date: egen `var'_mean = mean(`var')
}

* Drop unnecessary variables
drop diesel e5 e10 time hour

* Rename variables
rename diesel_mean diesel
rename e5_mean e5
rename e10_mean e10

* Collapse via duplicates drop
duplicates drop

* Save
save "$intermediate/01_germany_daily.dta", replace



*-----			 	  1.1.3 Le Prix Des Carburants (France)		   		  -----*

* Load data
import delimited "$data_in/PrixCarburants_annuel_2020.csv", numericcols(9) encoding("utf-8") clear

* Rename variables
rename v1 id
rename v2 postal
rename v4 latitude
rename v5 longitude
rename v7 id_fuel
rename v8 fuel
rename v9 price

* Street Type to Dummy
gen street_type = 0
replace street_type = 1 if v3 == "A"
drop v3

* Format date
gen double time = clock(v6, "YMD#hms")
format time %tcDD_Mon_CCYY_HH:MM:SS
drop v6

* Drop unnecessary observations
drop id_fuel
drop if fuel == "E85"
drop if fuel == "GPLc"
drop if time < clock("2020-06-15 00:00:00", "YMDhms")
drop if time > clock("2020-07-31 23:59:59", "YMDhms")

* Convert to euros
replace price = price/1000

* Reshape 
gen diesel = price if fuel == "Gazole"	
gen e10 = price if fuel == "E10"
gen e5 = price if fuel == "SP95"
drop price fuel

* Convert coordinates
replace latitude = latitude/100000
replace longitude = longitude/100000

* Create further temporal variables
gen date = dofc(time)
gen hour = hh(time)
gen datehour = date*24 + hour

* Replace 0 or missing values with previous prices
foreach var of varlist diesel e5 e10 {
    bys id (time): replace `var' = `var'[_n-1] if `var' == 0 | `var' == .
}

* Expand data
bys id (time): gen exp = cond(_n==_N, td(01-08-2020)*24-datehour, datehour[_n+1]-datehour)
expand exp
bys id (time): replace hour = cond(hour[_n-1]<23, hour[_n-1]+1, 0) if time == time[_n-1]
bys id (time): replace datehour = datehour[_n-1] + 1 if time == time[_n-1]
replace date = (datehour - hour) / 24

* Reformat time
replace time = dhms(date, hour, 0, 0)
format time %tc

* Drop unnecessary variables
drop exp date hour datehour

* Collapse data hourly
foreach var of varlist diesel e5 e10 {
	bysort id time: egen `var'_mean = mean(`var')
}
drop diesel e5 e10
rename diesel_mean diesel
rename e5_mean e5
rename e10_mean e10
duplicates drop

* Generate treatment variable
gen treat = 0

* Generate post variable
gen post = 1
replace post = 0 if time < clock("01jul2020 00:00:00", "DMYhms")

* Save
save "$intermediate/02_france_hourly.dta", replace


* Collapse data daily
gen date = dofc(time)
gen hour = hh(time)
drop if hour<6
drop if hour>22
foreach var of varlist diesel e5 e10 {
	bysort id date: egen `var'_mean = mean(`var')
}
drop diesel e5 e10 time hour
rename diesel_mean diesel
rename e5_mean e5
rename e10_mean e10
duplicates drop

* Save
save "$intermediate/02_france_daily.dta", replace


*-----				1.1.4 Type of Attached Street (Germany)				  -----*

* Load data
import excel "$data_in/tankstellen_autobahn_bundestrasse.xls", clear 

* Rename
rename A street_id
rename B street_type
rename C id
rename D name
rename E brand
rename F street
rename G number
rename H postal
rename I city

* Drop unnecessary variables
drop street_id name street number postal city

* save
save "$intermediate/03_germany_streettype.dta", replace



*-----					 1.1.5 Google Mobility Reports					  -----*

* Load data
foreach c in "DE" "FR"{
		
		import delimited "$data_in/2020_`c'_Region_Mobility_Report", encoding("utf-8") clear
		
		gen double date2 = date(date, "YMD")
		drop date
		rename date2 date
		format date %tdDD_Mon_CCYY
		
		
		save "$source/Mobility/2020_`c'_Region_Mobility_Report.dta", replace
}



*----- 1.1.6 French postal codes to regions (sub_region_1) and deparments (sub_region_2) -----*

* Load data
import delimited "https://www.data.gouv.fr/fr/datasets/r/dbe8a621-a9c4-4bc3-9cae-be1699c5ff25", encoding("utf-8") clear

* Drop unnecessary variables
keep code_postal nom_departement nom_region

* Rename for merging
rename code_postal postal
rename nom_region sub_region_1
rename nom_departement sub_region_2

* Save
save "$intermediate/04_france_postal.dta", replace



*-----		 1.1.7 German postal codes to Bundesländer (sub_region_1)	  -----*

* Load data
import delimited "$data_in/PLZ_BULA_amtlOZUSATZ_2021_Q1.txt", clear

* Generate iso_3166_2_code
gen iso_3166_2_code="DE"
replace iso_3166_2_code="DE-SH" if bundesland=="Schleswig-Holstein"
replace iso_3166_2_code="DE-HH" if bundesland=="Hamburg"
replace iso_3166_2_code="DE-NI" if bundesland=="Niedersachsen"
replace iso_3166_2_code="DE-HB" if bundesland=="Bremen"
replace iso_3166_2_code="DE-NW" if bundesland=="Nordrhein-Westfalen"
replace iso_3166_2_code="DE-HE" if bundesland=="Hessen"
replace iso_3166_2_code="DE-RP" if bundesland=="Rheinland-Pfalz"
replace iso_3166_2_code="DE-BW" if bundesland=="Baden-Württemberg"
replace iso_3166_2_code="DE-BY" if bundesland=="Bayern"
replace iso_3166_2_code="DE-SL" if bundesland=="Saarland"
replace iso_3166_2_code="DE-BE" if bundesland=="Berlin"
replace iso_3166_2_code="DE-BB" if bundesland=="Brandenburg"
replace iso_3166_2_code="DE-MV" if bundesland=="Mecklenburg-Vorpommern"
replace iso_3166_2_code="DE-SN" if bundesland=="Sachsen"
replace iso_3166_2_code="DE-ST" if bundesland=="Sachsen-Anhalt"
replace iso_3166_2_code="DE-TH" if bundesland=="Thüringen"

* Generate sub_region_1
gen sub_region_1="Germany"
replace sub_region_1="Schleswig-Holstein" if bundesland=="Schleswig-Holstein"
replace sub_region_1="Hamburg" if bundesland=="Hamburg"
replace sub_region_1="Lower Saxony" if bundesland=="Niedersachsen"
replace sub_region_1="Bremen" if bundesland=="Bremen"
replace sub_region_1="North Rhine-Westphalia" if bundesland=="Nordrhein-Westfalen"
replace sub_region_1="Hessen" if bundesland=="Hessen"
replace sub_region_1="Rhineland-Palatinate" if bundesland=="Rheinland-Pfalz"
replace sub_region_1="Baden-Württemberg" if bundesland=="Baden-Württemberg"
replace sub_region_1="Bavaria" if bundesland=="Bayern"
replace sub_region_1="Saarland" if bundesland=="Saarland"
replace sub_region_1="Berlin" if bundesland=="Berlin"
replace sub_region_1="Brandenburg" if bundesland=="Brandenburg"
replace sub_region_1="Mecklenburg-Vorpommern" if bundesland=="Mecklenburg-Vorpommern"
replace sub_region_1="Saxony" if bundesland=="Sachsen"
replace sub_region_1="Saxony-Anhalt" if bundesland=="Sachsen-Anhalt"
replace sub_region_1="Thuringia" if bundesland=="Thüringen"

* Rename
rename plz postal

* Drop unnecessary variables
drop oname plz_ozusatz bundesland plz_art_auslieferung

/*
* Add missing postals
set obs `=_N+21'
replace postal = 01275 if _n == _N-20
replace iso_3166_2_code = "" if _n == _N-20
replace sub_region_1 = "" if _n == _N-20
replace postal = 01275 if _n == _N-20
replace iso_3166_2_code = "" if _n == _N-20
replace sub_region_1 = "" if _n == _N-20
replace postal = 01275 if _n == _N-20
replace iso_3166_2_code = "" if _n == _N-20
replace sub_region_1 = "" if _n == _N-20
*/

* Save
save "$intermediate/05_germany_postal.dta", replace



*------------------------------------------------------------------------------*
*----						1.2 Merge and Append						  -----*
*------------------------------------------------------------------------------*

*--					1.2.2 Merge German Data with Regions					 --*

* Load data
use "$intermediate/01_germany_weighted.dta", clear

* Merge
merge m:m postal using "$intermediate/05_germany_postal.dta" // 326 not matched from master -> see errors with postal
keep if _merge == 3
drop _merge



*--					1.2.3 Merge German Data with Mobility					 --*

* Merge
merge m:m sub_region_1 date using"$source/Mobility/2020_DE_Region_Mobility_Report.dta"	// 0 not matched from master
keep if _merge == 3
drop _merge

* Save
save "$final/01_germany.dta", replace



*--					1.2.4 Merge French  Data with Regions					 --*

* Load data
use "$intermediate/02_france_daily.dta", clear

* Merge
merge m:m postal using "$intermediate/04_france_postal.dta" //1844 not matched from master
keep if _merge == 3
drop _merge



*--					1.2.5 Merge French Data with Mobility					 --*

* Merge
merge m:m sub_region_2 date using"$source/Mobility/2020_FR_Region_Mobility_Report.dta" // 32,880 not matched from master

* Save
save "$final/02_france.dta", replace

*--						1.2.6 Append German and French Data					 --*

* Hourly
use "$intermediate/02_france_hourly", clear
append using "$intermediate/01_prices_germany_hourly.dta"

* Generate log prices
foreach var of varlist diesel e5 e10{
	gen ln_`var' = ln(`var')
}
* Save
save "$final/final_hourly"


* Daily weighted
use "$intermediate/02_france_daily", clear
append using "$intermediate/01_prices_germany_weighted.dta"

* Generate log prices	
foreach var of varlist diesel e5 e10{
	gen ln_`var' = ln(`var')
}
* Save
save "$final/final_weighted"
	

* Daily
use "$intermediate/02_france_daily", clear
append using "$intermediate/01_prices_germany_daily.dta"
	
* Generate log prices
foreach var of varlist diesel e5 e10{
	gen ln_`var' = ln(`var')
}
* Save
save "$final/final_daily"


*------------------------------------------------------------------------------*
*----				1.3 Cleaning, Labelling, Construction				  -----*
*------------------------------------------------------------------------------*

*--							 1.3.1 Labelling								 --*

* Regular Labels
label variable id "Petrol Station ID"
label variable date "Date"
label variable postal "Postal Code"
label variable latitude "Latitude of the Petrol Station"
label variable longitude "Longitude of the Petrol Station"
label variable diesel "Diesel Price (weighted average for Germany)"
label variable e5 "E5 Price (weighted average for Germany)"
label variable e10 "E10 Price (weighted average for Germany)"

* Labels with Value Label
label variable treat "Treatment Dummy (1 for Germany)"
label define treatl 1 "Treatment Group (Germany)" 0 "Control Group (France)"
label values treat treatl
label variable post "Post Reform Dummy (1 after 30.06.2020)"
label define postl 1 "Post Reform" 0 "Before Reform"
label values post postl
label variable street_type "Type of Attached Street (Highway or Normal Street)"
label define stl 1 "Highway" 0 "Normal Street"
label values street_type stl


** 1.3.1 Counting stations in certain radius
use "$data_out/Stations/2020-12-01-stations.dta", clear
geonear street latitude longitude using "$data_out/Stations/2020-12-05-stations.dta", n(uuid latitude longitude) within(15) long

