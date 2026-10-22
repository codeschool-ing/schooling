Feature: Ordering books
  A customer orders books from the catalogue, and the shop
  never sells a copy it does not have.

  Background:
    Given the customer "ana" has signed in

  Scenario: An order takes copies out of stock
    Given the shop has 5 copies of "The War of the Worlds"
    When she orders 2 copies of "The War of the Worlds"
    Then the order is accepted with a total of 6400 cents
    And "The War of the Worlds" has 3 copies left

  Scenario Outline: An order for more copies than the shop has is refused
    Given the shop has <stock> copies of "Persuasion"
    When she orders <ordered> copies of "Persuasion"
    Then the order is refused as out of stock
    And "Persuasion" has <stock> copies left

    Examples:
      | stock | ordered |
      | 5     | 6       |
      | 0     | 2       |
