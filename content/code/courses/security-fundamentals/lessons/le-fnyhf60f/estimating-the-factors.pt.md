---
title: Estimando probabilidade e impacto
version: 1
---

A fórmula **risco = probabilidade × impacto** só é tão boa quanto os dois números que entram nela,
e nenhum dos dois sai de uma tabela. Os dois são estimativas, e a habilidade útil é saber o que os
move.

### O que deixa uma ameaça mais provável

Probabilidade é a chance de uma ameaça específica ter sucesso contra uma vulnerabilidade específica
num período, em geral um ano. Quatro perguntas a movem:

| pergunta | sobe a probabilidade | desce |
|---|---|---|
| **exposição:** quem alcança a fraqueza? | qualquer um na internet | só a rede do escritório, só um administrador |
| **facilidade:** quão difícil é explorar? | uma senha padrão que qualquer um acha | uma falha que exige acesso físico e habilidade |
| **motivação:** tem alguém procurando? | scanners automáticos varrem a internet atrás dela | exige alguém mirando a loja pelo nome |
| **controles existentes:** o que já está no caminho? | nada | MFA, uma regra de firewall, um monitoramento que perceberia |

A primeira e a última linha são as que o defensor controla. Uma loja não consegue deixar criminosos
menos motivados, e consegue tirar o portal do alcance da internet e pôr um segundo fator nele. É por
isso que tanto deste curso é sobre exposição e controles: são as alavancas.

O histórico também ajuda. Se os notebooks da loja são perdidos ou roubados mais ou menos uma vez a
cada dois anos, essa é uma probabilidade com evidência por trás, e a aula 3 transforma exatamente
esse tipo de número em dinheiro.

### O que deixa um impacto maior

O impacto começa pela tríade: qual propriedade de qual ativo se perde. Ele fica útil quando é
traduzido no que o negócio de fato sofre:

| tipo de impacto | na livraria |
|---|---|
| **financeiro** | vendas perdidas com o site fora, dinheiro roubado, o custo da limpeza |
| **legal e regulatório** | um incidente com dado pessoal comunicado à ANPD, multas pela LGPD (aula 17) |
| **reputacional** | clientes que param de comprar depois que os dados deles vazaram |
| **operacional** | equipe que não consegue trabalhar enquanto os sistemas são restaurados |
| **segurança física** | raro numa livraria; central num hospital ou numa fábrica |

O mesmo incidente pode pontuar diferente em cada linha. Um dia fora do ar em fevereiro é sobretudo
impacto financeiro; o mesmo dia na semana antes do Natal é um impacto bem maior. Vazar a lista de
preços não tem impacto; vazar a lista de clientes tem impacto legal, reputacional e, para os
clientes, pessoal.

**O impacto é julgado pelo dono do ativo, não pela TI.** Quem cuida do financeiro sabe quanto custa
uma semana sem o sistema da folha; quem cuida da TI sabe quanto tempo levaria para restaurar. Uma
avaliação de risco precisa dos dois, e é por isso que a aula 3 começa perguntando a pessoas, e não
escaneando máquinas.
