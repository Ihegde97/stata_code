***************************************************
*Project: BDE Summer Internship
*Purpose: Setting the panel & attrition
*Last modified: 1st of August 2020 by Ishwara
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
*01 Merging the data 
***************************************************

* The variables below are the ones relating to "Employees and personnel costs"
local emp_vars "c200084_current c200082_current c200083_current c200309_current c200016_current c200023_current c200017_current c200018_current c200020_current c200021_current c200024_current c200085_current"
local profit_vars "c200075_current c200003_current c200005_current c200006_current c200076_current c200010_current c200011_current c200012_current c200015_current c200025_current c200030_current c290042_current c290037_current c290031_current c290308_current c200034_current c290041_current c290038_current c200039_current c200040_current c200043_current c290046_current c290059_current c200051_current c200048_current c200049_current c200306_current c290055_current c200052_current c290053_current c200307_current c200062_current c290068_current c200063_current c200064_current c200026_previous c290066_current c200069_current c290070_current c290071_current c290088_current c200002_current"
local id_vars "id any cif anyconst revc cnae09 sect09 gsec09 cues tamrec tamest grup bols codpos fuen peco esta cab alta_sitc baja_sitc calidad nif_dom nif_dom"
local i=2006
while `i'<=2018 {
	use "$dir/Data/cba_cbb_`i'.dta", clear
	set more off
	sort id
	local string_int "revc peco calidad fiab"

	foreach s of local string_int  {
		replace `s'="." if `s'==""
		replace `s'="1" if `s'=="S"
		replace `s'="0" if `s'=="N"
		destring `s', replace
	}
	*cues is a bit diff N=1, R=0
	replace cues ="." if cues==""
	replace cues ="1" if cues=="N"
	replace cues ="0" if cues =="R"

	keep `emp_vars' `profit_vars' `id_vars' 
	save "$dir/Data/cba_cbb_`i'_b.dta", replace
	local i=`i'+1
}


* Now I append using 2018 as the master
local j=2006
while `j'<=2017 {
	append using "$dir/Data/cba_cbb_`j'_b.dta", force
	local j=`j'+1
}

* creating the panel
xtset id any, yearly

*Keeping the current subset of variables it seems like the memory the panel takes is 2.05GB.
*From online research it seems strings are the most troublesome so I will convert strings 
*to binary 0-1 when needed using destring. 

*Converting strings to 0-1 binary 

*Variables that can be converted
*

*Problems: sect09 cnae09 
