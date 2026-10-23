package com.example.bookshop.catalogue;

public final class Isbn {

    private Isbn() {
    }

    /** True when the text is thirteen digits whose last one is the ISBN-13 check digit. */
    public static boolean isValid(String text) {
        if (text == null || !text.matches("\\d{13}")) {
            return false;
        }
        int sum = 0;
        for (int i = 0; i < 12; i++) {
            int digit = text.charAt(i) - '0';
            sum += (i % 2 == 0) ? digit : digit * 3;
        }
        int check = (10 - sum % 10) % 10;
        return check == text.charAt(12) - '0';
    }
}
