package edu.ohsu.dmice.cmp.htn.controller;

import edu.ohsu.dmice.cmp.htn.exception.ConfigurationException;
import edu.ohsu.dmice.cmp.htn.exception.InsertException;
import edu.ohsu.dmice.cmp.htn.exception.RecordNotFoundException;
import edu.ohsu.dmice.cmp.htn.model.QueryResults;
import edu.ohsu.dmice.cmp.htn.model.Config;
import edu.ohsu.dmice.cmp.htn.registry.ConfigRegistry;
import org.apache.commons.dbcp2.*;
import org.apache.commons.pool2.ObjectPool;
import org.apache.commons.pool2.impl.GenericObjectPool;

import javax.sql.DataSource;
import java.sql.*;

public class DatabaseController {
    private static final String DRIVER = "database.driver.class";
    private static final String URL = "database.jdbc.url";

    private static boolean loaded = false;

    private DataSource dataSource = null;

    public DatabaseController() throws ConfigurationException {
        if ( ! loaded ) {
            loadDriver();
            loaded = true;
        }
    }

    public QueryResults select(String sql, Object ... params) throws SQLException, RecordNotFoundException {
        Connection conn = null;
        PreparedStatement stmt = null;

        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            populateParams(stmt, params);

            QueryResults results = new QueryResults(stmt.executeQuery());

            if (results.getRowCount() == 0) {
                throw new RecordNotFoundException();

            } else {
                return results;
            }

        } finally {
            try { if (stmt != null) stmt.close(); } catch (Exception e) { /* handle silently */ }
            try { if (conn != null) conn.close(); } catch (Exception e) { /* handle silently */ }
        }
    }

    /**
     * creates a record, returning the auto-generated ID
     * for INSERT statements not generating an ID, call update instead
     * @param sql
     * @param params
     * @return
     * @throws SQLException
     * @throws InsertException
     */
    public int insert(String sql, Object ... params) throws SQLException, InsertException {
        Connection conn = null;
        PreparedStatement stmt = null;

        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            populateParams(stmt, params);

            stmt.executeUpdate();

            ResultSet rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                return rs.getInt(1);

            } else {
                throw new InsertException();
            }

        } finally {
            try { if (stmt != null) stmt.close(); } catch (Exception e) { /* handle silently */ }
            try { if (conn != null) conn.close(); } catch (Exception e) { /* handle silently */ }
        }
    }

    public int update(String sql, Object ... params) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;

        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            populateParams(stmt, params);

            return stmt.executeUpdate();

        } finally {
            try { if (stmt != null) stmt.close(); } catch (Exception e) { /* handle silently */ }
            try { if (conn != null) conn.close(); } catch (Exception e) { /* handle silently */ }
        }
    }


////////////////////////////////////////////////////////////////
// private methods
//

    private void populateParams(PreparedStatement stmt, Object ... params) throws SQLException {
        if (stmt != null && params != null) {
            for (int i = 0; i < params.length; i ++) {
                stmt.setObject(i + 1, params[i]);
            }
        }
    }

    private Connection getConnection() throws SQLException {
        if (dataSource == null) {
            dataSource = setupDataSource();
        }
        return dataSource.getConnection();
    }

    private DataSource setupDataSource() {
        Config config = ConfigRegistry.getInstance().getConfig();
        ConnectionFactory connectionFactory = new DriverManagerConnectionFactory(config.getProperty(URL), null);
        PoolableConnectionFactory poolableConnectionFactory = new PoolableConnectionFactory(connectionFactory, null);
        ObjectPool<PoolableConnection> connectionPool = new GenericObjectPool<>(poolableConnectionFactory);
        poolableConnectionFactory.setPool(connectionPool);
        return new PoolingDataSource<>(connectionPool);
    }

    private void loadDriver() throws ConfigurationException {
        try {
            Config config = ConfigRegistry.getInstance().getConfig();
            Class.forName(config.getProperty(DRIVER));

        } catch (ClassNotFoundException e) {
            throw new ConfigurationException("invalid JDBC driver", e);
        }
    }
}
