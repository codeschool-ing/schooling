---
title: HtmlUnit, the Java one
version: 1
---

**HtmlUnit is a browser written in Java, for Java programs**, and unlike Zombie it is still
released: 5.6.0 was the newest version on Maven Central, the registry Java libraries are published
to, when this lesson was captured in October 2026. It parses HTML, builds a DOM, matches CSS
rules and runs JavaScript, all inside the Java process that called it. Java teams meet it in two places: called directly, as below, and as
the browser behind Selenium's `HtmlUnitDriver`.

## Under Selenium

Lesson 8 drove Chromium through `chromedriver`. Selenium's Java binding also has a driver that
needs no browser at all, because the browser is HtmlUnit, loaded as a library. It is a separate
artifact, `org.seleniumhq.selenium:htmlunit3-driver`, and its version follows Selenium's: 4.51.0
is the release that matches the `selenium-webdriver` 4.51.0 of lesson 8, and it is built on
HtmlUnit 5.6.0. A test then changes one line:

```java
WebDriver driver = new HtmlUnitDriver(true);  // true: run the page's JavaScript
driver.get("http://localhost:3000/");
```

**That snippet was not run for this course**: it needs a Java test project around it, and the
program below shows the same engine more directly. The JavaScript binding has nothing like it:
`HtmlUnitDriver` is a Java class, and `selenium-webdriver` for Node has no HtmlUnit of its own.

## Its JavaScript engine

A real browser runs JavaScript in its own engine: V8 in Chrome, SpiderMonkey in Firefox,
JavaScriptCore in Safari. HtmlUnit cannot use any of them from Java, so it carries its own. The
package is `htmlunit-core-js`, and its description on Maven Central reads: "HtmlUnit adaptation of
Mozilla Rhino Javascript engine for Java". **Whatever JavaScript Rhino does not understand, HtmlUnit
does not run**, however well every real browser runs it.

## Run against the shop

This needs a JDK and Maven, which lesson 1 did not install; with neither, read the transcripts. The
JDK here is this one:

```
ana@laptop:~/quitanda$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
```

Maven downloads a Java library and everything it depends on. In a folder `htmlunit` inside the
project, the list of what to download goes in a file Maven reads by name. Save it as
`htmlunit/pom.xml`:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>quitanda</groupId>
  <artifactId>htmlunit-try</artifactId>
  <version>1</version>
  <dependencies>
    <dependency>
      <groupId>org.htmlunit</groupId>
      <artifactId>htmlunit</artifactId>
      <version>5.6.0</version>
    </dependency>
  </dependencies>
</project>
```

The program opens two pages of the shop: `/ssr`, which lesson 6 renders on the server with the
cards already in the HTML, and `/`, where `app.js` draws them. It tells HtmlUnit not to stop at the
first script error, waits up to three seconds for scripts still running, and counts. Save it as
`htmlunit/Shop.java`:

```java
import org.htmlunit.BrowserVersion;
import org.htmlunit.WebClient;
import org.htmlunit.html.HtmlPage;

public class Shop {
  public static void main(String[] args) throws Exception {
    try (WebClient client = new WebClient(BrowserVersion.CHROME)) {
      client.getOptions().setThrowExceptionOnScriptError(false);
      for (String path : new String[] { "/ssr", "/" }) {
        HtmlPage page = client.getPage("http://localhost:3000" + path);
        client.waitForBackgroundJavaScript(3000);
        int cards = page.querySelectorAll("#products li").size();
        System.out.println(path + " has " + cards + " cards");
      }
    }
  }
}
```

In `~/quitanda/htmlunit`, Maven copies the jars into `lib`:

```
ana@laptop:~/quitanda/htmlunit$ mvn -q dependency:copy-dependencies -DoutputDirectory=lib
ana@laptop:~/quitanda/htmlunit$ ls lib
commons-codec-1.11.jar
commons-io-2.22.0.jar
commons-lang3-3.21.0.jar
commons-logging-1.4.0.jar
htmlunit-5.6.0.jar
htmlunit-core-js-5.6.0.jar
htmlunit-csp-5.6.0.jar
htmlunit-cssparser-5.6.0.jar
htmlunit-websocket-client-5.6.0.jar
htmlunit-xpath-5.6.0.jar
httpclient-4.5.14.jar
httpcore-4.4.16.jar
httpmime-4.5.14.jar
neko-htmlunit-5.6.0.jar
```

**That download is the one step not run the way you will run it.** Maven Central's main address
was refusing this machine's requests when the transcripts were made, so Maven was pointed at a
mirror of the same registry. The jars are the same files; your command is the one shown.

Java 11 and later run a single source file without a separate compile step. With the shop running,
the program prints this many lines, most of them two stack traces:

```
ana@laptop:~/quitanda/htmlunit$ java -cp 'lib/*' Shop.java 2>&1 | wc -l
391
```

and `grep` keeps the count lines and the one line of each script error that names it:

```
ana@laptop:~/quitanda/htmlunit$ java -cp 'lib/*' Shop.java 2>&1 | grep -E 'cards|ScriptException'
org.htmlunit.ScriptException: missing formal parameter (http://localhost:3000/slow/ssr.js#3)
/ssr has 8 cards
org.htmlunit.ScriptException: missing ; before statement (http://localhost:3000/app.js#3)
/ has 0 cards
```

**`/ssr` has its eight cards, and `/` has none.** Both pages hit the same wall. Line 3 of `app.js`
is `async function getJson(url, options) {`, and line 3 of the script `/ssr` loads late is
`button.addEventListener('click', async () => {`. Rhino stopped at the word `async` both times,
with a message about a missing `;` or a missing parameter, because it did not parse the function at
all. So on `/` no script ran and no card was drawn, and on `/ssr` the cards came with the HTML but
no button would ever work.

Every browser a student of this course could install runs `async` functions.
A test that sees zero cards here is not reporting a defect in the shop. **It is reporting a
difference between HtmlUnit and every user**, which is the cost of a simulated browser in its
plainest form. Where HtmlUnit still earns its keep is the first page of that run: HTML that arrives
complete from the server, checked without starting a browser.
