***************************************************
*Project: BDE Summer Internship
*Purpose: Summarising employment variables
*Last modified: July 27th 2020 by Ishwara
***************************************************


***************************************************
*00. Preamble
***************************************************
	
	
clear all
set maxvar 30000
set more off

*Set user and the directory.Please specify your directory since this
*do file exports several files.
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
* The variables below are the ones relating to "Employees and personnel costs " and id
local emp_vars "c200084_current c200082_current c200083_current c200309_current c200016_current c200023_current c200017_current c200018_current c200020_current c200021_current c200024_current c200085_current"
local id_vars "id any anyconst revc cnae09 sect09 gsec09 cues tamrec tamest grup bols codpos fuen peco esta cab"
local i=2006
while `i'<=2018 {
	use "$dir/Data/cba_cbb_`i'.dta", clear
	set more off
	sort id
	keep `emp_vars' `id_vars' 
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
save "$dir/panel_for_emp_stats.dta", replace
***************************************************
*02 Outlier Check
***************************************************
*I include some code for scatter plots below 
****WARNING: generating plots takes too long so I took screenshots of the graphs.
gen n=_n
*Below is a scatter for all obs in our dataset
twoway (scatter c200084_current n, sort)

*Below is a scatter for all obs in 2008
twoway (scatter c200084_current n if any==2008, sort)

*Same for 2012
twoway (scatter c200084_current n if any==2012, sort)

*2008 and sectors C&E
twoway (scatter c200084_current n if any==2008 & (gsec09=="C" | gsec09=="E"), sort)
*2012 and sectors C&E
twoway (scatter c200084_current n if any==2012 & (gsec09=="C" | gsec09=="E"), sort)

**The plots show the clear presence of outliers 

*********************
*2.1 Method 1
*********************

*If firm only appears once and has a value above the a threshold
*First I create the maxrun vars as before 

* The cond function checks whether L.run ==. ; If true it sets run to 1
*If false it sets run to L.run +1
cap drop run
gen run = .
by id: replace run = cond(L.run == ., 1, L.run + 1)
by id: egen maxrun = max(run)
*maxrun shows the maximum continuous chain 
by id: gen gap =1 if run==run[_n -1]
replace gap =0 if gap ==.

*Now to find the outliers
*Tag the firm if it appears only once and employs more than 5000 people in any year
gen out=1 if (run ==1 & maxrun==1 & gap==0) & (c200084_current > 5000 & c200084_current <.)
*browsing the results shows only 3 instances in 2008 and none in 2012
*Conclusion: the firms with really large values in 2008 occur more than once

*********************
*2.2 Method 2
*********************
xtset id any,yearly
cap drop run
gen run = .
by id: replace run = cond(L.run == ., 1, L.run + 1)
by id: egen maxrun = max(run)
*maxrun shows the maximum continuous chain 
by id: gen gap =1 if run==run[_n -1]
replace gap =0 if gap ==.

cap drop out1
gen out1=.
sort id any
* create a variable for difference in emp b/w t and t-1
cap drop diff
by id: gen diff = c200084_current[_n]-c200084_current[_n -1]

*Tag firms which have a difference larger than 5000 
by id: replace out1=1 if (diff>5000 & diff<.) &(run!=.) 
*Now suppose you want to view only the outlier obs and not the entire series for the firm 

br id any gsec09 c200084_current if out1==1
*Suppose you want to see all the data for the firm which produces the outlier
cap drop grpflag 
egen grpflag = min(out1), by(id)
br id any gsec09 c200084_current if grpflag==1

***************************************************
*03 Summarising the data 
***************************************************
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
	drop if gsec09=="?" | gsec09==""
	reshape wide `v',j(any) i(gsec09)
	export excel using "$dir/emp_summary.xlsx", sheet("`v'") sheetmodify firstrow(variables)
	}

*emp_summary.xlsx should have the necessary output in each sheet of the workbook
