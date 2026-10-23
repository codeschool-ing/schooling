---
title: Quando o Bazel compensa, e quando não
version: 1
---

Pense na equipe que este curso tem em mente: cinco pessoas, um serviço Spring Boot, um
repositório. **Para elas, o Bazel custa mais do que devolve.** O build já leva um minuto, não há
código de mais ninguém no repositório, e cada hora gasta no build é uma hora a menos no serviço.

O custo é concreto, e as duas últimas seções mostraram a maior parte dele:

- **Cada dependência é nomeada, jar por jar, com o hash.** Uma `<dependency>` do pom da aula 1
  virou cinco entradas `http_jar` aqui, porque o Maven resolve a árvore transitiva e o `http_jar`
  busca exatamente o que mandam. A livraria que este curso constrói a partir da aula 4 resolve 39
  jars na primeira aula dela e 125 na aula 22. O conjunto de regras `rules_jvm_external` fecha boa
  parte dessa distância, gerando os alvos a partir de uma lista de coordenadas Maven e de um
  arquivo de lock, e traz as próprias dependências e a própria curva de aprendizado.
- **O mundo Java parte do Maven ou do Gradle.** O próprio plugin do Spring Boot gera o jar
  executável que a aula 23 publica; o IntelliJ IDEA abre um `pom.xml` do jeito que ele está e um
  projeto Bazel por meio de um plugin; a maioria das respostas que você procura está escrita em
  termos de `pom.xml`. JUnit 5 e as versões seguintes precisam de um launcher próprio, como o
  teste da seção anterior precisou.
- **Alguém precisa cuidar do build.** Arquivos BUILD são código, escrito em Starlark, e as regras,
  as toolchains e um cache remoto são infraestrutura para atualizar e manter de pé.

A troca vira para o outro lado quando o repositório cresce além do que uma equipe consegue ter na
cabeça:

| | Maven (aula 1) | Gradle (aula 2) | Bazel |
|---|---|---|---|
| o que ele compila | um projeto, por fases | um projeto, por tarefas | um grafo de alvos, por ações |
| dependências | resolvidas a partir de coordenadas | resolvidas a partir de coordenadas | declaradas por alvo, fixadas por hash |
| reaproveitamento entre builds | classes cujas fontes não mudaram; os testes rodam toda vez | saídas de tarefas atualizadas, e um build cache | toda ação e todo resultado de teste, pela chave |
| compartilhado entre máquinas | só com a extensão de build cache | com um build cache remoto | cache remoto, e execução remota |
| linguagens | Java, outras por plugin | JVM primeiro, outras por plugin | qualquer uma, por conjuntos de regras |

O Bazel compensa quando várias destas valem ao mesmo tempo: **muitas equipes num repositório só**;
várias linguagens que dependem umas das outras; tempo de CI gasto principalmente recompilando e
retestando código que nenhum commit tocou; a exigência de que o mesmo commit gere os mesmos bytes
em qualquer máquina. O Google, onde ele nasceu, tem as quatro. Uma empresa de duzentas pessoas
desenvolvendo num repositório só pode muito bem ter três.

O resto deste curso compila com Maven. A aula 2 diz por que Maven e não Gradle, e o motivo tem a
ver com ler o build, não com a ferramenta. Contra o Bazel, os motivos são os de cima: um serviço,
uma linguagem e um ecossistema que começa num `pom.xml`. Se você entrar numa empresa que usa Bazel,
o que esta aula deixa com você é o vocabulário — `MODULE.bazel`, arquivos BUILD, alvos, rótulos,
conjuntos de regras — e o motivo por trás de cada um.
