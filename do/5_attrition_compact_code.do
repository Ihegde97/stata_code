***************************************************
*Project: BDE Summer Internship
*Purpose: Setting the panel & attrition
*Last modified: July 24th 2020 by Ishwara
***************************************************
*Note: This do file gives the same result as attrition_long.do
*The results are also in an excel sheet attrition.csv

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
*01. Attrition -- Email
***************************************************
*The goal is to get attrition rates for each wave
* More specifically, goal is to complete the csv example sent by email.
*Goal: To check atttrition by wave according to csv

*Now as usual I create the panel First
local i=2006
while `i'<=2018 {
	use "$dir/Data/cba_cbb_`i'.dta", clear
	set more off
	sort id
* here you can keep any variable that you want to summarise
	keep id any 
	save "$dir/Data/cba_cbb_`i'_a.dta", replace
	local i=`i'+1
}
* Now we append all waves using 2018 as the master
local j=2006
while `j'<=2017 {
	append using "$dir/Data/cba_cbb_`j'_a.dta"
	local j=`j'+1
}



*First I generate a dummy variable that will be useful for reshape
gen dummy=1

*I reshape the data to wide format
keep id any dummy 
reshape wide dummy, i(id) j(any)


*Now I want to convert . to 0's for convenience in addition
local i=2006
while `i'<=2018 {
	set more off
	replace dummy`i'=0 if dummy`i'==.
	local i=`i'+1
}

*This is the code provided by user=="Federico"

local dumlist "dummy2007 dummy2008 dummy2009 dummy2010 dummy2011 dummy2012 dummy2013 dummy2014 dummy2015 dummy2016 dummy2017 dummy2018"
forvalues j = 2007/2018 {
	local k = `j' - 1
	local ex "dummy`j'"							
	local dumlist : list dumlist - ex							// this excludes the contemporaneous dummy from the rowtotal argument
	di "`j' wave"
	if `j' <= 2017 {											// exclude 2018 because we don't know if missing firms will appear again in the future
		egen rt_`j' = rowtotal(`dumlist')						// this is the total number of future waves with non-missing data
		// (t-1) firms missing in t but non-missing in t+s
		count if dummy`k' == 1 & dummy`j' == 0 & rt_`j' > 0
		// (t-1) firms missing in t and in all t+s
		count if dummy`k' == 1 & dummy`j' == 0 & rt_`j' == 0	
	}	
	// (t-1) firms non-missing in t
	count if dummy`k' == 1 & dummy`j' == 1		
}


**** Erase all the intermediary files ****

local i=2006
while `i'<=2011 {
	cap erase "$dir/Data/cba_cbb_`i'_a.dta"
	cap erase "$dir/Data/cba_cbb_`i'_b.dta"
	local i=`i'+ 1
}
