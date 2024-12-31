create table beneficiary (
	BeneID varchar (255)
    , DOB date
    , DOD date
    , Gender int
    , Race int
	, RenalDiseaseIndicator int
    , State int
    , County int
    , NoOfMonths_PartACov int
    , ChronicCond_Alzheimer int
    , ChronicCond_Heartfailure int
    , ChronicCond_KidneyDisease int
	, ChronicCond_Cancer int
    , ChronicCond_ObstrPulmonary int
    , ChronicCond_Depression int
    , ChronicCond_Diabetes int
    , ChronicCond_IschemicHeart int
    , ChronicCond_Osteoporasis int
    , ChronicCond_rheumatoidarthritis int
    , IPAnnualReimbursementAmt int
    , IPAnnualDeductibleAmt int
    , OPAnnualReimbursementAmt int
    , OPAnnualDeductibleAmt int
)
;

create table inpatient_data (
	BeneID varchar (255)
    , ClaimID varchar (255)
    , ClaimStartDt date
	, ClaimEndDt date
    , Provider varchar (255)
    , InscClaimAmtReimbursed int
    , AttendingPhysician varchar (255)
    , OperatingPhysician varchar (255)
    , OtherPhysician varchar (255)
    , AdmissionDt date
    , ClmAdmitDiagnosisCode varchar (50)
	, DeductibleAmtPaid int
    , DischargeDt date
    , DiagnosisGroupCode int
    , ClmDiagnosisCode_1 varchar (50)
    , ClmDiagnosisCode_2 varchar (50)
    , ClmDiagnosisCode_3 varchar (50)
    , ClmDiagnosisCode_4 varchar (50)
    , ClmDiagnosisCode_5 varchar (50)
    , ClmDiagnosisCode_6 varchar (50)
    , ClmDiagnosisCode_7 varchar (50)
    , ClmDiagnosisCode_8 varchar (50)
    , ClmDiagnosisCode_9 varchar (50)
    , ClmDiagnosisCode_10 varchar (50)
    , ClmProcedureCode_1 varchar (10)
    , ClmProcedureCode_2 varchar (10) 
    , ClmProcedureCode_3 varchar (10)
    , ClmProcedureCode_4 varchar (10)
    , ClmProcedureCode_5 varchar (10)
    , ClmProcedureCode_6 varchar (10)
)
;

create table outpatient_data (
	BeneID varchar (255)
    , ClaimID varchar (255)
    , ClaimStartDt date
	, ClaimEndDt date
    , Provider varchar (255)
    , InscClaimAmtReimbursed int
    , AttendingPhysician varchar (255)
    , OperatingPhysician varchar (255)
    , OtherPhysician varchar (255)
    , ClmDiagnosisCode_1 varchar (50)
    , ClmDiagnosisCode_2 varchar (50)
    , ClmDiagnosisCode_3 varchar (50)
    , ClmDiagnosisCode_4 varchar (50)
    , ClmDiagnosisCode_5 varchar (50)
    , ClmDiagnosisCode_6 varchar (50)
    , ClmDiagnosisCode_7 varchar (50)
    , ClmDiagnosisCode_8 varchar (50)
    , ClmDiagnosisCode_9 varchar (50)
    , ClmDiagnosisCode_10 varchar (50)
    , ClmProcedureCode_1 varchar (10)
    , ClmProcedureCode_2 varchar (10) 
    , ClmProcedureCode_3 varchar (10)
    , ClmProcedureCode_4 varchar (10)
    , ClmProcedureCode_5 varchar (10)
    , ClmProcedureCode_6 varchar (10)
    , DeductibleAmtPaid int
    , ClmAdmitDiagnosisCode varchar (50)
)
;

create table potential_fraud (
	Provider varchar (255)
    , PotentialFraud varchar (5)
)
;

-- Combining tables of providers with potential fraud with patient data.

create temporary table inpatient_fraud as ( -- want to continue to refer to evaluate fraud 
select
	id.BeneID
    , id.ClaimID
    , id.ClaimStartDt
    , id.ClaimEndDt
    , id.Provider
    , id.InscClaimAmtReimbursed
    , id.AttendingPhysician
    , id.OperatingPhysician
    , id.OtherPhysician
    , id.AdmissionDt
    , id.ClmAdmitDiagnosisCode
    , id.DeductibleAmtPaid
    , id.DischargeDt
    , id.DiagnosisGroupCode
    , id.ClmDiagnosisCode_1
    , id.ClmDiagnosisCode_2
    , id.ClmDiagnosisCode_3
    , id.ClmDiagnosisCode_4
    , id.ClmDiagnosisCode_5
    , id.ClmDiagnosisCode_6
    , id.ClmDiagnosisCode_7
    , id.ClmDiagnosisCode_8
    , id.ClmDiagnosisCode_9
    , id.ClmDiagnosisCode_10
    , id.ClmProcedureCode_1
    , id.ClmProcedureCode_2
    , id.ClmProcedureCode_3
    , id.ClmProcedureCode_4
    , id.ClmProcedureCode_5
    , id.ClmProcedureCode_6
    , pf.PotentialFraud
from
	inpatient_data id 
		join -- will be able to view all providers that have Y/N match to fraud
			potential_fraud pf
				on id.provider = pf.provider
where
	pf.potentialfraud = 'Yes' -- only want to view potential fraud claims 
)
;

-- want to identify which month potential fraud is occuring the most in

select
	substring(claimstartdt,6,2) as claim_month
    , count(*) as total_potential_fraud
from
	inpatient_fraud
group by
	claim_month
order by
	total_potential_fraud desc -- want to see the highest
; -- findings:the first half of the year, specifically January and March (Feb shorter by a few days) lead 

-- what trends are there in potential fraud when providers work with specific attending and operating physicians?

select
	provider
    , attendingphysician
    , operatingphysician
    , count(*) as times_worked_together
from
	inpatient_fraud
group by
	provider, attendingphysician, operatingphysician
order by
	times_worked_together desc -- want to see the highest
; -- top physician pairings to be aware of fraud

-- what is is the average, min and max insurance claim reimbursement amount reimbursed when potential fraud?

select
	avg(inscclaimamtreimbursed)
    , min(inscclaimamtreimbursed)
    , max(inscclaimamtreimbursed)
from
	inpatient_fraud
;
    
-- what is the most common claim admit diagnosis code for potential fraud?

select
	ClmAdmitDiagnosisCode
    , count(ClmAdmitDiagnosisCode) as total_occurrence
from
	inpatient_fraud
group by
	ClmAdmitDiagnosisCode
order by
	total_occurrence desc -- want to see highest
;

-- need to see what the actual claim procedure and diagnosis codes are, split in different columns, but still all together occurring

with total_claim_procedure_occurrence as (  -- cte to union all in one and then can add together 
select
	clmprocedurecode_1 as claim_procedure_code
    , count(clmprocedurecode_1) as total_occurrence
from
	inpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_2 as claim_procedure_code
    , count(clmprocedurecode_2) as total_occurrence
from
	inpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_3 as claim_procedure_code
    , count(clmprocedurecode_3) as total_occurrence
from
	inpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_4 as claim_procedure_code
    , count(clmprocedurecode_4) as total_occurrence
from
	inpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_5 as claim_procedure_code
    , count(clmprocedurecode_5) as total_occurrence
from
	inpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_6 as claim_procedure_code
    , count(clmprocedurecode_6) as total_occurrence
from
	inpatient_data
group by
	claim_procedure_code
order by
	total_occurrence desc 
)
select
	claim_procedure_code
    , sum(total_occurrence) as total_occurrence
from
	total_claim_procedure_occurrence
group by
	claim_procedure_code
having 
	claim_procedure_code != 'NA' -- no relative information here 
order by
	total_occurrence desc 
; -- top procedure codes "4019", "9904", "2724"

-- continuing same for diagnosis codes  

with total_claim_diagnosis_occurrence as (
select
	clmdiagnosiscode_1 as claim_diagnosis_code
    , count(clmdiagnosiscode_1) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_2 as claim_diagnosis_code
    , count(clmdiagnosiscode_2) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_3 as claim_diagnosis_code
	, count(clmdiagnosiscode_3) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_4 as claim_diagnosis_code
	, count(clmdiagnosiscode_4) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_5 as claim_diagnosis_code
	, count(clmdiagnosiscode_5) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_6 as claim_diagnosis_code
	, count(clmdiagnosiscode_6) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_7 as claim_diagnosis_code
	, count(clmdiagnosiscode_7) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_8 as claim_diagnosis_code
	, count(clmdiagnosiscode_8) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_9 as claim_diagnosis_code
	, count(clmdiagnosiscode_9) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_10 as claim_diagnosis_code
	, count(clmdiagnosiscode_10) as total_occurrence
from
	inpatient_data
group by
	claim_diagnosis_code
order by
	total_occurrence desc 
)
select
	claim_diagnosis_code
    , sum(total_occurrence) as total_occurrence -- can see total amount of each claim no matter which number diagnosis it is 
from
	total_claim_diagnosis_occurrence
group by
	claim_diagnosis_code
having 
	claim_diagnosis_code != 'NA'
order by
	total_occurrence desc 
; -- top claim diagnosis codes "4019", "2724", "25000"

-- 4019 is top for diagnosis and procedure 

-- looking into trends for outpatient data as well
-- first combining the two tables as temp table

create temporary table outpatient_fraud as (
select
	od.BeneID
    , od.ClaimID
    , od.ClaimStartDt
    , od.ClaimEndDt
    , od.Provider
    , od.InscClaimAmtReimbursed
    , od.AttendingPhysician
    , od.OperatingPhysician
    , od.OtherPhysician
    , od.ClmDiagnosisCode_1
    , od.ClmDiagnosisCode_2
    , od.ClmDiagnosisCode_3
    , od.ClmDiagnosisCode_4
    , od.ClmDiagnosisCode_5
    , od.ClmDiagnosisCode_6
    , od.ClmDiagnosisCode_7
    , od.ClmDiagnosisCode_8
    , od.ClmDiagnosisCode_9
    , od.ClmDiagnosisCode_10
    , od.ClmProcedureCode_1
    , od.ClmProcedureCode_2
    , od.ClmProcedureCode_3
    , od.ClmProcedureCode_4
    , od.ClmProcedureCode_5
    , od.ClmProcedureCode_6
    , od.DeductibleAmtPaid
    , od.ClmAdmitDiagnosisCode
    , pf.PotentialFraud
from
	outpatient_data od 
		join -- will be able to view all providers that have Y/N match to fraud
			potential_fraud pf
				on od.provider = pf.provider
where
	pf.potentialfraud = 'Yes' -- only want to view potential fraud claims 
)
;

-- want to identify which month potential fraud is occuring the most in, see if comparible to inpatient

select
	substring(claimstartdt,6,2) as claim_month
    , count(*) as total_potential_fraud
from
	outpatient_fraud
group by
	claim_month
order by
	total_potential_fraud desc -- want to see the highest
; -- same trends at beginning of year

-- what trends are there in potential fraud when providers work with specific attending and operating physicians?

select
	provider
    , attendingphysician
    , operatingphysician
    , count(*) as times_worked_together
from
	outpatient_fraud
group by
	provider, attendingphysician, operatingphysician
order by
	times_worked_together desc -- want to see the highest
; -- common pairings of provider and attending physician, but also some common providers 

-- what is is the average, min and max insurance claim reimbursement amount reimbursed when potential fraud?

select
	avg(inscclaimamtreimbursed)
    , min(inscclaimamtreimbursed)
    , max(inscclaimamtreimbursed)
from
	outpatient_fraud
; -- avg potential claim reimbursement amount is a lot lower

-- what is the most common claim admit diagnosis code for potential fraud?

select
	ClmAdmitDiagnosisCode
    , count(ClmAdmitDiagnosisCode) as total_occurrence
from
	outpatient_fraud
group by
	ClmAdmitDiagnosisCode
order by
	total_occurrence desc -- want to see highest
; -- some commonalities to inpatient

-- looking at claim and procedure codes for outpatient

with total_claim_procedure_occurrence as (  -- cte to union all in one and then can add together 
select
	clmprocedurecode_1 as claim_procedure_code
    , count(clmprocedurecode_1) as total_occurrence
from
	outpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_2 as claim_procedure_code
    , count(clmprocedurecode_2) as total_occurrence
from
	outpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_3 as claim_procedure_code
    , count(clmprocedurecode_3) as total_occurrence
from
	outpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_4 as claim_procedure_code
    , count(clmprocedurecode_4) as total_occurrence
from
	outpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_5 as claim_procedure_code
    , count(clmprocedurecode_5) as total_occurrence
from
	outpatient_data
group by
	claim_procedure_code
union all 
select
	clmprocedurecode_6 as claim_procedure_code
    , count(clmprocedurecode_6) as total_occurrence
from
	outpatient_data
group by
	claim_procedure_code
order by
	total_occurrence desc 
)
select
	claim_procedure_code
    , sum(total_occurrence) as total_occurrence
from
	total_claim_procedure_occurrence
group by
	claim_procedure_code
having 
	claim_procedure_code != 'NA' -- no relative information here 
order by
	total_occurrence desc 
; -- lesser amount since outpatient, almost negligible results, but top three are "9904", "66", "4516"

-- continuing same for diagnosis codes  

with total_claim_diagnosis_occurrence as (
select
	clmdiagnosiscode_1 as claim_diagnosis_code
    , count(clmdiagnosiscode_1) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_2 as claim_diagnosis_code
    , count(clmdiagnosiscode_2) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_3 as claim_diagnosis_code
	, count(clmdiagnosiscode_3) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_4 as claim_diagnosis_code
	, count(clmdiagnosiscode_4) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_5 as claim_diagnosis_code
	, count(clmdiagnosiscode_5) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_6 as claim_diagnosis_code
	, count(clmdiagnosiscode_6) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_7 as claim_diagnosis_code
	, count(clmdiagnosiscode_7) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_8 as claim_diagnosis_code
	, count(clmdiagnosiscode_8) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_9 as claim_diagnosis_code
	, count(clmdiagnosiscode_9) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
union all 
select
	clmdiagnosiscode_10 as claim_diagnosis_code
	, count(clmdiagnosiscode_10) as total_occurrence
from
	outpatient_data
group by
	claim_diagnosis_code
order by
	total_occurrence desc 
)
select
	claim_diagnosis_code
    , sum(total_occurrence) as total_occurrence -- can see total amount of each claim no matter which number diagnosis it is 
from
	total_claim_diagnosis_occurrence
group by
	claim_diagnosis_code
having 
	claim_diagnosis_code != 'NA'
order by
	total_occurrence desc 
; -- top claim diagnosis codes "4019", "2724", "25000", same top results 

-- lets confirm the average age of those with potential fraud
-- need to join beneficiary table to inpatient and outpatient data

with inpatient_age_table as (
	select
		b.beneid
		, b.dob
		, timestampdiff(year, b.dob, current_date) as age 
		, inf.potentialfraud
	from
		beneficiary b
			join
				inpatient_fraud inf -- can use temp table 
					on b.beneid = inf.beneid
)
select
	age
    , count(age) as total_patients
from
	inpatient_age_table
group by
	age
having
	age < 65 
order by
	total_patients desc
; -- majority potential fraud occurring just under 65 or high 50s. 

-- checking outpatient trends

with outpatient_age_table as (
	select
		b.beneid
		, b.dob
		, timestampdiff(year, b.dob, current_date) as age 
		, opf.potentialfraud
	from
		beneficiary b
			join
				outpatient_fraud opf -- can use temp table 
					on b.beneid = opf.beneid
)
select
	age
    , count(age) as total_patients
from
	outpatient_age_table
group by
	age
having
	age < 65 
order by
	total_patients desc
; -- a lot, much more than inpatient potential fraud is occuring with those less than 65. still in the same age range as inpatient 




    
    
    
    
    