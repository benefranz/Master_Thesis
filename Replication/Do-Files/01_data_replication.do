*------------------------------------------------------------------------------*
*-----						   		1. DATA								  -----*
*------------------------------------------------------------------------------*
/*
Changes:
	- consistent file names
*/



*------------------------------------------------------------------------------*
*----					1.1 Data Download and Reshaping					  -----*
*------------------------------------------------------------------------------*

*-----					1.1.1 Tankerkönig Prices (Germany)				  -----*

* June
forvalues ii=15/30{
	local i : di %02.0f `ii'	
	import delimited "$data_in/06 Prices_Germany/2020-06-`i'-prices.csv", varnames(1) encoding("utf-8") clear
	
	rename station_uuid id
	
	save "$source/Prices_Germany/2020-06-`i'-prices.dta", replace
}

* July
forvalues ii=01/31{
	local i : di %02.0f `ii'
	import delimited "$data_in/07 Prices_Germany/2020-07-`i'-prices.csv", varnames(1) encoding("utf-8") clear
	
	rename station_uuid id
	
	save "$source/Prices_Germany/2020-07-`i'-prices.dta", replace
}

* Apend Data
use "$source/Prices_Germany/2020-06-15-prices.dta", clear
forvalues mm = 16/30 {
	local m : di %02.0f `mm'	
	append using "$source/Prices_Germany/2020-06-`m'-prices.dta"
}
forvalues oo = 01/31{ 
	local o : di %02.0f `oo'	
	cap append using "$source/Prices_Germany/2020-07-`o'-prices.dta"
}

* Create numeric ID based on non-numeric ID
egen id_new = group(id)
drop id
rename id_new id

* Extract time and create further temporal variables
gen double time = clock(date, "YMDhms#")
format time %tcDD_Mon_CCYY_HH:MM:SS
drop date

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
drop diesel e5 e10 dieselchange e5change e10change
rename diesel_mean diesel
rename e5_mean e5
rename e10_mean e10
duplicates drop

* Generate country variable
gen country = "Germany"

* Generate treatment variable
gen vat = 1
replace vat = 0 if time < clock("01jul2020 00:00:00", "DMYhms")

* Save
save "$intermediate/01_prices_germany_hourly.dta", replace


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
save "$intermediate/01_prices_germany_weighted.dta", replace


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
save "$intermediate/01_prices_germany_daily.dta", replace



*-----				1.1.2 Tankerkönig Stations (Germany)				  -----*

* June
forvalues ii=15/30{
	local i : di %02.0f `ii'
	import delimited "$data_in/06 Stations/2020-06-`i'-stations.csv", varnames(1) encoding("utf-8") clear
	
	gen date = date("2020-06-`i'", "YMD")
	rename uuid id
	
	drop openingtimes_json first_active
	
	save "$source/Stations_Germany/2020-06-`i'-stations.dta", replace
}


* July
forvalues ii=01/31{
	local i : di %02.0f `ii'
	import delimited "$data_in/07 Stations/2020-07-`i'-stations.csv", varnames(1) encoding("utf-8") clear
	
	gen date = date("2020-07-`i'", "YMD")
	rename uuid id
	
	drop openingtimes_json first_active
	
	save "$source/Stations_Germany/2020-07-`i'-stations.dta", replace
}


* Apend Data
use "$source/Stations_Germany/2020-06-15-stations.dta", clear
forvalues mm = 16/30 {
	local m : di %02.0f `mm'	
	append using "$source/Stations_Germany/2020-06-`m'-stations.dta"
}
forvalues oo = 01/31{ 
	local o : di %02.0f `oo'	
	cap append using "$source/Stations_Germany/2020-07-`o'-stations.dta"
}

save "$intermediate/02_stations_germany.dta", replace



*-----			 	  1.1.3 Le Prix Des Carburants (France)		   		  -----*

* Loading data
import delimited "$data_in/PrixCarburants_annuel_2020.csv", numericcols(9) encoding("utf-8") clear

* Rename variables
rename v1 id
rename v2 postal
rename v3 street_type
rename v4 latitude
rename v5 longitude
rename v7 id_fuel
rename v8 fuel
rename v9 price

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

* Generate country variable
gen country = "France"

* Generate treatment variable
gen vat = 0

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
save "$data_out/03_france_daily.dta", replace



*-----					 1.1.3 Google Mobility Reports					  -----*

* Load data
foreach c in "DE" "FR"{
		
		import delimited "$data_in/2020_`c'_Region_Mobility_Report", encoding("utf-8") clear
		
		gen double date2 = date(date, "YMD")
		drop date
		rename date2 date
		format date %tdDD_Mon_CCYY
		
		
		save "$source/Mobility/2020_`c'_Region_Mobility_Report.dta", replace
}



*----- 1.1.4 French postal codes to regions (sub_region_1) and deparments (sub_region_2) -----*

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



*-----		 1.1.5 German postal codes to Bundesländer (sub_region_1)	  -----*

* Load data
import excel "https://www.destatis.de/DE/Themen/Laender-Regionen/Regionales/Gemeindeverzeichnis/Administrativ/Archiv/GVAuszugQ/BTW20213Q2021.xlsx?__blob=publicationFile", sheet("Bundestagswahlkreise_2021") cellrange(A7:L11054) encoding("utf-8") clear

* Rename
rename A ars
rename B ags
rename C gemeinde
rename D wahlkreis_id
rename E wahlkreis
rename F postal
rename G area
rename H pop
rename I pop_m
rename J pop_f
drop K L

* Generate iso_3166_2_code
gen bundesland_id = substr(ags, 1, 2)
gen iso_3166_2_code="DE"
replace iso_3166_2_code="DE-SH" if bundesland_id=="01"
replace iso_3166_2_code="DE-HH" if bundesland_id=="02"
replace iso_3166_2_code="DE-NI" if bundesland_id=="03"
replace iso_3166_2_code="DE-HB" if bundesland_id=="04"
replace iso_3166_2_code="DE-NW" if bundesland_id=="05"
replace iso_3166_2_code="DE-HE" if bundesland_id=="06"
replace iso_3166_2_code="DE-RP" if bundesland_id=="07"
replace iso_3166_2_code="DE-BW" if bundesland_id=="08"
replace iso_3166_2_code="DE-BY" if bundesland_id=="09"
replace iso_3166_2_code="DE-SL" if bundesland_id=="10"
replace iso_3166_2_code="DE-BE" if bundesland_id=="11"
replace iso_3166_2_code="DE-BB" if bundesland_id=="12"
replace iso_3166_2_code="DE-MV" if bundesland_id=="13"
replace iso_3166_2_code="DE-SN" if bundesland_id=="14"
replace iso_3166_2_code="DE-ST" if bundesland_id=="15"
replace iso_3166_2_code="DE-TH" if bundesland_id=="16"

* Generate sub_region_1
gen sub_region_1="Germany"
replace sub_region_1="Schleswig-Holstein" if bundesland_id=="01"
replace sub_region_1="Hamburg" if bundesland_id=="02"
replace sub_region_1="Lower Saxony" if bundesland_id=="03"
replace sub_region_1="Bremen" if bundesland_id=="04"
replace sub_region_1="North Rhine-Westphalia" if bundesland_id=="05"
replace sub_region_1="Hessen" if bundesland_id=="06"
replace sub_region_1="Rhineland-Palatinate" if bundesland_id=="07"
replace sub_region_1="Baden-Württemberg" if bundesland_id=="08"
replace sub_region_1="Bavaria" if bundesland_id=="09"
replace sub_region_1="Saarland" if bundesland_id=="10"
replace sub_region_1="Berlin" if bundesland_id=="11"
replace sub_region_1="Brandenburg" if bundesland_id=="12"
replace sub_region_1="Mecklenburg-Vorpommern" if bundesland_id=="13"
replace sub_region_1="Saxony" if bundesland_id=="14"
replace sub_region_1="Saxony-Anhalt" if bundesland_id=="15"
replace sub_region_1="Thuringia" if bundesland_id=="16"

* Save
save "$intermedate/05_germany_postal.dta", replace




*------------------------------------------------------------------------------*
*----						1.2 Merge and Append						  -----*
*------------------------------------------------------------------------------*

*--					1.2.1 Merge German Prices with Stations					 --*

use "$intermediate/01_prices_germany", clear

* Merge and Show Results
//merge 1:1 date uuid using "$data_out/02_stations_germany"



*--					1.2.2 Merge German Data with Regions					 --*

*--					1.2.3 Merge German Data with Mobility					 --*

*--					1.2.4 Merge French  Data with Regions					 --*

*--					1.2.5 Merge French Data with Mobility					 --*

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

** 1.3.1 Counting stations in certain radius
use "$data_out/Stations/2020-12-01-stations.dta", clear
geonear street latitude longitude using "$data_out/Stations/2020-12-05-stations.dta", n(uuid latitude longitude) within(15) long

