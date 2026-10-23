---
title: Como diagramas C4 dão errado, e uma lista de verificação
version: 1
---

**A maioria dos erros em C4 vem de quebrar o vocabulário**: uma caixa que é um tipo de coisa
diferente das vizinhas, um nível que mostra o nível de baixo, uma linha que não diz nada. A notação
é livre; as palavras não são.

## Cinco erros comuns

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-c4-wrong\" aria-label=\"Um diagrama de containers com cinco erros, numerados. Um: uma caixa chamada serviço de reservas, um componente, entre containers. Dois: um balanceador de carga e um cluster Kubernetes desenhados como containers. Três: duas APIs, a de passagens e a de back office, as duas gravando num mesmo banco, sem dono nomeado. Quatro: toda linha com o rótulo usa. Cinco: uma caixa chamada ticketing sem tipo e sem tecnologia.\"><defs><marker id=\"l03-c4-wrong-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20.0\" y=\"38.0\" width=\"140.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"53.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Balanceador</text><text x=\"90.0\" y=\"66.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"20.0\" y=\"138.0\" width=\"140.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"153.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Cluster Kubernetes</text><text x=\"90.0\" y=\"166.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"260.0\" y=\"38.0\" width=\"140.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Ticketing</text><rect x=\"255.0\" y=\"138.0\" width=\"150.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"153.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Serviço de reservas</text><text x=\"330.0\" y=\"166.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Component]</text><rect x=\"485.0\" y=\"38.0\" width=\"150.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"53.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">API de back office</text><text x=\"560.0\" y=\"66.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Container: Kotlin]</text><path d=\"M395.0 217.0 L395.0 263.0 A75.0 7 0 0 0 545.0 263.0 L545.0 217.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"var(--panel)\"></path><ellipse cx=\"470.0\" cy=\"217.0\" rx=\"75.0\" ry=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></ellipse><text x=\"470.0\" y=\"238.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">Banco compartilhado</text><text x=\"470.0\" y=\"249.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"7.5\" fill=\"var(--paper-dim)\">[PostgreSQL]</text><path d=\"M160.0 60.0 L258.0 60.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"205.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">usa</text><path d=\"M90.0 82.0 L90.0 136.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"98.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">usa</text><path d=\"M330.0 82.0 L330.0 136.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"338.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">usa</text><path d=\"M370.0 182.0 L440.0 210.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"414.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">usa</text><path d=\"M560.0 82.0 L500.0 208.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"536.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">usa</text><circle cx=\"330.0\" cy=\"196.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"330.0\" y=\"196.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">1</text><circle cx=\"20.0\" cy=\"110.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"20.0\" y=\"110.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">2</text><circle cx=\"560.0\" cy=\"240.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"560.0\" y=\"240.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">3</text><circle cx=\"250.0\" cy=\"46.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"250.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">4</text><circle cx=\"410.0\" cy=\"40.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"410.0\" y=\"40.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">5</text></svg>", "caption": "Cada caixa e cada linha se desenha em qualquer ferramenta e está errada no vocabulário do C4. A lista desta seção encontra os cinco.", "same": ["Ticketing", "[Component]", "[Container: Kotlin]", "[Container]", "[PostgreSQL]"]}
```

1. **Níveis misturados.** O *serviço de reservas*, um componente, está no diagrama de containers ao
   lado do banco de dados. Quem lê não consegue distinguir as caixas que rodam sozinhas das que
   vivem dentro de outra coisa.
2. **Infraestrutura como container.** O *balanceador de carga* e o *cluster Kubernetes* estão
   desenhados como containers. Eles são onde os containers rodam, e isso pertence a um diagrama de
   implantação.
3. **O banco compartilhado sem dono.** Duas APIs gravam no mesmo banco, e nada diz qual delas é a
   dona. O desenho está correto e esconde o fato mais importante sobre ele: que mudanças de schema
   agora precisam de dois times.
4. **Linhas que dizem *usa*.** Toda seta traz o mesmo verbo, então o diagrama mostra que as coisas
   estão ligadas, e não por quê.
5. **Tipos e tecnologia faltando.** *Ticketing* sem `[Container: Kotlin]` poderia ser um serviço,
   um time, um schema de banco ou o sistema inteiro.

## A lista de verificação da revisão

O próprio site do C4 publica uma lista curta de verificação para revisões. No espírito dela, estas
são as perguntas para qualquer diagrama C4, e elas estendem o teste de leitura da aula 1:

| sobre | pergunta |
| --- | --- |
| **o diagrama** | Tem um título dizendo o nível e o escopo? Tem legenda? O escopo, um sistema ou um container, está claro? |
| **cada elemento** | Tem nome, tipo, tecnologia quando for relevante, e descrição? É o tipo certo de coisa para este nível? |
| **cada relação** | Tem uma descrição da intenção? Uma tecnologia, se quem lê é técnico? Um sentido que bate com a descrição? |
| **entre níveis** | Todo elemento pode ser rastreado até o nível de cima? Toda relação de um nível aparece, explicada, no nível de baixo? |

## Container ou componente: os casos difíceis

Alguns casos aparecem em todo time:

- **Uma função serverless** é um container: ela roda e é implantada sozinha.
- **Uma biblioteca compartilhada por dois serviços** é um componente de cada um, ou código, e não um
  container: ela nunca roda sozinha.
- **Um schema dentro de um servidor de banco compartilhado** é um container de dados próprio se tem
  dono e uso separados; o *servidor* de banco é infraestrutura.
- **Um monólito modular** é um container cujos módulos são componentes, e esse é todo o objetivo do
  estilo: as fronteiras existem dentro de uma única unidade implantável.

**Desenhe você também.** Pegue o diagrama errado desta seção e redesenhe-o corretamente: decida o
nível, tire o que pertence a outro lugar e escreva um verbo de verdade em cada linha.
