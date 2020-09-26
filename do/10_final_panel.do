***************************************************
*Project: BDE Summer Internship
*Purpose: Creating a final panel V1
*Last modified: 7th of August 2020 by Ishwara
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
*01 Basic appending
***************************************************
*local profit_vars "c200075_* c200003_* c200005_* c200006_* c200076_* c200010_* c200011_* c200012_* c200015_* c200025_* c200030_* c290042_* c290037_* c290031_* c290308_* c200034_* c290041_* c290038_* c200039_* c200040_* c200043_* c290046_* c290059_* c200051_* c200048_* c200049_* c200306_* c290055_* c200052_* c290053_* c200307_* c200062_* c290068_* c200063_* c200064_* c200026_* c290066_* c200069_* c290070_* c290071_* c290088_* c200002_*"
local emp_vars "c200084_* c200082_* c200083_* c200309_* c200016_* c200023_* c200017_* c200018_* c200020_* c200021_* c200024_* c200085_*"
local id_vars "id any cif anyconst revc cnae09 sect09 gsec09 cues tamrec tamest grup bols codpos fuen peco esta cab alta_sitc baja_sitc calidad fiab nif_dom"
local profit_vars "c200075_* c200003_* c200005_* c200006_* c200076_* c200030_* c290042_* c290037_* c290031_* c290308_* c200034_* c290041_* c290038_* c200039_* c200040_* c200043_* c290046_*"

local i=2006
while `i'<=2018 {
	use "$dir/Data/cba_cbb_`i'.dta", clear
	set more off
	keep  `id_vars' `profit_vars' //`emp_vars' 
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

sort id any 

***************************************************
*02 Sampling the Data 
***************************************************
tempfile paneldata
save `paneldata'
 
collapse (mean) c200075_current, by(id)
keep id
sample 50 // creates a sample of 50 percent of observations
 
tempfile randomsampleid
save `randomsampleid'
 
use `paneldata'
 
merge m:1 id using `randomsampleid'
 
drop if _merge == 1
drop _merge


***************************************************
*03 Cleaning 2012 data 
***************************************************
*Creating panel structure 
xtset id any, yearly

*Usual maxrun code. Note, now there is one extra
cap drop run
gen run = .
by id: replace run = cond(L.run == ., 1, L.run + 1)
by id: egen maxrun = max(run)
*maxrun shows the maximum continuous chain 
by id: gen gap =1 if run==run[_n -1]
replace gap =0 if gap ==.

*The n_years line gives the number of years of gaps
by id: gen n_years = cond(gap==1, any[_n]-any[_n-1], 0)

**Cleaning 2012

*Replacing by t+1. 
by id: replace sect09 = sect09[_n+1] if sect09==.

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

***************************************************
*04 Filling the data 
***************************************************
*fill will be used to back-fill gaps and first to back-fill t_0 -1
cap drop fill
cap drop first
gen fill=.

*fill is 1 if there is a gap between two obs within firms in a panel
bysort id (any): replace fill = cond(gap[_n+1]==1 & n_years[_n+1]>0, 1, 0)
expand 2 if fill==1,gen(dup)
replace any =any +1 if dup==1


bysort id (any) : gen byte first = _n == 1
expand 2 if first==1 & any >2006,gen(dup1)
replace any =any -1 if dup1==1

sort id any 
local fill_vars "c200075 c200003 c200005 c200006 c200076 c200030 c290042 c290037 c290031 c290308 c200034 c290041 c290038 c200039 c200040 c200043 c290046"
foreach v of local fill_vars  {
	by id (any):replace `v'_current=`v'_previous[_n+1] if dup==1 |dup1 ==1	
	}
	
