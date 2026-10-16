package com.example.bookshop.acceptance;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;

import io.cucumber.java.Before;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;

import org.springframework.boot.test.web.server.LocalServerPort;

public class OrderingSteps {

    private static final Map<String, String> PASSWORDS = Map.of("ana", "ana-reads-books");

    @LocalServerPort
    int port;

    private String token;
    private Response lastOrder;

    @Before
    public void pointRestAssuredAtTheServer() {
        RestAssured.port = port;
    }

    @Given("the customer {string} has signed in")
    public void theCustomerHasSignedIn(String name) {
        token = given().auth().preemptive().basic(name, PASSWORDS.get(name))
                .post("/auth/token")
                .then().statusCode(200)
                .extract().path("accessToken");
    }

    @Given("{string} has {int} copies in stock")
    public void hasCopiesInStock(String title, int copies) {
        assertThat(book(title).<Integer>path("stock")).isEqualTo(copies);
    }

    @When("she orders {int} copies of {string}")
    public void sheOrders(int quantity, String title) {
        int bookId = book(title).path("id");
        lastOrder = given().auth().oauth2(token)
                .contentType(ContentType.JSON)
                .body("{\"lines\": [{\"bookId\": " + bookId + ", \"quantity\": " + quantity + "}]}")
                .post("/orders");
    }

    @Then("the order is accepted with a total of {int} cents")
    public void theOrderIsAccepted(int total) {
        assertThat(lastOrder.statusCode()).isEqualTo(201);
        assertThat(lastOrder.<Integer>path("totalCents")).isEqualTo(total);
    }

    @Then("the order is refused as out of stock")
    public void theOrderIsRefused() {
        assertThat(lastOrder.statusCode()).isEqualTo(409);
        assertThat(lastOrder.<String>path("title")).isEqualTo("Out of stock");
    }

    private Response book(String title) {
        Response found = given().queryParam("q", title).get("/books/search");
        found.then().statusCode(200);
        return given().get("/books/{id}", found.<Integer>path("[0].id"));
    }
}
