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
*01 Difference in abs values 
***************************************************
use "$dir/Data/panel_cba_emp.dta", replace
*dropping the previous variables 

xtset id any,yearly
cap drop run
gen run = .
by id: replace run = cond(L.run == ., 1, L.run + 1)
by id: egen maxrun = max(run)
*maxrun shows the maximum continuous chain 
by id: gen gap =1 if run==1 &run[_n -1]<.
replace gap =0 if gap ==.

*Tag the firm if it appears only once and employs more than 5000 people in any year
cap drop out1
gen out1=1 if (run ==1 & maxrun==1 & gap==0) & (c200084_current > 1000 & c200084_current <.)
count if out1==1
*Conclusion: Only 25 firms in the entire dataset satisfy out ==1. None from 2008 or 2012

*Therefore I check for firms that have a difference of 5000 from one year to the next
cap drop out2 
cap drop out1
gen out1=.
gen out2=.
* create a variable for difference in emp b/w t and t-1
cap drop diff
by id: gen diff =abs(c200084_current[_n]-c200084_current[_n -1])

*Tag firms which have a difference larger than 1000 
by id: replace out1=1 if (diff>1000 & diff<.) &(run!=.) 
count if out1==1 //->1,856 firms
tab peco if out1==1

*Tag firms which have a difference larger than 5000
by id: replace out2=1 if (diff>5000 & diff<.) &(run!=.) 
count if out2==1 //->632 firms
tab peco if out2==1


***************************************************
*02 large percentage changes 
***************************************************

*Suppose we want to see % 
cap drop diff_percent
by id: gen diff_percent = abs((c200084_current[_n]-c200084_current[_n -1])/(c200084_current[_n-1]))
cap drop out3
gen out3 =.
by id: replace out3=1 if (diff_percent>1 & diff_percent<.) &(run!=.) 

count if out3==1 // 367,886 (for 1)

cap drop out3
gen out3 =.
by id: replace out3=1 if (diff_percent>5 & diff_percent<.) &(run!=.) 
tab peco if out3==1
* 88,742 if >5 

*Too many small firms throw this off.


***************************************************
*03 Combination of 1 & 2 
***************************************************
* Use % change for large firms and abs value for small firms
*the 99 percentile of avg emp is 80.4. Therefore I will start by defining large as >80
cap drop grpsize
egen grpsize = median(c200084_current), by(id)
cap drop large_dummy
by id: gen large_dummy=grpsize>80
cap drop out4
gen out4=.
by id:replace out4=1 if  (diff_percent>1 & diff_percent<.) &(run!=.) &(large_dummy==1)
by id:replace out4=1 if (diff>1000 & diff<.) &(run!=.) &(large_dummy==0)
tab peco if out4==1
*1,833 outliers generated 
*if change diff_percent to 5 then we get 1579 outliers 



/*
*Suppose you want to see all the data for the firm which produces the outlier

cap drop grpflag 
egen grpflag = min(out4), by(id)
br id any c200084_current if grpflag==1
*/
