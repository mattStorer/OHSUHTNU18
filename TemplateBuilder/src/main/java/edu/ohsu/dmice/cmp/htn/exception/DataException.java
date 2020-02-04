package edu.ohsu.dmice.cmp.htn.exception;

public class DataException extends Exception {
    public DataException() {
        super();
    }

    public DataException(String message) {
        super(message);
    }

    public DataException(String message, Throwable cause) {
        super(message, cause);
    }
}
