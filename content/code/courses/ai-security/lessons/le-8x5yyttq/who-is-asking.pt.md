---
title: Quem está pedindo a chave
version: 1
---

A Tarefa está prestes a abrir o assistente a outras empresas por uma API: uma confeitaria que quer que
ele responda clientes, uma agência de tradução, um escritório de advocacia. Cada uma recebe uma chave,
e a chave chega ao fornecedor do modelo pela conta da própria Tarefa. **O que um cliente fizer com essa
chave, o fornecedor vê a Tarefa fazendo**, e o acordo da Tarefa com o fornecedor, como a maioria
deles, torna a Tarefa responsável por como os próprios clientes usam o acesso. A aula 7 tratou de
distinguir os usuários da Tarefa; esta aula trata de decidir quais empresas viram usuárias.

O primeiro instinto costuma ser que um formulário e um cartão de crédito bastam, já que quem paga é
cliente. O problema é que quem quer abusar de um modelo em escala prefere fazê-lo **pela conta de outra
pessoa**, para que o aviso, a conta e o banimento caiam em outro lugar. Uma API que entrega chaves a
qualquer um com cartão vira exatamente essa conta.

## O que o laboratório confere

Um pedido de acesso no laboratório é uma linha de JSON, escrita pelo curso, com uma empresa, o CNPJ,
um e-mail de contato, um site e o caso de uso que ela declara:

```
ana@lab:~/guard$ head -1 data/applications.jsonl
{"id": "ap-01", "company": "Doce Lar Confeitaria", "cnpj": "45.781.296/0001-63", "contact": "ana@docelar.example", "website": "docelar.example", "use_case": "customer-support", "description": "Answer our customers' questions about orders, delivery times and opening hours."}
```

A primeira verificação é aritmética. Um CNPJ traz dois dígitos verificadores, calculados a partir dos
doze anteriores, e um número digitado errado quase sempre falha:

```
ana@lab:~/guard$ guard cnpj 19.384.756/0001-01
19.384.756/0001-01  check digits WRONG
ana@lab:~/guard$ guard cnpj 19.384.756/0001-00
19.384.756/0001-00  check digits right
```

A conta diz que o número está bem formado, não que a empresa existe. A segunda verificação pergunta ao
cadastro. A Receita Federal publica dados de CNPJ, inclusive a situação cadastral e a data de abertura;
o `data/cnpj-registry.json` do laboratório é um substituto curto, escrito pelo curso, porque nada no
laboratório chega à rede. Depois vêm dois sinais mais baratos: se o e-mail de contato está no domínio
da própria empresa, e há quanto tempo ela foi aberta. Eis os oito pedidos, julgados em 30 de setembro
de 2026:

```
ana@lab:~/guard$ guard onboard data/applications.jsonl --now 2026-09-30
ap-01  Doce Lar Confeitaria   ACCEPT  tier-1   all checks passed
ap-02  Contrata Já RH         REVIEW  sandbox  use case hiring-screening needs a person to approve it
ap-03  Avalia+ Marketing      REVIEW  sandbox  company opened 41 days ago
                                               use case marketing-copy needs a person to approve it
                                               description says "5-star reviews", a prohibited use
ap-04  Nuvem Tradutora        VERIFY  sandbox  contact webmail.example is not at nuvemtradutora.example
ap-05  Clínica Bem Viver      REVIEW  sandbox  use case health-information needs a person to approve it
ap-06  Disparo Total          REFUSE  -        CNPJ status is INAPTA
                                               use case mass-messaging is prohibited
ap-07  Studio Pixel           REFUSE  -        CNPJ check digits are wrong
ap-08  Lima Advocacia         REVIEW  sandbox  use case legal-drafting needs a person to approve it
```

Cada decisão nomeia todas as regras que a produziram, não só a primeira, para que uma recusa possa ser
explicada à empresa e um erro possa ser corrigido. O Studio Pixel digitou o CNPJ com o último dígito
errado; o cadastro tem o certo, e a recusa diz qual verificação falhou. A Disparo Total é recusada duas
vezes: a Receita a lista como *inapta*, situação que ela atribui, entre outros motivos, a uma empresa
que deixou de entregar as declarações obrigatórias; e o caso de uso dela é proibido, assunto da próxima
seção.

## Sinais, não provas

Nenhuma dessas verificações prova que uma empresa é honesta. Um CNPJ real pode ser comprado junto com a
empresa dona dele, um domínio custa pouco, e uma empresa aberta há 41 dias pode ser uma startup
perfeitamente boa. Cada sinal encarece um pouco a mentira, e **o que eles decidem é com quanto a
empresa começa**, não se ela é confiável para sempre. É por isso que a Nuvem Tradutora, cujo contato
está num webmail e não no próprio domínio, recebe `VERIFY` e um sandbox em vez de uma recusa: confirmar
o e-mail no domínio resolve.

Os dados coletados aqui também são dados pessoais, ao menos o nome e o e-mail do contato, e a aula 12
vale para eles como para qualquer outra coisa: colete o que a decisão exige, e diga por quê.
