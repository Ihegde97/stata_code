***************************************************
*Project: BDE Summer Internship
*Purpose: Updating current with prev
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
*01 Using the expand method 
***************************************************
*First I will create a panel with any 2006-11 and two profit vars and id /any
*local profit_vars "c200075_current c200003_current c200005_current c200006_current c200076_current c200010_current c200011_current c200012_current c200015_current c200025_current c200030_current c290042_current c290037_current c290031_current c290308_current c200034_current c290041_current c290038_current c200039_current c200040_current c200043_current c290046_current c290059_current c200051_current c200048_current c200049_current c200306_current c290055_current c200052_current c290053_current c200307_current c200062_current c290068_current c200063_current c200064_current c200026_current c290066_current c200069_current c290070_current c290071_current c290088_current c200002_current"
*local emp_vars "c200084_current c200082_current c200083_current c200309_current c200016_current c200023_current c200017_current c200018_current c200020_current c200021_current c200024_current c200085_current"
*local id_vars "id any cif anyconst revc cnae09 sect09 gsec09 cues tamrec tamest grup bols codpos fuen peco esta cab alta_sitc baja_sitc calidad fiab nif_dom"
local profit_vars "c200075_*  c200030_*"
local id_vars "id any "
local i=2006
while `i'<=2012 {  //change 
	use "$dir/Data/cba_cbb_`i'.dta", clear
	set more off
	sort id
	keep `profit_vars' `id_vars' //`emp_vars'
	save "$dir/Data/cba_cbb_`i'_a.dta", replace
	local i=`i'+1
}


* Now I append using 2011 as the master
local j=2006
while `j'<=2011 { //change 
	append using "$dir/Data/cba_cbb_`j'_a.dta", force
	local j=`j'+1
}
 creating the panel
*save "$dir/Data/panel_filling _data.dta",replace
use "$dir/Data/panel_filling _data.dta", clear
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


*fill will be used to back-fill gaps and first to back-fill t_0 -1
cap drop fill
cap drop first
gen fill=.

*fill is 1 if there is a gap between two obs within firms in a panel
bysort id (any): replace fill = cond(gap[_n+1]==1 & n_years[_n+1]>0, 1, 0)
expand 2 if fill==1,gen(dup)
replace any =any +1 if dup==1

*
bysort id (any) : gen byte first = _n == 1
expand 2 if first==1 & any >2006,gen(dup1)
replace any =any -1 if dup1==1

sort id any 
by id (any):replace c200075_current=c200075_prev[_n+1] if dup==1 
by id (any):replace c200075_current=c200075_prev[_n+1] if dup1==1 


*To-Do:
*Add profit vars
*Add emp vars 
*Add id 
*clean 2012
*Do not destring
*back_fill
