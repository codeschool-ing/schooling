---
title: Antes de comprar um
version: 1
---

O `sync.sh` tem cinquenta e cinco linhas e levou 2.649 contatos para um CRM. Um produto leva milhões para
dezenas de destinos, com APIs em lote, mapeamentos que conhecem os campos de cada destino, novas
tentativas ajustadas a cada API, alertas e um histórico que outra pessoa mantém. **A pergunta não é se o
produto faz mais. É se a empresa precisa daquilo de que ele faz mais**, pelo preço que custa.

Construa à mão quando há um destino, alguns milhares de registros e alguém que vai ser dono do script.
Compre quando os destinos se multiplicam, quando gente de fora do time de dados precisa montar públicos
sozinha, ou quando as horas gastas mantendo scripts vivos custam mais que a licença.

## Como eles cobram

Cada um dos três conta uma coisa diferente, e essa é a primeira coisa a ler na página de preços. A coleta
de eventos do Segment é cobrada por **monthly tracked users**, como a seção de identidade descreveu;
produtos de reverse ETL já cobraram pelo número de destinos, de registros sincronizados ou de recursos.
Preços e planos mudam com frequência suficiente para este curso não citar nenhum: leia a página no dia em
que decidir, e calcule qual seria a *sua* contagem — 2.649 contatos e um CRM é uma conta muito diferente
de dois milhões de visitantes por mês.

## Perguntas para fazer a um fornecedor

- **Onde os dados são tratados e guardados?** Que país, que nuvem, e se as linhas ficam guardadas depois
  de uma execução ou só passam.
- **Há um contrato de tratamento de dados**, e que suboperadores ele lista? Pela LGPD a empresa continua
  responsável pelo que o fornecedor faz com os dados.
- **Como ele chega ao warehouse?** Um usuário que só lê os modelos de que precisa, como o papel
  `metabase` da aula 3, e nunca o do dono. Se o motor dele guarda estado no warehouse, ele escreve num
  schema próprio e em nenhum outro lugar.
- **O que acontece com as exclusões e com um full resync**, para cada destino que você vai usar?
- **O que dá para levar embora?** Os modelos são o seu SQL e ficam com você. Os mapeamentos, agendamentos
  e públicos montados nas telas dele estão no formato do fornecedor; pergunte como são exportados,
  porque o dia em que você sair é o dia em que vai querê-los.
