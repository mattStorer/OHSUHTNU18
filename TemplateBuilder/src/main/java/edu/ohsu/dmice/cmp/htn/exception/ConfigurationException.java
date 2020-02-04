package edu.ohsu.dmice.cmp.htn.exception;

/**
 * Exception to be thrown when the system's configuration is requested but has not been instantiated
 */
public class ConfigurationException extends RuntimeException {
    public ConfigurationException() {
        super();
    }

    public ConfigurationException(String message) {
        super(message);
    }

    public ConfigurationException(String message, Throwable cause) {
        super(message, cause);
    }
}
