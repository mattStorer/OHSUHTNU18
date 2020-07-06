library Screening_FHIR3 version '0.1'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers
include OHSUHTN_Common_FHIR3 version '0.1' called OHSUHTN_Common

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

valueset "Essential Hypertension Diagnosis": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.104.12.1011'
valueset "Pregnancy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.378'
valueset "Secondary Hypertension": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.10'
valueset "ESRD": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.353'
valueset "Hospice": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1108.15'

parameter MeasurementPeriod default Interval[
  @2019-01-01T00:00:00.0,
  @2019-06-30T23:59:59.0
)

context Patient

define "Info":
  'info'

define "Warning":
  'warning'

define "Critical":
  'critical'

define "In Population":
  "Inclusion Criteria" is true
    and "Exclusion Criteria" is not true

define "Inclusion Criteria":
  "Adult at start of Measurement Period"
    and "Any Essential Hypertension Diagnosis Ever"
    and "Minimum HTN Stage 1 BP over Last 4 readings"

define "Exclusion Criteria":
  "Became Pregnant During Measurement Period"  // TODO: should be Pregnant Right Now
    or "Secondary Hypertension Right Now"      // TODO: should be Secondary Hypertension Right Now
    or "Any ESRD Ever"
    or "Any Hospice Ever"

define "Recommendation":
  if "In Population" is true then
    'is in population, provide recommendation'
  else
    null

define "Rationale":
  if "In Population" is true then
    'is in population, provide rationale'
  else
    null

// inclusion ////////////////////////

define "Adult at start of Measurement Period":
  OHSUHTN_Common."Adult at start of Measurement Period"

define "Any Essential Hypertension Diagnosis Ever":
  Count("All Essential Hypertension Diagnosis Conditions") > 0

define "Minimum HTN Stage 1 BP over Last 4 readings":
  (OHSUHTN_Common."Avg Last 4 BP" O
    where O.systolic >= 130
    or O.diastolic >= 80) is not null

define "All Essential Hypertension Diagnosis Conditions":
  [Condition: "Essential Hypertension Diagnosis"] C
//    where OHSUHTN_Common."Normalize Interval"(C.onset) during MeasurementPeriod

// exclusion ////////////////////////

define "Secondary Hypertension Right Now":
  Count("Secondary Hypertension Conditions") > 0

define "Became Pregnant During Measurement Period":
  Count("Pregnancy Observations") > 0

define "Any ESRD Ever":
  Count("ESRD Conditions") > 0

define "Any Hospice Ever":
  Count("Hospice Conditions") > 0

define "Pregnancy Observations":
  [Observation: "Pregnancy"] O
    where OHSUHTN_Common."Normalize Interval"(O.effective) during MeasurementPeriod
    and O.status in { 'final', 'amended' }

define "Secondary Hypertension Conditions":
  [Condition: "Secondary Hypertension"] C
    where C.clinicalStatus = 'active' and C.verificationStatus = 'confirmed'
  // OHSUHTN_Common."Normalize Interval"(C.onset) during MeasurementPeriod

define "ESRD Conditions":
  [Condition: "ESRD"] C
//  where OHSUHTN_Common."Normalize Interval"(C.onset) during MeasurementPeriod

define "Hospice Conditions":
  [Condition: "Hospice"] C
//  where OHSUHTN_Common."Normalize Interval"(C.onset) during MeasurementPeriod
