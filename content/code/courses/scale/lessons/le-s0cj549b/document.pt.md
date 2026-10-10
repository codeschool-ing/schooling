---
title: Documentos, tudo de uma coisa junto
version: 1
---

Um **armazenamento de documentos** guarda cada registro como um documento, geralmente JSON ou uma
forma binária dele, sob uma chave. Diferente de um chave-valor, ele olha por dentro: consegue
indexar um campo, filtrar por ele e devolver parte de um documento. Diferente de uma tabela
relacional, os documentos de uma coleção não precisam ter o mesmo formato, e um documento guarda
listas e objetos aninhados em vez de apontar para outras tabelas.

O segundo padrão de acesso da seção 03, a página de um show, é o caso para o qual ele foi feito. Nas
tabelas da bilheteria essa página é um join entre shows, casas, artistas e preços. Como documento é
uma leitura:

```json
{
  "_id": "show-1",
  "name": "Sabiá Festival, Sunday",
  "starts_at": "2026-11-15T18:00:00-03:00",
  "venue": { "name": "Arena Sul", "city": "São Paulo", "capacity": 12000 },
  "artists": ["Banda Ipê", "Marta Lins"],
  "prices": [
    { "section": "floor", "cents": 18000 },
    { "section": "upper", "cents": 9000 }
  ]
}
```

A casa está **embutida**: o nome e a cidade dela são copiados em todo show naquela casa, então a
página não precisa de mais nada. Essa é a decisão central da família dos documentos, tomada relação
por relação.

## Embutir ou referenciar

| embuta os dados relacionados quando | guarde uma referência, um id, quando |
|---|---|
| eles são lidos com o pai quase sempre | eles são lidos sozinhos, ou por muitos pais |
| eles são pequenos e limitados: alguns preços, alguns artistas | eles crescem sem limite: todo ingresso do show |
| eles mudam raramente, ou uma cópia velha é aceitável | eles mudam muito e toda cópia precisa acompanhar |

Os ingressos de um show falham nos três testes para embutir: podem ser doze mil, são lidos um de
cada vez e mudam o tempo todo. Embutidos, toda venda reescreveria um documento que cresce um
ingresso a cada vez. Então os ingressos são documentos próprios, cada um levando o id do show, o que
é uma **referência**: a mesma coisa que uma chave estrangeira, sem um banco que a confira.

**O custo de embutir é a atualização.** Quando a Arena Sul muda de nome, todo documento de show
naquela casa guarda o nome velho, e o programa precisa achá-los e reescrevê-los todos. Um banco
relacional tinha esse fato numa linha. Essa é a troca da desnormalização na forma mais simples:
**leituras mais baratas, pagas com escritas mais difíceis**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois documentos de show embutem cada um uma cópia da casa Arena Sul. Quando a casa muda de nome, as duas cópias precisam ser achadas e reescritas. Ao lado, os documentos de ingresso ficam à parte, cada um com só uma referência ao id do seu show.\"><rect x=\"20\" y=\"20\" width=\"220\" height=\"90\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-1</text><rect x=\"36\" y=\"56\" width=\"188\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">venue: Arena Sul</text><text x=\"130\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma cópia</text><rect x=\"20\" y=\"130\" width=\"220\" height=\"90\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-7</text><rect x=\"36\" y=\"166\" width=\"188\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">venue: Arena Sul</text><text x=\"130\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma cópia</text><text x=\"130\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">renomear a casa: reescrever as duas</text><rect x=\"440\" y=\"40\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ticket-101</text><text x=\"520\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">show: &quot;show-1&quot;</text><path d=\"M440 62 L240 65\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"440\" y=\"100\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ticket-102</text><text x=\"520\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">show: &quot;show-1&quot;</text><path d=\"M440 122 L240 65\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"440\" y=\"160\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ticket-103</text><text x=\"520\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">show: &quot;show-1&quot;</text><path d=\"M440 182 L240 65\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"520\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ingressos: referências, à parte</text></svg>", "caption": "Embutido: lido de uma vez, atualizado em todo lugar. Referenciado: guardado uma vez, juntado pelo programa."}
```

## O que um armazenamento de documentos dá e segura

- **Escritas atômicas num documento**, inclusive nas partes aninhadas. Mudar os preços e a data de
  um show juntos é uma escrita.
- **Índices em campos**, inclusive aninhados, então "todo show em São Paulo na semana que vem" é uma
  consulta e não uma varredura.
- **Transações entre documentos mais fracas ou mais caras.** O MongoDB as oferece desde a versão
  4.0, e elas custam mais que escritas num documento; um desenho que precisa delas em todo pedido
  geralmente escolheu os documentos errados.
- **Nada de joins no sentido de costume.** Montar dados de várias coleções é uma etapa de pipeline,
  mais lenta que um join relacional, ou duas consultas no programa.

O MongoDB é o membro mais conhecido da família, e a aula 5 o roda. As colunas `jsonb` do PostgreSQL
dão a um banco relacional boa parte do mesmo modelo dentro de uma tabela, o que muitas vezes basta.
