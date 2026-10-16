package com.example.bookshop.security;

import java.time.Duration;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties("bookshop.jwt")
public record JwtProperties(@NotNull @Size(min = 32) String secret, @NotNull Duration lifetime) {
}
