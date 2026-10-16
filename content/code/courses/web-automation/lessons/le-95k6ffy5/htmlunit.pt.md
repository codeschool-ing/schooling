---
title: HtmlUnit, o de Java
version: 1
---

**O HtmlUnit é um navegador escrito em Java, para programas Java**, e ao contrário do Zombie ainda
tem versões novas: a 5.6.0 era a mais recente no Maven Central, o registro em que as bibliotecas
Java são publicadas, quando esta aula foi capturada, em outubro de 2026. Ele analisa o HTML, monta
um DOM, casa regras de CSS e roda JavaScript, tudo dentro do processo Java que o chamou. Equipes
Java o encontram em dois lugares: chamado diretamente, como abaixo, e como o navegador por trás do
`HtmlUnitDriver` do Selenium.

## Debaixo do Selenium

A aula 8 conduziu o Chromium pelo `chromedriver`. O binding Java do Selenium também tem um driver
que não precisa de navegador nenhum, porque o navegador é o HtmlUnit, carregado como biblioteca. É
um artefato separado, `org.seleniumhq.selenium:htmlunit3-driver`, e a versão dele acompanha a do
Selenium: a 4.51.0 é a que corresponde ao `selenium-webdriver` 4.51.0 da aula 8, e é construída
sobre o HtmlUnit 5.6.0. Um teste então muda uma linha:

```java
WebDriver driver = new HtmlUnitDriver(true);  // true: run the page's JavaScript
driver.get("http://localhost:3000/");
```

**Esse trecho não foi rodado neste curso**: ele precisa de um projeto de testes Java em volta, e o
programa abaixo mostra o mesmo motor de forma mais direta. O binding JavaScript não tem nada
parecido: o `HtmlUnitDriver` é uma classe Java, e o `selenium-webdriver` do Node não tem HtmlUnit
próprio.

## O motor de JavaScript dele

Um navegador de verdade roda JavaScript no próprio motor: o V8 no Chrome, o SpiderMonkey no
Firefox, o JavaScriptCore no Safari. O HtmlUnit não consegue usar nenhum deles a partir do Java,
então carrega o seu. O pacote é o `htmlunit-core-js`, e a descrição dele no Maven Central diz:
"HtmlUnit adaptation of Mozilla Rhino Javascript engine for Java", uma adaptação do motor Rhino, da
Mozilla. **O JavaScript que o Rhino não entende, o HtmlUnit não roda**, por melhor que todos os
navegadores de verdade o rodem.

## Rodando contra a loja

Isto pede um JDK e o Maven, que a aula 1 não instalou; sem eles, leia as transcrições. O JDK aqui é
este:

```
ana@laptop:~/quitanda$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
```

O Maven baixa uma biblioteca Java e tudo de que ela depende. Numa pasta `htmlunit` dentro do
projeto, a lista do que baixar vai num arquivo que o Maven lê pelo nome. Salve-o como
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

O programa abre duas páginas da loja: `/ssr`, que a aula 6 renderiza no servidor com os cards já
no HTML, e `/`, onde o `app.js` os desenha. Ele diz ao HtmlUnit para não parar no primeiro erro de
script, espera até três segundos pelos scripts que ainda estão rodando, e conta. Salve-o como
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

Em `~/quitanda/htmlunit`, o Maven copia os jars para `lib`:

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

**Esse download é o único passo que não rodou do jeito que você vai rodar.** O endereço principal
do Maven Central estava recusando os pedidos desta máquina quando as transcrições foram feitas,
então o Maven foi apontado para um espelho do mesmo registro. Os jars são os mesmos arquivos; o seu
comando é o que aparece acima.

Do Java 11 em diante, um arquivo-fonte único roda sem um passo de compilação separado. Com a loja
rodando, o programa imprime esta quantidade de linhas, a maioria de dois rastros de pilha:

```
ana@laptop:~/quitanda/htmlunit$ java -cp 'lib/*' Shop.java 2>&1 | wc -l
391
```

e o `grep` guarda as linhas da contagem e a única linha de cada erro de script que diz qual é:

```
ana@laptop:~/quitanda/htmlunit$ java -cp 'lib/*' Shop.java 2>&1 | grep -E 'cards|ScriptException'
org.htmlunit.ScriptException: missing formal parameter (http://localhost:3000/slow/ssr.js#3)
/ssr has 8 cards
org.htmlunit.ScriptException: missing ; before statement (http://localhost:3000/app.js#3)
/ has 0 cards
```

**`/ssr` tem os oito cards, e `/` não tem nenhum.** As duas páginas batem no mesmo muro. A linha 3
do `app.js` é `async function getJson(url, options) {`, e a linha 3 do script que `/ssr` carrega
atrasado é `button.addEventListener('click', async () => {`. O Rhino parou na palavra `async` as
duas vezes, com uma mensagem sobre um `;` ou um parâmetro faltando, porque nem chegou a entender a
função. Então em `/` nenhum script rodou e nenhum card foi desenhado, e em `/ssr` os cards vieram
com o HTML mas nenhum botão funcionaria nunca.

Todo navegador que um aluno deste curso poderia instalar roda funções `async`. Um teste que vê zero
cards aqui não está relatando um defeito da loja. **Está relatando uma diferença entre o HtmlUnit e
todos os usuários**, que é o custo de um navegador simulado na forma mais simples. Onde o HtmlUnit
ainda se paga é a primeira página dessa rodada: HTML que chega completo do servidor, verificado sem
iniciar um navegador.
