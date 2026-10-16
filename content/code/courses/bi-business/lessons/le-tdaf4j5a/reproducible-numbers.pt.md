---
title: Números que saem iguais um ano depois
version: 1
---

Um relatório interno responde a uma pergunta hoje. **Um relatório regulatório também precisa
respondê-la de novo, idêntica, sempre que alguém pedir**: um auditor no ano que vem, um regulador
daqui a três anos, os advogados da própria empresa numa disputa. "Rodamos a consulta de novo e deu
outro número" é a resposta que ninguém quer dar, e em dados vivos é a resposta que a consulta vai dar.

## Por que a mesma consulta dá outra resposta

As tabelas que um relatório lê continuam mudando depois da data de que o relatório trata. Pagamentos
chegam atrasados e são lançados com a data em que foram feitos. Empréstimos são renegociados e o
histórico deles, reescrito. O cadastro de um cliente é corrigido. Nada disso está errado; é o sistema
mantendo a verdade atualizada. Mas a verdade de 31 de dezembro de 2025, como a Ipê a conhecia em 5 de
janeiro de 2026, quando enviou o relatório, é outra coisa que a verdade sobre 31 de dezembro como se
conhece hoje.

Pegue os doze empréstimos da seção anterior. Em fevereiro de 2026, um pagamento que o cliente do
empréstimo 6 fez em 20 de dezembro, e que um arquivo bancário não tinha entregado, foi finalmente
lançado com a data verdadeira. Nas tabelas vivas, o empréstimo 6 passou a ter 70 dias de atraso em 31
de dezembro, e não 95. Troque B7 para 70 e olhe de novo a parcela inadimplente:

```localised
=ARRED(SOMARPRODUTO(C2:C13;D2:D13)/C14*100;1)      3,9
```

**10,5% foi enviado; a mesma consulta, na mesma data, agora diz 3,9%.** As duas estão certas. Só uma
delas é o que a Ipê disse ao regulador, e só uma pode ser defendida como o que a Ipê sabia quando
enviou. Se ninguém guardou os dados como estavam em 5 de janeiro, o número enviado não pode mais ser
produzido por ninguém.

## Quatro coisas que tornam um número reproduzível

**Uma foto congelada.** No dia do fechamento, os dados de que o relatório precisa são copiados para
uma tabela, ou um arquivo, que nunca mais é atualizado, com a data que representa no nome. O
relatório lê a foto, nunca as tabelas vivas. Correções que chegam depois entram no período seguinte,
ou num reenvio formal se a regra exigir, e a foto antiga fica como estava.

**Uma definição com versão.** A consulta que transforma a foto no número é guardada com uma versão, e
cada envio registra que versão o produziu. Quando o regulador muda a regra, ou a Ipê acha um erro na
própria consulta, a versão nova é acrescentada; a antiga não é sobrescrita, porque os envios do ano
passado foram feitos com ela.

**Linhagem.** Para cada número, o registro de onde ele veio: qual foto, quais tabelas dela, qual versão
da consulta. A aula 9 de `data-governance` trata de linhagem em geral; aqui ela é a resposta a "de
onde saiu esse 10,5%?" numa linha, em vez de uma semana de escavação.

**Quem aprovou, e quando.** Uma pessoa com nome confere o relatório antes de ele sair, e a aprovação
fica registrada com a data e o arquivo exato aprovado. É o começo de uma **trilha de auditoria**, o
registro de quem fez o que com os dados e quando, que a aula 10 de `data-governance` trata junto com
quanto tempo esses registros precisam ser guardados.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Cinco caixas da esquerda para a direita, ligadas por setas: os sistemas de origem; a cópia noturna; uma foto congelada com data de 31 de dezembro de 2025; o relatório, calculado com a versão 3 da definição; o arquivo enviado, aprovado por uma pessoa com nome. Embaixo das três últimas, o que cada uma guarda: a data da foto, a versão da definição, o nome e a data de quem aprovou.\" data-fig=\"l21-path\"><rect x=\"18.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"78.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">sistemas de origem</text><text x=\"78.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">crédito, cartões</text><path d=\"M140.0 95.0 L156.0 95.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M156.0 95.0 L147.9 98.9 L147.9 91.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"158.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"218.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">cópia noturna</text><text x=\"218.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">muda todo dia</text><path d=\"M280.0 95.0 L296.0 95.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M296.0 95.0 L287.9 98.9 L287.9 91.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"298.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"358.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">foto congelada</text><text x=\"358.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">posição de 31/12/2025</text><path d=\"M420.0 95.0 L436.0 95.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M436.0 95.0 L427.9 98.9 L427.9 91.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M358.0 134.0 L358.0 156.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"358.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nunca editada</text><rect x=\"438.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o relatório</text><text x=\"498.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inadimpl.: 90+ dias</text><path d=\"M560.0 95.0 L576.0 95.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M576.0 95.0 L567.9 98.9 L567.9 91.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M498.0 134.0 L498.0 156.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"498.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">definição v3</text><rect x=\"578.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"638.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">arquivo enviado</text><text x=\"638.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aprovado: Fernanda</text><path d=\"M638.0 134.0 L638.0 156.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"638.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">quem, quando, qual arquivo</text><text x=\"18.0\" y=\"30.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">muda</text><text x=\"298.0\" y=\"30.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fixo daqui em diante</text><text x=\"360.0\" y=\"225.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">refeito um ano depois a partir da foto, dá a mesma resposta</text></svg>", "caption": "O caminho dos sistemas até um relatório enviado. Tudo à direita da foto é fixo e registrado, e é isso que permite produzir o mesmo número de novo quando alguém pedir."}
```

## O custo, e por que ele é pago

Nada disso sai de graça. Uma foto por mês por relatório é armazenamento; uma consulta com versão é
disciplina; uma aprovação é o tempo de uma pessoa alguns dias antes de cada prazo. Para um painel
interno, muitas vezes é mais do que a pergunta merece. Para um relatório regulatório, é o mínimo, e
o hábito vale levar de volta ao trabalho interno sempre que um número for citado depois: **os números
de fim de ano que Helena apresenta ao conselho da Varanda na aula 16 são exatamente o tipo de número
que alguém pede para ver de novo**, e uma foto congelada de 31 de dezembro custa uma noite de janeiro.
