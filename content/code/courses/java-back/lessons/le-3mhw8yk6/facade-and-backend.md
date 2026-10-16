---
title: The facade and the backend
version: 1
---

DRAFT

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>logging-look</artifactId>
  <version>1.0.0</version>

  <dependencies>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-api</artifactId>
      <version>2.0.18</version>
    </dependency>
  </dependencies>

  <profiles>
    <profile>
      <id>logback</id>
      <dependencies>
        <dependency>
          <groupId>ch.qos.logback</groupId>
          <artifactId>logback-classic</artifactId>
          <version>1.5.38</version>
        </dependency>
      </dependencies>
    </profile>
    <profile>
      <id>log4j2</id>
      <dependencies>
        <dependency>
          <groupId>org.apache.logging.log4j</groupId>
          <artifactId>log4j-slf4j2-impl</artifactId>
          <version>2.25.5</version>
        </dependency>
        <dependency>
          <groupId>org.apache.logging.log4j</groupId>
          <artifactId>log4j-core</artifactId>
          <version>2.25.5</version>
        </dependency>
      </dependencies>
    </profile>
    <profile>
      <id>tinylog</id>
      <dependencies>
        <dependency>
          <groupId>org.tinylog</groupId>
          <artifactId>slf4j-tinylog</artifactId>
          <version>2.8.1</version>
        </dependency>
        <dependency>
          <groupId>org.tinylog</groupId>
          <artifactId>tinylog-impl</artifactId>
          <version>2.8.1</version>
        </dependency>
      </dependencies>
    </profile>
  </profiles>

  <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <artifactId>maven-dependency-plugin</artifactId>
          <version>3.10.0</version>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
</project>
```

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Hello {

    private static final Logger log = LoggerFactory.getLogger(Hello.class);

    public static void main(String[] args) {
        log.debug("Looking up book {}", 3);
        log.info("Order {} placed by {}: {} line(s)", 7, "ana", 2);
        log.warn("Only {} of '{}' left", 1, "Frankenstein");
        try {
            Integer.parseInt("two");
        } catch (NumberFormatException e) {
            log.error("Quantity '{}' is not a number", "two", e);
        }
    }
}
```
