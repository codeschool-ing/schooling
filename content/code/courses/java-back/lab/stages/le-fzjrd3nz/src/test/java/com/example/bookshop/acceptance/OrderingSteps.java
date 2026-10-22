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
import org.springframework.jdbc.core.simple.JdbcClient;

public class OrderingSteps {

    private static final Map<String, String> PASSWORDS = Map.of("ana", "ana-reads-books");

    private final JdbcClient jdbc;
    private final int port;

    private String token;
    private Response lastOrder;

    public OrderingSteps(JdbcClient jdbc, @LocalServerPort int port) {
        this.jdbc = jdbc;
        this.port = port;
    }

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

    @Given("the shop has {int} copies of {string}")
    public void theShopHas(int copies, String title) {
        int rows = jdbc.sql("UPDATE book SET stock = ? WHERE title = ?")
                .params(copies, title)
                .update();
        assertThat(rows).as("books titled %s", title).isEqualTo(1);
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

    @Then("{string} has {int} copies left")
    public void hasCopiesLeft(String title, int copies) {
        assertThat(book(title).<Integer>path("stock")).isEqualTo(copies);
    }

    private Response book(String title) {
        Response found = given().queryParam("q", title).get("/books/search");
        found.then().statusCode(200);
        return given().get("/books/{id}", found.<Integer>path("[0].id"));
    }
}
