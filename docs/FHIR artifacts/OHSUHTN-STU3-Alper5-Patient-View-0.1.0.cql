library OHSUHTN_STU3_Alper5_Patient_View version '0.1.0'

/*
  Alper Recommendation #5 reads as follows:

  "In adults with suspected hypertension and without diagnostic uncertainty
  or blood pressure variability, use home blood pressure monitoring for
  diagnostic confirmation."

  See https://ohsu.app.box.com/file/576404341810 page 6

  concepts:
    - "adult"
    - "suspected hypertension"
    - "diagnostic uncertainty"
    - "blood pressure variability"
    - "home blood pressure monitoring"
    - "diagnostic confirmation"

  pseudocode:
    if (isAdult(patient)
      and isSuspectedHypertension(patient.bpList)
      and not(diagnosticUncertainty or isTooVariable(patient.bpList)))
    then
      useHomeBloodPressureMonitoring
      confirmDiagnosis

  thoughts:
    - to identify hypertension, we need to examine blood pressure readings.
    - but we probably don't want to look at ALL blood pressure readings, as
      those from years ago aren't going to be as relevant as those taken
      within the last month.  so what is the time window we're looking at?
      blood pressure readings taken from when?
    - "suspected hypertension" is interpreted to mean BP readings near the
      hypertension threshold, such that some values qualify, with other values
      that don't. this necessarily represents the gray area just before actual
      hypertension.
      - is 1 HTN reading in a collection of otherwise non-HTN readings
        sufficient to qualify as "suspected hypertension"?
      - conversely, is 1 non-HTN reading in a collection of otherwise HTN
        readings sufficient to qualify as "suspected hypertension"?
      - if 1 of either isn't sufficient to render a label of "suspected
        hypertension", what is the threshold?  would 20% of "recent" BP
        readings that qualify as HTN be sufficient?
    - is "diagnostic uncertainty" a meaningless term in this context?  if
      hypertension is only suspected, the diagnosis is necessarily uncertain.
      if this term does have separate meaning, how is it defined?
    - what does "blood pressure variability" mean?  nobody has consistent
      blood pressure readings, everyone's blood pressure readings change
      constantly.  so is this a meaningless term?  or does it refer to
      blood pressure readings that are *excessively* variable?  assuming
      it means excessively variable, how is that defined?  > 1 standard
      deviation across the examined time window?  something different?
    - "without ((diagnostic uncertainty) or (blood pressure variability))"
      can be represented more clearly as "with ((diagnostic certainty) and
      (blood pressure consistency))"
    - ... but it's specified that HTN diagnosis is uncertain because
      hypertension is only *suspected*, so neither can the diagnosis be certain,
      nor can the blood pressure readings be consistent.
    - some of the wording in this is confusing.  how can hypertension be
      only suspected when the diagnosis is also certain?
*/

using FHIR version '3.0.2'  /* STU3 */

// http://hl7.org/fhir/STU3/library-fhir-helpers.json.html
include FHIRHelpers version '1.8' called FHIRHelpers

codesystem "LOINC": 'http:/loinc.org' // 'urn:oid:2.16.840.1.113883.6.1'
codesystem "ICD-9-CM": 'urn:oid:2.16.840.1.113883.6.103'
codesystem "ICD-10-CM": 'urn:oid:2.16.840.1.113883.6.90'
codesystem "SNOMED-CT": 'urn:oid:2.16.840.1.113883.6.96'

code "Blood Pressure": '85354-9' from "LOINC" display 'blood pressure'
// code "Blood Pressure": '55284-4' from "LOINC" display 'Blood pressure'

code "Systolic Blood Pressure": '8480-6' from "LOINC" display 'Systolic blood pressure'
code "Diastolic Blood Pressure": '8462-4' from "LOINC" display 'Diastolic blood pressure'
code "Elevated BP without HTN diagnosis": '371622005' from "SNOMED-CT" display 'Elevated BP'

// see http://hl7.org/fhir/STU3/resourcelist.html for FHIR STU3 structure reference

// valuesets

valueset "Blood Pressure Measured": 'urn:oid:2.16.840.1.113883.3.600.2012'
valueset "Diagnosis of Hypertension": 'urn:oid:2.16.840.1.113883.3.600.263'
valueset "Ambulatory Blood Pressure Monitoring": 'urn:oid:2.16.840.1.113762.1.4.1047.511'
valueset "Home Blood Pressure Monitoring": 'urn:oid:2.16.840.1.113762.1.4.1047.507'
valueset "Elevated BP Reading": 'urn:oid:2.16.840.1.113762.1.4.1047.513'
valueset "Finding of Elevated Blood Pressure": 'urn:oid:2.16.840.1.113762.1.4.1047.514'

// parameters

// todo: implement parameters when we figure out how to get them to work.  Bryn has provided info but it's convoluted
// parameter MeasurementPeriod Interval<DateTime>

// context

context Patient

// definitions

// todo: remove this hard-coded MeasurementPeriod definition when the parameterized version is working
define MeasurementPeriod:
  Interval<DateTime>[@2019-01-01T00:00:00.0, @2019-06-29T23:59:59.0]

// copied from https://github.com/esacinc/CQL-Formatting-and-Usage-Wiki/blob/master/Source/Example%20Measures/EXM137v5/EXM137v5_QDM.cql
define "Inclusion Criteria":
  AgeInYearsAt(start of MeasurementPeriod) >= 18
    // todo: and no HTN diagnosis, nor has been prescribed home BP monitoring

define "Pre-Hypertensive":
  "Average Blood Pressure" ABP
    where

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

define "Average Blood Pressure":
  Tuple { systolic: "Average Systolic Blood Pressure", diastolic: "Average Diastolic Blood Pressure" }

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

define "Valid Encounters":
  distinct (
    ["Encounter, Performed": "Office Visit"]
      union ["Encounter, Performed": "Emergency Department Visit"]
      union ["Encounter, Performed": "Detoxification Visit"]
      union ["Encounter, Performed": "Hospital Observation Care - Initial"]
      union ["Encounter, Performed": "Hospital Inpatient Visit - Initial"]
      union ["Encounter, Performed": "Discharge Services - Hospital Inpatient Same Day Discharge"]
      union ["Encounter, Performed": "Discharge Services - Hospital Inpatient"]
      union ["Encounter, Performed": "Face-to-Face Interaction"]
  )

define "Encounters During Measurement Period":
  "Valid Encounters" Encounter
    where Encounter.relevantPeriod during MeasurementPeriod

define "Average Blood Pressure":
  return Tuple { systolic: "Average Systolic Blood Pressure", diastolic: "Average Diastolic Blood Pressure" }

define "Suspected Hypertension"
  [Encounter: "Outpatient"] E
    with [Observation: "Elevated BP Reading"] O

  // I think this is defined as one or more HTN BP readings at 2 or more

// define "Diagnostic Uncertainty"

// define "Blood Pressure Variability"

// define "Home Blood Pressure Monitoring"
