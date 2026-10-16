---
title: What not to assert
version: 1
---

**A test should fail when the API is wrong, and only then.** A test that also fails when the clock
moves, when another test ran first, or when the server adds a harmless field is a test people learn to
ignore, and an ignored test catches nothing. The usual cause is asserting on something the API never
promised.

This collection gets it wrong on purpose, three times. Save it as `postman/brittle.postman_collection.json`:

```json
{
  "info": {
    "name": "brittle",
    "description": "Three assertions that pass once and never again.",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "auth": {"type": "bearer", "bearer": [{"key": "token", "value": "{{token}}", "type": "string"}]},
  "item": [
    {
      "name": "Get token",
      "event": [
        {
          "listen": "test",
          "script": {
            "type": "text/javascript",
            "exec": ["pm.collectionVariables.set('token', pm.response.json().access_token);"]
          }
        }
      ],
      "request": {
        "method": "POST",
        "url": "{{baseUrl}}/oauth/token",
        "body": {
          "mode": "urlencoded",
          "urlencoded": [
            {"key": "grant_type", "value": "client_credentials"},
            {"key": "client_id", "value": "{{clientId}}"},
            {"key": "client_secret", "value": "{{clientSecret}}"}
          ]
        },
        "auth": {"type": "noauth"}
      }
    },
    {
      "name": "Create order",
      "event": [
        {
          "listen": "test",
          "script": {
            "type": "text/javascript",
            "exec": [
              "pm.test('the order is ord-1001', () => {",
              "  pm.expect(pm.response.json().id).to.equal('ord-1001');",
              "});",
              "pm.test('the body is exactly this', () => {",
              "  pm.expect(pm.response.json()).to.eql({",
              "    id: 'ord-1001', show_id: 'sh-103', seats: 1, total_cents: 6500,",
              "    status: 'confirmed', payment: 'ch-local-ord-1001',",
              "  });",
              "});",
              "pm.test('it was answered today', () => {",
              "  pm.expect(pm.response.headers.get('Date')).to.include('10 Oct 2026');",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "url": "{{baseUrl}}/v1/orders",
        "header": [{"key": "Content-Type", "value": "application/json"}],
        "body": {
          "mode": "raw",
          "raw": "{\"show_id\": \"sh-103\", \"seats\": 1}",
          "options": {"raw": {"language": "json"}}
        }
      }
    }
  ]
}
```

Restart boxoffice in its terminal, so it has no orders, and run it twice:

```
ana@laptop:~/boxoffice$ npx --yes newman@6.2.3 run postman/brittle.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode
newman

brittle

Root Get token
  POST http://localhost:8080/oauth/token [200 OK, 479B, 36ms]

Root Create order
  POST http://localhost:8080/v1/orders [201 Created, 316B, 5ms]
  Pass  the order is ord-1001
  Pass  the body is exactly this
  1. it was answered today

-----------------------------------------------------------------
|                         |         executed |           failed |
--------------------------+------------------+-------------------
|              iterations |                1 |                0 |
--------------------------+------------------+-------------------
|                requests |                2 |                0 |
--------------------------+------------------+-------------------
|            test-scripts |                2 |                0 |
--------------------------+------------------+-------------------
|      prerequest-scripts |                0 |                0 |
--------------------------+------------------+-------------------
|              assertions |                3 |                1 |
-----------------------------------------------------------------
| total run duration: 110ms                                     |
-----------------------------------------------------------------
| total data received: 408B (approx)                            |
-----------------------------------------------------------------
| average response time: 20ms [min: 5ms, max: 36ms, s.d.: 15ms] |
-----------------------------------------------------------------

  #  failure         detail                                                            
                                                                                       
 1.  AssertionError  it was answered today                                             
                     expected 'Sun, 11 Oct 2026 01:39:17 GMT' to include '10 Oct 2026' 
                     at assertion:2 in test-script                                     
                     inside "Create order"                                             
```

```
ana@laptop:~/boxoffice$ npx --yes newman@6.2.3 run postman/brittle.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode
newman

brittle

Root Get token
  POST http://localhost:8080/oauth/token [200 OK, 479B, 19ms]

Root Create order
  POST http://localhost:8080/v1/orders [201 Created, 316B, 5ms]
  1. the order is ord-1001
  2. the body is exactly this
  3. it was answered today

----------------------------------------------------------------
|                         |         executed |          failed |
--------------------------+------------------+------------------
|              iterations |                1 |               0 |
--------------------------+------------------+------------------
|                requests |                2 |               0 |
--------------------------+------------------+------------------
|            test-scripts |                2 |               0 |
--------------------------+------------------+------------------
|      prerequest-scripts |                0 |               0 |
--------------------------+------------------+------------------
|              assertions |                3 |               3 |
----------------------------------------------------------------
| total run duration: 85ms                                     |
----------------------------------------------------------------
| total data received: 408B (approx)                           |
----------------------------------------------------------------
| average response time: 12ms [min: 5ms, max: 19ms, s.d.: 7ms] |
----------------------------------------------------------------

  #  failure         detail                                                                     
                                                                                                
 1.  AssertionError  the order is ord-1001                                                      
                     expected 'ord-1002' to equal 'ord-1001'                                    
                     at assertion:0 in test-script                                              
                     inside "Create order"                                                      
                                                                                                
 2.  AssertionError  the body is exactly this                                                   
                     expected { id: 'ord-1002', …(5) } to deeply equal { id: 'ord-1001', …(5) } 
                     at assertion:1 in test-script                                              
                     inside "Create order"                                                      
                                                                                                
 3.  AssertionError  it was answered today                                                      
                     expected 'Sun, 11 Oct 2026 01:39:18 GMT' to include '10 Oct 2026'          
                     at assertion:2 in test-script                                              
                     inside "Create order"                                                      
```

The first run passes everything. The second run, moments later against the same server, fails two of
the three, and the API did nothing wrong in between.

## The order id

`ord-1001` is the id of the first order after a restart, and nothing more. boxoffice promises that an
order gets an id and that `location` says where it lives; it never promised which id. The second run
was given `ord-1002`, because the first run's order exists. Any test that runs after another test, in
the same run or on the same server, sees a different number. **Assert the shape, and read the value
from the answer**: an id that matches `/^ord-\d+$/`, and the request after it using `location`, as
section 04 does.

## The whole body

`eql` against the whole body repeats the id problem in every field, and adds one of its own: it fails
the day boxoffice adds a field, such as a `created_at`, that no client reads. **Assert the fields the
test is about.** The collection's Create order checks `show_id`, `seats` and `status`, because those
are what the request asked for. `total_cents` and `payment` deserve tests too, but tests of their own,
with names that say what rule they check: the price times the seats, the payment's reference.

## The Date header

The third test passed both times, and it is the worst of the three. It checks that the `Date` header
contains `10 Oct 2026`, which is true on the day the transcripts were recorded and false on every
other: **a student running it today sees it fail on the first run.** `Date` is when the server
answered. A test may check that it exists and parses as a date; its value belongs to the clock.

## The same rule, in four lines

| do not assert | because | assert instead |
|---|---|---|
| an id generated by the server | it depends on what ran before | its shape, then use it |
| the whole body with `eql` | any new field breaks it | the fields the test is about |
| `Date`, or any time | it depends on the clock | that it exists, or a range |
| a count of everything, such as all orders | other tests add to it | what this test created |

The collection still asserts that there are shows and that every one carries a whole number of seats left. It does not
assert that there are exactly three, which is true of boxoffice today and would fail on the day the
theatre adds a show, with nothing broken.
