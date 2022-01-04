import delimited "/Users/benediktfranz/OneDrive - bwedu/Studium/Master/MasterThesis/Analyse/Data Input/01 Prices/2021-01-01-prices.csv", clear

gen double time = clock(date, "YMDhms#")
format time %tcDD_Mon_CCYY_HH:MM:SS
drop date

gen date = dofc(time)
gen hour = hh(time)
gen datehour = date*24 + hour

foreach var of varlist diesel e5 e10 {
    bys station_uuid (time): replace `var' = `var'[_n-1] if `var' == 0
}

bys station_uuid (time): gen exp = cond(_n==_N, td(02-01-2021)*24-datehour, datehour[_n+1]-datehour)
expand exp
bys station_uuid (time): replace hour = cond(hour[_n-1]<23, hour[_n-1]+1, 0) if time == time[_n-1]
bys station_uuid (time): replace datehour = datehour[_n-1] + 1 if time == time[_n-1]
replace date = (datehour - hour) / 24

replace time = dhms(date, hour, 0, 0)
format time %tc

drop exp date hour datehour

collapse (mean) diesel e5 e10, by(station_uuid time)


