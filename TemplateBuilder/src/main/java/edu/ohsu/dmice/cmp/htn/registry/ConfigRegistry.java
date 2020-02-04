package edu.ohsu.dmice.cmp.htn.registry;

import edu.ohsu.dmice.cmp.htn.exception.ConfigurationException;
import edu.ohsu.dmice.cmp.htn.model.Config;

public class ConfigRegistry {
    private static ConfigRegistry registry = null;

    public static ConfigRegistry getInstance() {
        if (registry == null) registry = new ConfigRegistry();
        return registry;
    }

    private Config config = null;

    private ConfigRegistry() {
    }

    public Config getConfig() {
        if (config == null) {
            throw new ConfigurationException();

        } else {
            return config;
        }
    }

    public void setConfig(Config config) {
        this.config = config;
    }
}
