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

***************************************************
*01. Understanding prev and current variables
***************************************************
*The goal of this task is to indeed confirm the prev and current vars refer
*to previous years' variable and current. Alternatively, it could be 
*that it simply refers to the previous value and the current updated value

* Below I sort the data and keep only gross op profit for 2010 and 2011 waves
use "$dir/Data/cba_cbb_2010.dta", clear
sort id
rename c200030_current c200030_10
keep id any c200030_10
save "$dir/Data/cba_cbb_2010_a.dta", replace

use "$dir/Data/cba_cbb_2011.dta", clear
sort id
rename c200030_previous c200030_11
keep id any c200030_11
save "$dir/Data/cba_cbb_2011_a.dta", replace

*Note that now the "Master" data is 2011. 

merge 1:1 id using "$dir/Data/cba_cbb_2010_a.dta"
save "$dir/Data/cba_cbb_merged.dta", replace

*conclusion: It is the previous years' data and not a previous version of 
*current data.

*Below I check if we can use future years' prev var to fill in 
br if _merge==1

*seems like the vars exist in var_prev in 2011 even if absent in 2010. Perhaps
*it could be that the firm was incorporated only in 2011 (hence 0) or 
* the previous available year has been imputed.I check both hypotheses below


***************************************************
*1.1 Investigating prev variables
***************************************************
*Here the main goal is to check whether the prev_vars are imputed using actual 
*data from the previous year or from the last year available.
local i=2006
while `i'<=2011 {
	use "$dir/Data/cba_cbb_`i'.dta", clear
	sort id
	rename c200030_current c200030_current_`i'
	rename c200030_previous c200030_previous_`i'
	keep id any anyconst c200030_*
	save "$dir/Data/cba_cbb_`i'_a.dta", replace
	local i=`i'+1
}
* Now we merge using 2011 as the master
local j=2006
while `j'<=2010 {
	merge 1:1 id using "$dir/Data/cba_cbb_`j'_a.dta"
	*drop if _merge!=1
	cap drop _merge
	local j=`j'+1
}

br if c200030_previous_2011<. & c200030_current_2010==.

* Now we can check that indeed using prev for t+1 can be used to fill
*current for t. Why the value for t+1 in prev exists and not in t I am not sure.



***************************************************
*2. Checking The Number of Observations
***************************************************
*The code below is a while loop to confirm the number of firms in each wave
local i=2006
while `i'<=2018 {
	use "$dir/Data/cba_cbb_`i'.dta", clear
	disp _N
	local i=`i'+1
}
*conclusion: The number of obs in each wave match the screenshot.

***************************************************
*3. Checking for gaps in a panel
***************************************************
*First I will keep a select set of variables. 
local i=2006
while `i'<=2011 {
	use "$dir/Data/cba_cbb_`i'.dta", clear
	set more off
	sort id
	keep id any anyconst c200030_*
	save "$dir/Data/cba_cbb_`i'_b.dta", replace
	local i=`i'+1
}
*Note I use only 5 waves in this code -- can easily extend to more
* Now I append using 2011 as the master
local j=2006
while `j'<=2010 {
	append using "$dir/Data/cba_cbb_`j'_b.dta"
	local j=`j'+1
}

* creating the panel
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




*Erase all the intermediary files 

local i=2006
while `i'<=2011 {
	cap erase "$dir/Data/cba_cbb_`i'_a.dta"
	cap erase "$dir/Data/cba_cbb_`i'_b.dta"
	local i=`i'+ 1
}



*Note for firms that appear and then disappear forever one 
*can check that maxrun <6 & gap ==0.

***************************************************
*Personal Notes -- Please ignore 
* The amounts are always in thousands of euros
*any- year 
*cif - Tax ID - not a unique id
*c200030_* : Gross operating profit
*CBSO- central balance sheet office
*CBI- Integrated survey of the CBSO
*CBA database-voluntary reporting via CBI 
*CBB- obligatory filings by the companies 
*revc - var for sectorised 
*calidad- var for quality
*fuen- data source; CBA-0; CBB- non-zero

***************************************************
