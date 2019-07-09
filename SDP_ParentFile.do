clear
clear matrix
clear mata
capture log close
set maxvar 15000
set more off
numlabel, add

*******************************************************************************
*
*  FILENAME:	CCRX_SDP_ParentFile.do
*  PURPOSE:		PMA2020 data quality checks (clean and check SDP data)
*  DATA IN:		CCRX_SDP_Questionnaire_v#.csv
*  DATA OUT:	CCRX_SDP_$date.dta; CCRX_SDP_DataChecks_$date.xlsx
*
*******************************************************************************

*******************************************************************************
* SET MACROS: UPDATE THIS SECTION FOR EACH COUNTRY/ROUND
*******************************************************************************

* Set local macros for country and round
global country “ET”
local country "$country"

global round “2020”
local round "$round"

global CCRX "ET2020"
local CCRX "$CCRX"

* Set directory forcountry and round 
global datadir 
global dofiledir 
global csvfilesdir 
cd "$datadir"

global csv1 
local csv1  "$csv1"

*Only need to update if there is more than one version of the form
global csv2 
local csv2  "$csv2" 

* Set local/global macros for current date
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)
local todaystata=clock("`today'", "DMY")

 

*Zip all of the old versions of the datasets and the excel spreadsheets.  

capture zipfile `CCRX'*, saving (Archived_Data/Archived_SDP_Data_$date.zip, replace)

*Delete old versions: old version still saved in ArchivedData.zip
capture shell rm `CCRX'*

*Create log
log using "`CCRX'_SDP_DataChecking_$date.log ", replace

*******************************************************************************
* IMPORT SDP SURVEY DATA
*******************************************************************************

* Clear out data
clear

* Read in .csv file
insheet using "$csvfilesdir/`csv1'.csv", names
tempfile temp1
save `temp1', replace

capture insheet using "$csvfilesdir/`csv2'.csv", names
if _rc==0{
tempfile temp2
save `temp2', replace
use `temp1'
append using `temp2'
}

* Generate date variable
gen date="$date"
label variable date "Date"

* Save as a Stata dataset
save "$datadir/`CCRX'_SDP_$date.dta", replace

*******************************************************************************
* SDP CLEANING/CODING
*******************************************************************************

* Read in cleaning .do file here
run "$dofiledir/SDP_Datacleaning.do"

* Rename ea variable
capture rename ea EA
label variable EA "EA"

* Generate date variable
gen date="$date"
label variable date "Date"

* Generate variable that represents difference in minutes between survey start and end time	
gen survey_time_millsec=endSIF-startSIF
label variable survey_time_millsec "Time to complete SDP survey in milliseconds"
gen survey_time_min=survey_time_millsec/60000
label variable survey_time_min "Time to complete SDP survey in minutes"

* Create a time flag for any survey times less than 20 minutes
gen timeflag=0
replace timeflag=1 if survey_time_min<=20 
label variable timeflag "Time to complete SDP survey <20 minutes, or negative"

* Generate visit flag variable 
gen visitflag=0
replace visitflag=1 if times_visited<3 & SDP_result!=1
label variable visitflag "SDP visited less than 3 times and submitted but not complete"

* Generate GPS flag variable equal to 1 if data missing or > 6 meters
gen gpsflag=0
replace gpsflag=1 if (locationaccuracy>6 | locationaccuracy==. | locationlatitude==. | locationlongitude==.)
label variable gpsflag "GPS missing or greater than 6 meters accuracy"

* Generate flag for unknown year opened
gen yearopenflag=0
replace yearopenflag=1 if year_open_rw==-88| year_open_rw==.
label variable yearopenflag "Month and year SDP opened missing or unknown"

* Generate unknown catchment area flag
gen catchmentflag=0
replace catchmentflag=1 if knows_population_served==-88 & advanced_facility==1 | knows_population_served==1 &  advanced_facility==1 | knows_population_served==. &  advanced_facility==1
label variable catchmentflag "Catchment area of SDP unknown or missing"

* Generate duplicate SDP name flag
egen duplicatename = tag(facility_name)
label variable duplicatename "Duplicate SDP name"

*******************************************************************************
* SDP DATA CHECKS: SUMMARY 
*******************************************************************************

* Total number of submissions
preserve
egen number=seq()
egen total_submissions=max(number)
label variable total_submissions "Total number of SDP surveys submitted"

* Tota number of completed SDP surveys
gen completed=1 if SDP_result==1
replace completed=0 if SDP_result!=1
egen total_completed=total(completed)
label variable total_completed "Total number of SDP surveys completed"

* Order data before export
order date total_submissions total_completed

* Generate dichotomous public/private variable
gen public=1 if managing_authority==1
egen total_public=total(public)
label variable total_public "Total number of submitted SDP surveys public"
gen private=1 if managing_authority!=1 & managing_authority!=.
egen total_private=total(private)
label variable total_private "Total number of submitted SDP surveys private"

* Drop duplicate entries based on date
duplicates drop total_submissions, force

* Export number of submissions data to .xls file
export excel date total_submissions total_completed total_public total_private using `CCRX'_SDP_Checks_$date.xls, firstrow(varl) sh(Summary) sheetreplace 

restore

*******************************************************************************
* SDP DATA CHECKS: CONSENT FLAG, BY RE
*******************************************************************************

* Total number of submissions without consent, by RE
preserve
bysort RE: egen number=seq()
bysort RE: egen submissions=max(number)
bysort RE: gen totalconsent=sum(consent_obtained)

gen noconsentflag=submissions-totalconsent

bysort RE: egen noconsentflag2=min(noconsentflag)
drop noconsentflag 
rename noconsentflag2 noconsentflag

*******************************************************************************
* SDP DATA CHECKS: SURVEY TIME FLAG, BY RE
*******************************************************************************

* Total number of submissions that took 20 minutes or less (including negative times), by RE 
bysort RE: egen totaltimeflag=total(timeflag)
drop timeflag
bysort RE: egen timeflag=max(totaltimeflag)

*******************************************************************************
* SDP DATA CHECKS: NUMBER OF VISITS FLAG, BY RE
*******************************************************************************

* Total number of submissions where number of visits less than 3 but not marked as "completed",  by RE
bysort RE: egen totalvisitflag=total(visitflag)
drop visitflag
bysort RE: egen visitflag=max(totalvisitflag)

*******************************************************************************
* SDP DATA CHECKS: GPS FLAG, BY RE
*******************************************************************************

* Total number of submissions with GPS accuracy > 6 meters or missing, by RE
bysort RE: egen totalgpsflag=total(gpsflag)
drop gpsflag
bysort RE: egen gpsflag=max(totalgpsflag)

*******************************************************************************
* SDP DATA CHECKS: YEAR OPENED FLAG, BY RE
*******************************************************************************

* Total number of submissions with unkown year facility opened, by RE
bysort RE: egen totalyearopenflag=total(yearopenflag)
drop yearopenflag
bysort RE: egen yearopenflag=max(totalyearopenflag)

*******************************************************************************
* SDP DATA CHECKS: UNKNOWN CATCHMENT POPULATION FLAG, BY RE
*******************************************************************************

* Total number of submissions with unknown or no catchment area, by RE
bysort RE: egen totalcatchmentflag=total(catchmentflag)
drop catchmentflag
bysort RE: egen catchmentflag=max(totalcatchmentflag)

*******************************************************************************
* SDP DATA CHECKS: EXPORT SUMMARY FLAG DATA, BY RE
*******************************************************************************

* Create summary by RE
duplicates drop RE, force
order RE EA submissions noconsentflag timeflag visitflag gpsflag yearopenflag catchmentflag

* Export summary flag data to .xls file
export excel RE EA submissions noconsentflag timeflag visitflag gpsflag yearopenflag catchmentflag using `CCRX'_SDP_Checks_$date.xls, firstrow(varl) sh(Flag_Summary) sheetreplace 

restore

*******************************************************************************
* SDP DATA CHECKS: EXPORT FLAGGED OBSERVATIONS TO .XLS SHEET BY FLAG TYPE
*******************************************************************************
sort RE EA

* Export flagged survey time (less than 20 minutes) to .xls sheet
order RE EA facility_name managing_authority facility_type fp_offered startSIF endSIF survey_time_min SDP_result 
capture export excel RE EA facility_name managing_authority facility_type fp_offered startSIF endSIF survey_time_min SDP_result using `CCRX'_SDP_Checks_$date.xls if timeflag==1, firstrow(varl) sh(FlaggedTime_Data) sheetreplace 

* Export flagged GPS accuracy data to .xls sheet 
order RE EA facility_name managing_authority facility_type locationaccuracy SDP_result 
capture export excel RE EA facility_name managing_authority facility_type locationaccuracy SDP_result using `CCRX'_SDP_Checks_$date.xls if gpsflag==1, firstrow(varl) sh(FlaggedGPS_Data) sheetreplace 

* Export flagged year open data to .xls sheet
order RE EA facility_name managing_authority facility_type year_open_rw  
capture export excel RE EA facility_name managing_authority facility_type year_open_rw using `CCRX'_SDP_Checks_$date.xls if yearopenflag==1, firstrow(varl) sh(FlaggedYearOpen_Data) sheetreplace 

* Export flagged no catchment area data to .xls sheet
order RE EA facility_name managing_authority facility_type knows_population_served 
capture export excel RE EA facility_name managing_authority facility_type knows_population_served using `CCRX'_SDP_Checks_$date.xls if catchmentflag==1, firstrow(varl) sh(FlaggedCatchment_Data) sheetreplace 

*******************************************************************************
* SDP DATA CHECKS: EXPORT OBSERVATIONS WITH POTENTIAL NUMERIC TYPOS TO .XLS SHEET
*******************************************************************************
*Identify if there are any SDP integer variables with a value of 77, 88, or 99 indicating a potential mistype on the part of the RE or in the Cleaning file
preserve
sort RE EA

**Checking if numeric variables have the values
gen mistype=0
gen mistype_var=""
foreach var of varlist _all{
	capture confirm numeric var `var'
	if _rc==0 {
		replace mistype=mistype+1 if (`var'==77 | `var'==88 | `var'==99) 
		replace mistype_var=mistype_var+" "+"`var'" if `var'==77 | `var'==88 | `var'==99
	}
}

*Exclude entries for facility number
recode mistype 0=.
replace mistype_var=strtrim(mistype_var)
replace mistype=. if mistype_var=="facility_number"
replace mistype_var="" if mistype_var=="facility_number"

*Keep all variables that have been mistyped
levelsof mistype_var, local(typo) clean
keep if mistype!=. 
keep metainstanceID RE EA `typo'
capture drop facility_number
order metainstanceID RE EA, first

capture noisily export excel using `CCRX'_SDP_Checks_$date.xls, firstrow(variables) sh(Potential_Typos) sheetreplace
	if _rc!=198 {
		restore
	}
	else {
		clear 
		set obs 1
		gen x="NO NUMERIC VARIABLES WITH A VALUE OF 77, 88, OR 99"
		export excel using `CCRX'_SDP_Checks_$date.xls, firstrow(variables) sh(Potential_Typos) sheetreplace
		restore
		}

*******************************************************************************
* SDP DATA CHECKS: EXPORT PUBLIC FACILITIES SUBMITTED BY COUNTY/RE/EA TO .XLS SHEET
*******************************************************************************

* Sort public facilities to match public listing Excel file
sort RE EA facility_type facility_name 

* Export
capture export excel RE EA facility_type facility_name if managing_authority==1 using `CCRX'_SDP_Checks_$date.xls, firstrow(varl) sh(PublicFacilities_Submitted) sheetreplace 

*******************************************************************************
* SDP DATA CHECKS: EXPORT PRIVATE FACILITIES SUBMITTED BY RE/EA TO .XLS SHEET
*******************************************************************************

* Export 
export excel RE EA facility_name if managing_authority!=1 using `CCRX'_SDP_Checks_$date.xls, firstrow(varl) sh(PrivateFacilities_Submitted) sheetreplace 

*******************************************************************************
* READ IN MODULES
*******************************************************************************
*run "$dofiledir/`phcdofile'"

*******************************************************************************
* SAVE, CLOSE LOG AND EXIT
*******************************************************************************

save "$datadir/`CCRX'_SDP_Clean_Data_with_checks_$date.dta", replace
capture log close


