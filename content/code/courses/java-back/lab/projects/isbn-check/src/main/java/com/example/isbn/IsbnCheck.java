package com.example.isbn;

import org.apache.commons.validator.routines.ISBNValidator;

public class IsbnCheck {

    private static final ISBNValidator ISBN = ISBNValidator.getInstance();

    public static String verdict(String text) {
        String isbn13 = ISBN.validate(text);
        return isbn13 == null ? "invalid" : "valid, ISBN-13 " + isbn13;
    }

    public static void main(String[] args) {
        for (String arg : args) {
            System.out.println(arg + ": " + verdict(arg));
        }
    }
}
