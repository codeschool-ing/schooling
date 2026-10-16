package com.example.bookshop;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
class BooksApiIT {

    @LocalServerPort
    int port;

    @BeforeEach
    void pointRestAssuredAtTheServer() {
        RestAssured.port = port;
    }

    @Test
    void anyoneCanReadABook() {
        given()
            .accept(ContentType.JSON)
        .when()
            .get("/books/{id}", 1)
        .then()
            .statusCode(200)
            .body("title", equalTo("Dom Casmurro"))
            .body("author", equalTo("Machado de Assis"));
    }

    @Test
    void anUnknownBookIsAProblemDetail() {
        given()
            .accept(ContentType.JSON)
        .when()
            .get("/books/{id}", 999)
        .then()
            .statusCode(404)
            .contentType("application/problem+json")
            .body("title", equalTo("Book not found"));
    }

    @Test
    void addingABookNeedsAToken() {
        given()
            .contentType(ContentType.JSON)
            .body("""
                {"isbn": "9786500000078", "title": "Emma", "author": "Jane Austen",
                 "priceCents": 3300, "stock": 3}""")
        .when()
            .post("/books")
        .then()
            .statusCode(401);
    }

    @Test
    void aCustomerWithATokenCanPlaceAnOrder() {
        String token =
            given()
                .auth().preemptive().basic("ana", "ana-reads-books")
            .when()
                .post("/auth/token")
            .then()
                .statusCode(200)
                .extract().path("accessToken");

        given()
            .auth().oauth2(token)
            .contentType(ContentType.JSON)
            .body("""
                {"lines": [{"bookId": 2, "quantity": 1}]}""")
        .when()
            .post("/orders")
        .then()
            .statusCode(201)
            .body("customer", equalTo("ana"))
            .body("lines", hasSize(1))
            .body("totalCents", equalTo(2950));
    }
}
