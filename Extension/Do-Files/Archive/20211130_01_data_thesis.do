 *------------------------------------------------------------------------------*
*-----						   		1. DATA								  -----*
*------------------------------------------------------------------------------*




*------------------------------------------------------------------------------*
*----					1.1 Data Download and Reshaping					  -----*
*------------------------------------------------------------------------------*

** 1.1.1 Tankerkönig (Prices)
cd "$data_out/Prices"

* December
forvalues ii=01/31{
	local i : di %02.0f `ii'
	cap use "2020-12-`i'-prices.dta", clear 	
	import delimited "$data_in/12 Prices/2020-12-`i'-prices.csv", varnames(1) clear
	
	collapse (mean) diesel e5 e10 dieselchange e5change e10change,  by(station_uuid)
	gen date="2020-12-`i'"
	rename station_uuid id
	
	save "2020-12-`i'-prices.dta", replace
}

* January
forvalues ii=01/31{
	local i : di %02.0f `ii'
	cap use "2021-01-`i'-prices.dta", clear 	
	
	import delimited "$data_in/01 Prices/2021-01-`i'-prices.csv", varnames(1) clear
	
	collapse (mean) diesel e5 e10 dieselchange e5change e10change,  by(station_uuid)
	gen date="2021-01-`i'"
	rename station_uuid id
	
	save "2021-01-`i'-prices.dta", replace
}


* Apend Data
use "2020-12-01-prices.dta", replace
forvalues mm = 02/31 {
	local m : di %02.0f `mm'	
	append using "2020-12-`m'-prices.dta"
}
forvalues oo = 01/31{ 
	local o : di %02.0f `oo'	
	cap append using "2021-01-`o'-prices.dta"
}

save "$data_out/01_prices_germany.dta", replace



** 1.1.2 Tankerkönig (Stations)
cd "$data_out/Stations"

* December
forvalues ii=01/31{
	local i : di %02.0f `ii'
	cap use "2020-12-`i'-stations.dta", clear 	

	import delimited "$data_in/12 Stations/2020-12-`i'-stations.csv", varnames(1) clear
	gen date="2020-12-`i'"
	rename uuid id
	
	drop openingtimes_json
	
	save "2020-12-`i'-stations.dta", replace
}


* January
forvalues ii=01/31{
	local i : di %02.0f `ii'
	cap use "2021-01-`i'-stations.dta", clear 	
	
	import delimited "$data_in/01 Stations/2021-01-`i'-stations.csv", varnames(1) clear
	gen date="2021-01-`i'"
	rename uuid id
	
	drop openingtimes_json
	
	save "2021-01-`i'-stations.dta", replace
}


* Apend Data
use "2020-12-01-stations.dta", replace
forvalues mm = 02/31 {
	local m : di %02.0f `mm'	
	append using "2020-12-`m'-stations.dta"
}
forvalues oo = 01/31{ 
	local o : di %02.0f `oo'	
	cap append using "2021-01-`o'-stations.dta"
}

save "$data_out/02_stations_germany.dta", replace



** 1.1.3 Markttransparenzstelle für Kraftstoffe (Autobahn/Bundesstraßen Tankstellen)
import excel "$data_in/tankstellen_autobahn_bundestrasse.xls", clear

gen autobahn=0 
replace autobahn=1 if B=="Autobahn"

gen bundestrasse=0
replace bundestrasse=1 if B=="Bundesstraße"

rename C id
rename F street
rename G house_number
rename H post_code
rename I city

keep id street house_number post_code city

save "$data_out/03_stations_AB.dta", replace



** 1.1.4 Le Prix Des Carburants (French Data)

**** General
forvalues i = 2020(1)2021{
	import delimited "$data_in/PrixCarburants_annuel_`i'.csv", numericcols(9) clear
	rename v1 id_pdv
	rename v2 cp_pdv
	rename v3 pop
	rename v4 lat
	rename v5 lon
	rename v6 date
	rename v7 id_prix
	rename v8 nom
	rename v9 valeur
	
	* Convert to euros
	replace valeur = valeur/1000
	
	* Convert coordinates
	replace lat = lat/100000
	replace lon = lon/100000
	
	* Extract date without time to be able to mean-collaps by date
	gen double date2= clock(date, "YMD#hms")
	drop date
	rename date2 date
	
	* Drop E85 and GPLc
	drop if nom=="E85"
	drop if nom=="GPLc"
	
	* Drop missing prices (stations listed in XML but no prices reported)
	drop if valeur==.		
	
	* Save
	save "$data_out/04_frenchdata_`i'", replace
}


**** 2020
use "$data_out/04_frenchdata_2020", clear

drop if date < date("01dec2020","DMY")		// 3,179,712 obs
format date %tcDD_Mon_CCYY_HH:MM:SS

save "$data_out/04_frenchdata_2020", replace


**** 2021
use "$data_out/04_frenchdata_2021", clear

drop if date >= clock("01feb2021","DMY")		// 2,743,490 obs
format date %tcDD_Mon_CCYY_HH:MM:SS

save "$data_out/04_frenchdata_2021", replace



** 1.1.5 Google Mobility Reports

*** Load data
foreach c in "DE" "FR"{
	forvalues i = 2020(1)2021{
		
		import delimited "$data_in/`i'_`c'_Region_Mobility_Report", clear
	
		save "$data_out/Mobility/`i'_`c'_Region_Mobility_Report.dta", replace
	
	}
}

*** Append data
use "$data_out/Mobility/2020_DE_Region_Mobility_Report", clear

append using "$data_out/Mobility/2020_FR_Region_Mobility_Report"
append using "$data_out/Mobility/2021_DE_Region_Mobility_Report"
append using "$data_out/Mobility/2021_FR_Region_Mobility_Report"

save "$data_out/05_mobility"



** 1.1.6 Europe Brent Spot Price FOB
import delimited "$data_in/Europe_Brent_Spot_Price_FOB_Daily.csv", delimiter(comma) rowrange(6) clear 

* Format date variable
gen date= date(v1, "MDY")
drop v1
drop if date < date("01dec2020","DMY")
drop if date > date("31jan2021","DMY")
format date %td

rename v2 oil_price




*------------------------------------------------------------------------------*
*----							1.2 Merging								  -----*
*------------------------------------------------------------------------------*

** 1.2.1 Merge Prices with Stations

*** Setup
clear all
set more off
use "$data_out/01_prices_germany"

*** Merge and Show Results
merge 1:1 date uuid using "$data_out/02_stations_germany"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       127,985
        from master                       149  (_merge==1)
        from using                    127,836  (_merge==2)

    matched                           874,551  (_merge==3)
    -----------------------------------------
*/




*------------------------------------------------------------------------------*
*----				1.3 Cleaning, Labelling, Construction				  -----*
*------------------------------------------------------------------------------*

** 1.3.1 Counting stations in certain radius
use "$data_out/Stations/2020-12-01-stations.dta", clear
geonear street latitude longitude using "$data_out/Stations/2020-12-05-stations.dta", n(uuid latitude longitude) within(15) long






