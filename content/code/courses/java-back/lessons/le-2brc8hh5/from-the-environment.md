---
title: x
version: 1
---

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.hikari.pool-name=bookshop-pool
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=5000

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false

bookshop.jwt.secret=${BOOKSHOP_JWT_SECRET}
bookshop.jwt.lifetime=15m

logging.pattern.correlation=[%X{requestId:-}] 

management.server.port=8081
management.server.address=127.0.0.1
management.endpoints.web.exposure.include=health,info,metrics,prometheus
management.endpoint.health.show-details=always
management.endpoint.health.probes.enabled=true
management.info.java.enabled=true
```
