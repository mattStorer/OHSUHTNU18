package edu.ohsu.dmice.cmp.htn.model;

import edu.ohsu.dmice.cmp.htn.exception.DataException;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;

public class QueryResults {
    private static final DateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    private List<String> columnNames;
    private List<RowData> data;

    public QueryResults(ResultSet rs) throws SQLException {
        ResultSetMetaData metaData = rs.getMetaData();

        columnNames = new ArrayList<String>();
        for (int i = 0; i < metaData.getColumnCount(); i ++) {
            columnNames.add(metaData.getColumnLabel(i + 1));
        }

        data = new ArrayList<RowData>();
        while (rs.next()) {
            List<String> list = new ArrayList<String>();
            for (int i = 0; i < metaData.getColumnCount(); i ++) {
                Object o = rs.getObject(i + 1);
                if (o == null) {
                    list.add(null);

                } else {
                    list.add(String.valueOf(o).trim());
                }
            }
            data.add(new RowData(columnNames, list));
        }
    }

    public int getColumnCount() {
        return columnNames.size();
    }

    public List<String> getColumnNames() {
        return columnNames;
    }

    public int getRowCount() {
        return data.size();
    }

    public RowData getRowData(int index) {
        return data.get(index);
    }

    public List<RowData> getRowData() {
        return data;
    }

    public static final class RowData {
        private Map<String, String> map;

        private RowData(List<String> columnNames, List<String> data) {
            map = new LinkedHashMap<String, String>();
            for (int i = 0; i < columnNames.size(); i ++) {
                map.put(columnNames.get(i), data.get(i));
            }
        }

        public List<String> getColumnNames() {
            return new ArrayList<String>(map.keySet());
        }

        public Integer getInt(String columnName) throws DataException {
            String s = getString(columnName);
            return s == null ?
                    null :
                    Integer.valueOf(s);
        }

        public Boolean getBoolean(String columnName) throws DataException {
            String s = getString(columnName);
            return s == null ?
                    null :
                    s.equals("1") || s.equalsIgnoreCase("true");
        }

        public Date getDate(String columnName) throws DataException {
            try {
                String s = getString(columnName);
                return s == null ?
                        null :
                        DATE_FORMAT.parse(getString(columnName));

            } catch (ParseException e) {
                throw new DataException("error parsing date for column=" + columnName, e);
            }
        }

        // todo : implement other parse methods

        public String getString(String columnName) throws DataException {
            if (map.containsKey(columnName)) {
                return map.get(columnName);

            } else {
                throw new DataException("invalid column: " + columnName);
            }
        }
    }
}
