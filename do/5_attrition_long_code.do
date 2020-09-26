***************************************************
*Project: BDE Summer Internship
*Purpose: Setting the panel & attrition
*Last modified: July 23th 2020 by Ishwara
***************************************************
*Note: This do file has been replaced by attrition_compact.do 
*Both give the same results --- can be found in attrition.csv
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

* Now I will generate rowtotals of all years 
*all years >= 2006
egen rt_06=rowtotal( dummy2006 dummy2007 dummy2008 /// 
	dummy2009 dummy2010 dummy2011 dummy2012 dummy2013 /// 
	dummy2014 dummy2015 dummy2016 dummy2017 dummy2018)
*missing in t but non-missing in t+s
count if dummy2006==0 & rt_06 >0

*****2007******
egen rt_07=rowtotal(dummy2007 dummy2008 /// 
	dummy2009 dummy2010 dummy2011 dummy2012 dummy2013 /// 
	dummy2014 dummy2015 dummy2016 dummy2017 dummy2018)

*missing in 07 but non-missing in t+s
count if dummy2006==1 & dummy2007==0 & rt_07 >0 

*missing in >=07 
count if dummy2006==1 & dummy2007==0 & rt_07 ==0

*non-missing in 07
count if dummy2007==1 & dummy2006==1
*missing in 06
count if dummy2006==0 & dummy2007==1

*****2008******
egen rt_08=rowtotal(dummy2008 /// 
	dummy2009 dummy2010 dummy2011 dummy2012 dummy2013 /// 
	dummy2014 dummy2015 dummy2016 dummy2017 dummy2018)

*missing in 08 but non-missing in t+s
count if dummy2007==1 & dummy2008==0 & rt_08 >0 

*missing in >=08 
count if dummy2007==1 & dummy2008==0 & rt_08 ==0

*non-missing in 08
count if dummy2008==1 & dummy2007==1
*missing in 07
count if dummy2007==0 & dummy2008==1

*****2009******
egen rt_09=rowtotal(dummy2009 dummy2010 dummy2011 dummy2012 dummy2013 /// 
	dummy2014 dummy2015 dummy2016 dummy2017 dummy2018)

*missing in 09 but non-missing in t+s
count if dummy2008==1 & dummy2009==0 & rt_09 >0 

*missing in >=09 
count if dummy2008==1 & dummy2009==0 & rt_09 ==0

*non-missing in 09
count if dummy2008==1 & dummy2009==1
*missing in 08
count if dummy2008==0 & dummy2009==1


*****2010******
egen rt_10=rowtotal(dummy2010 dummy2011 dummy2012 dummy2013 /// 
	dummy2014 dummy2015 dummy2016 dummy2017 dummy2018)

*missing in 10 but non-missing in t+s
count if dummy2009==1 & dummy2010==0 & rt_10 >0 

*missing in >=10
count if dummy2009==1 & dummy2010==0 & rt_10 ==0

*non-missing in 10
count if dummy2009==1 & dummy2010==1
*missing in 10
count if dummy2009==0 & dummy2010==1


*****2011******
egen rt_11=rowtotal(dummy2011 dummy2012 dummy2013 /// 
	dummy2014 dummy2015 dummy2016 dummy2017 dummy2018)

*missing in 10 but non-missing in t+s
count if dummy2010==1 & dummy2011==0 & rt_11 >0 

*missing in >=11
count if dummy2010==1 & dummy2011==0 & rt_11 ==0

*non-missing in 11
count if dummy2010==1 & dummy2011==1
*missing in 11
count if dummy2010==0 & dummy2011==1


*****2012******
egen rt_12=rowtotal(dummy2012 dummy2013 /// 
	dummy2014 dummy2015 dummy2016 dummy2017 dummy2018)

*missing in 12 but non-missing in t+s
count if dummy2011==1 & dummy2012==0 & rt_12 >0 

*missing in >=12
count if dummy2011==1 & dummy2012==0 & rt_12 ==0

*non-missing in 12
count if dummy2011==1 & dummy2012==1
*missing in 11
count if dummy2011==0 & dummy2012==1


*****2013******
egen rt_13=rowtotal(dummy2013 /// 
	dummy2014 dummy2015 dummy2016 dummy2017 dummy2018)


*missing in 13 but non-missing in t+s
count if dummy2012==1 & dummy2013==0 & rt_13 >0 

*missing in >=13
count if dummy2012==1 & dummy2013==0 & rt_13 ==0

*non-missing in 13
count if dummy2012==1 & dummy2013==1
*missing in 12
count if dummy2012==0 & dummy2013==1


*****2014******
egen rt_14=rowtotal(dummy2014 dummy2015  /// 
	dummy2016 dummy2017 dummy2018)

*missing in 14 but non-missing in t+s
count if dummy2013==1 & dummy2014==0 & rt_14 >0 

*missing in >=14
count if dummy2013==1 & dummy2014==0 & rt_14==0

*non-missing in 14
count if dummy2013==1 & dummy2014==1
*missing in 13
count if dummy2013==0 & dummy2014==1

*****2015******
egen rt_15=rowtotal(dummy2015  /// 
	dummy2016 dummy2017 dummy2018)

*missing in 14 but non-missing in t+s
count if dummy2014==1 & dummy2015==0 & rt_15 >0 

*missing in >=15
count if dummy2014==1 & dummy2015==0 & rt_15==0

*non-missing in 15
count if dummy2014==1 & dummy2015==1
*missing in 14
count if dummy2014==0 & dummy2015==1

*****2016******
egen rt_16=rowtotal(dummy2016 dummy2017 dummy2018)

*missing in 14 but non-missing in t+s
count if dummy2015==1 & dummy2016==0 & rt_16 >0 

*missing in >=16
count if dummy2015==1 & dummy2016==0 & rt_16==0

*non-missing in 16
count if dummy2015==1 & dummy2016==1
*missing in 15
count if dummy2015==0 & dummy2016==1

*****2017******
egen rt_17=rowtotal(dummy2017 dummy2018)

*missing in 16 but non-missing in t+s
count if dummy2016==1 & dummy2017==0 & rt_17 >0 

*missing in >=17
count if dummy2016==1 & dummy2017==0 & rt_17==0

*non-missing in 17
count if dummy2016==1 & dummy2017==1
*missing in 17
count if dummy2016==0 & dummy2017==1


*****2018******
*missing in 19
count if dummy2017==1 & dummy2018==0

*non-missing in 19
count if dummy2017==1 & dummy2018==1

*missing in 18
count if dummy2017==0 & dummy2018==1


**** Erase all the intermediary files ****

local i=2006
while `i'<=2011 {
	cap erase "$dir/Data/cba_cbb_`i'_a.dta"
	cap erase "$dir/Data/cba_cbb_`i'_b.dta"
	local i=`i'+ 1
}


**Make a local
**
