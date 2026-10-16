---
title: The collection, now with tests
version: 1
---

**A test in Postman is a few lines of JavaScript attached to a request, run after its answer
arrives.** The request is the same as in lesson 4; the script reads the answer and says, by name,
what was right and what was not. This section gives you the whole collection with its scripts and
runs it. The four sections after it take the scripts apart.

It replaces the file of lesson 4, so save it as `postman/boxoffice.postman_collection.json`:

```json
{
  "info": {
    "name": "boxoffice",
    "description": "The ticket API of lessons 4 to 6, one request per thing a tester asks it.",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "auth": {"type": "bearer", "bearer": [{"key": "token", "value": "{{token}}", "type": "string"}]},
  "event": [
    {
      "listen": "prerequest",
      "script": {
        "type": "text/javascript",
        "exec": [
          "// Before every request: fetch a token when there is none, or when it has expired.",
          "const expires = Number(pm.collectionVariables.get('tokenExpires') || 0);",
          "if (!pm.collectionVariables.get('token') || Date.now() >= expires) {",
          "  pm.sendRequest({",
          "    url: pm.variables.replaceIn('{{baseUrl}}/oauth/token'),",
          "    method: 'POST',",
          "    body: {",
          "      mode: 'urlencoded',",
          "      urlencoded: [",
          "        { key: 'grant_type', value: 'client_credentials' },",
          "        { key: 'client_id', value: pm.variables.get('clientId') },",
          "        { key: 'client_secret', value: pm.variables.get('clientSecret') },",
          "      ],",
          "    },",
          "  }, (err, res) => {",
          "    if (err || res.code !== 200) {",
          "      throw new Error(`no token: ${err ? err.message : res.code}`);",
          "    }",
          "    const body = res.json();",
          "    pm.collectionVariables.set('token', body.access_token);",
          "    pm.collectionVariables.set('tokenExpires', Date.now() + (body.expires_in - 30) * 1000);",
          "  });",
          "}"
        ]
      }
    }
  ],
  "variable": [
    {"key": "showId", "value": "sh-103"},
    {"key": "seats", "value": "1"},
    {"key": "expected", "value": "201"}
  ],
  "item": [
    {
      "name": "shows",
      "auth": {"type": "noauth"},
      "item": [
        {
          "name": "List shows",
          "event": [
            {
              "listen": "test",
              "script": {
                "type": "text/javascript",
                "exec": [
                  "pm.test('status is 200', () => {",
                  "  pm.response.to.have.status(200);",
                  "});",
                  "pm.test('the body is JSON', () => {",
                  "  pm.response.to.have.header('content-type', 'application/json');",
                  "});",
                  "pm.test('every show has a whole number of seats left', () => {",
                  "  const { shows } = pm.response.json();",
                  "  pm.expect(shows).to.be.an('array').that.is.not.empty;",
                  "  shows.forEach((show) => pm.expect(show.seats_left).to.be.a('number').and.satisfy(Number.isInteger));",
                  "});"
                ]
              }
            }
          ],
          "request": {"method": "GET", "url": "{{baseUrl}}/v1/shows"}
        },
        {
          "name": "One show",
          "event": [
            {
              "listen": "test",
              "script": {
                "type": "text/javascript",
                "exec": [
                  "pm.test('status is 200', () => {",
                  "  pm.response.to.have.status(200);",
                  "});",
                  "pm.test('it is the show asked for', () => {",
                  "  pm.expect(pm.response.json().id).to.equal(pm.variables.get('showId'));",
                  "});",
                  "pm.test('it carries an etag', () => {",
                  "  pm.response.to.have.header('etag');",
                  "});"
                ]
              }
            }
          ],
          "request": {"method": "GET", "url": "{{baseUrl}}/v1/shows/{{showId}}"}
        },
        {
          "name": "HEAD one show",
          "event": [
            {
              "listen": "test",
              "script": {
                "type": "text/javascript",
                "exec": [
                  "// RFC 9110 9.1: every general-purpose server supports GET and HEAD.",
                  "pm.test('HEAD answers like GET', () => {",
                  "  pm.response.to.have.status(200);",
                  "});"
                ]
              }
            }
          ],
          "request": {"method": "HEAD", "url": "{{baseUrl}}/v1/shows/{{showId}}"}
        }
      ]
    },
    {
      "name": "auth",
      "auth": {"type": "noauth"},
      "item": [
        {
          "name": "Get token",
          "event": [
            {
              "listen": "test",
              "script": {
                "type": "text/javascript",
                "exec": [
                  "pm.test('status is 200', () => {",
                  "  pm.response.to.have.status(200);",
                  "});",
                  "const body = pm.response.json();",
                  "pm.test('a bearer token comes back', () => {",
                  "  pm.expect(body.token_type).to.equal('Bearer');",
                  "  pm.expect(body.access_token.split('.')).to.have.lengthOf(3);",
                  "});",
                  "pm.test('nobody may keep a copy of it', () => {",
                  "  pm.response.to.have.header('cache-control', 'no-store');",
                  "});",
                  "pm.collectionVariables.set('token', body.access_token);",
                  "pm.collectionVariables.set('tokenExpires', Date.now() + (body.expires_in - 30) * 1000);"
                ]
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
            }
          }
        }
      ]
    },
    {
      "name": "orders",
      "item": [
        {
          "name": "Create order",
          "event": [
            {
              "listen": "prerequest",
              "script": {
                "type": "text/javascript",
                "exec": ["pm.variables.set('idempotencyKey', pm.variables.replaceIn('{{$guid}}'));"]
              }
            },
            {
              "listen": "test",
              "script": {
                "type": "text/javascript",
                "exec": [
                  "pm.test('status is 201', () => {",
                  "  pm.response.to.have.status(201);",
                  "});",
                  "pm.test('the order is for the show and the seat asked for', () => {",
                  "  const order = pm.response.json();",
                  "  pm.expect(order.show_id).to.equal(pm.variables.get('showId'));",
                  "  pm.expect(order.seats).to.equal(1);",
                  "  pm.expect(order.status).to.equal('confirmed');",
                  "});",
                  "pm.test('location says where it lives', () => {",
                  "  pm.response.to.have.header('location');",
                  "});",
                  "pm.collectionVariables.set('orderUrl', pm.response.headers.get('location'));"
                ]
              }
            }
          ],
          "request": {
            "method": "POST",
            "url": "{{baseUrl}}/v1/orders",
            "header": [
              {"key": "Content-Type", "value": "application/json"},
              {"key": "Idempotency-Key", "value": "{{idempotencyKey}}"}
            ],
            "body": {
              "mode": "raw",
              "raw": "{\"show_id\": \"{{showId}}\", \"seats\": 1}",
              "options": {"raw": {"language": "json"}}
            }
          }
        },
        {
          "name": "Read order",
          "event": [
            {
              "listen": "test",
              "script": {
                "type": "text/javascript",
                "exec": [
                  "pm.test('status is 200', () => {",
                  "  pm.response.to.have.status(200);",
                  "});",
                  "pm.test('it is the order just created', () => {",
                  "  const id = pm.collectionVariables.get('orderUrl').split('/').pop();",
                  "  pm.expect(pm.response.json().id).to.equal(id);",
                  "});"
                ]
              }
            }
          ],
          "request": {"method": "GET", "url": "{{baseUrl}}{{orderUrl}}"}
        },
        {
          "name": "Cancel order",
          "event": [
            {
              "listen": "test",
              "script": {
                "type": "text/javascript",
                "exec": ["pm.test('status is 204', () => {", "  pm.response.to.have.status(204);", "});"]
              }
            }
          ],
          "request": {"method": "DELETE", "url": "{{baseUrl}}{{orderUrl}}"}
        },
        {
          "name": "Read cancelled order",
          "event": [
            {
              "listen": "test",
              "script": {
                "type": "text/javascript",
                "exec": [
                  "pm.test('the order now says cancelled', () => {",
                  "  pm.expect(pm.response.json().status).to.equal('cancelled');",
                  "});"
                ]
              }
            }
          ],
          "request": {"method": "GET", "url": "{{baseUrl}}{{orderUrl}}"}
        }
      ]
    },
    {
      "name": "seat rules",
      "item": [
        {
          "name": "Order seats",
          "event": [
            {
              "listen": "prerequest",
              "script": {
                "type": "text/javascript",
                "exec": ["pm.variables.set('idempotencyKey', pm.variables.replaceIn('{{$guid}}'));"]
              }
            },
            {
              "listen": "test",
              "script": {
                "type": "text/javascript",
                "exec": [
                  "const expected = Number(pm.variables.get('expected'));",
                  "pm.test(`seats ${pm.variables.get('seats')} answers ${expected}`, () => {",
                  "  pm.response.to.have.status(expected);",
                  "});"
                ]
              }
            }
          ],
          "request": {
            "method": "POST",
            "url": "{{baseUrl}}/v1/orders",
            "header": [
              {"key": "Content-Type", "value": "application/json"},
              {"key": "Idempotency-Key", "value": "{{idempotencyKey}}"}
            ],
            "body": {
              "mode": "raw",
              "raw": "{\"show_id\": \"sh-101\", \"seats\": {{seats}}}",
              "options": {"raw": {"language": "json"}}
            }
          }
        }
      ]
    }
  ]
}
```

It is longer for three reasons. Each request carries an `event` with `"listen": "test"`, the script
Postman runs after the response. The collection carries one with `"listen": "prerequest"`, which runs
before every request. And there are three new requests: **HEAD one show**, **Read cancelled order**,
and a fifth folder, `seat rules`, with one request in it. In Postman the scripts appear on each
request's **Scripts** tab, as *Pre-request* and *Post-response*; older versions of the app called the
second one *Tests*, which is why the file still says `test`.

## Running it without the window

Postman's Runner was not captured for this course, for the reason lesson 4 gave. The scripts are run
here by **Newman**, Postman's runner for the command line, which reads the same file and runs the
same scripts with the same library. Lesson 6 is about Newman; for now one command is enough, and
`npx` fetches Newman the first time and keeps it in a cache:

```
ana@laptop:~/boxoffice$ npx --yes newman@6.2.3 --version
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated uuid@3.4.0: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated @faker-js/faker@5.5.3: Please update to a newer version.
6.2.3
```

`--yes` lets npx download without asking, and `@6.2.3` pins the version every transcript was
recorded with. The four `npm warn deprecated` lines appear only on that first download: they say that
some libraries Newman is built on are no longer maintained by their authors. They are a fact about
Newman, not a fault on your machine, and nothing in this course depends on them.

Every run below also passes `--disable-unicode`. Without it Newman marks folders,
requests and passed tests with small symbols that some terminal fonts cannot draw; with it, it
writes them out as words: `Folder`, `Sub-folder` for a request inside a folder, `Root` for one
outside any folder, and `Pass`.

## A first run that goes wrong

With boxoffice running in its second terminal, run the `orders` folder against the environment as
lesson 4 left it:

```
ana@laptop:~/boxoffice$ npx --yes newman@6.2.3 run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --folder orders --disable-unicode
newman

boxoffice

Folder orders
Sub-folder Create order
  POST http://localhost:8080/oauth/token [200 OK, 479B, 37ms]
  POST http://localhost:8080/v1/orders [401 Unauthorized, 352B, 4ms]
  1. status is 201
  2. the order is for the show and the seat asked for
  3. location says where it lives

Sub-folder Read order
  GET http://localhost:8080null [errored]
     Port should be >= 0 and < 65536. Received type string ('8080null').
  5. status is 200
  6. it is the order just created

Sub-folder Cancel order
  DELETE http://localhost:8080null [errored]
     Port should be >= 0 and < 65536. Received type string ('8080null').
  8. status is 204

Sub-folder Read cancelled order
  GET http://localhost:8080null [errored]
     Port should be >= 0 and < 65536. Received type string ('8080null').
 10. the order now says cancelled

-----------------------------------------------------------------
|                         |         executed |           failed |
--------------------------+------------------+-------------------
|              iterations |                1 |                0 |
--------------------------+------------------+-------------------
|                requests |                5 |                3 |
--------------------------+------------------+-------------------
|            test-scripts |                4 |                0 |
--------------------------+------------------+-------------------
|      prerequest-scripts |                5 |                0 |
--------------------------+------------------+-------------------
|              assertions |                7 |                7 |
-----------------------------------------------------------------
| total run duration: 172ms                                     |
-----------------------------------------------------------------
| total data received: 377B (approx)                            |
-----------------------------------------------------------------
| average response time: 20ms [min: 4ms, max: 37ms, s.d.: 16ms] |
-----------------------------------------------------------------

   #  failure         detail                                                              
                                                                                          
 01.  AssertionError  status is 201                                                       
                      expected response to have status code 201 but got 401               
                      at assertion:0 in test-script                                       
                      inside "orders / Create order"                                      
                                                                                          
 02.  AssertionError  the order is for the show and the seat asked for                    
                      expected undefined to equal 'sh-103'                                
                      at assertion:1 in test-script                                       
                      inside "orders / Create order"                                      
                                                                                          
 03.  AssertionError  location says where it lives                                        
                      expected response to have header with key 'location'                
                      at assertion:2 in test-script                                       
                      inside "orders / Create order"                                      
                                                                                          
 04.  RangeError                                                                          
                      Port should be >= 0 and < 65536. Received type string ('8080null'). 
                      at request                                                          
                      inside ""                                                           
                                                                                          
 05.  AssertionError  status is 200                                                       
                      expected PostmanResponse{ …(5) } to have property 'code'            
                      at assertion:0 in test-script                                       
                      inside "orders / Read order"                                        
                                                                                          
 06.  TypeError       it is the order just created                                        
                      Cannot read properties of null (reading 'split')                    
                      at assertion:1 in test-script                                       
                      inside "orders / Read order"                                        
                                                                                          
 07.  RangeError                                                                          
                      Port should be >= 0 and < 65536. Received type string ('8080null'). 
                      at request                                                          
                      inside ""                                                           
                                                                                          
 08.  AssertionError  status is 204                                                       
                      expected PostmanResponse{ …(5) } to have property 'code'            
                      at assertion:0 in test-script                                       
                      inside "orders / Cancel order"                                      
                                                                                          
 09.  RangeError                                                                          
                      Port should be >= 0 and < 65536. Received type string ('8080null'). 
                      at request                                                          
                      inside ""                                                           
                                                                                          
 10.  JSONError       the order now says cancelled                                        
                      "undefined" is not valid JSON                                       
                      at assertion:0 in test-script                                       
                      inside "orders / Read cancelled order"                              
```

Every request in the folder failed, and the first failure is the only one that matters. **Create
order** answered `401`: boxoffice received no token. The token request did run, inside the
collection's pre-request script, and the script saved the token in a collection variable. But the
`lab` environment still defines `token`, empty, and lesson 4 section 04 said what happens then: the
environment is the narrower scope, so its empty value wins, and every request went out with nothing
after `Bearer`.

The rest is a cascade. Create order did not answer `201`, so it had no `location` header to save,
and `orderUrl` became `null`. The next three addresses were built from it,
`http://localhost:8080null`, and Newman could not even send them. **When a run fails, read the
first failure and distrust the ones after it**: they are usually the first one, echoing.

The fix is to stop the environment from defining `token` at all. Take the row out, then
save it as `postman/lab.postman_environment.json`:

```json
{
  "name": "lab",
  "values": [
    {"key": "baseUrl", "value": "http://localhost:8080", "type": "default", "enabled": true},
    {"key": "clientId", "value": "ci-tests", "type": "default", "enabled": true},
    {"key": "clientSecret", "value": "ci-secret", "type": "secret", "enabled": true}
  ],
  "_postman_variable_scope": "environment"
}
```

```
ana@laptop:~/boxoffice$ jq -r '.values[].key' postman/lab.postman_environment.json
baseUrl
clientId
clientSecret
```

In Postman, delete the `token` row from the `lab` environment by hand too, or re-import the file;
a row with an empty value is still a row.

## The run, whole

```
ana@laptop:~/boxoffice$ npx --yes newman@6.2.3 run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode
newman

boxoffice

Folder shows
Sub-folder List shows
  POST http://localhost:8080/oauth/token [200 OK, 479B, 21ms]
  GET http://localhost:8080/v1/shows [200 OK, 569B, 3ms]
  Pass  status is 200
  Pass  the body is JSON
  Pass  every show has a whole number of seats left

Sub-folder One show
  GET http://localhost:8080/v1/shows/sh-103 [200 OK, 312B, 4ms]
  Pass  status is 200
  Pass  it is the show asked for
  Pass  it carries an etag

Sub-folder HEAD one show
  HEAD http://localhost:8080/v1/shows/sh-103 [405 Method Not Allowed, 171B, 3ms]
  1. HEAD answers like GET

Folder auth
Sub-folder Get token
  POST http://localhost:8080/oauth/token [200 OK, 479B, 4ms]
  Pass  status is 200
  Pass  a bearer token comes back
  Pass  nobody may keep a copy of it

Folder orders
Sub-folder Create order
  POST http://localhost:8080/v1/orders [201 Created, 316B, 2ms]
  Pass  status is 201
  Pass  the order is for the show and the seat asked for
  Pass  location says where it lives

Sub-folder Read order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 3ms]
  Pass  status is 200
  Pass  it is the order just created

Sub-folder Cancel order
  DELETE http://localhost:8080/v1/orders/ord-1001 [204 No Content, 111B, 2ms]
  Pass  status is 204

Sub-folder Read cancelled order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 3ms]
  Pass  the order now says cancelled

Folder seat rules
Sub-folder Order seats
  POST http://localhost:8080/v1/orders [201 Created, 316B, 3ms]
  Pass  seats 1 answers 201

---------------------------------------------------------------
|                         |        executed |          failed |
--------------------------+-----------------+------------------
|              iterations |               1 |               0 |
--------------------------+-----------------+------------------
|                requests |              10 |               0 |
--------------------------+-----------------+------------------
|            test-scripts |               9 |               0 |
--------------------------+-----------------+------------------
|      prerequest-scripts |              11 |               0 |
--------------------------+-----------------+------------------
|              assertions |              18 |               1 |
---------------------------------------------------------------
| total run duration: 245ms                                   |
---------------------------------------------------------------
| total data received: 1.55kB (approx)                        |
---------------------------------------------------------------
| average response time: 4ms [min: 2ms, max: 21ms, s.d.: 5ms] |
---------------------------------------------------------------

  #  failure         detail                                                
                                                                           
 1.  AssertionError  HEAD answers like GET                                 
                     expected response to have status code 200 but got 405 
                     at assertion:0 in test-script                         
                     inside "shows / HEAD one show"                        
```

Seventeen passes and one failure, which is the one this collection is meant to fail. **HEAD one
show** checks that `HEAD` answers like `GET`, and boxoffice still refuses it with `405`, the defect
lesson 1 found. A test that fails until a defect is fixed is the defect report in a form a machine
can repeat, and it turns green on the day somebody fixes boxoffice, without anybody remembering to
check. Lesson 6 reads the table at the bottom line by line.
