Feature: Ordering books
  A customer orders books from the catalogue, and the shop
  never sells a copy it does not have.

  Background:
    Given the customer "ana" has signed in

  Scenario: An order takes copies out of stock
    Given "The War of the Worlds" has 5 copies in stock
    When she orders 2 copies of "The War of the Worlds"
    Then the order is accepted with a total of 6400 cents
    And "The War of the Worlds" has 3 copies in stock

  Scenario: An order for more copies than the shop has is refused
    Given "Persuasion" has 5 copies in stock
    When she orders 6 copies of "Persuasion"
    Then the order is refused as out of stock
    And "Persuasion" has 5 copies in stock
