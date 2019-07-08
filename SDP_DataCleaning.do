clear
clear matrix
clear mata
capture log close
set maxvar 15000
set more off
numlabel, add

*******************************************************************************
*
*  FILENAME:	CCRX_SDP_DataCleaning.do
*  PURPOSE:		PMA2020 SDP data cleaning, labeling, and encoding
*  CREATED:		14 April 2015 by Suzanne Bell
*  DATA IN:		CCRX_Service_Delivery_Point_v#.csv 
*  DATA OUT:	CCRX_SDP_$date_100Prelim.dta"
* 
*******************************************************************************

*******************************************************************************
* INSTRUCTIONS
*******************************************************************************
*
* 1. Update the macros in Section 1 by country and round, modeling the example 
*	 provided (before data collection)
* 2. Update the country-specific code in Section 2 (before data collection)
* 3. Clean facility names in Section 7
* 4. Apply random ID number from pre-specified country range to facility name in
*	 Section 8
* 5. Apply random ID number from pre-specified country range to EA name in 
*	 Section 9
* 6. Clean RE names and apply random ID number from pre-specified country range 
*	 to RE names in Section 10
* 7. Update any country-specific variables to be dropped in Section 11
* 8. When ready to generate dataset for public release, comment out Section 12,
* 	 un-comment out Section 13 and add any country-specific identifying variables
*	 to the list of variables to be dropped in Section 13
* 9. Un-comment out Section 14 to merge in EA weights
*10. Un-comment out Section 15 and save data set for public release
*11. Un-comment out Section 16 and test merge to ensure all SDPs are
*	 in an EA with at least one household
*
*******************************************************************************
* 1. SET MACROS: UPDATE THIS SECTION FOR EACH COUNTRY/ROUND
*******************************************************************************

* Set macros for country and round
cd "$datadir"

local country "$country"
local round "$round"
local CCRX "$CCRX"
local csv1 "$csv1"
local csv2 "$csv2"


* Update list of all methods offered/counseled on ("methods"), all methods provided/prescribed ("methods_short") and all physical methods ("methods_stock")
local methods "fster mster impl iud inj pill ec mc fc mod beads lam rhyth withd"
local methods_short "fster mster impl iud inj pill ec mc fc beads"


* Update list of all methods counseled on ("methods_full") and provided/referred ("methods_short_full")	
* but use full method name, not abbreviation from ODK
local methods_full "female_ster male_ster implants iud injectables pills ec male_condoms female_condoms mod beads lam rhythm withdrawal"
local methods_short_full "female_ster male_ster implants iud injectables pills ec male_condoms female_condoms beads"


* Update list of physical methods, but use full method name, not abbreviation (cross-check with ODK stockout variable names [stock_* stockout_days_* and stockout_3mo_*])
local methods_stock_full "implants iud injectables injectables_sp injectables_dp pills male_condoms female_condoms ec beads diaphragm foam"

* Last method offered/counseled, i.e. last method listed in "methods" macro above
local lastmethodoffered "withd"

* Last method provided/prescribed/charged, i.e. last method listed in "methods_short" above
local lastmethodprovided "beads"


* Set local/global macros for current date
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)
local todaystata=clock("`today'", "DMY")

* Create log
log using "`CCRX'_SDP_DataCleaning_$date.log", replace


* Append .csv files if more than one version of the form was used in data collection
	* Read in latest version of the .csv file (largest .csv file)
	insheet using "$csvfilesdir/`csv1'.csv", names clear
	save "`csv1'.dta", replace

	* Read in earlier version of the .csv file (smaller .csv file)
	capture insheet using "$csvfilesdir/`csv2'.csv", names clear
	if _rc==0 {

	* Append and check if any information was lost in "forcing" the append
	* If not information in some variables (i.e. all missing) data will be stored as byte; 
	* this will be overwritten as string if stored as string in larger .csv file with responses
	append using "`csv1'.dta", force
	}
	
	* Otherwise just use csv1
	else {
	use "`csv1'.dta", clear
	}

* Drop duplicate submissions
duplicates drop metainstanceid, force

*******************************************************************************
* 2. GENERATE, RENAME, AND LABEL VARIABLES COUNTRY SPECIFIC VARIABLES: UPDATE BY COUNTRY
*******************************************************************************

* Location
* UPDATE BY COUNTRY


* Facility type
* UPDATE BY COUNTRY

label define facility 1 national_hospital 2 teaching_hospital 3 regional_hospital 4 surgery_center 5 health_center ///
	6 clinic_private 7 health_center_private 8 bulk_pharmacy 9 pharmacy 10 pharm_shop 11 other  
encode facility_type, gen(facility_typev2) lab(facility)


* Survey language 
* UPDATE BY COUNTRY
label define language_list 1 english 2 french 3 moore 4 gourmantchema 5 fulfulde 6 dioula 96 other  
encode survey_language, gen(survey_languagev2) lab(language_list)


* UPDATE BY COUNTRY
capture rename ea EA

* Mobile Outreach 
* CHECK ODK FORM AND UPDATE BY COUNTRY
*	Some countries will be mobile outreach 6 months and some will be 12 months
*	generate the mobile outreach variable specific to your country (confirm with ODK)
*	and cancel out the code for the other one--do NOT create both variables
/*
rename mobile_outreach mobile_outreach_6mo
rename service_stats service_stats_6mo
rename service_charts service_charts_6mo
*/
*label variable mobile_outreach_6mo "Number of times in past 6 months visited by mobile outreach"
*label variable service_stats_6mo "Meetings in past 6 months to discuss services statistics"
*label variable service_charts_6mo "Service charts from service data in past 6 months"

capture rename mobile_outreach mobile_outreach_12mo
capture rename service_stats service_stats_12mo
capture rename service_charts service_charts_12mo
label variable mobile_outreach_12mo "Number of times in past 12 months visited by mobile outreach"
label variable service_stats_12mo "Meetings in past 12 months to discuss services statistics"
label variable service_charts_12mo "Service charts from service data in past 12 months"

* Rename staff variables
* UPDATE BY COUNTRY
rename staff_other_tot other_tot

* Label staff variables
* UPDATE BY COUNTRY
label variable doctor_tot "Total number of doctors"
label variable clinic_director_tot "Total number of clinic directors"
label variable nurse_tot "Total number of nurses"
label variable midwife_tot "Total number of midwives"
*label variable ma_tot "Total number of MAs"
label variable ba_tot "Total number of birth attendants/aids"
label variable fieldworker_tot "Total number of fieldworkers"
*label variable auxiliary_tot "Total number of medical assistants"
*label variable param_officer_tot "Total number of paramedics officer"
*label variable clinic_officer_tot "Total number of clinic officers"
*label variable distrib_tot "Total number of distributors"
label variable tech_tot "Total number of technicians"
label variable pharmacist_tot "Total number of pharmacists"
label variable pharm_owner_tot "Total number of pharmaceutical store owners"
*label variable pharm_tech_tot "Total number of pharm techs"
label variable other_tot "Total number of other medical staff"


*******************************************************************************
* 3. RENAME GENERIC VARIABLES
*******************************************************************************

* Fees Charged Group Variables 
rename fpf_grpfster_fees fees_female_ster
rename fpf_grpmster_fees fees_male_ster
rename fpf_grpimpl_fees fees_implants
rename fpf_grpiud_fees fees_iud
capture rename fpf_grpinj_fees fees_injectables
capture rename fpf_grpinj3m_fees fees_injectables_3mo
capture rename fpf_grpinj1m_fees fees_injectables_1mo
capture rename fpf_grpinjsp_fees fees_injectables_sp
capture rename fpf_grpinjdp_fees fees_injectables_dp
rename fpf_grppill_fees fees_pills
rename fpf_grpec_fees fees_ec
capture rename fpf_grpntab_fees fees_ntablet
rename fpf_grpmc_fees fees_male_condoms
rename fpf_grpfc_fees fees_female_condoms
capture rename fpf_grpdia_fees fees_diaphragm
capture rename fpf_grpfoam_fees fees_foam
capture rename fpf_grpbeads_fees fees_beads
capture rename fpf_grpother_fees fees_other 

* Family Planning Register - total and new clients 
capture rename reg_fster_grpfster_tot visits_female_ster
rename reg_mster_grpmster_tot visits_male_ster
rename reg_impl_grpimpl_tot visits_implants_total
rename reg_impl_grpimpl_new visits_implants_new
rename reg_iud_grpiud_tot visits_iud_total
rename reg_iud_grpiud_new visits_iud_new
capture rename reg_inj_grpinj_tot visits_injectables_total
capture rename reg_inj_grpinj_new visits_injectables_new
capture rename reg_inj3m_grpinj3m_tot visits_injectables_3mo_total
capture rename reg_inj3m_grpinj3m_new visits_injectables_3mo_new
capture rename reg_inj1m_grpinj1m_tot visits_injectables_1mo_total
capture rename reg_inj1m_grpinj1m_new visits_injectables_1mo_new
capture rename reg_injsp_grpinjsp_tot visits_injectables_sp_total
capture rename reg_injsp_grpinjsp_new visits_injectables_sp_new
capture rename reg_injdp_grpinjdp_tot visits_injectables_dp_total
capture rename reg_injdp_grpinjdp_new visits_injectables_dp_new
rename reg_pill_grppill_tot visits_pills_total
rename reg_pill_grppill_new visits_pills_new
rename reg_ec_grpec_tot visits_ec_total
rename reg_ec_grpec_new visits_ec_new
capture rename reg_ec_grpntab_tot visits_ntablet_total
capture rename reg_ec_grpntab_new visits_ntablet_new
rename reg_mc_grpmc_tot visits_male_condoms_total
rename reg_mc_grpmc_new visits_male_condoms_new
rename reg_fc_grpfc_tot visits_female_condoms_total
rename reg_fc_grpfc_new visits_female_condoms_new
capture rename reg_dia_grpdia_tot visits_diaphragm_total
capture rename reg_dia_grpdia_new visits_diaphragm_new
capture rename reg_foam_grpfoam_tot visits_foam_total
capture rename reg_foam_grpfoam_new visits_foam_new
capture rename reg_beads_grpbeads_tot visits_beads_total
capture rename reg_beads_grpbeads_new visits_beads_new
capture rename reg_other_grpother_tot visits_other_total
capture rename reg_other_grpother_new visits_other_new

* Family Planning Record Book - # of products sold
rename reg_sold_grpimpl_units sold_implants
rename reg_sold_grpiud_units sold_iud
capture rename reg_sold_grpinj_units sold_injectables
capture rename reg_sold_grpinj3m_units sold_injectables_3mo
capture rename reg_sold_grpinj1m_units sold_injectables_1mo
capture rename reg_sold_grpinjsp_units sold_injectables_sp
rename reg_sold_grppill_units sold_pills
rename reg_sold_grpec_units sold_ec
capture rename reg_sold_grpntab_units sold_ntabet
rename reg_sold_grpmc_units sold_male_condoms
rename reg_sold_grpfc_units sold_female_condoms
capture rename reg_sold_grpdia_units sold_diaphragm
capture rename reg_sold_grpfoam_units sold_foam
capture rename reg_sold_grpbeads_units sold_beads
capture rename reg_sold_grpother_units sold_other

* FP Examination Rooms 
rename exr_grpexr_piped exam_room_piped_water
rename exr_grpexr_pour exam_room_other_running_water
rename exr_grpexr_bucket exam_room_bucket_water
rename exr_grpexr_soap exam_room_soap
rename exr_grpexr_towels exam_room_towels
rename exr_grpexr_bin exam_room_wastebin
rename exr_grpexr_sharps exam_room_sharps
rename exr_grpexr_gloves exam_room_latex_gloves
rename exr_grpexr_disinf exam_room_disinfectant
rename exr_grpexr_needles exam_room_needles
rename exr_grpexr_aud_priv exam_room_auditory_privacy
rename exr_grpexr_vis_priv exam_room_visual_privacy
rename exr_grpexr_tables exam_room_tables
rename exr_grpexr_fp_edu exam_room_ed_materials

* FP Storage
rename storage_grpprotected_floor protected_floor
rename storage_grpprotected_water protected_water
rename storage_grpprotected_sun protected_sun
rename storage_grpprotected_pests protected_pests

* HIV Consulation  //SJ:hiv and sti are capitalized in KER5
capture rename HIV_info_elsewhere hiv_info_elsewhere
capture rename HIV_referred_where hiv_referred_where
capture rename HIV_services hiv_services
capture rename STI_services sti_services
capture rename HIV_condom hiv_condom
capture rename HIV_other_fp hiv_other_fp

* Other
rename metainstanceid metainstanceID
rename submissiondate SubmissionDate
rename antenatal maternalservices
rename sdp_result SDP_result
rename date_groupsystem_date system_date
capture rename fp_health_volunteers fp_community_health_volunteers
capture rename community_health_volunteers community_health_workers
capture rename num_health_volunteers num_health_workers

*******************************************************************************
* 4. RECODE/CLEAN VARIABLES
*******************************************************************************

* Country/round identifying variables
gen country = "`country'"
gen round = "`round'" 
label var country "PMA2020 country" 
label var round "PMA2020 round"  
order country-round, first 

* Create label for yes/no variables
label define yes_no_dnk_nr_list -77 "-77" -88 "-88" -99 "-99" 0 "no" 1 "yes"

* RE name
capture replace your_name=name_typed if your_name==""
rename your_name RE
label variable RE "RE"

* Managing Authority
label define managing_list 1 government 2 NGO 3 faith_based 4 private 5 other
encode managing_authority, gen(managing_authorityv2) lab(managing_list)
label define managing_list 1 "Government" 2 "NGO" 3 "Faith-based Organization" 4 "Private" 5 "Other", replace

* Position
label define positions_list 1 "Owner" 2 "In-Charge/Manager" 3 "Staff"
label values position positions_list

* Generate all date/dateTime varibles in STATA internal form (SIF)
* DateTime: generate SIF variables
foreach x of varlist start end SubmissionDate system_date {
capture confirm variable `x'
if _rc==0 {	
	gen double `x'SIF=clock(`x', "MDYhms")
	format `x'SIF %tc
	} 
}

* Today
gen double todaySIF=clock(today, "YMD")
format todaySIF %tc

* Begin working, open year, fp begin: generate SIF variables
foreach x of varlist year_open_rw fp_begin_rw work_begin {
capture confirm variable `x'
if _rc==0 {
	gen double `x'SIF=clock(`x', "MDY")
	format `x'SIF %tc
	}
}

* Order new *SIF variables to be next to string counterpart
unab vars: *SIF
local stubs: subinstr local vars "SIF" "", all
foreach var in `stubs'{
order `var'SIF, after(`var')
}

foreach x of varlist year_open_rw fp_begin_rw work_begin_rw {
capture drop `x'_yr
gen `x'_yr = year(dofc(`x'SIF))
order `x'_yr, after(`x')
drop `x' `x'SIF
rename `x'_yr `x'
replace `x'=-88 if `x'==2020
}

* Times visited
label define visits_list 1 "1st visit" 2 "2nd visit" 3 "3rd visit"
label values times_visited visits_list
	
* Catchment area
label define catchment_list 1 no_catchment 2 yes_knows_size -88 "-88" -99 "-99"
capture encode knows_population_served, gen (knows_population_servedv2) lab(catchment_list)
label define catchment_list -88 "Doesn't know size of catchment area" ///
-99 "No response" 1 "No catchment area" 2 "Yes, knows size of catchment area", replace

* Supervisor visit
label define supervisor_list 0 never 1 past_6mo 2 6mo_plus -88 "-88" -99 "-99"
capture encode supervisor_visit, gen(supervisor_visitv2) lab(supervisor_list)
label define supervisor_list -88 "Don't know" -99 "No response" ///
0 "Never external supervision" 1 "Within the past 6 months" 2 "More than 6 months ago", replace

* Handwashing stations observation //SJ: option wording has changed in KER5
capture rename handwashing_observations handwashing_observations_staff
capture tostring handwashing_observations_staff, replace
gen soap_present=regexm(handwashing_observations_staff, "soap") if handwashing_observations_staff~=""
gen stored_water_present=regexm(handwashing_observations_staff, "stored_water") if handwashing_observations_staff~=""
gen running_water_present=regexm(handwashing_observations_staff, "tap_water") if handwashing_observations_staff~=""
gen near_sanitation=regexm(handwashing_observations_staff, "near_sanitation") if handwashing_observations_staff~=""
order soap_present-near_sanitation, after(handwashing_observations_staff)

* CHV methods offered
capture tostring methods_offered, replace
gen chv_condoms=regexm(methods_offered, "male_condoms") if methods_offered~=""
gen chv_pills=regexm(methods_offered, "pill") if methods_offered~=""
gen chv_injectables=regexm(methods_offered, "injectables") if methods_offered~=""
order chv_condoms-chv_injectables, after(methods_offered)

* Mobile outreach
foreach var in mobile_outreach_6mo mobile_outreach_12mo {
capture confirm variable `var'
if _rc==0 {
     gen any_`var'=.
     replace any_`var'=0 if `var'==0
     replace any_`var'=1 if `var'>0 & `var'!=. & `var'!=-88 & `var'!=-99
     label val any_`var' yes_no_dnk_nr_list 
	 order any_`var', after(`var')
	 }
	 }

* Implant Supplies 
capture tostring implant_supplies, replace
gen implant_gloves=regexm(implant_supplies, "clean-gloves") if implant_supplies~=""
gen implant_antiseptic=regexm(implant_supplies, "antiseptic") if implant_supplies~=""
gen implant_sterile_gauze=regexm(implant_supplies, "sterile-gauze-pad-or-cotton-wool") if implant_supplies~=""
gen implant_anesthetic=regexm(implant_supplies, "local-anesthetic") if implant_supplies~=""
gen implant_sealed_pack=regexm(implant_supplies, "sealed-implant-pack") if implant_supplies~=""
gen implant_blade=regexm(implant_supplies, "blade") if implant_supplies~=""
order implant_gloves-implant_blade, after(implant_supplies)

* IUD Supplies 
capture tostring iud_supplies, replace
gen iud_forceps=regexm(iud_supplies, "sponge-holding-forceps") if iud_supplies~=""
gen iud_speculums=regexm(iud_supplies, "speculums") if iud_supplies~=""
gen iud_tenaculum=regexm(iud_supplies, "tenaculum") if iud_supplies~=""
gen iud_uterinesound=regexm(iud_supplies, "uterine_sound") if iud_supplies~=""
order iud_forceps-iud_uterinesound, after(iud_supplies)

* See service charts
capture tostring service_charts_12mo, replace
gen service_charts_wall=regexm(service_charts_12mo, "wall") if service_charts_12mo~=""
gen service_charts_written=regexm(service_charts_12mo, "written") if service_charts_12mo~=""
gen service_charts_reviews=regexm(service_charts_12mo, "reviews") if service_charts_12mo~=""
gen service_charts_other=regexm(service_charts_12mo, "other") if service_charts_12mo~=""
order service_charts_wall-service_charts_other, after(service_charts_12mo)

* Maternal Health Services
capture tostring maternalservices, replace
gen antenatal=regexm(maternalservices, "antenatal") if maternalservices~=""
gen delivery=regexm(maternalservices, "delivery") if maternalservices~=""
gen postnatal=regexm(maternalservices, "postnatal") if maternalservices~=""
gen post_abortion=regexm(maternalservices, "postabortion") if maternalservices~=""
order antenatal-post_abortion, after(maternalservices)

* Postpartum services 
capture tostring postpartum_rw, replace
gen postpartum_fertility=regexm(postpartum_rw, "fertility") if postpartum_rw~=""
gen postpartum_space=regexm(postpartum_rw, "space") if postpartum_rw~=""
gen postpartum_breastfeed=regexm(postpartum_rw, "breastfeed") if postpartum_rw~="" 
gen postpartum_fp_bf=regexm(postpartum_rw, "fp_bf") if postpartum_rw~=""
gen postpartum_LAM=regexm(postpartum_rw, "LAM") if postpartum_rw~=""
gen postpartum_long_acting_fp=regexm(postpartum_rw, "long_acting") if postpartum_rw~=""
order postpartum_fertility-postpartum_long_acting, after(postpartum_rw)

* Post-abortion services
capture tostring postabortion_discussion, replace
gen postabortion_mental=regexm(postabortion_discussion, "mental") if postabortion_discussion~=""
gen postabortion_fertility=regexm(postabortion_discussion, "fertility") if postabortion_discussion~=""
gen postabortion_healthy_spacing=regexm(postabortion_discussion, "healthy_spacing") if postabortion_discussion~=""
gen postabortion_long_acting_fp=regexm(postabortion_discussion, "long_acting") if postabortion_discussion~=""
gen postabortion_spacing=regexm(postabortion_discussion, "FP_methods_spacing") if postabortion_discussion~=""
order postabortion_mental-postabortion_spacing, after(postabortion_discussion)

* Adolescent FP Services
gen adolescents_counseled=regexm(adolescents, "counseled") if adolescents~=""
gen adolescents_provided=regexm(adolescents, "provided") if adolescents~=""
gen adolescents_prescribed=regexm(adolescents, "prescribed") if adolescents~=""
order adolescents_counseled-adolescents_prescribed, after(adolescents)

* HIV FP service integration  //SJ: can't find hiv_fp in KER5
capture gen hiv_fp_counseled=regexm(hiv_fp, "counseled") if hiv_fp~=""
capture gen hiv_fp_provided=regexm(hiv_fp, "provided") if hiv_fp~=""
capture gen hiv_fp_prescribed=regexm(hiv_fp, "prescribed") if hiv_fp~=""
capture order hiv_fp_counseled-hiv_fp_prescribed, after(hiv_fp)

* HIV client services
label define hiv_referred_where_list 1 "Within facility only" 2 "Outside facility only" 3 "Both" -88 "-88" -99 "-99"
capture encode hiv_referred_where, gen(hiv_referred_wherev2) lab(hiv_referred_where_list)

* FP Exam Room
capture label define ORUNA_list 1 observed 2 reported_unseen -77 "-77"
foreach item in piped_water other_running_water bucket_water soap towels wastebin sharps	///
latex_gloves disinfectant needles auditory_privacy tables visual_privacy ed_materials {
capture encode exam_room_`item', gen(exam_room_`item'v2) lab (ORUNA_list)
}
label define ORUNA_list -77 "NA" 1 "O (observed)" 2 "RU (reported unseen)", replace

* SDP Result
label define SDP_result_list 1 completed 2 not_at_facility 3 postponed 4 refused 5 partly_completed 6 other
encode SDP_result, gen(SDP_resultv2) lab(SDP_result_list)
label define SDP_result_list 1 "Completed" 2 "Not at facility" ///
3 "Postponed" 4 "Refused" 5 "Partly completed" 6 "Other", replace

* Contraception Supplies Storage  
foreach var in protected_floor protected_water protected_sun protected_pests{
encode `var', gen(`var'v2) lab(yes_no_dnk_nr_list)
}  

*******************************************************************************
* 5. GENERATE FP METHOD VARIABLES
*******************************************************************************

* FP Methods: Counseled 
foreach method in `methods' {
capture confirm `method'
if _rc==0{
gen counseled_`method'=regexm(fp_counseled, "`method'") if fp_counseled~=""
label values counseled_`method' yes_no_dnk_nr_list
}
}
capture order counseled_fster-counseled_`lastmethodoffered', after(adolescents)

* FP Methods: Provided
foreach method in `methods_short' {
capture confirm `method'
if _rc!=0{
gen provided_`method'=regexm(fp_provided, "`method'") if fp_provided~=""
label values provided_`method' yes_no_dnk_nr_list
}
}
capture order provided_fster-provided_`lastmethodprovided', after(counseled_`lastmethodoffered')

* FP methods: charged 
foreach method in `methods_short' {
capture confirm `method'
if _rc!=0{
rename fpc_grp`method'_charged charged_`method'
capture encode charged_`method', gen(charged_`method'v2) lab(yes_no_dnk_nr_list)
}
}
capture order charged_fster-charged_`lastmethodprovided', after(provided_`lastmethodprovided')

capture order referred_fster-referred_`lastmethodprovided', after(charged_`lastmethodprovided') 

* Stockouts today
label define stock_list 1 instock_obs 2 instock_unobs 3 outstock -99 "-99"
foreach method in `methods_stock_full' {
capture encode stock_`method', gen(stock_`method'v2) lab (stock_list)
}
label define stock_list 1 "In-stock and observed" ///
2 "In-stock but not observed" 3 "Out of stock" -99 "No response", replace

* Stockouts in last 3 months
foreach method in `methods_stock_full' {
capture encode stockout_3mo_`method', gen(stockout_3mo_`method'v2) lab(yes_no_dnk_nr_list)
}

* Rename counseled_*, provided_*, referred_*, and charged_* variables to be consistent with earlier rounds
foreach var in counseled provided referred charged {
capture rename `var'_fster `var'_female_ster
capture rename `var'_fsterv2 `var'_female_sterv2
capture rename `var'_mster `var'_male_ster
capture rename `var'_msterv2 `var'_male_sterv2
capture rename `var'_impl `var'_implants
capture rename `var'_implv2 `var'_implantsv2
capture rename `var'_inj `var'_injectables
capture rename `var'_injv2 `var'_injectablesv2
capture rename `var'_inj3m `var'_injectables_3mo
capture rename `var'_inj3mv2 `var'_injectables_3mov2
capture rename `var'_inj1m `var'_injectables_1mo
capture rename `var'_inj1mv2 `var'_injectables_1mov2
capture rename `var'_injsp `var'_injectables_sp
capture rename `var'_injspv2 `var'_injectables_spv2
capture rename `var'_injdp `var'_injectables_dp
capture rename `var'_injdpv2 `var'_injectables_dpv2
capture rename `var'_ntab `var'_ntablet
capture rename `var'_ntabv2 `var'_ntabletv2
capture rename `var'_pill `var'_pills
capture rename `var'_pillv2 `var'_pillsv2
capture rename `var'_mc `var'_male_condoms
capture rename `var'_mcv2 `var'_male_condomsv2
capture rename `var'_fc `var'_female_condoms
capture rename `var'_fcv2 `var'_female_condomsv2
capture rename `var'_dia `var'_diaphragm
capture rename `var'_diav2 `var'_diaphragmv2
capture rename `var'_rhyth `var'_rhythm
capture rename `var'_rhythv2 `var'_rhythmv2
capture rename `var'_withd `var'_withdrawal
capture rename `var'_withdv2 `var'_withdrawalv2

}

*******************************************************************************
* 6. LABEL VARIABLES
*******************************************************************************

* Encode and label Yes/No variables 
foreach var in available begin_interview present_24hr elec_cur elec_rec water_cur water_rec fp_offered	///
fp_today fp_community_health_volunteers fees_rw opinions_reported implant_insert implant_remove  ///
iud_insert iud_remove fp_during_postpartum fp_during_postabortion hiv_services sti_services	hiv_condom	///
hiv_other_fp hiv_info_elsewhere {
capture encode `var', gen(`var'v2) lab(yes_no_dnk_nr_list)
} 

foreach var in previously_participated service_stats_6mo service_stats_12mo {
capture confirm var `var'
if _rc==0 {
encode `var', gen(`var'v2) lab(yes_no_dnk_nr_list)
order `var'v2, after (`var')
drop `var'
rename `var'v2 `var'
} 
}

* Label Yes/No variables 
foreach var in  advanced_facility chv_condoms chv_pills chv_injectable ///
implant_gloves-implant_blade iud_forceps-iud_uterinesound antenatal-post_abortion	///
postpartum_fertility-postpartum_long_acting postabortion_mental-postabortion_spacing	///
adolescents_counseled-adolescents_prescribed consent_obtained soap_present	///
stored_water_present running_water_present near_sanitation {
label values `var' yes_no_dnk_nr_list
}

* Order and rename generated variables
foreach var in facility_type supervisor_visit	///
available begin_interview elec_cur elec_rec water_cur water_rec	///
fp_offered hiv_services SDP_result	///
fees_rw protected_floor protected_water protected_sun	///
protected_pests fp_community_health_volunteers managing_authority survey_language {
order `var'v2, after (`var')
drop `var'
rename `var'v2 `var' 
}

* Order generated charge variables
capture rename charged_ntabv2 charged_n_tabletv2
foreach var in `methods_short_full' {
capture order charged_`var'v2, after(charged_`var')
capture drop charged_`var'
capture rename charged_`var'v2 charged_`var' 
}

* Order generated referral variables
foreach var in `methods_short_full' {
capture order referred_`var'v2, after(referred_`var')
capture drop referred_`var'
capture rename referred_`var'v2 referred_`var' 
}

* Order generated stock variables
foreach var in `methods_stock_full' {
capture order stock_`var'v2, after (stock_`var')
capture drop stock_`var'
capture rename stock_`var'v2 stock_`var' 
}

* Order generated stockout variables
foreach var in `methods_stock_full' {
capture order stockout_3mo_`var'v2, after (stockout_3mo_`var')
capture drop stockout_3mo_`var'
capture rename stockout_3mo_`var'v2 stockout_3mo_`var' 
}


unab vars: *v2
local stubs: subinstr local vars "v2" "", all
foreach var in `stubs'{
rename `var' `var'QZ
order `var'v2, after (`var'QZ)
}

rename *v2 *

drop *QZ


* Label method related FP variables
foreach method in `methods_full'{
capture label variable counseled_`method' "Counsel on `method'" 
}

foreach method in `methods_short_full' {
capture label variable provided_`method' "Provide `method'"
capture label variable referred_`method' "Refer for `method'"  
capture label variable charged_`method' "Charge for `method'" 
capture label variable fees_`method' "Fees for `method'"
capture label variable ref_`method' "Refer `method'"
}

foreach method in `methods_stock_full' {
capture label variable sold_`method' "Number of `method' sold in last month"
}

label variable visits_female_ster "Number of female sterilization visits in last month"
label variable visits_male_ster "Number of male sterilization visits in last month"
foreach method in `methods_stock_full' {
capture label variable visits_`method'_new "Number of new `method' visits in last month" 
capture label variable visits_`method'_total "Number of total `method' visits in last month" 
capture label variable stock_`method' "Observed and in/out stock: `method'"
capture label variable stockout_days_`method' "Number of days have been stocked out of `method'" 
capture label variable stockout_3mo_`method' "Whether has been out of stock in last 3 months: `method'" 
}

* Label other non-country specific variables
label variable times_visited "Number of times visited facility"
capture label variable fp_begin_rw "Year began providing FP"
label variable startSIF "SDP interview start time (SIF)"
label variable start "SDP interview start time (string)"
label variable endSIF "SDP interview end time (SIF)"
label variable end "SDP interview end time (string)"
label variable SubmissionDateSIF "Date and time of SDP submission (SIF)"
label variable SubmissionDate "Date and time of SDP submission (string)"
label variable system_date "Current date & time (string)"
label variable system_dateSIF "Current date & time (SIF)"
label variable today "Date of interview (string)"
label variable todaySIF "Date of interview (SIF)"
label variable EA "EA number"
label variable facility_type "Type of facility"
label variable advanced_facility "Advanced facility"
label variable managing_authority "Managing authority"
label variable available "Competent respondent available for interview"
label variable consent_obtained "Consent obtained from interviewee"
label variable position "Interviewee position at facility"
label variable days_open "Number of days per week facility is open"
label variable knows_population_served "Know size of catchment area"
label variable population_served "Size of catchment population"
label variable beds "Number of beds"
label variable supervisor_visit "Recent supervisor visit"
label variable elec_cur "Facility has electricity at this time"
label variable elec_rec "Facility has electricity but out for two or more hours today"
label variable water_cur "Facility has water at this time"
label variable water_rec "Facility has water but out for two or more hours today"
label variable handwashing_stations "Number of handwashing facilities"
label variable handwashing_observations_staff "Hand washing facility observations used by staff"
label variable soap_present "Soap present at handwashing station"
label variable stored_water_present "Stored water present at handwashing station"
label variable running_water_present "Running water present at handwashing station"
label variable near_sanitation "Handwashing area is near a sanitation facility"
label variable fp_offered "Facility usually offers FP"
label variable fp_counseled "Methods for which providers at this facility counsel women about characteristics, benefits, and side effects"
label variable fp_provided "Which of the following methods are provided to clients at this facility?"
label variable fp_community_health_volunteers "Facility provides family planning supervision, support, or supplies to CHVs"
label variable num_fp_volunteers "Number of family planning CHVs supported by facility"
label variable methods_offered "CHVs provide FP methods"
label variable chv_condoms "Community Health Volunteers offer male condoms" 
label variable chv_pills "Community Health Volunteers offer pills"
label variable chv_injectables "Community Health Volunteers offer injectables"
label variable fees_rw "Facility has routine FP fees"
label variable service_charts_wall "Observed wall chart/graph produced using service data from last 12 months"
label variable service_charts_written "Observed written report/minutes produced using service data from last 12 months"
label variable service_charts_reviews "Observed other means of reviewing service data from last 12 months"
label variable service_charts_other "Observed other use of data from last 12 months"
capture label variable stats_analyzed "Items facility uses to review service data"
label variable implant_insert "Personnel able to insert implant"
label variable implant_remove "Personnel able to remove implant"
label variable iud_insert "Personnel able to insert IUD"
label variable iud_remove "Personnel able to remove IUD"
label variable implant_supplies "Facility has implant supplies"
label variable implant_gloves "Implant supplies: clean gloves"
label variable implant_antiseptic "Implant supplies: antiseptic"
label variable implant_sterile_gauze "Implant supplies: sterile gauze"
label variable implant_anesthetic "Implant supplies: anesthetic"
label variable implant_sealed_pack "Implant supplies: sealed implant pack"
label variable implant_blade "Implant supplies: blade"
label variable iud_supplies "Facility has IUD supplies"
label variable iud_forceps "Have forceps for IUD insertion/removal"
label variable iud_speculums "Have speculums for IUD insertion/removal"
label variable iud_tenaculum "Have tenaculum for IUD insertion/removal"
label variable iud_uterinesound "Have uterine sound for IUD insertion/removal"
label variable maternalservices "Types of maternal health services offered"
label variable postpartum_rw "Items discussed with mother after delivery or during the first postnatal visit"
label variable fp_during_postpartum "Facility offers FP during postpartum visit"
label variable postabortion_discussion "Items discussed during postabortion visit"
label variable fp_during_postabortion "Facility offers FP during postabortion visit"
label variable adolescents "FP services offered to unmarried adolescents"
label variable hiv_services "Facility offers HIV services"
label variable hiv_condom "Facility offers condoms when client comes in for HIV services"
label variable hiv_other_fp "Facility offers other FP services to HIV clients"
label variable hiv_info_elsewhere "Facility offers HIV clients information on obtaining contraception elsewhere"
label variable hiv_referred_where "Where facility refers HIV clients for contraceptives"
label variable SDP_result "SDP interview result"


capture label variable year_open_rw "Year facility opened"
label variable antenatal "Provide antenatal services" 
label variable delivery "Provide delivery services"
label variable postnatal "Provide postnatal services"
label variable post_abortion "Provide post-abortion services"
label variable postpartum_fertility "Discuss return to fertility"
label variable postpartum_space "Discuss healthy timing and spacing of pregnancies"
label variable postpartum_breastfeed "Discuss Immediate and exclusive breastfeeding"
label variable postpartum_fp_bf "Discuss Family planning methods available to use while breastfeeding"
label variable postpartum_LAM "Discuss Lactational Amenorrhea Method and transition to other methods"
label variable postpartum_long_acting "Discuss Long-acting method options "
label variable postabortion_mental "Discuss mental health during post-abortion visit"
label variable postabortion_fertility "Discuss return to fertility during post-abortion visit"
label variable postabortion_healthy_spacing "Discuss healthy spacing during post-abortion visit"
label variable postabortion_long_acting_fp "Discuss long-acting FP during post-abortion visit"
label variable postabortion_spacing "Discuss FP methods for birth spacing during post-abortion visit"
label variable adolescents_counseled "Counseled on family planning methods to unmarried adolescents"
label variable adolescents_provided "Provided family planning methods to unmarried adolescents"
label variable adolescents_prescribed "Prescribed/referred family planning methods to unmarried adolescents"
capture label variable fp_begin_rw "Year began providing FP"
label variable fp_days "Number of days per week FP offered"
capture label variable num_fp_volunteers "Number of CHVs supported to provide FP services" 
label variable exam_room_piped_water "Piped water in FP room"
label variable exam_room_other_running_water "Other running water in FP room"
label variable exam_room_bucket_water "Bucket water in FP room"
label variable exam_room_soap "Soap in FP room"
label variable exam_room_towels "Towels in FP room"
label variable exam_room_wastebin "Waste bin in FP room"
label variable exam_room_sharps "Sharps container in FP room"
label variable exam_room_latex_gloves "Latex gloves in FP room"
label variable exam_room_disinfectant "Disinfectant in FP room"
label variable exam_room_needles "Disposable needles in FP room"
label variable exam_room_auditory_privacy "Auditory privacy in FP room"
label variable exam_room_visual_privacy "Visual privacy in FP room"
label variable exam_room_tables "Exam table in FP room"
label variable exam_room_ed_materials "Educational materials in FP room"
label variable protected_floor "FP methods off floor"
label variable protected_water "FP methods protected from water"
label variable protected_sun "FP methods protected from sun"
label variable protected_pests "FP methods protected from pests"
label variable metainstanceID "Metainstance ID"
label variable locationlatitude "Facility location: latitude"
label variable locationlongitude "Facility location: longitude"
label variable locationaltitude "Facility location: altitude"
label variable locationaccuracy "Facility GPS accuracy"
label variable facility_name "Facility name"
label variable facility_name_other "Facility name (other)"
label variable facility_number "Facility number"
capture label var work_begin_rw "When did you begin working at this facility"
capture label var previously_participated "Previously participated in PMA2020 survey at this SDP"
label variable survey_language "Language of SDP survey"


capture confirm variable any_mobile_outreach_6mo
if _rc==0 {     
label variable any_mobile_outreach_6mo "Facility has had mobile outreach team visit in last 6 months"
}
capture confirm variable any_mobile_outreach_12mo
if _rc==0 {     
label variable any_mobile_outreach_12mo "Facility has had mobile outreach team visit in last 12 months"
}

label define yes_no_dnk_nr_list -88 "Don't know" -99 "No response" 0 "No" 1 "Yes", replace

*******************************************************************************
* 7. CLEAN FACILITY NAMES/TYPES: UPDATE BY COUNTRY
*******************************************************************************
/*
* Change facility location
replace facility_location=# if metainstanceID==""

* Change facility type
replace facility_type=# if metainstanceID==""

* Clean facility names
replace facility_name=strtrim(facility_name)
replace facility_name=strproper(facility_name)
split facility_name, gen(facility_name_)
foreach var of varlist facility_name_* {
	replace `var'="Center" if `var'=="Centre"
	}

egen facility_namev2=concat(facility_name_*), punc(" ")
order facility_namev2, after(facility_name)
drop facility_name_* facility_name
rename facility_namev2 facility_name
label variable facility_name "Facility Name"

* Rename facility names
replace facility_name="" if facility_name==""
*/
*******************************************************************************
* 8. DISGUISE FACILITY NAME: UPDATE BY COUNTRY
*******************************************************************************
/*
* Code facility names
gen facility_ID=facility_name
replace facility_ID="random # from pre-specified ranged" if facility_name==""
...
destring facility_ID, replace
order facility_ID, after(facility_name)
*/
*******************************************************************************
* 9. DISGUISE EA: UPDATE BY COUNTRY
*******************************************************************************
/*
* Disguise EA number consistently with HQ/FQ in previous rounds (generate code in Excel)
gen EA_ID=EA
replace EA_ID="# in pre-specified range" if EA_ID=="EA name"
...
destring EA_ID, replace
label variable EA_ID "EA ID (random)"
order EA_ID, after(EA)
*/
*******************************************************************************
* 10. DISGUISE RE NAMES: UPDATE BY COUNTRY
*******************************************************************************
/*
* Correct RE name spelling
replace RE="" if RE==""

* Apply random RE codes (generate code in Excel)
gen RE_ID=RE
replace RE_ID="# in pre-specified range" if RE_ID=="RE name"
...
destring RE_ID, replace
order RE_ID, after(RE)
*/
*******************************************************************************
* 11. DROP UNNECESSARY VARIABLES 
*******************************************************************************

* Drop country-specific variables
* UPDATE BY COUNTRY


* Drop variables
drop date_groupsystem_date_check manual_date your_name_check name_typed 	///
consent_start consent begin_interview witness_auto witness_manual staffing_prompt	/// 
facility_open_string fpc_grpfpc_label fpc_grpfpc_note fpc_grpcharged_joined	///
fpf_grpfpf_note exam_room_permission sect_fps_info sect_fp_methods_note	///
fpc_grpfpc_other methods_selected stockout_note sect_fp_service_integration_note rega_note reg_sold_grpregb_note	///
storage_check storage_grpstorage_prompt storage_grpstorage_labels thankyou	///
exr_grpexr_labels sdp_photo photo_permission sect_end sect_services_info	///
deviceid simserial phonenumber key exr_grpexr_prompt consent_warning ///
fpc_grpcharged_joined exr_grpexr_prompt exr_grpexr_labels this_country

* Drop variables for PMA2020 staff data
*drop RE facility_name locationlatitude locationlongitude locationaltitude locationaccuracy

*******************************************************************************
* 12. SAVE DATA AND CLOSE LOG
*******************************************************************************


numlabel, add

saveold "`CCRX'_SDP_$date_100Prelim.dta", version(12) replace

log close

*******************************************************************************
* ADDITIONAL CLEANING FOR PUBLIC RELEASE
*******************************************************************************

*******************************************************************************
* 13. DROP ADDITIONAL VARIABLES FOR PUBLIC RELEASE
*******************************************************************************
*Export GPS before dropping
replace facility_name=facility_name_other if facility_name=="other"
export excel round metainstanceID level1 level2 level3 EA RE facility_name facility_type managing_authority locationlatitude locationlongitude locationaltitude locationaccuracy SubmissionDateSIF using "`CCRX'_SDPGPS_$date.xls", firstrow(variables) replace

/*
* Drop for public release
* UPDATE BY COUNTRY
drop EA RE EA_location zone district locality facility_number facility_name	///
locationlatitude locationlongitude locationaltitude locationaccuracy 
*/
*******************************************************************************
* 14. MERGE VARIABLES FROM HH/F: UPDATE BY COUNTRY
*******************************************************************************
/*
* Incorporate EA weights & whether EA is urban or rural
rename ea EA
merge m:1 EA using "mergeEAweightsfile", gen (weightmerge)

* EA weights
capture drop if weightmerge!=3
drop weightmerge
drop EASelectionProbability
rename EAweight EA_weight
label variable EA_weight "Weight of EA"
label variable ur "EA urban or rural"

*******************************************************************************
* 15. SAVE DATA FOR PUBLIC RELEASE AND CLOSE LOG
*******************************************************************************

numlabel, add

saveold "PMA`year'_`CCRX'_SDP_$date.dta", version(12) replace
outsheet using "PMA`year'_`CCRX'_SDP_$date.csv", nolabel replace comma
export excel using "PMA`year'_`CCRX'_SDP_$date.xlsx", firstrow(variables) replace

log close

*******************************************************************************
* 16. FINAL CHECK: TEST MERGE TO ENSURE ALL SDPs ARE IN AN EA WITH AT LEAST ONE HOUSEHOLD
*******************************************************************************

* Go into HHF data to keep only one HHF data point per EA
egen EAtag=tag(EA)
drop if EAtag==0

* Back in SDP data merge in the modified HHF data
merge m:1 EA using "$datadir\Data\`mergecheckfile'", gen (EAmerge)

/* 
* Results should have 0 unmatched from master. Example: 
    Result                           # of obs.
    -----------------------------------------
    not matched                             8
        from master                         0  (EAmerge==1)
        from using                          8  (EAmerge==2)

    matched                               275  (EAmerge==3)
    -----------------------------------------
/*

*******************************************************************************
* REMAINING QUESTIONS/CONCERNS
*******************************************************************************

