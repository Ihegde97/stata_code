***************************************************
*Project: BDE Summer Internship
*Purpose: Identify Gaps in the Panel
*Last modified: July 20th 2020 by Ishwara
***************************************************


***************************************************
*00. Preamble
***************************************************
	
	
clear all
set maxvar 30000
set more off

*Set user and the directory
local users  "Ishwara" // "Federico"

	if "`users'" == "Federico" {
	global dir "Enter your directory here"
}

	if "`users'" == "Ishwara" {
		global dir "C:/Users/user/OneDrive - City University of Hong Kong/University/Cemfi/Internship"
	}

*Creating a panel using code from final_panel.do

***************************************************
*1 Peco Summary 		
***************************************************
*First I load .dta file from 11_outliers.do


replace peco="1" if peco=="S"
replace peco="0" if peco=="N"
destring(peco), replace
set more off
tabstat peco, by(year) statistics(mean sd) ///
columns(statistics) listwise

** cummulated pass **
*The dummy for complete panel
gen peco_no_gap=.
replace peco_no_gap=peco if maxrun==13

*The dummy for one_gap
gen peco_one_gap=.
replace peco_one_gap=peco if maxrun==12

gen peco_myear_gaps=.
replace peco_myear_gaps=peco if maxrun<12

preserve 
*The code below will collapse the data and give a cummulated peco 
*Alternatively check the peco.csv file 
collapse (min) cumm_peco= peco cumm_peco_no_gaps=peco_no_gap ///
cumm_peco_one_gap=peco_one_gap cumm_peco_myear_gaps=peco_myear_gaps , by(id) 

tab cumm_peco,missing

tab cumm_peco_no_gaps,missing

tab cumm_peco_one_gap,missing

tab cumm_peco_myear_gaps,missing

restore

*Now I check the proportion of firms with emp <=1
cap drop less_than_one
gen less_than_one=.
replace less_than_one=1 if empl<=1
replace less_than_one=0 if less_than_one==.

cap drop less_than_five
gen less_than_five=.
replace less_than_five=1 if empl<=5
replace less_than_five=0 if less_than_five==.

cap drop zero
gen zero=.
replace zero=1 if empl<=0
replace zero=0 if zero==.

asdoc tabstat less_than_one less_than_five zero, by(year) statistics(mean) 

***************************************************
*03 Employment Summary
***************************************************

use "$dir/cba_data.dta", replace
drop if gsec09=="?"
collapse (mean) total_emp= empl perma= empl_perm non_perma= empl_temp  unclass= empl_uncl , by( gsec09 year ) 
*Save this result to open later
save "$dir/collapsed_data.dta",replace
set more off 

*I will now reshape the data as recommended
local vars "total_emp perma non_perma unclass perma_share temp_share" 
foreach v of local vars  {
	use "$dir/collapsed_data.dta",clear
	set more off 
	gen perma_share=perma/total_emp
	gen temp_share=non_perma/total_emp
	keep year gsec09 `v'
	cap drop if gsec09=="?" | gsec09==""
	reshape wide `v',j(year) i(gsec09)
	export excel using "$dir/output/emp_summary2.xlsx", sheet("`v'") sheetmodify firstrow(variables)
	}


*Conclusion:
