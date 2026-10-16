package com.example.bookshop.ordering;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record OrderRequest(@NotEmpty List<@Valid Line> lines) {

    public record Line(@NotNull Long bookId, @Positive int quantity) {
    }
}
