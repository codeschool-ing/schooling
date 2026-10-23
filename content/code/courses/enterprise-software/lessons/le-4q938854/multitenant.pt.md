---
title: Uma plataforma, muitos inquilinos
version: 1
---

A primeira reunião de Joana com Talita Gomes, a administradora de Salesforce da Serra Alta, começou
com a pergunta que ela fazia sobre qualquer sistema na fintech: onde roda o banco de dados, e o time
de relatórios pode ter uma réplica de leitura? Talita riu, sem maldade. **Não existe um banco de
dados ao qual a Serra Alta possa se conectar, e não vai existir.** O Salesforce não é um software que
a Serra Alta instalou em algum lugar. É uma plataforma só, compartilhada por muitos milhares de
empresas, e a Serra Alta aluga uma fatia dela, que o Salesforce chama de **org**.

Todo o resto desta aula decorre dessa frase. O jeito de customizar o Salesforce, o jeito de
integrar com ele e os limites que aparecem pelo caminho são todos consequências do
compartilhamento.

## Hospedado não é o mesmo que multitenant

A imagem comum é a de uma cópia hospedada. Em algum data center um servidor roda "o
Salesforce da Serra Alta", com o banco da Serra Alta dentro, do jeito que uma empresa de hospedagem
poderia rodar uma cópia de um ERP para cada cliente. Esse arranjo existe e tem nome, hospedagem
single-tenant. Não é este.

**Numa plataforma multitenant, todo cliente roda no mesmo código de aplicação e no mesmo banco de
dados, e o que os mantém separados é um identificador em cada linha.** As contas, as oportunidades e
os casos da Serra Alta ficam nas mesmas tabelas físicas que os registros de um banco, de um hospital
e de um varejista, cada linha carimbada com a org a que pertence. A plataforma acrescenta essa
condição a toda consulta que executa em seu nome. Você nunca a vê e não consegue removê-la.

A objeção óbvia é que as empresas querem campos diferentes. A Account da Serra Alta tem um campo para
o número de cliente no SAP e outro para a capacidade de refrigeração do depósito de um distribuidor;
a Account de um banco não tem nenhum dos dois. Se toda org compartilha uma tabela, onde moram esses
campos?

**A resposta é que um campo que você cria é um dado sobre a sua org, não uma mudança no banco.**
Quando Talita cria um campo, nenhum `ALTER TABLE` roda em lugar nenhum. A plataforma grava uma linha
de **metadados**: esta org, este objeto, um campo com este nome, este tipo e este rótulo. A descrição
que o próprio Salesforce publicou do desenho, escrita quando a plataforma ainda se chamava Force.com,
explica que os registros ficam em grandes tabelas compartilhadas com colunas genéricas, e que os
metadados dizem qual coluna genérica guarda qual dos seus campos. Quando uma página é desenhada, um
relatório roda ou uma chamada de API chega, a plataforma lê os seus metadados e monta a resposta a
partir deles.

É por isso que um campo novo aparece no editor de páginas, nos relatórios e na API segundos depois de
salvo. É também por isso que toda a sua configuração pode ser lida como arquivos, assunto a que a
seção 03 volta, e por isso que ninguém nunca vai lhe entregar uma string de conexão. Os seus dados
estão em tabelas que você não reconheceria, misturados com os de todo mundo.

## Objetos padrão e objetos customizados

O Salesforce chama suas tabelas de **objetos** e suas colunas de **campos**. Alguns objetos vêm com
toda org, porque toda empresa que vende precisa deles. Estes são os cinco que um arquiteto encontra
primeiro:

| objeto padrão | o que é um registro | na Serra Alta |
|---|---|---|
| Account | uma empresa para quem você vende, ou uma unidade dela | uma rede de supermercados, um distribuidor, uma das 300 lojas de uma rede |
| Contact | uma pessoa numa conta | o comprador da categoria de laticínios da rede |
| Lead | alguém que pode virar cliente, ainda não qualificado | uma rede regional que pediu uma tabela de preços |
| Opportunity | uma venda possível, com valor, estágio e data | um ano de fornecimento de leite UHT a um distribuidor novo |
| Case | um problema que um cliente levantou | uma reclamação sobre um pote de iogurte estufado; uma dúvida sobre um lote recolhido |

Tudo o que uma empresa acrescenta é customizado, e **o nome de API de um objeto ou campo customizado
termina em `__c`**. A Serra Alta tem `Visit__c`, um registro por visita que um representante faz a
uma loja, e `Invoice__c`, uma cópia das faturas que o SAP emite, preenchida toda noite por uma
integração. Ela também tem campos customizados em objetos padrão: `Account.SAP_Customer_Number__c` é
um campo que a Serra Alta acrescentou à Account padrão. O sufixo ajuda quando você lê um mapeamento de
integração, porque diz na hora qual metade de um nome veio do Salesforce e qual metade alguém da Serra
Alta inventou.

Você lê os dados com **SOQL**, a linguagem de consulta do Salesforce. Ela parece SQL e é mais
estreita: um `SELECT` sobre um objeto e os objetos relacionados a ele, sem joins arbitrários, sem
`UPDATE` e sem caminho que passe por fora da plataforma.
`SELECT Name, SAP_Customer_Number__c FROM Account WHERE Industry = 'Retail'` é uma consulta SOQL, e
ela roda pela plataforma como todo o resto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l04-tenants\" aria-label=\"Quatro orgs lado a lado no alto: a org da Serra Alta, as orgs de duas outras empresas e uma caixa para as milhares restantes. Cada uma guarda seus próprios metadados e suas próprias linhas. Abaixo delas, uma linha tracejada âmbar, os governor limits, vale para todas as orgs igualmente: por transação, 100 consultas SOQL, 150 comandos DML e 10 segundos de CPU. Sob a linha está uma plataforma só: servidores de aplicação compartilhados, tabelas compartilhadas em que um campo é uma linha de metadados e não uma coluna, e três releases por ano chegando a todas as orgs ao mesmo tempo.\"><defs><marker id=\"l04-tenants-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"21.0\" y=\"28.0\" width=\"158.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">org da Serra Alta</text><text x=\"100.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seus metadados</text><text x=\"100.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">suas linhas</text><path d=\"M100.0 114.0 L100.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 176.0 L100.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-tenants-es-ah-paper-dim)\"></path><rect x=\"194.0\" y=\"28.0\" width=\"158.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"273.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">org de um banco</text><text x=\"273.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seus metadados</text><text x=\"273.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">suas linhas</text><path d=\"M273.0 114.0 L273.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M273.0 176.0 L273.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-tenants-es-ah-paper-dim)\"></path><rect x=\"367.0\" y=\"28.0\" width=\"158.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">org de um hospital</text><text x=\"446.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seus metadados</text><text x=\"446.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">suas linhas</text><path d=\"M446.0 114.0 L446.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M446.0 176.0 L446.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-tenants-es-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"28.0\" width=\"158.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"619.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">milhares de outras</text><text x=\"619.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seus metadados</text><text x=\"619.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">suas linhas</text><path d=\"M619.0 114.0 L619.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M619.0 176.0 L619.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-tenants-es-ah-paper-dim)\"></path><path d=\"M24.0 150.0 L696.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"360.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">governor limits, iguais para todas as orgs: por transação, 100 consultas SOQL, 150 comandos DML, 10 s de CPU</text><rect x=\"24.0\" y=\"198.0\" width=\"672.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">uma plataforma só</text><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidores de aplicação e tabelas compartilhados, cada linha marcada com a sua org</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um campo que você cria é uma linha de metadados, não uma coluna sua</text><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três releases por ano, chegando a todas as orgs ao mesmo tempo</text></svg>", "caption": "O que multitenant quer dizer. Toda org roda no mesmo código e nas mesmas tabelas; a cerca entre elas e a plataforma são os governor limits, e é a mesma cerca para todas."}
```

## Três releases por ano, no calendário de outra pessoa

Na Serra Alta, o time de SAP decide quando o SAP muda. A aula 1 descreveu o calendário que o time de
Edson Prado mantém: a janela de manutenção todo domingo, da 01:00 às 05:00, e a semana congelada
enquanto o financeiro fecha o mês. **O Salesforce muda no calendário do Salesforce.** São três
releases principais por ano, chamados Spring, Summer e Winter seguidos de um ano, e cada um chega a
todas as orgs da plataforma em poucas semanas. O ano no nome corre à frente do calendário: um release
Winter chega no outono do hemisfério norte anterior a ele.

Você não pode recusar um release nem adiá-lo. O que você recebe é aviso: notas de release publicadas
antes da atualização, e uma **janela de preview** em que um sandbox pode ser atualizado algumas
semanas antes da produção. A rotina de Talita é construída sobre essa janela. O sandbox Full da Serra
Alta, a cópia da produção descrita na seção 03, entra no preview, e o time de Rui Andrade roda os
fluxos de integração contra ele antes de o release chegar aos 140 representantes.

Cada release também traz uma nova versão das APIs. As versões antigas continuam funcionando por anos,
até que o Salesforce anuncia que uma faixa delas será aposentada numa data. **Uma integração em que
ninguém mexe desde 2018 pode parar de funcionar por causa de uma data nas notas de release de outra
empresa**, e nada no registro de mudanças da própria Serra Alta vai explicar o porquê. Saber qual
versão de API cada fluxo chama agora faz parte do inventário de Rui.

## Governor limits: o preço de compartilhar

Uma plataforma compartilhada tem um problema que um servidor privado não tem. Se uma org roda um laço
mal escrito que consulta o banco um milhão de vezes, todas as outras orgs nos mesmos servidores ficam
lentas. A resposta da plataforma é pôr uma cerca em volta de todo código que roda nela.

**Toda transação no Salesforce roda sob governor limits, e o código que passa de um deles é
interrompido, não desacelerado.** Estes quatro existem há muito tempo e estão documentados na
própria referência de Apex do Salesforce:

| limite, por transação | síncrona | assíncrona |
|---|---|---|
| consultas SOQL emitidas | 100 | 200 |
| comandos DML (insert, update, delete…) | 150 | 150 |
| tempo de CPU | 10 segundos | 60 segundos |
| registros retornados por todas as consultas SOQL | 50.000 | 50.000 |

Um código escrito em Apex, a linguagem de programação do Salesforce, que emite a 101ª consulta numa
transação síncrona recebe uma exceção com uma mensagem famosa, `Too many SOQL queries: 101`. O Apex
não consegue capturá-la. **A transação inteira é desfeita**, inclusive cada registro que ela já tinha
gravado, e quem a iniciou, uma pessoa clicando em Salvar ou uma integração chamando a API, recebe o
erro.

Na fintech, uma consulta dentro de um laço era um endpoint lento, um gráfico que subia numa segunda e
um chamado para alguém consertar. Aqui é uma falha no instante em que o volume passa de uma linha, e a
linha é fixada pela plataforma, não pela Serra Alta. Joana achou o arranjo duro por mais ou menos uma
semana. Depois viu o que ele compra: nenhuma outra org consegue deixar a Serra Alta lenta, e o código
que sobrevive aos limites foi escrito para trabalhar com registros em conjuntos, que é o hábito que a
seção 04 mostra faltando na Serra Alta.

Também há limites no nível da org inteira, além da transação: quanto dado ela pode armazenar, e
quantas requisições de API todas as integrações juntas podem fazer em 24 horas. O segundo é onde a
Serra Alta se machucou, e ele tem uma seção só sua.

## Uma org gratuita para dar uma olhada

O Salesforce dá uma org **Developer Edition** gratuita a quem se cadastra. Ela tem os objetos padrão,
as telas de configuração, o Flow e as APIs, com armazenamento e cotas pequenos. **Nada nesta aula
depende dela.** Se você quiser ver o gerenciador de objetos, criar um campo e vê-lo aparecer na API,
é o jeito mais barato que existe de olhar o produto por dentro.
