---
title: Requisitos no backlog
version: 1
---

Um requisito num arquivo CSV é uma promessa. **Ele vira trabalho quando chega ao lugar de onde a
equipe planeja o trabalho**, e esse lugar é o backlog, com as mesmas regras de prioridade de
qualquer outro item. Requisitos de segurança que moram num documento separado são feitos num tempo
separado, o que na prática quer dizer depois de todo o resto.

### Três formas que um requisito toma lá

| forma | quando cabe | na Vereda |
|---|---|---|
| **uma história própria** | o requisito é uma funcionalidade que alguém vai usar | R17, pacientes veem e encerram as sessões abertas |
| **critério de aceite numa história existente** | o requisito restringe uma funcionalidade que está sendo construída de qualquer jeito | R13 na história que redesenha a página de upload |
| **uma regra na definição de pronto** | o requisito vale para toda história de um tipo | a verificação de dono do R10, para toda história que devolve dados de um paciente |

A terceira forma é a mais poderosa e a menos usada. Uma regra na definição de pronto é conferida em
toda história sem ninguém precisar lembrar a ameaça por trás dela: "todo endpoint novo que devolve
dados de paciente confere que os dados pertencem ao paciente logado, e tem um teste que pede os de
outra pessoa".

### Mantendo o fio

Cada item do backlog leva o id do requisito, e o requisito leva o da ameaça. É tudo de que o fio
precisa. Quando o daniel pergunta por que uma história sobre números de telefone está acima de uma
história sobre o calendário de agendamentos, a resposta é o R19, que responde à T17, que é o caso de
abuso em que um ex-parceiro toma a conta de um paciente. Uma prioridade com motivo por trás
sobrevive à reunião de planejamento melhor que uma sem motivo.

### Quem decide a ordem

O dono do produto ordena o backlog, e itens de segurança não são exceção. O que o modelo de ameaças
contribui é a informação para ordená-los bem: qual objetivo cada ameaça põe em risco, do estágio 1
do PASTA, e de que tamanho é o risco, que as aulas 9 a 11 transformam em números. Quem é de segurança
e quer um requisito feito primeiro deveria conseguir dizer por quê nesses termos. Se não conseguir, a
ordem que o dono do produto escolheu provavelmente está certa.
