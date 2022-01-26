*------------------------------------------------------------*
*----				3. GRAPHS AND TABLES				-----*
*------------------------------------------------------------*

graph set window fontface "Garamond"

use "$final/00_final_weighted.dta", clear

*** Diesel Prices Germany
preserve

keep diesel treat date

collapse (mean) diesel, by (date treat) 

twoway  (line diesel date if treat==1 , lcolor(navy) msymbol(O) msize(medsmall) mcolor(navy) lwidth(medthick)), /// 
 xline(22097, lcolor(red) lpattern(dash)) ///
graphregion(color(white)) bgcolor(white) xtitle("Dates", height(6))  ///
ytitle("Diesel Price per liter in €" , height(6))  ///	
ylabel(1.06(0.01)1.11)
graph export "$graphs/diesel_germany.pdf", replace as(pdf)

restore


*** E5 Prices Germany
preserve

keep e5 treat date

collapse (mean) e5, by (date treat) 

twoway  (line e5 date if treat==1 , lcolor(navy) msymbol(O) msize(medsmall) mcolor(navy) lwidth(medthick)), /// 
 xline(22097, lcolor(red) lpattern(dash)) ///
graphregion(color(white)) bgcolor(white) xtitle("Dates", height(6))  ///
ytitle("E5 Price per liter in €" , height(6))  ///	
ylabel(1.25(0.01)1.3)
graph export "$graphs/e5_germany.pdf", replace as(pdf)

restore


*** E10 Prices Germany
preserve

keep e10 treat date

collapse (mean) e10, by (date treat) 

twoway  (line e10 date if treat==1 , lcolor(navy) msymbol(O) msize(medsmall) mcolor(navy) lwidth(medthick)), /// 
 xline(22097, lcolor(red) lpattern(dash)) ///
graphregion(color(white)) bgcolor(white) xtitle("Dates", height(6))  ///
ytitle("E10 Price per liter in €" , height(6))  ///	
ylabel(1.22(0.01)1.27)
graph export "$graphs/e10_germany.pdf", replace as(pdf)

restore
