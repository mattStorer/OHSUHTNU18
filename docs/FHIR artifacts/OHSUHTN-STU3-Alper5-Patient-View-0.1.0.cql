library ALPER_5 version '1.0'

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

/*
  Inclusion criteria:

  Exclusion criteria:

*/

using FHIR version '3.0.2'  /* STU3 */

// http://hl7.org/fhir/STU3/library-fhir-helpers.json.html
include FHIRHelpers version '1.8' called FHIRHelpers

codesystem "LOINC": 'urn:oid:2.16.840.1.113883.6.1'
codesystem "ICD-9-CM": 'urn:oid:2.16.840.1.113883.6.103'
codesystem "ICD-10-CM": 'urn:oid:2.16.840.1.113883.6.90'
codesystem "SNOMED-CT": 'urn:oid:2.16.840.1.113883.6.96'

code "Blood Pressure": '55284-4' from "LOINC" display 'Blood pressure'
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

parameter MeasurementPeriod Interval<DateTime>

// context


context Patient

// definitions

// copied from https://github.com/esacinc/CQL-Formatting-and-Usage-Wiki/blob/master/Source/Example%20Measures/EXM137v5/EXM137v5_QDM.cql
define "In Demographic":
  AgeInYearsAt(start of MeasurementPeriod) >= 18

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

define "Average Systolic Blood Pressure":
  Avg([Observation: "Systolic Blood Pressure"] O
    where O.effectiveDateTime during MeasurementPeriod)

// same as in the FHIR app, need to get observation.valueQuantity.value for LOINC 8462-4 and 8480-6,
// or observation.
define "Average Diastolic Blood Pressure":
  Avg([Observation: "Diastolic Blood Pressure"] O
    where O.effectiveDateTime during MeasurementPeriod)

define "Suspected Hypertension"
  [Encounter: "Outpatient"] E
    with [Observation: "Elevated BP Reading"] O

  // I think this is defined as one or more HTN BP readings at 2 or more

define "Diagnostic Uncertainty"

define "Blood Pressure Variability"

define "Home Blood Pressure Monitoring"
