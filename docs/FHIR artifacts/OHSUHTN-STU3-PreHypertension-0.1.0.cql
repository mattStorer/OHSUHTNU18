library OHSUHTN_STU3_PreHypertension version '0.1.0'

using FHIR version '3.0.0'  /* STU3 */

include FHIRHelpers version '3.0.0' called FHIRHelpers
include OHSUHTN_Common version '0.0.1' called Common

// parameter MeasurementPeriod Interval<DateTime>

context Patient

define "Inclusion Criteria":
  Common."Adult at start of Measurement Period"

/////////////////////////////////////////
// ELIGIBILE ONLY

define "Is Eligible Detail":
  if "Inclusion Criteria"
    then 'Will process ' + First(Patient.name).text +
      ': Born ' + ToString(Patient.birthDate) +
      ' (Age at start of measurement period: ' + ToString(AgeInYearsAt(start of Common."Measurement Period")) +
      '), Gender: ' + Patient.gender + ', ' +
      ToString(Count(Common."Blood Pressure Observations")) + ' BP observations' +
      '<br/>Avg Systolic: ' + ToString(Common."Avg Systolic BP") +
      '<br/>Avg Diastolic: ' + ToString(Common."Avg Diastolic BP") +
      '<br/>Systolic Variability: ' + Common."Systolic BP Variability String"
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
  Common."Normal BP" is not null

define "Normal Detail":
  if "Inclusion Criteria" and "Is Normal"
    then 'Patient has normal blood pressure (' + Common."Avg BP String" + ')'
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
  Common."Elevated BP" is not null

define "Elevated Detail":
  if "Inclusion Criteria" and "Is Elevated"
    then 'Patient has elevated blood pressure (' + Common."Avg BP String" + ')'
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
  Common."HTN Stage 1 BP" is not null

define "Hypertension Stage 1 Detail":
  if "Inclusion Criteria" and "Is Hypertension Stage 1"
    then 'Patient has stage 1 hypertension (' + Common."Avg BP String" + ')'
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
  Common."HTN Stage 2 BP" is not null

define "Hypertension Stage 2 Detail":
  if "Inclusion Criteria" and "Is Hypertension Stage 2"
    then 'Patient has stage 2 hypertension (' + Common."Avg BP String" + ')'
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
  Common."HTN Crisis BP" is not null

define "Hypertension Crisis Detail":
  if "Inclusion Criteria" and "Is Hypertension Crisis"
    then 'Patient is in a hypertension crisis (' + Common."Avg BP String" + ')'
  else null

define "Hypertension Crisis Summary":
  if "Inclusion Criteria" and "Is Hypertension Crisis"
    then 'Hypertension Crisis'
  else null

define "Hypertension Crisis Indicator":
  if "Inclusion Criteria"
    then 'warning'
  else null

