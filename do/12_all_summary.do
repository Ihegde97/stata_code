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
use "$dir/Data/panel_cba_emp.dta", replace


replace peco="1" if peco=="S"
replace peco="0" if peco=="N"
destring(peco), replace
set more off
tabstat peco, by(any) statistics(mean sd) ///
columns(statistics) listwise

** cummulated pass **
*The dummy for complete panel
gen peco_no_gap=.
replace peco_no_gap=peco if maxrun==13

*The dummy for one_gap
gen peco_one_gap=.
replace peco_one_gap=peco if maxrun==12

gen peco_many_gaps=.
replace peco_many_gaps=peco if maxrun<12

preserve 
*The code below will collapse the data and give a cummulated peco 
*Alternatively check the peco.csv file 
collapse (min) cumm_peco= peco cumm_peco_no_gaps=peco_no_gap ///
cumm_peco_one_gap=peco_one_gap cumm_peco_many_gaps=peco_many_gaps , by(id) 

tab cumm_peco,missing

tab cumm_peco_no_gaps,missing

tab cumm_peco_one_gap,missing

tab cumm_peco_many_gaps,missing

restore

*Now I check the proportion of firms with emp <=1
cap drop less_than_one
gen less_than_one=.
replace less_than_one=1 if c200084_current<=1
replace less_than_one=0 if less_than_one==.

cap drop less_than_five
gen less_than_five=.
replace less_than_five=1 if c200084_current<=5
replace less_than_five=0 if less_than_five==.

cap drop zero
gen zero=.
replace zero=1 if c200084_current<=0
replace zero=0 if zero==.

asdoc tabstat less_than_one less_than_five zero, by(any) statistics(mean) 

***************************************************
*03 Employment Smmary
***************************************************
preserve
*First the summaries by year across all sectors
local vars "c200084_current c200082_current c200083_current c200309_current "
foreach v of local vars  {
		tabstat `v' , by(any) statistics(mean sd)columns(statistics)
	}	
*The result of the above can be found in emp_sumary.csv
drop if gsec09=="?"

collapse (mean) total= c200084_current perma= c200082_current non_perma= c200083_current  unclass= c200309_current , by( gsec09 any ) 
*Save this result to open later
save "$dir/Data/collapsed_data.dta",replace
set more off 

*I will now reshape the data as recommended
local vars "total perma non_perma unclass perma_share" 
foreach v of local vars  {
	use "$dir/Data/collapsed_data.dta", clear
	set more off 
	gen perma_share=perma/total
	keep any gsec09 `v'
	cap drop if gsec09=="?" | gsec09==""
	reshape wide `v',j(any) i(gsec09)
	export excel using "$dir/output/emp_summary.xlsx", sheet("`v'") sheetmodify firstrow(variables)
	}
restore 
***************************************************
* Attrition -
***************************************************
*The goal is to get attrition rates for each wave
preserve
gen dummy=1

*I reshape the data to wide format
keep id any dummy 
reshape wide dummy, i(id) j(any)


*Now I want to convert . to 0's for convenience in addition
local i=2006
while `i'<=2018 {
	set more off
	replace dummy`i'=0 if dummy`i'==.
	local i=`i'+1
}


*This is the code provided by user=="Federico"
set more off 
local dumlist "dummy2007 dummy2008 dummy2009 dummy2010 dummy2011 dummy2012 dummy2013 dummy2014 dummy2015 dummy2016 dummy2017 dummy2018"
forvalues j = 2007/2018 {
	local k = `j' - 1
	local ex "dummy`j'"							
	local dumlist : list dumlist - ex							// this excludes the contemporaneous dummy from the rowtotal argument
	di "`j' wave"
	if `j' <= 2017 {											// exclude 2018 because we don't know if missing firms will appear again in the future
		egen rt_`j' = rowtotal(`dumlist')						// this is the total number of future waves with non-missing data
		di (`j'-1) " firms missing in " `j' " but non-missing in " `j' "+s " " :"
		count if dummy`k' == 1 & dummy`j' == 0 & rt_`j' > 0
		di (`j'-1) " firms missing in " `j' " and all " `j' "+s "  " :"
		count if dummy`k' == 1 & dummy`j' == 0 & rt_`j' == 0	
	}	
	// (t-1) firms non-missing in t
	di (`j'-1) " firms  not missing in " `j' " :"
	count if dummy`k' == 1 & dummy`j' == 1		
}

restore 

**************************************************
*Proportion of firms with zero employees
***************************************************
*Firms with zero
cap drop zero_emp half_zero all_zero num_zero_years 
gen zero_emp=c200084_current<=0 // there are 6 obs with negative avg emp
bysort id: egen num_zero_years = total(zero_emp==1) // counts total number of years with zero emp


by id: gen all_zero = num_zero_years==_N // takes value 1 if all the years have 0 emp
by id: gen half_zero=num_zero_years >= (_N)/2 // takes value 1 at least half zero
tab all_zero half_zero

*asdoc tab all_zero half_zero // exports table 
