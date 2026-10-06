---
title: Choosing inputs at the edges
version: 1
---

A test checks the inputs you gave it and no others, so **choosing the inputs is most of writing a
test.** Two techniques do most of the work, and both come from the same observation: bugs gather
where behaviour changes.

## Equivalence classes

Split the possible inputs into groups the code should treat the same way. For the free-shipping
rule there are two groups: subtotals below R$ 199,00, which pay freight, and subtotals of R$ 199,00
or more, which do not. Any value inside a group is as good as any other at telling you whether
that group is handled; testing 5,000 cents and 6,000 cents adds nothing that 5,000 alone did not.

For a CEP the classes are less obvious, and that is the value of listing them: eight digits, eight
digits with a hyphen, too short, too long, with a letter in it. `shipquote` tests one invalid case
that is easy to miss: `0131O-100`, where the fifth character is a capital O, not a zero. A form
that a person typed into produces exactly that.

## Boundary values

Within each class, the values next to the edge are the ones most likely to be wrong, because the
edge is where somebody wrote `>` or `>=`. So test **the last value of one class and the first value
of the next**: 19,899 and 19,900 cents. A third value just past the edge, 19,901, confirms the rule
holds beyond the single point.

To see what that buys, here is the comparison in `freight` changed from `>=` to `>`, the kind of
slip that survives code review because both read like "199 or more":

```
ana@laptop:~/shipquote$ python -m pytest tests/test_quote.py -q
.......F...                                                              [100%]
=================================== FAILURES ===================================
____________ test_an_order_of_199_reais_or_more_ships_free[19900-0] ____________

subtotal = 19900, cents = 0

    @pytest.mark.parametrize("subtotal, cents", [
        (FREE_FROM - 1, 1290),
        (FREE_FROM, 0),
        (FREE_FROM + 1, 0),
    ])
    def test_an_order_of_199_reais_or_more_ships_free(subtotal, cents):
>       assert freight("01310-100", 300, subtotal) == cents
E       AssertionError: assert 1290 == 0
E        +  where 1290 = freight('01310-100', 300, 19900)

tests/test_quote.py:27: AssertionError
=========================== short test summary info ============================
FAILED tests/test_quote.py::test_an_order_of_199_reais_or_more_ships_free[19900-0]
1 failed, 10 passed in 0.15s
```

One row of three fails, and it is the row **at** the boundary: an order of exactly R$ 199,00 is now
charged R$ 12,90. The line `where 1290 = freight('01310-100', 300, 19900)` shows the call and what
it returned. A test that used R$ 250,00 as its "free" example would still pass, and so would the
acceptance test of section 08 if it had used a round R$ 200,00. The customer who spends exactly the
advertised amount would find out first.

## A checklist that catches most of it

For any input, ask what the classes are and where they meet. Some edges come up again and again:

| kind of input | values worth trying |
|---|---|
| a number with a threshold | the threshold, one below, one above |
| a quantity | zero, one, the largest allowed, one more than that |
| a text | empty, one character, the maximum length, non-ASCII (`São`) |
| a list | empty, one element, many, duplicates |
| a date or time | midnight, a cut-off hour, a weekend, a time-zone change |

The last row is not decoration. `shipquote` decides the dispatch day by a 14:00 cut-off, and lesson
5 shows that rule passing on one machine and failing on another because of where the machine
thinks it is.

**Edges are also a reason to read the requirement twice.** "Orders over R$ 199,00 ship free" and
"orders of R$ 199,00 or more ship free" differ only at the edge, and only a test at the edge forces
somebody to decide which one the business meant.
