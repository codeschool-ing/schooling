---
title: O que é um ADR, e a pergunta que ele responde
version: 1
---

O código responde *o quê* e quase nunca *por quê*. Abra o módulo de reservas do `coreto-core` e dá
para ler exatamente como funciona uma reserva de assento: uma transação abre, a linha do assento é
travada, e a trava fica até o comprador pagar ou desistir. O que não dá para ler é por que alguém
escolheu isso, o que mais foi considerado e o que era verdade na Coreto quando a escolha foi feita.
**Um registro de decisão de arquitetura guarda essa segunda metade.** É um documento curto, um por
decisão, escrito quando a decisão é tomada e guardado ao lado do código que ele explica.

## Para onde os motivos costumam ir

A maioria dos times acredita que os motivos já estão guardados em algum lugar. Pergunte, e apontam
para três lugares. Cada um perde os motivos do seu jeito.

O primeiro são **as pessoas que estavam lá**. Funciona até elas saírem, mudarem de time ou lembrarem
da reunião de um jeito diferente do colega sentado ao lado. A trava no código de reserva de assento é
mais antiga que qualquer pessoa do novo time de Reservas, e o engenheiro que a escreveu saiu da
Coreto há anos. Quando o diagnóstico do Davi apontou esse código como causa das aberturas de vendas
que falhavam, ninguém soube dizer se as travas tinham sido uma escolha pensada ou a primeira coisa
que funcionou.

O segundo é **o documento de design ou a RFC**. A aula 2 de `architect-communication` trata do
documento de uma página e da RFC interna, e eles são as ferramentas certas para propor uma mudança e
recolher objeções. São escritos antes da decisão, defendem uma opção e raramente são atualizados
quando a discussão termina em outro lugar. Um ano depois, a RFC descreve o que alguém queria, e quem
lê não consegue dizer que partes foram construídas.

O terceiro é **a conversa no chat e a reunião**. A decisão sai em algum ponto no meio de uma conversa
longa, ou é dita em voz alta numa sala e nunca escrita. A busca não a encontra, porque a palavra que
alguém vai digitar daqui a um ano não é uma palavra que alguém usou na época.

Um ADR difere dos três numa propriedade: **ele registra uma decisão que foi tomada, nos termos do
momento em que foi tomada**, e fica onde o próximo engenheiro a mexer naquele código vai encontrá-lo.

## O formato de Nygard

Michael Nygard propôs a forma num artigo curto, "Documenting Architecture Decisions" (2011). Ele
queria um documento que um time de fato escrevesse, então o limitou a cinco partes.

| parte | o que contém |
|---|---|
| título | uma frase nominal curta que nomeia a decisão, depois do número |
| status | proposto, aceito, obsoleto ou substituído |
| contexto | as forças em jogo: o que é verdade, o que restringe a escolha, o que puxa para cada lado |
| decisão | o que o time vai fazer, em frases completas e na voz ativa: "Vamos…" |
| consequências | o que passa a ser verdade quando a decisão vale, sejam boas, ruins ou neutras |

Ele pedia uma ou duas páginas, escritas como texto simples no repositório do projeto e numeradas em
sequência. Cada uma dessas escolhas tem uma função. Um registro curto é escrito no dia; um longo é
adiado até o contexto se perder. Um arquivo de texto no repositório é revisado no mesmo pull request
do código, e continua lá depois que a wiki mudou de lugar duas vezes.

O formato também é magro de propósito. Não há seção para quem aprovou, nem espaço para diagrama, nem
matriz de risco. Um time que acrescenta essas coisas tem liberdade para isso, e **um time que
acrescenta coisas demais para de escrever registros**, o que custa mais que qualquer campo ausente.

## O status é um ciclo de vida

O único campo que muda depois que um registro é aceito é o status. Todo o resto fica como foi
escrito, e a próxima seção desta aula se apoia nisso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"O ciclo de vida do status de um ADR. Proposto, em discussão, leva a Aceito, quando o time se compromete e o texto fica fixo. Aceito termina como Substituído, quando um ADR posterior o trocou e um aponta para o outro, ou como Obsoleto, quando não se aplica mais e nada o substituiu. Depois de aceito, só a linha de status muda.\"><defs><marker id=\"adrst-pt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"160\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Proposto</text><text x=\"100\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">em discussão;</text><text x=\"100\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nada construído</text><path d=\"M186 115 L224 115\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adrst-pt-ah)\"></path><rect x=\"230\" y=\"70\" width=\"180\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Aceito</text><text x=\"320\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o time se comprometeu;</text><text x=\"320\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o texto agora é fixo</text><path d=\"M416 104 L474 66\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adrst-pt-ah)\"></path><path d=\"M416 126 L474 172\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adrst-pt-ah)\"></path><rect x=\"480\" y=\"20\" width=\"220\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"48\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--amber)\">Substituído</text><text x=\"590\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um ADR posterior o trocou,</text><text x=\"590\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">e um aponta para o outro</text><rect x=\"480\" y=\"136\" width=\"220\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper-dim)\">Obsoleto</text><text x=\"590\" y=\"188\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">não se aplica mais,</text><text x=\"590\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">e nada o substituiu</text><rect x=\"20\" y=\"238\" width=\"680\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">depois de aceito, só a linha de status muda; uma decisão nova é um registro novo</text></svg>", "caption": "Os quatro status que Nygard nomeou. Só a linha de status muda depois da aceitação: uma decisão alterada é um registro novo que substitui o antigo, nunca uma edição."}
```

Um registro está proposto enquanto o time discute e aceito quando o time se compromete. Ele termina
de um de dois jeitos. **Substituído** quer dizer que um registro posterior tomou o lugar dele, e os
dois apontam um para o outro. Obsoleto quer dizer que a decisão não se aplica mais e nada ocupou o
lugar dela: quando a réplica antiga de relatórios da aula 5 for enfim desligada, o registro que a
escolheu fica obsoleto, e não substituído, porque não há sucessor para apontar.

## Que decisões merecem um registro

Nem toda escolha merece. A expressão de Nygard era "arquiteturalmente significativa": decisões que
afetam a estrutura do sistema, qualidades como desempenho e disponibilidade, suas dependências, suas
interfaces ou o jeito como ele é construído. Dois testes simples funcionam na Coreto.

- Sai caro reverter? Travar linhas para reservar assentos sai. Contratar um serviço de busca
  hospedado também (aula 8), ou o banco de dados em que um serviço novo guarda seus dados.
- Alguém vai perguntar "por quê" daqui a um ano e não vai conseguir descobrir? Se a resposta depende
  de algo verdadeiro só agora, como um prazo, a licença de um fornecedor ou o tamanho de um time,
  ela pertence ao papel.

A atualização de uma biblioteca, o nome de um módulo, o executor de testes que um time prefere:
nada disso precisa de registro. **Um time que escreve um para cada escolha logo não escreve nenhum**,
porque o log vira ruído, as pessoas param de lê-lo, e depois param de escrevê-lo.

A aula 16 também é uma boa fonte de registros. Uma decisão técnica que é uma decisão de produto
disfarçada, como quanto tempo dura uma reserva de assento, é exatamente o tipo em que, um ano depois,
alguém pergunta quem concordou com ela. O contexto do registro é onde mora essa resposta.
