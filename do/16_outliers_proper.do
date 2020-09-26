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
* 1. Output
***************************************************	

*use out1 for output 
xtset id year,yearly
cap drop out1
gen out1=.

* Negative values of output
 count if output <0 & inputs >=0 
	gen output_neg = 1 if output < 0
	
	replace output = -output if output_neg == 1 & inputs > 0			// 
	replace output = . if output_neg == 1 & inputs == 0				// 
	drop output_neg

// Too large values Outliers for output -- Max va is 20,000 (va for Telefonica )

	gen out_output = 1 if output > 20000 & output < .					
	replace output = output_0[_n+1] if id == id[_n+1] & out_output == 1	 
	replace output = . if id != id[_n+1] & out_output == 1				 
	drop out_output
	replace output_0 = . if output_0 > 20000

// Replace incorrect zero output observations
	gen output_zero = 1 if id == id[_n+1] & output == 0 & output[_n+1] != 0 & output_0[_n+1] != .	
	replace output = output_0[_n+1] if output_zero == 1 // assume output incorrect if output(t+1)>0 & output_0>0
	drop output_zero

 
// Drop firms with all zero output
	*replace output = . if 
	by id : egen min_output = min(output)
	by id : egen max_output = max(output)
	drop if min_output == 0 & max_output == 0		//39,635 observations deleted
	drop if min_output == . & max_output == . 		//49,413 observations deleted
		
***************************************************
* 2. staf (personnel costs)
***************************************************	

// Negative values of staf
	gen staf_neg = 1 if staf < 0
	replace staf = -staf if staf_neg == 1 & empl > 0			
	replace staf = . if staf_neg == 1 & empl == 0				
	drop staf_neg

// Too large values
	gen out_staf = 1 if staf > 10000 & staf < .					
	replace staf = staf_0[_n+1] if id == id[_n+1] & out_staf == 1	 
	replace staf = . if id != id[_n+1] & out_staf == 1				 
	drop out_staf
	replace staf_0 = . if staf_0 > 10000

// Replace incorrect zero staf observations
	gen staf_zero = 1 if id == id[_n+1] & staf == 0 & staf[_n+1] != 0 & staf_0[_n+1] != .	
	replace staf = staf_0[_n+1] if staf_zero == 1								// assume staf incorrect if staf(t+1)>0 & staf_0>0
	drop staf_zero

// Replace zero staf for observations with positive emp
	gen emp_staf_check = 1 if staf == 0 & empl > 0 & empl < .
	replace staf = . if emp_staf_check == 1								
	drop emp_staf_check	

	
// drop if all zero or all misssing	
	by id : egen min_staf = min(staf)
	by id : egen max_staf = max(staf)
	drop if min_staf == 0 & max_staf == 0		// 7,838 observations deleted
	drop if min_staf == . & max_staf == . 		// 3,491 observations deleted
	
