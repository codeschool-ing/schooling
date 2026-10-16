---
title: Para que serve o Bazel
version: 1
---

A imagem que vem fácil é a de que o Bazel é um terceiro Maven: mais um formato de arquivo que
baixa dependências e roda o `javac`, talvez mais rápido. Ele baixa e ele compila, mas essa imagem
deixa de fora aquilo em torno do que o Bazel foi construído. **O Bazel não sabe nada de Java.** Ele
conhece **ações**: comandos com todas as entradas e todas as saídas declaradas de antemão. Ensinar
Java a ele é trabalho de um conjunto de regras, o `rules_java`, carregado como uma biblioteca. O
Maven, ao contrário, parte das convenções do Java e completa o resto.

O Bazel nasceu dentro do Google como **Blaze**, a ferramenta que compila o repositório único do
Google, onde fica a maior parte do código da empresa, em muitas linguagens. O Google o publicou
como Bazel em 2015. O desenho dele decorre desse repositório: quando uma mudança toca um arquivo
entre milhões, o build precisa achar exatamente o que esse arquivo afeta, recompilar isso e nada
mais, e rodar só os testes que a mudança pode ter quebrado.

## Hermético, para poder ir para o cache

Uma ação é **hermética** quando nada fora das entradas declaradas consegue mudar o resultado dela.
O Bazel garante isso: cada ação roda num sandbox onde só existem os arquivos declarados, então um
arquivo-fonte que alguém esqueceu de declarar é erro de compilação em toda máquina, em vez de um
build que funciona no notebook onde o arquivo por acaso está. As ferramentas também contam como
entradas. Por conta própria, o Bazel baixa o JDK com que compila e o fixa, em vez de usar o `java`
que a máquina tiver no `PATH`.

Essa disciplina é o que paga o cache. Como toda entrada é conhecida, o Bazel consegue calcular um
hash de todas elas, a **chave da ação**, e duas ações com a mesma chave produzem a mesma saída onde
quer que rodem:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Quatro entradas de uma ação de compilação, o arquivo-fonte, o jar que ele usa, a linha de comando do javac e o JDK, viram juntas uma chave de ação. Com a chave, o Bazel procura no cache local, depois num cache remoto que a equipe compartilha, e só quando nenhum dos dois tem a saída ele roda o javac e guarda o resultado sob a chave.\"><defs><marker id=\"bz-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IsbnCheck.java</text><line x1=\"220\" y1=\"38\" x2=\"268\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><rect x=\"20\" y=\"75\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">commons-validator-1.11.0.jar</text><line x1=\"220\" y1=\"93\" x2=\"268\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><rect x=\"20\" y=\"130\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a linha de comando do javac</text><line x1=\"220\" y1=\"148\" x2=\"268\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><rect x=\"20\" y=\"185\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o JDK em que ele roda</text><line x1=\"220\" y1=\"203\" x2=\"268\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><rect x=\"270\" y=\"95\" width=\"150\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"345\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chave da ação</text><text x=\"345\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um hash de todas as entradas</text><rect x=\"470\" y=\"20\" width=\"210\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  procura no cache local</text><rect x=\"470\" y=\"85\" width=\"210\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2  depois no cache remoto</text><text x=\"575\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">que a equipe inteira usa</text><rect x=\"470\" y=\"160\" width=\"210\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  só então roda o javac,</text><text x=\"575\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">e guarda a saída sob a chave</text><line x1=\"420\" y1=\"125\" x2=\"468\" y2=\"38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><line x1=\"575\" y1=\"56\" x2=\"575\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#bz-ah)\"></line><line x1=\"575\" y1=\"131\" x2=\"575\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#bz-ah)\"></line><text x=\"575\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um acerto em 1 ou 2 nem chega a abrir o compilador</text></svg>", "caption": "Uma ação, do jeito que o Bazel a vê. Mude qualquer entrada e a chave muda; não mude nenhuma e a saída já existe em algum lugar."}
```

O **cache local** fica em `~/.cache/bazel` e deixa rápido o segundo build numa máquina, o que o
build incremental do Gradle, na aula 2, também faz. O **cache remoto** é onde o desenho se paga: um
servidor que a equipe inteira e as máquinas de CI compartilham. Uma colega que compilou o mesmo
commit uma hora atrás já guardou as saídas, então o seu build as baixa em vez de compilar. A
**execução remota** vai um passo além e manda as próprias ações para uma fazenda de máquinas, de
modo que um build de milhares de alvos roda mil compiladores ao mesmo tempo. Os dois falam um
protocolo aberto, a Remote Execution API, e várias empresas os vendem como serviço.

## Onde uma pessoa que programa em Java o encontra

Sobretudo em dois lugares. O primeiro é uma empresa com um **monorepo**, um repositório só com
muitos serviços e bibliotecas, muitas vezes em várias linguagens ao mesmo tempo: serviços Java ao
lado de ferramentas em Go, um front end em TypeScript e os arquivos Protocol Buffers que todos
compartilham. Maven e Gradle compilam bem uma linguagem e o resto por plugins; o Bazel compila
todas com um grafo só, e `bazel test //...` roda de novo apenas os testes que um commit pode ter
mudado. O segundo é um projeto de código aberto que compila com ele. O Selenium e o servidor de
revisão de código Gerrit, os dois em boa parte Java, são dois que você talvez clone um dia e
encontre um `MODULE.bazel` onde esperava um `pom.xml`.

O que você dificilmente vai encontrar é um serviço Spring Boot de uma equipe, compilado com Bazel,
sozinho. A última seção desta aula diz por quê.
