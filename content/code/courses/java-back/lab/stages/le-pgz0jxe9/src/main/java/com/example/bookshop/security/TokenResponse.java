package com.example.bookshop.security;

public record TokenResponse(String accessToken, String tokenType, long expiresIn) {
}
