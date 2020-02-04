const CQF_RULER_URL = "http://localhost:8080/cqf-ruler-dstu3";
const CDS_SERVICES_URL = CQF_RULER_URL + "/cds-services";

function populatePlanDefinitions(_callback) {
    $.ajax({
        "url": CDS_SERVICES_URL,
        "type": "GET",
        "dataType": "json",
        "contentType": "application/json; charset=utf-8",
//        "data": buildRulerRequest(fhirServer, bearerToken),
        "success": function (msg) {
            populatePlanDefinitionSelect(msg.services);
            _callback();
        }
    });
}

function populatePlanDefinitionSelect(arr) {
    var options = "<option value='' selected>-- Select PlanDefinition --</option>\n";
    var info = '';

    arr.forEach(function(item) {
        let trimmedTitle = item.title;
        if (trimmedTitle.indexOf("PlanDefinition - ") == 0) {
            trimmedTitle = trimmedTitle.substring(17);
        }

        options += "<option value='" + item.id + "'>" + item.title + "</option>\n";
        info += "<div class='plan hidden' data-plan-id='" + item.id +
            "'>\n<span class='planTitle'>" + item.title +
            "</span>\n<span class='planDesc'>" + item.description +
            "</span></div>\n";
    });

    $('#planSelect').html(options);
    $('#plans').html(info);
}

function planDefinitionChanged() {
    let button = $('#executeHookButton');
    let planId = $('#planSelect').children('option:selected').attr('value');
    if (planId == '') {
        $(button).prop('disabled', true);
        $('div.plan').not('.hidden').each(function() {
            $(this).addClass('hidden');
        });

    } else {
        $(button).prop('disabled', false);
        $('div.plan').each(function() {
            if ($(this).attr('data-plan-id') == planId) {
                $(this).removeClass('hidden');
            } else {
                $(this).addClass('hidden');
            }
        });
    }
}

function executeSelectedPlanDefinition() {
    let fhirServer = getFHIRServer();
    let bearerToken = getFHIRBearerToken();
    let patientId = getFHIRPatientId();
    let planId = $('#planSelect').children("option:selected").attr("value");

    $.ajax({
        "url": CDS_SERVICES_URL + "/" + planId,
        "type": "POST",
        "dataType": "json",
        "contentType": "application/json; charset=utf-8",
        "data": JSON.stringify(buildOpioidRulerRequest(fhirServer, bearerToken, patientId)),
        "success": function (obj) {
            populateCards(obj.cards);
        }
    });
}

function populateCards(cards) {
    html = "";
    cards.forEach(function(card) {
        html += "<div class='card " + card.indicator +
            "'>\n<span class='cardTitle'>" + card.summary +
            "</span>\nSee: <a href='" + card.source.url +
            "' target='_blank' rel='noopener noreferrer'>" + card.source.label +
            "</a></div>\n";
    });
    $('#cards').html(html);
}

function genUUID() {
    const uuidv4 = require('uuid/v4');
    return uuidv4();
}


function buildHTNRulerRequest(fhirServer, bearerToken, patientId, code) {
    return {
      "hookInstance" : genUUID(),
      "fhirServer" : fhirServer,
      "hook" : "patient-view",
      "fhirAuthorization" : {
        "access_token" : bearerToken,
        "token_type" : "Bearer",
        "expires_in" : 300,
        "scope" : "patient/Patient.read patient/Observation.read",
        "subject" : "cds-service4"
      },
      "context" : {
    //                      "userId" : "Practitioner/example",
          "patientId" : patientId,
          "code" : "http://loinc.org|" + code
      },
      "prefetch" : {
          "patient" : "Patient?_id={{context.patientId}}",
          "observations" : "Observation?patient={{context.patientId}}&code={{context.code}}"
//          "patientToGreet" : {
//             "resourceType" : "Patient",
//             "gender" : "male",
//             "birthDate" : "1925-12-23",
//             "id" : "1288992",
//             "active" : true
//          }
      }
    };
}

// see https://cds-hooks.hl7.org/1.0/#http-request_1 for details
function buildOpioidRulerRequest(fhirServer, bearerToken, patientId) {
    // opioidJson taken from http://build.fhir.org/ig/cqframework/opioid-cds/requests/request-example-rec-10-patient-view-illicit-drugs.json
    // see http://build.fhir.org/ig/cqframework/opioid-cds/quick-start.html section 8.3.1
    return {
       "hookInstance": "31c74cfc-747c-4afc-82e4-bdd3b7a0a58c",
       "fhirServer": "http://measure.eval.kanvix.com/cqf-ruler/baseDstu3",
       "hook": "patient-view",
       "applyCql": true,
       "context": {
         "user": "Practitioner/example",
         "patientId": "Patient/example-rec-10-illicit-drugs",
         "encounterId": "Encounter/example-rec-10-illicit-drugs-context"
       },
       "prefetch": {
         // see http://hl7.org/fhir/STU3/resourcelist.html for STU3 model structure used in prefetch
         "item1": {
           "response": {
             "status": "200 OK"
           },
           "resource": {
             "resourceType": "MedicationRequest",
             "id": "example-rec-10-illicit-drugs-prefetch",
             "status": "active",
             "intent": "order",
             "category": {
               "coding": [
                 {
                   "system": "http://hl7.org/fhir/medication-request-category",
                   "code": "outpatient"
                 }
               ]
             },
             "medicationCodeableConcept": {
               "coding": [
                 {
                   "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                   "code": "1049502",
                   "display": "12 HR Oxycodone Hydrochloride 10 MG Extended Release Oral Tablet"
                 }
               ]
             },
             "subject": {
               "reference": "Patient/example-rec-10-illicit-drugs"
             },
             "context": {
               "reference": "Encounter/example-rec-10-illicit-drugs-prefetch"
             },
             "_authoredOn": {
               "extension": [
                 {
                   "url": "http://hl7.org/fhir/StructureDefinition/cqif-cqlExpression",
                   "valueString": "Today() - 90 days"
                 }
               ]
             },
             "dosageInstruction": [
               {
                 "timing": {
                   "repeat": {
                     "frequency": 3,
                     "period": 1.0,
                     "periodUnit": "d"
                   }
                 },
                 "asNeededBoolean": false,
                 "doseQuantity": {
                   "value": 1.0,
                   "unit": "tablet"
                 }
               }
             ],
             "dispenseRequest": {
               "validityPeriod": {
                 "extension": [
                   {
                     "url": "http://hl7.org/fhir/StructureDefinition/cqif-cqlExpression",
                     "valueString": "FHIR.Period { start: FHIR.dateTime { value: Today() - 90 days }, end: FHIR.dateTime { value: Today() } }"
                   }
                 ]
               },
               "numberOfRepeatsAllowed": 3,
               "expectedSupplyDuration": {
                 "value": 30.0,
                 "unit": "d"
               }
             }
           }
         },
         "item2": {
           "response": {
             "status": "200 OK"
           },
           "resource": {
             "resourceType": "Encounter",
             "id": "example-rec-10-illicit-drugs-prefetch",
             "status": "finished",
             "subject": {
               "reference": "Patient/example-rec-10-illicit-drugs"
             },
             "period": {
               "extension": [
                 {
                   "url": "http://hl7.org/fhir/StructureDefinition/cqif-cqlExpression",
                   "valueString": "FHIR.Period { start: FHIR.dateTime { value: Today() - 90 days }, end: FHIR.dateTime { value: Today() - 90 days } }"
                 }
               ]
             }
           }
         },
         "item3": {
           "response": {
             "status": "200 OK"
           },
           "resource": {
             "resourceType": "Observation",
             "id": "example-rec-10-illicit-drugs-prefetch",
             "status": "final",
             "code": {
               "coding": [
                 {
                   "system": "http://loinc.org",
                   "code": "3426-4",
                   "display": "Tetrahydrocannabinol [Presence] in Urine"
                 }
               ]
             },
             "subject": {
               "reference": "Patient/example-rec-10-illicit-drugs"
             },
             "_effectiveDateTime": {
               "extension": [
                 {
                   "url": "http://hl7.org/fhir/StructureDefinition/cqif-cqlExpression",
                   "valueString": "Today() - 28 days"
                 }
               ]
             },
             "interpretation": {
               "coding": [
                 {
                   "system": "http://hl7.org/fhir/v2/0078",
                   "version": "v2.8.2",
                   "code": "POS",
                   "display": "Tetrahydrocannabinol [Presence] in Urine"
                 }
               ]
             }
           }
         },
         "item4": {
           "response": {
             "status": "200 OK"
           },
           "resource": {
             "resourceType": "Patient",
             "id": "example-rec-10-illicit-drugs",
             "gender": "female",
             "birthDate": "1982-01-07",
             "name": [
               {
                 "family": "Smith",
                 "given": [
                   "John",
                   "A."
                 ]
               }
             ]
           }
         },
         "item5": {
           "resourceType": "MedicationRequest",
           "id": "example-rec-10-illicit-drugs-context",
           "status": "active",
           "intent": "order",
           "category": {
             "coding": [
               {
                 "system": "http://hl7.org/fhir/medication-request-category",
                 "code": "outpatient"
               }
             ]
           },
           "medicationCodeableConcept": {
             "coding": [
               {
                 "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                 "code": "197696",
                 "display": "72 HR Fentanyl 0.075 MG/HR Transdermal System"
               }
             ]
           },
           "subject": {
             "reference": "Patient/example-rec-10-illicit-drugs"
           },
           "context": {
             "reference": "Encounter/example-rec-10-illicit-drugs-context"
           },
           "_authoredOn": {
             "extension": [
               {
                 "url": "http://hl7.org/fhir/StructureDefinition/cqif-cqlExpression",
                 "valueString": "Today()"
               }
             ]
           },
           "dosageInstruction": [
             {
               "timing": {
                 "repeat": {
                   "frequency": 1,
                   "period": 12.0,
                   "periodUnit": "d"
                 }
               },
               "asNeededBoolean": false,
               "doseQuantity": {
                 "value": 1.0,
                 "unit": "patch"
               }
             }
           ],
           "dispenseRequest": {
             "validityPeriod": {
               "extension": [
                 {
                   "url": "http://hl7.org/fhir/StructureDefinition/cqif-cqlExpression",
                   "valueString": "FHIR.Period { start: FHIR.dateTime { value: Today() }, end: FHIR.dateTime { value: Today() + 3 months } }"
                 }
               ]
             },
             "numberOfRepeatsAllowed": 3,
             "expectedSupplyDuration": {
               "value": 30.0,
               "unit": "d"
             }
           }
         },
         "item6": null,
         "item7": null,
         "item8": null,
         "item9": null,
         "item10": null,
         "item11": null,
         "item12": null,
         "item13": null,
         "item14": null,
         "item15": null
       }
     };
}