---
title: Dependências, o escopo delas, e as que ninguém pediu
version: 1
---

O pom cita duas dependências. O build usou mais que duas, e um objetivo mostra todas:

```
ana@vm:~/isbn-check$ mvn dependency:tree
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:isbn-check >-----------------------
[INFO] Building isbn-check 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-dependency-plugin:2.8:tree (default-cli) @ isbn-check ---
[INFO] com.example:isbn-check:jar:1.0.0
[INFO] +- commons-validator:commons-validator:jar:1.11.0:compile
[INFO] |  +- commons-beanutils:commons-beanutils:jar:1.11.0:compile
[INFO] |  +- commons-digester:commons-digester:jar:2.1:compile
[INFO] |  +- commons-logging:commons-logging:jar:1.4.0:compile
[INFO] |  \- commons-collections:commons-collections:jar:3.2.2:compile
[INFO] \- org.junit.jupiter:junit-jupiter:jar:6.0.3:test
[INFO]    +- org.junit.jupiter:junit-jupiter-api:jar:6.0.3:test
[INFO]    |  +- org.opentest4j:opentest4j:jar:1.3.0:test
[INFO]    |  +- org.junit.platform:junit-platform-commons:jar:6.0.3:test
[INFO]    |  +- org.apiguardian:apiguardian-api:jar:1.1.2:test
[INFO]    |  \- org.jspecify:jspecify:jar:1.0.0:test
[INFO]    +- org.junit.jupiter:junit-jupiter-params:jar:6.0.3:test
[INFO]    \- org.junit.jupiter:junit-jupiter-engine:jar:6.0.3:test
[INFO]       \- org.junit.platform:junit-platform-engine:jar:6.0.3:test
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.720 s
[INFO] Finished at: 2026-10-22T19:33:35-03:00
[INFO] ------------------------------------------------------------------------
```

O `dependency:tree` não é uma fase do build; é um **objetivo** do plugin de dependências, pedido
pelo nome, e ele não faz nada além de imprimir. Cada linha é uma dependência na forma
`grupo:artefato:tipo:versão:escopo`, e o recuo diz quem a pediu. As duas da margem esquerda são as
do pom. **Tudo que está recuado é uma dependência transitiva**: o Commons Validator precisa do
Commons BeanUtils, do Digester, do Logging e do Collections para funcionar, então o Maven os buscou
também, sem o pom citar nenhum deles. Isso é a maior parte da razão de existir de uma ferramenta de
build. O pom diz o que o projeto usa diretamente, e o pom de cada biblioteca diz do que ela
precisa, até o fim.

O `2.8` na linha do plugin merece uma pergunta, e a seção sobre plugins a responde.

## Escopo

O último campo de cada linha é o **escopo**, que diz onde uma dependência fica visível.

| escopo | compila o programa | compila e roda os testes | necessária quando o programa roda |
|---|---|---|---|
| `compile`, o padrão | sim | sim | sim |
| `test` | não | sim | não |
| `provided` | sim | sim | não: o lugar onde roda a fornece |
| `runtime` | não | sim | sim |

O Commons Validator não tem `<scope>` no pom, então é `compile`: o programa o importa, os testes
chegam a ele pelo programa, e ele precisa estar presente quando o programa roda. O JUnit diz
`test`, e **o escopo é herdado para baixo**: toda biblioteca que o JUnit traz também é `test`.
Escrever `import org.junit...` em `src/main/java` não compila, e essa é a ideia, porque senão o
programa sairia dependendo de uma biblioteca de teste. Os outros dois não aparecem neste projeto:
`provided` é para uma API que o lugar onde o programa roda já tem, e `runtime` para uma
implementação que o código nunca cita pelo nome, como um driver de banco de dados.

## Dois caminhos até uma biblioteca

Um grafo transitivo tem um problema que uma lista simples não tem: duas bibliotecas podem pedir a
mesma terceira em versões diferentes. Aqui o Commons Validator pede o Commons Logging 1.4.0, e o
BeanUtils, que o Validator também traz, pede a 1.3.5. A árvore acima mostrou só a vencedora. A
opção `verbose` mostra as perdedoras também, e `includes` corta a saída para as bibliotecas
envolvidas:

```
ana@vm:~/isbn-check$ mvn dependency:tree -Dverbose -Dincludes=commons-logging,commons-beanutils
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:isbn-check >-----------------------
[INFO] Building isbn-check 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-dependency-plugin:2.8:tree (default-cli) @ isbn-check ---
[INFO] com.example:isbn-check:jar:1.0.0
[INFO] \- commons-validator:commons-validator:jar:1.11.0:compile
[INFO]    +- commons-beanutils:commons-beanutils:jar:1.11.0:compile
[INFO]    |  \- (commons-logging:commons-logging:jar:1.3.5:compile - omitted for conflict with 1.4.0)
[INFO]    \- commons-logging:commons-logging:jar:1.4.0:compile
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.652 s
[INFO] Finished at: 2026-10-22T19:33:37-03:00
[INFO] ------------------------------------------------------------------------
```

O Validator declara o Commons Logging 1.4.0 ele mesmo, a dois passos do seu projeto. O BeanUtils
pede a 1.3.5 um passo mais abaixo, e a linha entre parênteses diz que esse pedido foi **omitido por
conflito** (`omitted for conflict`): o build tem um Commons Logging só no classpath, e é o 1.4.0.

**O mais perto vence** é a regra do Maven: de duas versões de uma biblioteca, usa-se a que está a
menos passos do seu projeto, e quando estão à mesma distância, a declarada primeiro. É uma regra
sobre a posição no grafo, não sobre qual versão é mais nova. Aqui a mais perto calha de ser também a
mais nova, o que esconde a regra; no dia em que uma versão antiga vencer, é a regra que explica.
Quando a vencedora não é a versão de que você precisa, **declare a biblioteca você mesmo**, na
versão que quer, e a sua declaração é a mais perto que existe. Um elemento `<exclusions>` dentro de
uma dependência faz o trabalho oposto: remove uma biblioteca transitiva que uma dependência arrasta
e que o seu programa não pode ter.

## Para onde os jars foram

Nada foi copiado para dentro do projeto. Todo jar que o Maven buscou fica num diretório só, na sua
pasta pessoal, o **repositório local**:

```
ana@vm:~/isbn-check$ ls ~/.m2/repository/commons-validator/commons-validator/1.11.0
_remote.repositories
commons-validator-1.11.0.jar
commons-validator-1.11.0.jar.sha1
commons-validator-1.11.0.pom
commons-validator-1.11.0.pom.sha1
```

Quatro tipos de arquivo. O jar é a biblioteca. O pom é a descrição da própria biblioteca, e foi ali
que o Maven leu que o Validator precisa de mais quatro. Cada `.sha1` é um checksum que o Maven
comparou com o que baixou, para que um jar estragado no caminho seja notado. O
`_remote.repositories` é a anotação do Maven sobre de qual repositório os arquivos vieram. E o
caminho são as coordenadas, grupo, artefato e versão, um diretório para cada: a seção sobre plugins
e repositórios desenha isso.
