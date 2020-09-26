***************************************************
*Project: BDE Summer Internship
*Purpose: Cleaning 2012 wave
*Last modified: 4th of August 2020 by Ishwara
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

***************************************************
*02 Exploring the data for 2012 
***************************************************
*The data for 2012 has several coding discrepancies:
*Majority of sect09 is filled in as "?"
*

*Checking the sect09 
use "$dir/Data/cba_cbb_2012.dta", clear
count if sect09 =="?"

*A large portion of gsec09 is also missing
count if gsec09==""

*cnae09 also has a large number of "??". 
count if cnae09=="??"

* large number of cab also missing 	


***************************************************
*02 Merging the data 
***************************************************

* The variables below are the ones relating to id only.
local id_vars "id any cif anyconst revc cnae09 sect09 gsec09 cues tamrec tamest grup bols codpos fuen peco esta cab alta_sitc baja_sitc calidad nif_dom nif_dom"
local i=2006
while `i'<=2018 {
	use "$dir/Data/cba_cbb_`i'.dta", clear
	set more off
	keep  `id_vars' `emp_vars' `profit_vars'
	save "$dir/Data/cba_cbb_`i'_b.dta", replace
	local i=`i'+1
}
*Loading 2012 data specifically
use "$dir/Data/cba_cbb_2012_b.dta", clear
replace sect09="" if sect09=="?"
destring sect09, replace
replace gsec09="" if gsec09=="?"
replace cnae09="" if cnae09=="??"
save "$dir/Data/cba_cbb_2012_b.dta",replace

*Use 2018 data
use "$dir/Data/cba_cbb_2018_b.dta", clear


* Now I append using 2018 as the master
local j=2006
while `j'<=2017 {
	append using "$dir/Data/cba_cbb_`j'_b.dta"
	local j=`j'+1
}


* creating the panel
xtset id any, yearly

*Saving here
*save "$dir/Data/panel_pre_2012_clean.dta",replace


***************************************************
*03 Modifying the data for 2012 
***************************************************
use "$dir/Data/panel_pre_2012_clean.dta",clear
xtset id any,yearly
gen run = .
* The cond function checks whether L.run ==. ; If true it sets run to 1
*If flase it sets run to L.run +1
by id: replace run = cond(L.run == ., 1, L.run + 1)
by id: egen maxrun = max(run)
*maxrun shows the maximum continuous chain 

*The gap variable is a binary var that will equal to 1 if there is a gap 
*between two dates within a particular firm.
by id: gen gap =1 if run==run[_n -1]
replace gap =0 if gap ==.


*Replacing by t+1. 
by id: replace sect09 = sect09[_n+1] if sect09==.

*there are still missing valuess for sect09 and all from 2012
count if sect09==.
count if sect09==. & any ==2012

* The above code does not capture them since these firms exit the panel in 2012
by id: replace sect09 = sect09[_n-1] if sect09==.

* there are still some missing values from firms that only appear in 2012
drop if sect09==. & run==1 & maxrun==1 & gap==0
*We ddecided to drop these observations
*Now I need to do it for all the sector-type variables
local string_int "cnae09 gsec09 "
sort id 
	foreach s of local string_int  {
		by id: replace `s'=`s'[_n+1] if `s'==""
		by id: replace `s'=`s'[_n-1] if `s'==""
		
	}
*All three variables cnae09 gsec09 and sect09 have the same 8606 observations
*missing from 2012. These firms only appear once. They do have other data.

* I want to check if these variables have profit/loss / emp variables as well
*importing the csv of the 8606 ids
import delimited "$dir/Data/id_missing.csv",clear
save "$dir/Data/id_missing.dta",replace
use "$dir/Data/cba_cbb_2012.dta", clear

*Merge the data and keep only those that are in the using dataset
merge 1:1 id using "$dir/Data/id_missing.dta"
keep if _merge==3

br // we see that there are values in the profit loss account in these obs/firms

*Conclusion: we decided to drop these variables
drop if sect09==. & any ==2012
