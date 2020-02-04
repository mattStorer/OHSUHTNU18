package edu.ohsu.dmice.cmp.htn.model;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class Config {
    private Properties props;

    public Config(String filename) throws IOException {
        loadProperties(filename);
    }

    public String getProperty(String key) {
        return props.getProperty(key);
    }

    private void loadProperties(String filename) throws IOException {
        FileInputStream fis = null;
        try {
            fis = new FileInputStream(filename);
            props = new Properties();
            props.load(fis);

        } finally {
            if (fis != null) fis.close();
        }
    }
}
