***************************************************
*Project: BDE Summer Internship
*Purpose: Setting the panel & attrition
*Last modified: July 23th 2020 by Ishwara
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
*01. Creating Summary statistics for peco
***************************************************
*Creating a panel with peco, use any var you like
local i=2006
while `i'<=2018 {
	use "$dir/Data/cba_cbb_`i'.dta", clear
	set more off
	sort id
* here you can keep any variable that you want to summarise
	keep id any peco
	save "$dir/Data/cba_cbb_`i'_a.dta", replace
	local i=`i'+1
}
* Now we append all waves using 2018 as the master
local j=2006
while `j'<=2017 {
	append using "$dir/Data/cba_cbb_`j'_a.dta"
	local j=`j'+1
}

*Converting peco to a 0-1 binary
replace peco="1" if peco=="S"
replace peco="0" if peco=="N"
destring(peco), replace
set more off 

*Creating export tables
estpost tabstat peco, by(any) statistics(mean sd) ///
columns(statistics) listwise
*This table does not export nicely 
*esttab using peco.csv, main(mean) aux(sd) nostar unstack 


***************************************************
*02. Email Task-Summary Stats for peco 
***************************************************
*This is using the previously loaded data.
*The code is also the same as previously used for checking gaps
*Setting the panel
xtset id any, yearly

*Counting the longest run 
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

*if there is a gap I will store the number of years gap in n_years
*If there is no gap the n_years =0
by id: gen n_years = cond(gap==1, any[_n]-any[_n-1], 0)

****New section****
*Note : 1:Pass;0:Not pass

*The dummy for complete panel
gen peco_no_gap=.
replace peco_no_gap=peco if maxrun==13

*The dummy for one_gap
gen peco_one_gap=.
replace peco_one_gap=peco if maxrun==12

gen peco_many_gaps=.
replace peco_many_gaps=peco if maxrun<12


*The code below will collapse the data and give a cummulated peco 
*Alternatively check the peco.csv file 
collapse (min) cumm_peco= peco cumm_peco_no_gaps=peco_no_gap ///
cumm_peco_one_gap=peco_one_gap cumm_peco_many_gaps=peco_many_gaps , by(id) 

tab cumm_peco,missing

tab cumm_peco_no_gaps,missing

tab cumm_peco_one_gap,missing

tab cumm_peco_many_gaps,missing

*need t
