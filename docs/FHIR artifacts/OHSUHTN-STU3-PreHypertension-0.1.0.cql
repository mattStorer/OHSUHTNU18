library OHSUHTN_STU3_Pre_Hypertension version '0.1.0'

using FHIR version '3.0.0'  /* STU3 */

include FHIRHelpers version '3.0.0' called FHIRHelpers

codesystem "LOINC": 'http:/loinc.org'

valueset "Blood Pressure Measured": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.2012'

code "Blood Pressure": '55284-4' from "LOINC" display 'blood pressure'
code "Systolic Blood Pressure": '8480-6' from "LOINC" display 'Systolic blood pressure'
code "Diastolic Blood Pressure": '8462-4' from "LOINC" display 'Diastolic blood pressure'

// todo: implement parameters when we figure out how to get them to work.  Bryn has provided info but it's convoluted
// parameter MeasurementPeriod Interval<DateTime>

context Patient

// todo: remove this hard-coded MeasurementPeriod definition when the parameterized version is working
define MeasurementPeriod:
  Interval[@2019-01-01T00:00:00.0, @2019-06-29T23:59:59.0]

define "Inclusion Criteria":
  AgeInYearsAt(start of MeasurementPeriod) >= 18

define "Pre-Hypertension Detail":
  if "Inclusion Criteria" and "Is Pre-Hypertensive"
    then 'Patients has pre-hypertension based on average blood pressure'
  else null

define "Pre-Hypertension Summary":
  if "Inclusion Criteria" and "Is Pre-Hypertensive"
    then 'Pre-Hypertensive'
  else null

define "Pre-Hypertension Indicator":
  if "Inclusion Criteria"
    then 'warning'
  else null

define "Is Pre-Hypertensive":
  "Pre-Hypertensive Blood Pressure" is not null

define "Pre-Hypertensive Blood Pressure":
  "Average Blood Pressure" O
    where O.systolic between 120 and 130
    and O.diastolic between 80 and 90

define "Average Blood Pressure":
  Tuple { systolic: "Average Systolic Blood Pressure", diastolic: "Average Diastolic Blood Pressure" }

define "Blood Pressure Observations":
  [Observation: "Blood Pressure"] O
    where "Normalize Interval"(O.effective) during MeasurementPeriod
      and O.status in { 'final', 'amended' }

define "Average Systolic Blood Pressure":
  Avg("Blood Pressure Observations" O
    return FHIRHelpers.ToQuantity(singleton from (O.component C where FHIRHelpers.ToConcept(C.code) ~ "Systolic Blood Pressure").value)
  )

define "Average Diastolic Blood Pressure":
  Avg("Blood Pressure Observations" O
    return FHIRHelpers.ToQuantity(singleton from (O.component C where FHIRHelpers.ToConcept(C.code) ~ "Diastolic Blood Pressure").value)
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
