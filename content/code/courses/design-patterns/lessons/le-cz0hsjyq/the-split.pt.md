---
title: A divisão, um modelo de escrita e um de leitura
version: 1
---

**O CQRS, segregação de responsabilidade entre comando e consulta, leva a regra de Meyer dos métodos
para os modelos: os comandos vão para um modelo, feito para aplicar as regras, e as consultas vão
para outro, feito para responder às telas.** Greg Young deu o nome por volta de 2010, a partir de um
trabalho que ele e Udi Dahan vinham descrevendo havia alguns anos. O modelo de escrita é pequeno e
guarda só o que as regras verificam. O modelo de leitura tem a forma da tela que o lê, muitas vezes
uma tabela por tela, e é mantido em dia a partir das mudanças que o modelo de escrita faz.

A imagem com que a maioria chega são três coisas de uma vez: dois bancos de dados, um barramento de
mensagens entre eles e event sourcing por baixo. Nenhuma delas é obrigatória. O CQRS é a decisão de
ter dois modelos; onde eles moram e como o segundo é mantido em dia são decisões separadas, e a menor
versão disso tudo roda num processo Python sobre um arquivo SQLite.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l08-split\" aria-label=\"A divisão do CQRS para a biblioteca. À esquerda, o balcão. Em cima, o lado dos comandos: o balcão manda um comando como LendCopy para handle, que chama o modelo de escrita, Lending, que guarda só quem está com cada exemplar e quem está esperando, e aplica as regras. Quando um comando dá certo, Lending publica um evento como CopyLent. Um projetor à direita recebe o evento e atualiza o modelo de leitura embaixo, uma tabela de disponibilidade com uma linha por título, o autor, os exemplares na estante e quantos esperam. O lado das consultas: o balcão pergunta ao modelo de leitura com um SELECT e recebe linhas de volta, sem chegar perto do modelo de escrita.\"><defs><marker id=\"l08-split-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-split-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l08-split-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">lado dos comandos: regras, um modelo</text><text x=\"360.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">lado das consultas: moldado para as telas, quantos forem precisos</text><path d=\"M150.0 162.0 L580.0 162.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"20.0\" y=\"139.0\" width=\"110.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o balcão</text><rect x=\"215.0\" y=\"63.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">handle()</text><rect x=\"400.0\" y=\"50.0\" width=\"150.0\" height=\"96.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Lending</text><path d=\"M400.0 72.5 L550.0 72.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"408.0\" y=\"83.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">holder</text><text x=\"408.0\" y=\"98.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">waiting</text><path d=\"M400.0 109.5 L550.0 109.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"408.0\" y=\"120.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend()</text><text x=\"408.0\" y=\"135.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">give_back()</text><rect x=\"590.0\" y=\"145.0\" width=\"100.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">projetor</text><rect x=\"380.0\" y=\"206.0\" width=\"190.0\" height=\"74.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"217.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«table»</text><text x=\"475.0\" y=\"231.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">availability</text><path d=\"M380.0 243.0 L570.0 243.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"388.0\" y=\"254.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title, author</text><text x=\"388.0\" y=\"268.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">on_shelf, waiting</text><path d=\"M75.0 139.0 L75.0 80.0 L213.0 80.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-phosphor)\"></path><text x=\"140.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">LendCopy</text><path d=\"M325.0 80.0 L398.0 80.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-phosphor)\"></path><text x=\"362.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend</text><path d=\"M550.0 80.0 L640.0 80.0 L640.0 143.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-amber)\"></path><text x=\"596.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">CopyLent</text><path d=\"M640.0 179.0 L640.0 240.0 L572.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-amber)\"></path><text x=\"668.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">UPDATE</text><path d=\"M75.0 185.0 L75.0 236.0 L378.0 236.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-phosphor)\"></path><text x=\"220.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SELECT</text><path d=\"M378.0 260.0 L95.0 260.0 L95.0 187.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l08-split-dp-ah-paper-dim)\"></path><text x=\"220.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linhas</text></svg>", "caption": "Os comandos passam pelas regras e mudam o modelo de escrita; um evento leva a mudança ao modelo de leitura, que responde a toda consulta."}
```

## As duas formas, lado a lado

A classe tensionada da primeira seção já continha os dois modelos, misturados. Separados, é isto que
cada lado guarda para o mesmo momento, o Caio com o único *Vidas Secas* e a Bia esperando:

```python
# what the rules need: the write model
holder = {"C1": ("bia", date(2026, 3, 16)), "C3": ("caio", date(2026, 3, 16))}
waiting = {"T2": ["bia"]}

# what the availability screen needs: one row of the read model
{"title": "Vidas Secas", "author": "Graciliano Ramos", "on_shelf": 0, "waiting": 1}
```

O lado da escrita indexa tudo por exemplar, porque um empréstimo muda um exemplar. Não tem nomes nem
autores, porque nenhuma regra os lê. O lado da leitura indexa por título, carrega o autor e guarda
as contagens já contadas, porque é isso que a tela desenha. **Nenhuma das formas está errada; cada uma
está errada para o trabalho da outra**, e a tensão da primeira seção era o custo de forçar uma forma
só a fazer os dois.

## O que cada lado promete

| | o lado da escrita | o lado da leitura |
|---|---|---|
| recebe | comandos: `LendCopy`, `ReturnCopy`, `Reserve` | consultas: "o que está na estante?" |
| devolve | nada, ou uma recusa | linhas, já moldadas para uma tela |
| guarda | exatamente o que as regras verificam | o que uma tela mostra, duplicado à vontade |
| quantos | um por fronteira de consistência | tantos quantas forem as telas que precisam de formas diferentes |
| se for perdido | o estado da biblioteca se perde | é reconstruído a partir do lado da escrita, com algum custo |

A última linha é a que muda o jeito de tratar o lado da leitura. **Um modelo de leitura é um dado
derivado**: tudo nele pode ser recalculado a partir do modelo de escrita ou dos eventos que ele
publicou. É por isso que duplicar o nome do autor em toda linha é aceitável aqui, quando seria um
erro de normalização no modelo de escrita. Se um modelo de leitura sair errado, você corrige o
projetor e o reconstrói, e a lição 9 mostra essa reconstrução feita reaplicando todos os eventos.

## Três níveis de separação

O CQRS vem em graus, e a maioria dos sistemas que ganham com ele precisa só do primeiro ou do
segundo.

1. **Código separado, um armazenamento.** Comandos e consultas passam por classes diferentes, e o
   lado da leitura faz suas próprias consultas nas mesmas tabelas, na forma de views ou de SQL
   escrito para a tela. Nada é duplicado, e o ganho é que nenhum dos lados tem o código entortado
   pelo outro.
2. **Tabelas separadas, uma transação.** O modelo de leitura tem tabelas próprias, atualizadas na
   mesma transação da escrita. A tela lê uma tabela feita para ela, e ela nunca está desatualizada.
3. **Armazenamentos separados, atualizados depois.** O modelo de leitura mora em outro banco, num
   índice de busca ou num cache, e um projetor o atualiza depois que a escrita foi confirmada. As
   leituras escalam por conta própria, e podem estar desatualizadas, que é o assunto da seção sobre
   projeções.

O resto da lição constrói o nível 2 em memória e depois mostra o que muda no nível 3. A lição 13 de
`architecture` olha a mesma divisão do lado do sistema, com os armazenamentos, as mensagens entre
eles e o custo de operação; esta lição fica no código.
