---
title: Structured logs, and what never goes in them
version: 1
---

The lines so far are written for a person at a terminal, and a person reads them well. A server's log
is mostly read by a program instead: something collects every line from every copy of the
application, stores it, and answers questions like "every `ERROR` from `OrderService` this morning"
or "every line with request id `checkout-42`". To answer those from text, it has to cut each line into
fields with a pattern, and the pattern breaks the first time a message contains the character it cuts
on, or runs over several lines, as Hibernate's report on the database does at every start-up.

A **structured log** writes each event as data instead: one JSON object per line, with the level, the
logger, the thread and every MDC entry as fields of their own. Spring Boot does it with one property,
so the bookshop keeps the readable format by default and turns JSON on with a profile. Create
`src/main/resources/application-json.properties`:

```properties
logging.structured.format.console=ecs
```

`ecs` is the **Elastic Common Schema**, the field names that Elastic's stack reads. Run `mvn -q
package` again, and restart the second terminal with the profile:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=json > app.log
```

The token from the previous section is still valid: it lives fifteen minutes, and the restarted
application checks it with the same secret. (If it has expired, fetch another the same way.)

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -H 'X-Request-Id: checkout-43' -d '{"lines":[{"bookId":4,"quantity":2}]}' localhost:8080/orders
201
ana@vm:~/bookshop$ grep checkout-43 app.log
{"@timestamp":"2026-10-16T23:30:49.335782513Z","log":{"level":"INFO","logger":"com.example.bookshop.ordering.OrderService"},"process":{"pid":25221,"thread":{"name":"http-nio-8080-exec-2"}},"service":{"name":"bookshop","version":"0.1.0","node":{}},"message":"Order 2 placed by ana: 1 line(s), 6200 cents","requestId":"checkout-43","ecs":{"version":"8.11"}}
ana@vm:~/bookshop$ grep checkout-43 app.log | python3 -m json.tool
{
    "@timestamp": "2026-10-16T23:30:49.335782513Z",
    "log": {
        "level": "INFO",
        "logger": "com.example.bookshop.ordering.OrderService"
    },
    "process": {
        "pid": 25221,
        "thread": {
            "name": "http-nio-8080-exec-2"
        }
    },
    "service": {
        "name": "bookshop",
        "version": "0.1.0",
        "node": {}
    },
    "message": "Order 2 placed by ana: 1 line(s), 6200 cents",
    "requestId": "checkout-43",
    "ecs": {
        "version": "8.11"
    }
}
```

The same event, and nothing has to be guessed from its position any more. The logger's name is
whole, not shortened to 40 characters; the thread's name is whole; the time is in UTC with the zone
written as `Z`, so lines from machines in different zones sort together; and **`requestId` is a field
of its own**, because Boot copies every MDC entry into the object. A log platform can now filter on
`requestId` exactly, rather than searching text for a string that might also appear in a message.
And a message that runs over several lines, like Hibernate's report on the database, stays a single
object: its line breaks are written as `\n` inside the string, so nothing in a message can start a
line of its own. The text format prints them as real line breaks.

One more thing the JSON shows that the text did not. Spring's own classes log through
`commons-logging`, and their lines carry a tag saying so:

```
ana@vm:~/bookshop$ grep -c '"tags":\["COMMONS-LOGGING"\]' app.log
14
```

## Three formats, one event

ECS is one of three formats Boot writes; `logstash` and `gelf` (Graylog's) are the others. Which one
is right is decided by whatever collects the log, not by the application. A property on the command
line wins over the profile's file, so the same event in Logstash's names is one restart away:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=json --logging.structured.format.console=logstash > app.log
```

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -H 'X-Request-Id: checkout-44' -d '{"lines":[{"bookId":5,"quantity":1}]}' localhost:8080/orders
201
ana@vm:~/bookshop$ grep checkout-44 app.log | python3 -m json.tool
{
    "@timestamp": "2026-10-16T20:30:59.853674663-03:00",
    "@version": "1",
    "message": "Order 3 placed by ana: 1 line(s), 3690 cents",
    "logger_name": "com.example.bookshop.ordering.OrderService",
    "thread_name": "http-nio-8080-exec-2",
    "level": "INFO",
    "level_value": 20000,
    "requestId": "checkout-44"
}
```

`logger_name` instead of `log.logger`, a numeric `level_value` beside the level, the time with São
Paulo's offset rather than in UTC, and the same `requestId`. The code that wrote the line did not
change, and neither did the MDC.

## What never goes in a log

A log is a copy of what the application saw, and it travels further than the database does. It is
shipped to another system, kept for months, read by everybody who debugs anything, and attached to
tickets, and deleting a customer from the database deletes nothing from it. So some things never go in, at any level:

- **Passwords**, including the wrong ones: a failed login with a password one character off is the
  password.
- **Credentials of any kind**: the `Authorization` header, a JWT, the JWT secret, a session id, an API
  key. Anybody who reads a token in a log can use it until it expires.
- **Personal data the line does not need**: an e-mail address, a name, a street address, a document
  number. The bookshop's order line writes the token's subject, `ana`, which is an account name and so
  identifies a person; a shop with real customers would write an opaque account id and look the person
  up only when it had a reason to.

Spring's own request logging is built with the second rule in mind. The `dev` profile from lesson 4 turns
`org.springframework.web` up to `debug`; send it a request with a token it will refuse:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dev > app.log
```

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Authorization: Bearer not-a-real-token' localhost:8081/books/1
401
ana@vm:~/bookshop$ grep -c not-a-real-token app.log
0
ana@vm:~/bookshop$ grep masked app.log
2026-10-16T20:31:14.255-03:00 DEBUG 26381 --- [bookshop] [nio-8081-exec-1] [] o.s.web.servlet.DispatcherServlet        : enableLoggingRequestDetails='false': request parameters and headers will be masked to prevent unsafe logging of potentially sensitive data
```

The token appears nowhere, and Spring says why on the first request. The switch that unmasks them,
`spring.mvc.log-request-details`, exists for a developer's own machine. The same goes for Hibernate's
`org.hibernate.orm.jdbc.bind` logger, which at `trace` writes the value of every SQL parameter: every
customer's details, one line at a time.
