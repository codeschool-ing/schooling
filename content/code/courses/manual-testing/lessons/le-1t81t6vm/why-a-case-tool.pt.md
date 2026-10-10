---
title: Para que serve uma ferramenta de casos
version: 1
---

É fácil imaginar uma ferramenta de gestão de casos como um arquivo de aço: um lugar para guardar
casos de teste para que não se percam numa pasta de documentos. Guardar é a menor parte do
trabalho. **O que uma ferramenta de casos acrescenta é a separação entre o caso, escrito uma vez, e
as suas execuções, cada vez que ele roda contra uma versão, com os vínculos entre eles e os
requisitos e defeitos de cada lado.** Tudo o que as quatro ferramentas desta aula vendem é
construído sobre essa separação.

## Quatro coisas que uma ferramenta mantém separadas

**Um repositório de casos.** Cada caso tem a forma que a aula 2 deu a ele: um id, uma
pré-condição, passos, um resultado esperado e o requisito que ele confere. O repositório os agrupa
em **suítes**, em geral uma por área do produto. O boxoffice teria quatro: contas, reservas,
pedidos e as próprias páginas.

**Execuções.** Uma execução é uma seleção de casos rodada contra uma versão, e guarda **um
resultado por caso**. A execução de regressão da aula 10 no boxoffice 1.1 é uma execução: os casos
que ela escolheu, a versão em que rodou e o que cada um fez. O caso é o mesmo texto em todas as
execuções; só o resultado pertence à execução.

**Histórico de resultados.** Como o caso é um objeto e as execuções são muitas, a ferramenta mostra
os resultados de um caso em todas as execuções de que ele participou. No boxoffice, o caso que
reserva dois ingressos de Hamlet como estudante passou na 1.0 e falhou na 1.1. Vistos como dois
documentos, são dois fatos; vistos como uma linha com dois resultados, são uma regressão, que é o
que vale notar.

**Rastreabilidade.** Um caso cita um requisito, um resultado que falhou cita um relato de defeito,
e a ferramenta segue esses vínculos nos dois sentidos. Perguntada "o R5 está testado, e está
passando?", ela lista os casos que citam o R5 e seus últimos resultados. Perguntada "o que este
defeito ameaça?", ela vai do relato de volta ao resultado que falhou, ao caso e ao requisito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l18-trace\" aria-label=\"Quatro tipos de caixa ligados por setas. O requisito R5, estudante paga meia, aponta para o caso TC-10, Student pays half, escrito uma vez. O caso aponta para duas execuções, cada uma com um resultado: a execução na 1.0 passou, a execução na 1.1 falhou. O resultado que falhou aponta para um relato de defeito, desconto de estudante perdido. Uma linha embaixo diz que os mesmos vínculos podem ser percorridos nos dois sentidos.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15.0\" y=\"60.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"78.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requisito R5</text><text x=\"90.0\" y=\"93.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">estudante paga meia</text><rect x=\"200.0\" y=\"60.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"78.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">caso TC-10</text><text x=\"275.0\" y=\"93.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Student pays half</text><rect x=\"385.0\" y=\"20.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"38.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">execução na 1.0</text><text x=\"460.0\" y=\"53.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">passou</text><rect x=\"385.0\" y=\"100.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"118.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">execução na 1.1</text><text x=\"460.0\" y=\"133.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">falhou</text><rect x=\"560.0\" y=\"100.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"118.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">relato de defeito</text><text x=\"635.0\" y=\"133.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">desconto de estudante perdido</text><path d=\"M165.0 86.0 L197.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M350.0 78.0 L382.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M350.0 94.0 L382.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M535.0 126.0 L557.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"275.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escrito uma vez</text><text x=\"460.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um resultado por execução</text><text x=\"635.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">citado pela falha</text><path d=\"M15.0 196.0 L710.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"362.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rastreabilidade: os mesmos vínculos, percorridos nos dois sentidos</text></svg>", "caption": "Um caso, escrito uma vez, e seus resultados em duas execuções. Os vínculos do requisito até o defeito são o que deixa uma ferramenta responder tanto \"o R5 está testado?\" quanto \"o que este defeito ameaça?\".", "same": ["Student pays half"]}
```

## Os resultados, e o que todo mundo confunde

Cada ferramenta tem sua lista de status, e toda lista tem quatro que querem dizer a mesma coisa em
qualquer lugar:

| status | o que diz |
|---|---|
| passou | o caso rodou e o resultado esperado aconteceu |
| falhou | o caso rodou e aconteceu outra coisa |
| bloqueado | o caso não pôde rodar, porque algo de que ele precisa está quebrado |
| não executado | ninguém o rodou ainda nesta execução |

**Bloqueado não é falhou**, e misturar os dois corrompe todo número construído em cima deles. Se a
reserva respondesse a toda requisição com uma página de erro, o caso do desconto de sócio não
chegaria até um preço. Marcá-lo como falhou diz que o desconto está errado, e ninguém sabe disso;
marcá-lo como bloqueado diz que o desconto não foi testado, o que é verdade, e aponta para o defeito
que impediu o teste. O relato da aula 15 sobre o erro na reserva é o que vai ser corrigido, e os
casos bloqueados rodam de novo depois.

## Quando um time precisa de uma

Uma testadora com dezessete casos e uma versão para cuidar guarda tudo de cabeça e numa planilha, e
a seção 04 desta aula mostra essa planilha para o boxoffice. A ferramenta começa a se pagar quando
uma destas coisas passa a ser verdade:

- mais casos do que uma pessoa consegue lembrar, de modo que achar "todo caso que mexe com
  reembolso" pede uma busca, e não a memória;
- mais de um testador, de modo que duas pessoas registram resultados na mesma execução ao mesmo
  tempo;
- mais de uma versão ou configuração para comparar, como os quatro navegadores da aula 7, cada um
  uma execução própria;
- alguém de fora do time pedindo evidência, como um auditor num banco ou num hospital, que quer ver
  que cada requisito foi testado, em que versão, por quem e com que resultado.

**Uma ferramenta não escreve os casos, e não os escolhe.** Um repositório cheio de casos que dizem
"conferir se a reserva funciona" é um banco de dados de casos que ninguém mais consegue rodar, o
assunto da aula 3. E decidir que casos entram numa execução é o ranking de riscos da aula 1 e as
escolhas de regressão da aula 10. O que uma ferramenta faz bem é guardar o registro que essas
decisões produzem, para que a próxima versão parta dele e não da memória.
