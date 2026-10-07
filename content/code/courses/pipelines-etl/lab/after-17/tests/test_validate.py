"""Unit tests for the price validator: one record in, one decision out."""
from collections import Counter

from validate_prices import check, isbn13_ok


def price(**changes):
    """A record the validator accepts as it is, with some fields changed."""
    rec = {"isbn": "9786574218454", "publisher": "Borda", "list_price_cents": 10490,
           "currency": "BRL", "updated_at": "2026-01-01T05:01:00-03:00"}
    rec.update(changes)
    return rec


def test_a_real_isbn_passes_its_check_digit():
    assert isbn13_ok("9786574218454")


def test_one_wrong_digit_fails_it():
    assert not isbn13_ok("9786574218455")


def test_hyphens_are_removed_and_counted():
    rec, fixed = price(isbn="978-65-7421-845-4"), Counter()
    assert check(rec, fixed) is None
    assert rec["isbn"] == "9786574218454"
    assert fixed == {"isbn written with hyphens": 1}


def test_a_missing_price_is_rejected():
    assert check(price(list_price_cents=None), Counter()) == "price missing"


def test_a_price_with_a_decimal_comma_is_rejected():
    assert check(price(list_price_cents="104,90"), Counter()) == "price '104,90' is not a number"


def test_another_currency_is_rejected_not_converted():
    assert check(price(currency="USD"), Counter()) == "currency 'USD'"


def test_a_price_in_reais_is_not_taken_for_cents():
    assert check(price(list_price_cents=104.9), Counter()) == "price 104.9 is not a whole number of cents"
