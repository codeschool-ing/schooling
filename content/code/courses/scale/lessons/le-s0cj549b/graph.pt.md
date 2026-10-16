---
title: Grafos, quando a pergunta é um caminho
version: 1
---

Um **banco de grafos** guarda **nós**, coisas, e **relações** entre eles, cada uma com um tipo e
propriedades próprias. O ponto não é que relações possam ser guardadas, já que uma tabela relacional
faz isso com chaves estrangeiras. **O ponto é que seguir uma é barato e custa o mesmo seja qual for
o tamanho do grafo**: cada nó guarda referências diretas às suas relações, então uma consulta anda
de nó em nó sem procurar num índice a cada passo.

O quarto padrão de acesso da seção 03 é uma caminhada: de um show, às pessoas que compraram
ingresso para ele, aos outros shows para os quais elas compraram. No grafo ela é desenhada como é
perguntada:

```
(:Show {name: "Sabiá Festival"})<-[:BOUGHT]-(:Buyer)-[:BOUGHT]->(:Show)
```

Isso é Cypher, a linguagem de consulta do Neo4j, e ela se lê como uma figura: nós entre parênteses,
relações como setas. Uma consulta completa acrescenta o que devolver:

```
MATCH (s:Show {name: "Sabiá Festival"})<-[:BOUGHT]-(b:Buyer)-[:BOUGHT]->(other:Show)
WHERE other <> s
RETURN other.name, count(b) AS shared
ORDER BY shared DESC
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um caminho num grafo. O show Sabiá Festival à esquerda está ligado por relações BOUGHT a três compradores. Dois dos compradores também têm relações BOUGHT com o show Noite de Choro, e um com Rock na Praça. O caminho conta as rotas: Noite de Choro é alcançado duas vezes, Rock na Praça uma.\"><circle cx=\"90\" cy=\"115\" r=\"46\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"90\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Sabiá</text><text x=\"90\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Festival</text><path d=\"M136 115 L308 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M308 45 L303.3 50.2 L301.0 44.6 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><circle cx=\"330\" cy=\"45\" r=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"330\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">comprador</text><path d=\"M136 115 L308 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M308 115 L301.7 118.0 L301.7 112.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><circle cx=\"330\" cy=\"115\" r=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"330\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">comprador</text><path d=\"M136 115 L308 185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M308 185 L301.0 185.4 L303.3 179.8 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><circle cx=\"330\" cy=\"185\" r=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"330\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">comprador</text><text x=\"220\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">BOUGHT</text><circle cx=\"600\" cy=\"70\" r=\"40\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"600\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Noite de Choro</text><text x=\"600\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">2</text><circle cx=\"600\" cy=\"170\" r=\"40\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"600\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Rock na Praça</text><text x=\"600\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1</text><path d=\"M352 45 L560 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M560 70 L553.4 72.3 L554.1 66.2 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M352 115 L560 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M560 70 L554.5 74.3 L553.2 68.4 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M352 185 L560 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M560 170 L553.9 173.5 L553.5 167.4 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"465\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compradores em comum por show</text></svg>", "caption": "De um show, pelos compradores dele, até os outros shows deles. Cada passo segue uma referência guardada.", "same": ["Sabiá", "Festival", "Noite de Choro", "Rock na Praça"]}
```

## Contra a mesma pergunta em SQL

Nas tabelas da bilheteria a mesma pergunta é um auto-join de `tickets` pelos compradores: os
ingressos do show, juntados a todo ingresso dos mesmos compradores, agrupados por show. Um salto é
um join que um banco relacional faz bem. **O custo aparece com a profundidade.** "Amigos de amigos de
amigos" são três auto-joins, cada um multiplicando as linhas que o próximo vê, enquanto uma caminhada
no grafo toca só os nós ao longo dos caminhos que segue. Perguntas de profundidade variável,
"qualquer cadeia de conexões de até seis", são naturais num grafo e desajeitadas em SQL.

## Onde serve, e onde não

Grafos servem para perguntas sobre **conexões**: recomendações, quadrilhas de fraude que dividem
cartões e endereços, permissões herdadas por grupos, dependências entre serviços. Servem mal para o
que este curso mais trata: **contar e somar conjuntos grandes**, e espalhar dados por muitos
servidores. Um grafo é difícil de dividir em shards, porque qualquer partição corta relações e toda
relação cortada é um salto pela rede. O Neo4j escala leituras com réplicas e mantém as escritas de
cada grafo num primário, que é o arranjo da aula 2 com outro modelo de dados.
