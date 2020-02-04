package edu.ohsu.dmice.cmp.htn;

import edu.ohsu.dmice.cmp.htn.controller.DatabaseController;
import edu.ohsu.dmice.cmp.htn.exception.DataException;
import edu.ohsu.dmice.cmp.htn.model.Config;
import edu.ohsu.dmice.cmp.htn.model.QueryResults;
import edu.ohsu.dmice.cmp.htn.model.Template;
import edu.ohsu.dmice.cmp.htn.registry.ConfigRegistry;

import java.io.*;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

public class TemplateBuilder {
    private static final Pattern VARIABLE_PATTERN = Pattern.compile("\\$\\{([a-zA-Z][a-zA-Z0-9_]*)\\}");

    private static final String PATIENT_QUERY = "select pat_study_id as patientId, given_name as givenName, family_name as familyName, gender, date_format(birth_date, \"%Y-%m-%d\") as dobShortFormat, date_format(birth_date, \"%e %M %Y\") as dobLongFormat, date(now()) as lastUpdatedDate, time(now()) as lastUpdatedTime from patient";

    private static final String ENCOUNTER_QUERY = "select pat_enc_csn_study_id as encounterId, pat_study_id as patientId, date(start_date) as encBeginDate, time(start_date) as encBeginTime, date(end_date) as encEndDate, time(end_date) as encEndTime, date(now()) as lastUpdatedDate, time(now()) as lastUpdatedTime from encounter where pat_study_id=?";

    private static final String BP_QUERY = "select concat(\"OHSUHTNU18-\", id) as observationId, pat_study_id as patientId, pat_enc_csn_study_id as encounterId, date(recorded_time) as effectiveDate, time(recorded_time) as effectiveTime, date(now()) as lastUpdatedDate, time(now()) as lastUpdatedTime, substring_index(meas_value, '/', 1) as systolic, substring_index(meas_value, '/', -1) as diastolic from bpdata where pat_study_id=? and meas_value is not null";

    private Config config;
    private DatabaseController dbc;
    private Template bundleTemplate;
    private Template patientTemplate;
    private Template encounterTemplate;
    private Template bpTemplate;
    private boolean dirsMade = false;

    public TemplateBuilder() throws IOException {
        config = ConfigRegistry.getInstance().getConfig();
        dbc = new DatabaseController();
        bundleTemplate = new Template(config.getProperty("template.file.bundle"));
        patientTemplate = new Template(config.getProperty("template.file.patient"));
        encounterTemplate = new Template(config.getProperty("template.file.encounter"));
        bpTemplate = new Template(config.getProperty("template.file.bp"));
    }

    public void execute() throws IOException, DataException, SQLException {
        dirsMade = false;
        int thresholdFileSizeToBreak = Integer.parseInt(config.getProperty("output.filesize.threshold.bytes"));
        int fileCounter = 0;
        int fileSize = 0;
        List<String> resources = new ArrayList<String>();

        QueryResults patients = dbc.select(PATIENT_QUERY);
        for (int i = 0; i < patients.getRowCount(); i ++) {
            QueryResults.RowData currentPatient = patients.getRowData(i);
            String patientId = currentPatient.getString("patientId");

            String t = patientTemplate.populate(currentPatient);
            fileSize += t.length();
            resources.add(t);

            QueryResults encounters = dbc.select(ENCOUNTER_QUERY, patientId);
            for (int j = 0; j < encounters.getRowCount(); j ++) {
                t = encounterTemplate.populate(encounters.getRowData(j));
                fileSize += t.length();
                resources.add(t);
            }

            QueryResults bps = dbc.select(BP_QUERY, patientId);
            for (int j = 0; j < bps.getRowCount(); j ++) {
                t = bpTemplate.populate(bps.getRowData(j));
                fileSize += t.length();
                resources.add(t);
            }

            if (fileSize >= thresholdFileSizeToBreak) {
                writeOutput(fileCounter, resources);

                // reset
                resources.clear();
                fileSize = 0;
                fileCounter ++;
            }
        }

        if (resources.size() > 0) {
            writeOutput(fileCounter, resources);
        }
    }

    private void writeOutput(int fileCounter, List<String> resources) throws IOException {
        String outputFilename = config.getProperty("output.file");
        if (fileCounter > 0) {
            int pos = outputFilename.lastIndexOf('.');
            outputFilename = outputFilename.substring(0, pos) + "-" + fileCounter + outputFilename.substring(pos);
        }

        Map<String, String> params = new HashMap<String, String>();
        params.put("resources", String.join(",", resources));

        if ( ! dirsMade ) {
            int lastSlashPos = outputFilename.lastIndexOf('/');
            if (lastSlashPos > 0) {
                File f = new File(outputFilename.substring(0, lastSlashPos));
                if ( ! f.isDirectory() ) {
                    f.mkdirs();
                }
            }
            dirsMade = true;
        }

        OutputStream out = new BufferedOutputStream(new FileOutputStream(outputFilename));
        out.write(bundleTemplate.populate(params).getBytes());
        out.close();
    }
}
