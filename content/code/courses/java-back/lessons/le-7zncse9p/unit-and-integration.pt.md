---
title: Testes de unidade e testes de integração, surefire e failsafe
version: 1
---

`OrderServiceTest` é um **teste de unidade**: uma classe, os colaboradores substituídos, nada fora da
JVM, um segundo para rodar. Os próximos testes desta aula são **testes de integração**: o serviço real,
os repositórios reais, Hibernate, Flyway e um PostgreSQL de verdade, conferidos juntos, porque as
perguntas que eles respondem — esta consulta devolve o que o nome promete? as migrações produzem o
esquema que as entidades esperam? — não têm resposta sem as peças reais. Eles levam segundos e precisam
de um engine de contêineres na máquina.

Mocks não os substituem. Um mock de `BookRepository` devolve o que o teste mandou, então um teste que
faz mock do repositório nunca encontra um erro na consulta do próprio repositório. **Cada tipo de teste
é cego justamente onde o outro enxerga**, e um projeto mantém os dois, em duas execuções separadas.

## Dois plugins, duas regras de nome

O Maven os separa pelo nome da classe, com um plugin para cada:

| plugin | roda classes com nome | na fase | um teste que falha |
| --- | --- | --- | --- |
| **surefire** | `*Test`, `Test*`, `*Tests`, `*TestCase` | `test` | para o build ali |
| **failsafe** | `*IT`, `IT*`, `*ITCase` | `integration-test`, depois `verify` | é registrado, e para o build em `verify` |

Então `OrderServiceTest` é do surefire, e as duas classes da seção sobre Testcontainers,
`BookshopApplicationIT` e `BookRepositoryIT`, serão do failsafe. O sufixo é a chave inteira: uma classe
de teste chamada `BookRepositoryTests` rodaria com os testes de unidade, subiria um contêiner no meio
deles e deixaria mais lento cada `mvn test` que existe.

O failsafe divide o trabalho em duas fases de propósito. Um teste de integração muitas vezes precisa de
algo iniciado antes dele e parado depois, um servidor ou um banco, e o build tem de pará-lo mesmo quando
os testes falharam. Por isso o failsafe roda os testes em `integration-test` e só anota o resultado;
`post-integration-test` roda o que desliga o mundo lá fora; e `verify` lê a anotação e faz o build
falhar. O bookshop não liga nada às duas fases em volta dos testes, porque o Testcontainers inicia e para
os próprios contêineres de dentro da JVM dos testes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 360\" role=\"img\" aria-label=\"O ciclo de vida padrão do Maven de compile a verify, uma fase por linha. O Surefire roda as classes com nome Test na fase test e para o build numa falha. O jar é montado em package. O Failsafe roda as classes com nome IT em integration-test e só registra as falhas; post-integration-test ainda roda; em verify o failsafe lê o registro e faz o build falhar. mvn test roda as fases até test; mvn verify roda todas.\"><defs><marker id=\"f19b-ad\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"f19b-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"30\" y=\"20\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">compile</text><line x1=\"135\" y1=\"50\" x2=\"135\" y2=\"59\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><rect x=\"30\" y=\"60\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">test-compile</text><line x1=\"135\" y1=\"90\" x2=\"135\" y2=\"99\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><rect x=\"30\" y=\"100\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">test</text><line x1=\"135\" y1=\"130\" x2=\"135\" y2=\"139\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"115\" x2=\"268\" y2=\"115\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">surefire roda *Test; uma falha para aqui</text><rect x=\"30\" y=\"140\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">package</text><line x1=\"135\" y1=\"170\" x2=\"135\" y2=\"179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"155\" x2=\"268\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o jar, reempacotado pelo Boot</text><rect x=\"30\" y=\"180\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">pre-integration-test</text><line x1=\"135\" y1=\"210\" x2=\"135\" y2=\"219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"195\" x2=\"268\" y2=\"195\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nada ligado no bookshop</text><rect x=\"30\" y=\"220\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">integration-test</text><line x1=\"135\" y1=\"250\" x2=\"135\" y2=\"259\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"235\" x2=\"268\" y2=\"235\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">failsafe roda *IT e registra falhas</text><rect x=\"30\" y=\"260\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">post-integration-test</text><line x1=\"135\" y1=\"290\" x2=\"135\" y2=\"299\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"275\" x2=\"268\" y2=\"275\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma limpeza rodaria aqui, mesmo depois de uma falha</text><rect x=\"30\" y=\"300\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">verify</text><line x1=\"244\" y1=\"315\" x2=\"268\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"315\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">failsafe lê o registro: o build falha aqui</text><path d=\"M 567 22 L 575 22 L 575 128 L 567 128\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"583\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">mvn test</text><path d=\"M 667 22 L 675 22 L 675 328 L 667 328\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"683\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">mvn verify</text></svg>", "caption": "Cada comando roda a fase que nomeia e todas as anteriores a ela. As fases em âmbar são as que esta aula liga a um plugin."}
```

## Ligando o failsafe

O parent do Spring Boot gerencia o failsafe e já liga os dois goals dele, mas um plugin do
`pluginManagement` do parent só roda se o `<build>` do próprio projeto o nomear. Substitua o elemento
`<build>` mais uma vez, por este. O failsafe é novo, entre o surefire e o plugin de javadoc:

```xml
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-dependency-plugin</artifactId>
        <executions>
          <execution>
            <goals>
              <goal>properties</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-failsafe-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>
        </configuration>
        <executions>
          <execution>
            <goals>
              <goal>integration-test</goal>
              <goal>verify</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <configuration>
          <show>public</show>
          <doclint>all,-missing</doclint>
        </configuration>
      </plugin>
    </plugins>
  </build>
```

O bloco `<executions>` repete o que o parent já diz, e não muda nada; escrito aqui, deixa a ligação
visível para quem lê este arquivo, sem uma viagem ao pom do parent. O failsafe recebe o agente no
`argLine` pelo mesmo motivo do surefire: os testes de integração rodam num fork próprio, e um teste ali
que cria um mock também precisa dele.

**Os dois `argLine` também terminam numa opção nova, `--enable-native-access=ALL-UNNAMED`.** Ela é para
os testes de integração, que vão chegar ao Docker, e a seção sobre Testcontainers mostra o aviso que ela
evita. Os testes de unidade nunca chegam ao Docker e não precisam dela; a linha do surefire a leva mesmo
assim, para que as duas linhas fiquem idênticas e ninguém precise lembrar qual fork não tem o quê.

`mvn verify` roda todas as fases até `verify`, os testes de unidade incluídos. Ainda sem nenhuma classe
`*IT`, o `grep` guarda a linha que o Maven imprime quando cada plugin começa, os totais (as linhas que
terminam em `Skipped: 0` sem o nome de uma classe depois) e o resultado:

```
ana@vm:~/bookshop$ mvn -B verify 2>&1 | grep -E '^\[INFO\] --- |Skipped: 0$|No tests|BUILD'
[INFO] --- maven-dependency-plugin:3.10.0:properties (default) @ bookshop ---
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ bookshop ---
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ bookshop ---
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ bookshop ---
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ bookshop ---
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] --- maven-jar-plugin:3.5.1:jar (default-jar) @ bookshop ---
[INFO] --- spring-boot-maven-plugin:4.1.1:repackage (repackage) @ bookshop ---
[INFO] --- maven-failsafe-plugin:3.5.6:integration-test (default) @ bookshop ---
[INFO] --- maven-failsafe-plugin:3.5.6:verify (default) @ bookshop ---
[INFO] No tests to run.
[INFO] BUILD SUCCESS
```

O surefire rodou os dezessete testes de unidade, o jar foi montado e reempacotado, e o failsafe rodou e
não achou teste nenhum para rodar. **`mvn test` para antes de `package`, então nunca roda um teste de
integração**, e esse é o comando do dia a dia, minuto a minuto. `mvn verify` é o de antes de um commit,
e o que um servidor de build roda, que `testing-cicd` configura.
