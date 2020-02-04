package edu.ohsu.dmice.cmp.htn.model;

import edu.ohsu.dmice.cmp.htn.exception.DataException;
import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;
import java.util.Map;

public class Template {
    private static final String VAR_OPEN = "\\$\\{";
    private static final String VAR_CLOSE = "}";
    private static final String VAR_REGEX_STR = VAR_OPEN + "([a-z][a-zA-Z0-9_]*)" + VAR_CLOSE;

    private String templateText = null;

    public Template(String filename) throws IOException {
        templateText = new String(FileUtils.readFileToByteArray(new File(filename)));
    }

    public String populate(QueryResults.RowData rd) throws DataException {
        String text = templateText;
        for (String field : rd.getColumnNames()) {
            text = text.replaceAll(VAR_OPEN + field + VAR_CLOSE, rd.getString(field));
        }
        return text;
    }

    public String populate(Map<String, String> map) {
        String text = templateText;
        for (Map.Entry<String, String> entry : map.entrySet()) {
            text = text.replaceAll(VAR_OPEN + entry.getKey() + VAR_CLOSE, entry.getValue());
        }
        return text;
    }
}
