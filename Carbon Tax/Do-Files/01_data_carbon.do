*------------------------------------------------------------------------------*
*-----						   		1. DATA								  -----*
*------------------------------------------------------------------------------*



*------------------------------------------------------------------------------*
**#						1.1 Data Download and Reshaping					  	 #**
*------------------------------------------------------------------------------*

*-----				1.1.1 Tankerkönig Stations (Germany)				  -----*

* December

forvalues ii=16/31{
	local i : di %02.0f `ii'
	import delimited "$data_in/12 Stations/2021-12-`i'-stations.csv", varnames(1) encoding("utf-8") clear
	
	gen date = date("2021-12-`i'", "YMD")
	rename uuid id
	rename post_code postal
	
	drop openingtimes_json first_active street name brand house_number city
	
	save "$source/Stations_Germany/2021-12-`i'-stations.dta", replace
}


* January
forvalues ii=01/31{
	local i : di %02.0f `ii'
	import delimited "$data_in/01 Stations/2022-01-`i'-stations.csv", varnames(1) encoding("utf-8") clear
	
	gen date = date("2022-01-`i'", "YMD")
	rename uuid id
	rename post_code postal
	
	drop openingtimes_json first_active street name brand house_number city
	
	save "$source/Stations_Germany/2022-01-`i'-stations.dta", replace
}



*-----					1.1.2 Tankerkönig Prices (Germany)				  -----*

* December
forvalues ii=16/31{
	local i : di %02.0f `ii'	
	import delimited "$data_in/12 Prices/2021-12-`i'-prices.csv", varnames(1) encoding("utf-8") clear
	
	rename station_uuid id
	
	gen double time = clock(date, "YMDhms#")
	format time %tcDD_Mon_CCYY_HH:MM:SS
	drop date dieselchange e5change e10change

	gen date = dofc(time)
	gen hour = hh(time)
	gen datehour = date*24 + hour
	
	save "$source/Prices_Germany/2021-12-`i'-prices.dta", replace
}

* January
forvalues ii=01/31{
	local i : di %02.0f `ii'
	import delimited "$data_in/01 Prices/2022-01-`i'-prices.csv", varnames(1) encoding("utf-8") clear
	
	rename station_uuid id
	
	gen double time = clock(date, "YMDhms#")
	format time %tcDD_Mon_CCYY_HH:MM:SS
	drop date dieselchange e5change e10change

	gen date = dofc(time)
	gen hour = hh(time)
	gen datehour = date*24 + hour
	
	save "$source/Prices_Germany/2022-01-`i'-prices.dta", replace
}

* Merge prices with information stations (December)
forvalues ii=16/31{
	local i : di %02.0f `ii'
	use "$source/Prices_Germany/2021-12-`i'-prices.dta", clear
	
	merge m:1 id date using "$source/Stations_Germany/2021-12-`i'-stations.dta"
	
	keep if _merge == 3
	drop _merge
	
	save "$source/Merged_Germany/2021-12-`i'-merged.dta", replace
}

* Merge prices with information stations (January)
forvalues ii=01/31{
	local i : di %02.0f `ii'
	use "$source/Prices_Germany/2022-01-`i'-prices.dta", clear
	
	merge m:1 id date using "$source/Stations_Germany/2022-01-`i'-stations.dta"
	
	keep if _merge == 3
	drop _merge
	
	save "$source/Merged_Germany/2022-01-`i'-merged.dta", replace
}

* Apend Data
use "$source/Merged_Germany/2021-12-16-merged.dta", clear
forvalues mm = 17/31 {
	local m : di %02.0f `mm'	
	append using "$source/Merged_Germany/2021-12-`m'-merged.dta"
}
forvalues oo = 01/31{ 
	local o : di %02.0f `oo'	
	cap append using "$source/Merged_Germany/2022-01-`o'-merged.dta"
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
bys id (time): gen exp = cond(_n==_N, td(01-02-2022)*24-datehour, datehour[_n+1]-datehour)
expand exp
bys id (time): replace hour = cond(hour[_n-1]<23, hour[_n-1]+1, 0) if time == time[_n-1]
bys id (time): replace datehour = datehour[_n-1] + 1 if time == time[_n-1]
replace date = (datehour - hour) / 24

* Drop 01.02.2022
drop if date==date("01feb2022", "DMY")

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
duplicates drop id time, force

* Generate country variable
gen country = "Germany"

* Destring postal
destring postal, replace

* Correct Latitude/Longitude
replace longitude = longitude/10 if longitude > 90
drop if latitude == 0	// missing lat/long values

* Correct postal codes
replace postal = 06711 if postal == 06727
replace postal = 06905 if postal == 06909
replace postal = 09557 if postal == 09537
replace postal = 14712 if postal == 14721
replace postal = 23554 if postal == 23354
replace postal = 27639 if postal == 27637
replace postal = 28857 if postal == 28875
replace postal = 29559 if postal == 29596
replace postal = 35440 if postal == 35446
replace postal = 49448 if postal == 49889
replace postal = 59368 if postal == 59386
replace postal = 65760 if postal == 65767
replace postal = 65205 if postal == 66205
replace postal = 67480 if postal == 67440
replace postal = 73235 if postal == 72335
replace postal = 89355 if postal == 86355
replace postal = 86753 if postal == 86763
replace postal = 90765 if postal == 90785
replace postal = 97215 if postal == 91215
replace postal = 94559 if postal == 94595

* Sort
sort id time

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
duplicates drop id date, force

* Sort
sort id date

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
duplicates drop id date, force

* Sort
sort id date

* Save
save "$intermediate/01_germany_daily.dta", replace



*-----			 	  1.1.3 Le Prix Des Carburants (France)		   		  -----*

* Load data
import delimited "$data_in/PrixCarburants_annuel_2022.csv", numericcols(9) encoding("utf-8") clear

* Save
save "$source/PrixCarburants_annuel_2022.dta", replace

* Load data
import delimited "$data_in/PrixCarburants_annuel_2021.csv", numericcols(9) encoding("utf-8") clear

* Append
append using "$source/PrixCarburants_annuel_2022.dta"

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
drop if time < clock("2021-12-16 00:00:00", "YMDhms")
drop if time > clock("2022-01-31 23:59:59", "YMDhms")

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
bys id (time): gen exp = cond(_n==_N, td(01-02-2022)*24-datehour, datehour[_n+1]-datehour)
expand exp
bys id (time): replace hour = cond(hour[_n-1]<23, hour[_n-1]+1, 0) if time == time[_n-1]
bys id (time): replace datehour = datehour[_n-1] + 1 if time == time[_n-1]
replace date = (datehour - hour) / 24

* Drop 01.02.2022
drop if date==date("01feb2022", "DMY")

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
duplicates drop id time, force

* Generate country variable
gen country = "France"

* Destring postal
destring postal, replace

* Correct postal codes
replace postal = 04200 if postal == 4204
replace postal = 06340 if postal == 6345
replace postal = 06510 if postal == 6770
replace postal = 13290 if postal == 13546
replace postal = 13400 if postal == 13783
replace postal = 13290 if postal == 13853
replace postal = 30000 if postal == 30021
replace postal = 31200 if postal == 31075
replace postal = 31300 if postal == 31076
replace postal = 31100 if postal == 31084
replace postal = 33185 if postal == 33187	
replace postal = 34470 if postal == 34475
replace postal = 37170 if postal == 37172
replace postal = 42300 if postal == 42334
replace postal = 50200 if postal == 50204
replace postal = 51100 if postal == 51721
replace postal = 53100 if postal == 53102
replace postal = 53200 if postal == 53203
replace postal = 57300 if postal == 57303
replace postal = 66000 if postal == 66962
replace postal = 67450 if postal == 67452
replace postal = 68700 if postal == 68703
replace postal = 69400 if postal == 69651
replace postal = 69800 if postal == 69803
replace postal = 70000 if postal == 70004
replace postal = 73420 if postal == 73182
replace postal = 76200 if postal == 76371
replace postal = 77860 if postal == 77740
replace postal = 78200 if postal == 78205
replace postal = 80080 if postal == 80046
replace postal = 80800 if postal == 80380
replace postal = 84000 if postal == 84097
replace postal = 89340 if postal == 89720
replace postal = 92240 if postal == 92242
replace postal = 94310 if postal == 94537
replace postal = 94390 if postal == 94542
replace postal = 94150 if postal == 94594
replace postal = 94320 if postal == 94651
replace postal = 95330 if postal == 95331

* Sort
sort id time

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
duplicates drop id date, force

* Sort
sort id date

* Save
save "$intermediate/02_france_daily.dta", replace



*-----				1.1.4 Type of Attached Street (Germany)				  -----*

* Load data
import excel "$data_in/tankstellen_autobahn_bundestrasse.xls", clear 

* Rename
rename A street_id
rename C id
rename D name
rename E brand
rename F street
rename G number
rename H postal
rename I city
rename J longitude
rename K latitude

* Drop unnecessary variables
drop street_id id name brand street number postal city 

* Destring longitude/latitude
destring longitude latitude, replace

* Drop duplicates
duplicates drop

* Round to merge
generate longitude_merge = round(longitude, 0.0000001)
generate latitude_merge = round(latitude, 0.0000001)
drop longitude latitude

* save
save "$intermediate/03_germany_streettype.dta", replace



*-----					 1.1.5 Google Mobility Reports					  -----*

* Load data
foreach c in "DE" "FR"{
		
	foreach i in 2021 2022{
		
		import delimited "$data_in/`i'_`c'_Region_Mobility_Report", encoding("utf-8") clear
		
		gen double date2 = date(date, "YMD")
		drop date
		rename date2 date
		format date %tdDD_Mon_CCYY
		
		
		save "$source/Mobility/`i'_`c'_Region_Mobility_Report.dta", replace
	}
}


* Rename some name in sub_region_2 for merge
foreach i in 2021 2022{
	use "$source/Mobility/`i'_FR_Region_Mobility_Report.dta", clear
	replace sub_region_2="Ariège" if sub_region_2=="Ariege"
	replace sub_region_2="Bouches-du-Rhône" if sub_region_2=="Bouches-du-Rhone"
	replace sub_region_2="Corrèze" if sub_region_2=="Correze"
	replace sub_region_2="Finistère" if sub_region_2=="Finistere"
	replace sub_region_2="Isère" if sub_region_2=="Isere"
	replace sub_region_2="Puy-de-Dôme" if sub_region_2=="Puy-de-Dome"
	
	* Save
	save "$source/Mobility/`i'_FR_Region_Mobility_Report.dta", replace
}

* Append
foreach c in "DE" "FR"{
	use "$source/Mobility/2021_`c'_Region_Mobility_Report.dta", clear
	append using "$source/Mobility/2022_`c'_Region_Mobility_Report.dta"
	save "$source/Mobility/mobility_`c'.dta", replace
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

* Add missing postals
set obs `=_N+21'
replace postal = 98739 if _n == _N-20
replace iso_3166_2_code = "DE-TH" if _n == _N-20
replace sub_region_1 = "Thuringia" if _n == _N-20

* Save
save "$intermediate/05_germany_postal.dta", replace



*------------------------------------------------------------------------------*
**#							1.2 Merge and Append							 #**
*------------------------------------------------------------------------------*

*-----			1.2.1 Merge German Data with Attached Street Type		  -----*
use "$intermediate/01_germany_weighted.dta", clear

* Round for merge
generate longitude_merge = round(longitude, 0.0000001)
generate latitude_merge = round(latitude, 0.0000001)

* Merge
merge m:1 longitude_merge latitude_merge using "$intermediate/03_germany_streettype.dta"
drop if _merge==2
drop longitude_merge latitude_merge _merge

* Street Type to Dummy
gen street_type = 0
replace street_type = 1 if B == "Autobahn"
drop B



*-----					1.2.2 Merge German Data with Regions			  -----*

* Merge
merge m:m postal using "$intermediate/05_germany_postal.dta" // 0 not matched from master
keep if _merge == 3
drop _merge



*-----				1.2.3 Merge German Data with Mobility				  -----*

* Merge
merge m:m sub_region_1 date using"$source/Mobility/mobility_DE.dta"	// 0 not matched from master
keep if _merge == 3
drop _merge country_region_code country_region metro_area census_fips_code place_id grocery_and_pharmacy_percent_cha parks_percent_change_from_baseli transit_stations_percent_change_ residential_percent_change_from_

* sub_region_2 to string for append
tostring sub_region_2, replace

* Save
save "$final/01_germany.dta", replace



*-----					1.2.4 Merge French Data with Regions			  -----*

* Load data
use "$intermediate/02_france_daily.dta", clear

* Merge
merge m:m postal using "$intermediate/04_france_postal.dta" //0 not matched from master
keep if _merge == 3
drop _merge



*-----				1.2.5 Merge French Data with Mobility				  -----*

* Merge
merge m:m sub_region_2 date using"$source/Mobility/mobility_FR.dta" // 0 not matched from master
keep if _merge == 3
drop _merge country_region_code country_region metro_area census_fips_code place_id grocery_and_pharmacy_percent_cha parks_percent_change_from_baseli transit_stations_percent_change_ residential_percent_change_from_

* Save
save "$final/02_france.dta", replace

*-----					1.2.6 Append German and French Data				  -----*

/*
* Hourly
use "$intermediate/02_france_hourly.dta", clear
append using "$intermediate/01_prices_germany_hourly.dta"

* Generate log prices
foreach var of varlist diesel e5 e10{
	gen ln_`var' = ln(`var')
}
* Save
save "$final/final_hourly"
*/

* Daily


* Daily weighted
use "$final/02_france.dta", clear
append using "$final/01_germany.dta"
	
* Save
save "$final/merged_weighted.dta", replace



*------------------------------------------------------------------------------*
**#							1.3 Construction/Cleaning						 #**
*------------------------------------------------------------------------------*

*----- 						1.3.1 Competition by Radius					  -----* 

* Load data
use "$final/merged_weighted.dta", clear

* Reduce sample by id
keep id country latitude longitude
duplicates drop id, force

* Save
save "$source/Competition/competition_main.dta", replace

* Rename id
rename id id2

* Save
save "$source/Competition/competition_using.dta", replace

* Distance evaluation 
foreach i in 1 2 5{
	
	use "$source/Competition/competition_main.dta", clear
	
	preserve
	
	geonear id latitude longitude using "$source/Competition/competition_using.dta", n(id2 latitude longitude) within(`i') long
	bysort id (id2): egen within`i' = total(km_to_id2 <= `i')	
	
	drop id2 km_to_id2
	
	duplicates drop
	
	save "$source/Competition/competition_radius_`i'.dta", replace
	
	restore
}

* Merge
use "$source/Competition/competition_radius_1.dta", clear

foreach i in 2 5{
	merge 1:1 id using "$source/Competition/competition_radius_`i'.dta"
	drop _merge
}

* Generate medians
foreach var of varlist within1 within2 within5{
	egen `var'_median = median(`var')
	generate comp_`var' = 0
	replace comp_`var' = 1 if `var' > `var'_median
	drop `var'_median
} 

* Save 
save "$intermediate/06_competition_radius.dta", replace 



*----- 						1.3.2 Competition by Postal					  -----*

* Load data
use "$final/merged_weighted.dta", clear

* Reduce sample by id
keep id postal
duplicates drop id, force

* Sort
sort postal

* Generate within postal
egen within_postal = count(id), by (postal)

* Generate median
egen within_postal_median = median(within_postal)

* Generate competition dummy
generate comp_postal = 0
replace comp_postal = 1 if within_postal > within_postal_median
drop within_postal_median

* Save 
save "$intermediate/06_competition_postal.dta", replace 


* Merge competition by radius
use "$final/merged_weighted.dta", clear
merge m:1 id using "$intermediate/06_competition_radius.dta" // 0 not matched
drop _merge

* Merge competition by postal
merge m:1 id using "$intermediate/06_competition_postal"	// 0 not matched
drop _merge



*-----			1.3.3 Generate Treat, Post, and Dif-in-Dif Variable		  -----*

* Treat
generate treat = 1
replace treat = 0 if country == "France"

* Post
generate post = 1
replace post = 0 if date < date("01jan2022", "DMY")

* Dif-in-Dif
generate vat = treat * post 



*-----	 						1.3.4 Clean Prices							  -----*

foreach var of varlist e5 e10 diesel{
	replace `var'=. if `var'<0
}

foreach var of varlist e5 e10 diesel{
	replace `var'=. if `var'<0.9
	replace `var'=. if `var'>2.5
}



*-----	 						1.3.5 Ln Prices							  -----*

foreach var of varlist e5 e10 diesel{
	gen ln_`var' = ln(`var')
}



*-----	 						1.3.6 Setup Panel						  -----*

duplicates drop
xtset id date



*------------------------------------------------------------------------------*
**#							1.4 Label and Rename							 #**
*------------------------------------------------------------------------------*

* Rename
rename retail_and_recreation_percent_ch retail_recreation
rename workplaces_percent_change_from_b workplace



* Regular Labels
label variable id "Petrol Station ID"
label variable date "Date"
label variable postal "Postal Code"
label variable latitude "Latitude of the Petrol Station"
label variable longitude "Longitude of the Petrol Station"
label variable diesel "Diesel Price (weighted average for Germany)"
label variable e5 "E5 Price (weighted average for Germany)"
label variable e10 "E10 Price (weighted average for Germany)"
label variable ln_diesel "Log Diesel Price"
label variable ln_e5 "Log E5 Price"
label variable ln_e10 "Log E10 Price"
label variable retail_recreation "Change in Retail and Recreation Mobility"
label variable workplace "Change in Workplace Mobility"
label variable sub_region_1 "Bundesländer/Départements"
label variable sub_region_2 "French Regions"
label variable iso_3166_2_code "ISO 3166-2 Code"
label variable within1 "Petrol Stations within 1km"
label variable within2 "Petrol Stations within 2km"
label variable within5 "Petrol Stations within 5km"
label variable within_postal "Petrol Stations within Postal Code"
label variable vat "Dif-in-Dif Dummy"
label variable country "Countries"



* Labels with Value Label
label variable treat "Treatment Dummy (1 for Germany)"
label define treatl 1 "Treatment Group (Germany)" 0 "Control Group (France)"
label values treat treatl
label variable post "Post Reform Dummy (1 after 31.12.2021)"
label define postl 1 "Post Reform" 0 "Before Reform"
label values post postl
label variable street_type "Type of Attached Street (Highway or Normal Street)"
label define stl 1 "Highway" 0 "Normal Street"
label values street_type stl
label variable comp_within1 "Degree of Competition within 1km"
label define c1l 1 "Above Median" 0 "Below Median"
label values comp_within1 c1l
label variable comp_within2 "Degree of Competition within 2km"
label define c2l 1 "Above Median" 0 "Below Median"
label values comp_within2 c2l
label variable comp_within5 "Degree of Competition within 5km"
label define c5l 1 "Above Median" 0 "Below Median"
label values comp_within1 c5l
label variable comp_postal "Degree of Competition within 5km"
label define cpl 1 "Above Median" 0 "Below Median"
label values comp_postal cpl



* Date Formatting
format date %tdDD_Mon_CCYY



* Save
save "$final/00_final_weighted_unbalanced.dta", replace



*----- 	Drop if Petrol Stations Appear after first Date (Balance Panel)   -----*

bysort id (date): gen N = _N
bysort id (date): gen n = _n

bysort id (date): egen todrop = max(n==1 & date>date("16dec2021","DMY"))
drop if todrop == 1
drop n N todrop

save "$final/00_final_weighted_balanced", replace
