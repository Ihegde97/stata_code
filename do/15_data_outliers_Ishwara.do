***************************************************
*Project: BDE Summer Internship
*Purpose: Setting the panel & attrition
*Last modified: August 17th 2020 by Federico
***************************************************

***************************************************
* 0. Load data
***************************************************	
clear all
set maxvar 30000
set more off

// Set user and the directory
local users   "Ishwara" // "Federico"

if "`users'" == "Federico" {
	global dir "C:\TRABAJO\Central_de_balance"
}
if "`users'" == "Ishwara" {
		global dir "C:/Users/user/OneDrive - City University of Hong Kong/University/Cemfi/Internship"
}

use "$dir/cba_data.dta", clear


***************************************************
* 3. Identify outliers
***************************************************

// EMPLOYMENT
	// Negative values of employment
	gen empl_neg = 1 if empl < 0
	foreach var of varlist empl_perm empl_temp empl_uncl pcostpe empl  {
		replace `var' = -`var' if empl_neg == 1 & staf > 0			// 3 obs (negative employment, positive personnel costs)
		replace `var' = . if empl_neg == 1 & staf == 0				// 3 obs (negative employment, zero personnel cost)
	}	
	foreach var of varlist output inputs va staf profit_gross finrev depr profit_netop impdisp fairvachange corpinctax profit {
		replace `var' = . if empl_neg == 1 & (id == 71489 | id == 301495 | id == 1719387 | id == 2038249)			
	}
	drop empl_neg
	// Too large values
	gen out_empl = 1 if empl > 83000 & empl < .					// Mercadona in 2018 is the largest possible employment
	foreach var of varlist empl_perm empl_temp empl_uncl empl staf {
		replace `var' = `var'_0[_n+1] if id == id[_n+1] & out_empl == 1	 
		replace `var' = . if id != id[_n+1] & out_empl == 1				 
	}
	foreach var of varlist empl_perm empl_temp empl_uncl empl staf {		 
		replace `var' = . if out_empl == 1 & (empl == 0 | empl > 83000)
	}
	drop out_empl
	replace empl_0 = . if empl_0 > 83000
	// Replace incorrect zero employment observations
	gen empl_zero = 1 if id == id[_n+1] & empl == 0 & empl[_n+1] != 0 & empl_0[_n+1] != .	
	foreach var of varlist empl_perm empl_temp empl_uncl empl staf  {
		replace `var' = `var'_0[_n+1] if empl_zero == 1								// assume empl incorrect if empl(t+1)>0 & empl_0>0
	}
	drop empl_zero
	// Drop observations with all zeros in outut, inputs, value added, personnel cost, gross/net profits, employment
	egen check = rowtotal(output inputs va staf profit_gross profit empl empl_perm empl_temp empl_uncl)
	drop if check == 0						// 1,658,573 obs
	drop check	
	// Replace zero employment for observations with positive personnel costs
	gen emp_staf_check = 1 if empl == 0 & staf > 0 & staf < .
	foreach var of varlist empl_perm empl_temp empl_uncl empl {
		replace `var' = . if emp_staf_check == 1								
	}	
	drop emp_staf_check	
	// Replace zero employment observations for firms with otherwise min employment above 10
	gen t = (empl == 0)
	by id : egen temp = total(t)
	gen emp = empl
	replace emp = . if emp == 0
	by id : egen min_emp = min(emp)
	gen emp_zero = temp > 0 & temp <= 2 & min_emp > 10 & min_emp < . 		// 1-2 missing observations + second lowest value of employment > 10
	foreach var of varlist empl_perm empl_temp empl_uncl empl {
		replace `var' = . if emp_zero == 1								
	}	
	drop emp_zero emp min_emp t temp
	// Drop firms with all zero employment
	*replace empl = . if 
	by id : egen min_empl = min(empl)
	by id : egen max_empl = max(empl)
	drop if min_empl == 0 & max_empl == 0		// 2,267,817 obs
	drop if min_empl == . & max_empl == . 		// 90,824 obs
	// // Min-max difference
	drop if min_empl <= 1 & max_empl > 100 & max_empl < .		// 24,264 obs
	drop min_empl max_empl
	
	// Save dataset
	save "$dir\Data\cba_data.dta",replace

	
***************************************************
* 2. Identifying  outliers for other variables
***************************************************
*First I check whether the outliers are visible in summary stats
local out_vars "output inputs va staf profit_gross profit"

drop if gsec09=="?"
collapse (mean) output= output inputs = inputs value_add= va  p_costs= staf profit=profit , by( gsec09 year ) 
*Save this result to open later
save "$dir/collapsed_data.dta",replace
set more off 

*I will now reshape the data as recommended
local vars "output inputs value_add p_costs profit" 
foreach v of local vars  {
	use "$dir/collapsed_data.dta",clear
	set more off 
	keep year gsec09 `v'
	cap drop if gsec09=="?" | gsec09==""
	reshape wide `v',j(year) i(gsec09)
	export excel using "$dir/output/vars_summary.xlsx", sheet("`v'") sheetmodify firstrow(variables)
	}


*Conclusion: There may be potentiel outliers in these variables as well. However, since a firm 
*can change output (and thus profits,value added) by its discretion I am not sure whether these should 
*recorded as outliers 

use "$dir/cba_data.dta",clear 
xtset id year,yearly
cap drop run
gen run = .
by id: replace run = cond(L.run == ., 1, L.run + 1)
by id: egen maxrun = max(run)
*maxrun shows the maximum continuous chain 
by id: gen gap =1 if run==1 &run[_n -1]<.
replace gap =0 if gap ==.

*Outliers for output -- Max output is 20,000 (va for Telefonica )

cap drop out2 
cap drop out1
gen out1=.
* create a variable for difference in emp b/w t and t-1
cap drop diff 
cap drop diff_percent
by id: gen diff =abs(output[_n]-output[_n -1])
by id: gen diff_percent = abs((output[_n]-output[_n -1])/(output[_n-1]))


*Tag firms which have a difference larger than 1000 
by id: replace out1=1 if (diff>50000 & diff<. |diff_percent>=100 & diff_percent<.)  & (run!=.) 
*count if out1==1 //->


cap drop grpflag 
egen grpflag = min(out1), by(id)
*br id year output out1 if grpflag==1


*Outliers for staf- greater than 10,000
cap drop out2
gen out2=.
* create a variable for difference in emp b/w t and t-1
cap drop diff2 
cap drop diff_percent2
by id: gen diff2 =abs(staf[_n]-staf[_n -1])
by id: gen diff_percent2 = abs((staf[_n]-staf[_n -1])/(staf[_n-1]))


*Tag firms which have a difference larger than 1000 
by id: replace out2=1 if (diff2>50000 & diff2<. |diff_percent2>=100 & diff_percent2<.)  & (run!=.) 
*count if out1==1 //->


cap drop grpflag 
egen grpflag = min(out2), by(id)
br id year staf out1 out2 if grpflag==1
