package com.example.bookshop.web;

import java.net.URI;
import java.util.Map;
import java.util.TreeMap;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import com.example.bookshop.catalogue.BookNotFoundException;
import com.example.bookshop.catalogue.DuplicateIsbnException;

@RestControllerAdvice
public class ApiErrorHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(BookNotFoundException.class)
    public ProblemDetail notFound(BookNotFoundException e) {
        return problem(HttpStatus.NOT_FOUND, "book-not-found", "Book not found", e.getMessage());
    }

    @ExceptionHandler(DuplicateIsbnException.class)
    public ProblemDetail duplicate(DuplicateIsbnException e) {
        return problem(HttpStatus.CONFLICT, "duplicate-isbn", "Duplicate ISBN", e.getMessage());
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException e, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        Map<String, String> errors = new TreeMap<>();
        e.getBindingResult().getFieldErrors()
                .forEach(f -> errors.put(f.getField(), f.getDefaultMessage()));
        ProblemDetail body = problem(HttpStatus.BAD_REQUEST, "invalid-request", "Invalid request",
                errors.size() + " field(s) failed validation");
        body.setProperty("errors", errors);
        return ResponseEntity.badRequest().body(body);
    }

    private static ProblemDetail problem(HttpStatus status, String type, String title, String detail) {
        ProblemDetail body = ProblemDetail.forStatusAndDetail(status, detail);
        body.setType(URI.create("https://bookshop.example/problems/" + type));
        body.setTitle(title);
        return body;
    }
}
