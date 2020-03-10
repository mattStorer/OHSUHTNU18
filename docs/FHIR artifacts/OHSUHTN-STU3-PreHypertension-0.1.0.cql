library OHSUHTN_STU3_PreHypertension version '0.1.0'

using FHIR version '3.0.0'  /* STU3 */

include FHIRHelpers version '3.0.0' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'

valueset "Blood Pressure Measured": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.2012'

code "Blood Pressure": '55284-4' from "LOINC" display 'blood pressure'
code "Systolic Blood Pressure": '8480-6' from "LOINC" display 'Systolic blood pressure'
code "Diastolic Blood Pressure": '8462-4' from "LOINC" display 'Diastolic blood pressure'

// todo: implement parameters when we figure out how to get them to work.  Bryn has provided info but it's convoluted
// parameter MeasurementPeriod Interval<DateTime>

context Patient

// todo: remove this hard-coded MeasurementPeriod definition when the parameterized version is working
define "MeasurementPeriod":
  Interval[@2019-01-01T00:00:00.0, @2019-06-29T23:59:59.0]

define "Inclusion Criteria":
  AgeInYearsAt(start of "MeasurementPeriod") >= 18

/////////////////////////////////////////
// ELIGIBILE ONLY

define "Is Eligible Detail":
  if "Inclusion Criteria"
    then 'Will process ' + First(Patient.name).text +
      ': Born ' + ToString(Patient.birthDate) +
      ' (Age at start of measurement period: ' + ToString(AgeInYearsAt(start of "MeasurementPeriod")) +
      '), Gender: ' + Patient.gender + ', ' +
      ToString(Count("Blood Pressure Observations")) + ' BP observations' +
      '<br/>Avg Systolic: ' + ToString("Average Systolic Blood Pressure") +
      '<br/>Avg Diastolic: ' + ToString("Average Diastolic Blood Pressure")
  else null

define "Is Eligible Summary":
  if "Inclusion Criteria"
    then 'Meets Eligibility Criteria'
  else null

define "Is Eligible Indicator":
  if "Inclusion Criteria"
    then 'info'
  else null

// see: https://www.heart.org/-/media/health-topics-images/hbp/blood-pressure-readings-chart-english.jpg

/////////////////////////////////////////
// NORMAL

define "Is Normal":
  "Normal Blood Pressure" is not null

define "Normal Blood Pressure":
  "Average Blood Pressure" O
    where O.systolic < 120
    and O.diastolic < 80

define "Normal Detail":
  if "Inclusion Criteria" and "Is Normal"
    then 'Patient has normal blood pressure (' + "ABP" + ')'
  else null

define "Normal Summary":
  if "Inclusion Criteria" and "Is Normal"
    then 'Normal Blood Pressure'
  else null

define "Normal Indicator":
  if "Inclusion Criteria"
    then 'info'
  else null

/////////////////////////////////////////
// ELEVATED

define "Is Elevated":
  "Elevated Blood Pressure" is not null

define "Elevated Blood Pressure":
  "Average Blood Pressure" O
    where O.systolic >= 120 and O.systolic < 130
    and O.diastolic < 80

define "Elevated Detail":
  if "Inclusion Criteria" and "Is Elevated"
    then 'Patient has elevated blood pressure (' + "ABP" + ')'
  else null

define "Elevated Summary":
  if "Inclusion Criteria" and "Is Elevated"
    then 'Elevated Blood Pressure'
  else null

define "Elevated Indicator":
  if "Inclusion Criteria"
    then 'warning'
  else null

/////////////////////////////////////////
// STAGE 1 HYPERTENSION

define "Is Hypertension Stage 1":
  "Hypertension Stage 1 Blood Pressure" is not null

define "Hypertension Stage 1 Blood Pressure":
  "Average Blood Pressure" O
    where (O.systolic >= 130 and O.systolic < 140)
    or (O.diastolic >= 80 and O.diastolic < 90)

define "Hypertension Stage 1 Detail":
  if "Inclusion Criteria" and "Is Hypertension Stage 1"
    then 'Patient has stage 1 hypertension (' + "ABP" + ')'
  else null

define "Hypertension Stage 1 Summary":
  if "Inclusion Criteria" and "Is Hypertension Stage 1"
    then 'Hypertension, Stage 1'
  else null

define "Hypertension Stage 1 Indicator":
  if "Inclusion Criteria"
    then 'warning'
  else null

/////////////////////////////////////////
// STAGE 2 HYPERTENSION

define "Is Hypertension Stage 2":
  "Hypertension Stage 2 Blood Pressure" is not null

define "Hypertension Stage 2 Blood Pressure":
  "Average Blood Pressure" O
    where O.systolic >= 140
    or O.diastolic >= 90

define "Hypertension Stage 2 Detail":
  if "Inclusion Criteria" and "Is Hypertension Stage 2"
    then 'Patient has stage 2 hypertension (' + "ABP" + ')'
  else null

define "Hypertension Stage 2 Summary":
  if "Inclusion Criteria" and "Is Hypertension Stage 2"
    then 'Hypertension, Stage 2'
  else null

define "Hypertension Stage 2 Indicator":
  if "Inclusion Criteria"
    then 'warning'
  else null

/////////////////////////////////////////
// HYPERTENSION CRISIS

define "Is Hypertension Crisis":
  "Hypertension Crisis Blood Pressure" is not null

define "Hypertension Crisis Blood Pressure":
  "Average Blood Pressure" O
    where O.systolic > 180
    or O.diastolic > 120

define "Hypertension Crisis Detail":
  if "Inclusion Criteria" and "Is Hypertension Crisis"
    then 'Patient is in a hypertension crisis (' + "ABP" + ')'
  else null

define "Hypertension Crisis Summary":
  if "Inclusion Criteria" and "Is Hypertension Crisis"
    then 'Hypertension Crisis'
  else null

define "Hypertension Crisis Indicator":
  if "Inclusion Criteria"
    then 'warning'
  else null

///////////////////////////////////////////////////////////

define "ABP":
  "Average Blood Pressure" O
    return ToString(Round(O.systolic.value)) + '/' + ToString(Round(O.diastolic.value)) + ' ' + O.systolic.unit

define "Average Blood Pressure":
  Tuple { systolic: "Average Systolic Blood Pressure", diastolic: "Average Diastolic Blood Pressure" }

define "Blood Pressure Observations":
   [Observation: "Blood Pressure"] O
   where "Normalize Interval"(O.effective) during "MeasurementPeriod"
      and O.status in { 'final', 'amended' }

define "Average Systolic Blood Pressure":
  Avg("Blood Pressure Observations" O
    return all FHIRHelpers.ToQuantity(singleton from (O.component C where FHIRHelpers.ToConcept(C.code) ~ "Systolic Blood Pressure").value)
  )

define "Average Diastolic Blood Pressure":
  Avg("Blood Pressure Observations" O
    return all FHIRHelpers.ToQuantity(singleton from (O.component C where FHIRHelpers.ToConcept(C.code) ~ "Diastolic Blood Pressure").value)
  )

define function "Normalize Interval"(choice Choice<FHIR.dateTime, FHIR.Period, FHIR.Timing, FHIR.instant, FHIR.string, FHIR.Age, FHIR.Range>):
  case
	  when choice is FHIR.dateTime then
    	Interval[FHIRHelpers.ToDateTime(choice as FHIR.dateTime), FHIRHelpers.ToDateTime(choice as FHIR.dateTime)]
		when choice is FHIR.Period then
  		FHIRHelpers.ToInterval(choice as FHIR.Period)
		when choice is FHIR.instant then
			Interval[FHIRHelpers.ToDateTime(choice as FHIR.instant), FHIRHelpers.ToDateTime(choice as FHIR.instant)]
		when choice is FHIR.Age then
		  Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(choice as FHIR.Age),
			  FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(choice as FHIR.Age) + 1 year)
		when choice is FHIR.Range then
		  Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((choice as FHIR.Range).low),
			  FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((choice as FHIR.Range).high) + 1 year)
		when choice is FHIR.Timing then
		  Message(null as Interval<DateTime>, true, '1', 'Error', 'Cannot compute a single interval from a Timing type')
    when choice is FHIR.string then
      Message(null as Interval<DateTime>, true, '1', 'Error', 'Cannot compute an interval from a String value')
		else
			null as Interval<DateTime>
	end
