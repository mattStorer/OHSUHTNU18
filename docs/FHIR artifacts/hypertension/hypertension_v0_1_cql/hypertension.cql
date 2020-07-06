library "hypertension" version '0.1'

using FHIR version '3.0.0'

include "FHIRHelpers" version '3.0.0' called FHIRHelpers 
include "CDS_Connect_Commons_for_FHIRv300" version '1.0.1' called C3F 
include "CDS_Connect_Conversions" version '1' called Convert 
include "OHSUHTN_Common" version '0.0.1'

context Patient

define "Info":
  'info'

define "Warning":
  'warning'

define "Critical":
  'critical'

define "Adult at start of Measurement Period":
  "OHSUHTN_Common"."Adult at start of Measurement Period"

define "Normal BP":
  ("OHSUHTN_Common"."Normal BP") is not null

define "Elevated BP":
  ("OHSUHTN_Common"."Elevated BP") is not null

define "HTN Stage 1 BP":
  ("OHSUHTN_Common"."HTN Stage 1 BP") is not null

define "HTN Stage 2 BP":
  ("OHSUHTN_Common"."HTN Stage 2 BP") is not null

define "HTN Crisis BP":
  ("OHSUHTN_Common"."HTN Crisis BP") is not null

define "MeetsInclusionCriteria":
  "Adult at start of Measurement Period"

define "Normal":
  if "InPopulation" is not true then
    null
  else
  "Normal BP"

define "Elevated":
  if "InPopulation" is not true then
    null
  else
  "Elevated BP"

define "HTN Stage 1":
  if "InPopulation" is not true then
    null
  else
  "HTN Stage 1 BP"

define "HTN Stage 2":
  if "InPopulation" is not true then
    null
  else
  "HTN Stage 2 BP"

define "HTN Crisis":
  if "InPopulation" is not true then
    null
  else
  "HTN Crisis BP"

define "InPopulation":
   "MeetsInclusionCriteria" 

define "Recommendation":
  if "HTN Crisis" then 'Patient is in Hypertension Crisis.  Get this person to a hospital RIGHT NOW, like, not even kidding.  Call them an ambulance.'
  else if "HTN Stage 2" then 'Patient has Stage 2 Hypertension.  Add or increase medication dosage, improve on exercise and diet initiatives.  Patient actually has to stop smoking and drinking now, for real.  I know they said they were going to stop last time around, but this time they really need to do it.'
  else if "HTN Stage 1" then 'Patient has Stage 1 Hypertension.  Recommend implementing lifestyle changes such as smoking cessation and sodium intake reduction. If needed, consider pharmacological intervention, which may include ACE-I, ARB, CCB, or Thiazide.'
  else if "Elevated" then 'Patient has Elevated blood pressure.  Consider behavioral modifications and continue monitoring BP.'
  else if "Normal" then 'Patient has Normal blood pressure.  Monitor BP for future elevation.'
  else null

define "Other Information":
  if "OHSUHTN_Common"."Systolic BP Variability" > 10 then
    'Systolic BP is highly variable.  Standard Deviation = ' + "OHSUHTN_Common"."Systolic BP Variability String"
  else
    null

define "Errors":
  null
