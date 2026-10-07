---
title: Para que serve este curso
version: 1
---

**Dado é responsabilidade antes de ser ativo.** Uma tabela de clientes é uma lista de pessoas que
confiaram a uma empresa o nome, o endereço e, numa farmácia, os remédios que tomam. Tudo o que
este curso ensina é um jeito de tornar essa confiança mensurável: quem pode ler a tabela, o que
está cifrado e com qual chave, o que a lei diz que a empresa pode fazer com ela, por quanto tempo
ela é guardada e quem mudou o quê.

O curso acompanha uma empresa. A **Farmácia Ipê** é uma farmácia online com clientes no Brasil
inteiro. Ela não existe, e ninguém no banco dela existe: o laboratório gera cada linha a partir de
sementes fixas, e monta os dados de modo que não possam ser reais. Todo CPF ali falha no próprio
dígito verificador, todo e-mail fica num domínio reservado para exemplos, e não aparece número de
telefone nenhum. A aula 6 explica por que dado de teste é feito assim.

A Ipê é uma farmácia de propósito. A lista de clientes de uma livraria é dado pessoal. A de uma
farmácia também é dado **sensível** no sentido da LGPD, porque um pedido de insulina diz algo
sobre a saúde de alguém. Essa diferença muda o que a lei exige, e a maior parte das decisões do
curso gira em torno dela.

## O que ele pressupõe

`sql-databases` é o único curso exigido: governa-se dado que mora em algum lugar, e aqui ele mora
no PostgreSQL. Você precisa conseguir ler um `SELECT` com join, criar uma tabela e saber o que é
chave primária. Nada aqui supõe que você já estudou segurança ou direito. Onde um assunto tem
curso próprio, este avisa e ensina o suficiente para usá-lo.

## Como ele se organiza

As onze aulas vão da porta para dentro e depois para fora:

| aulas | o que cobrem |
|---|---|
| 1 e 2 | quem pode conectar, e o que cada papel pode ler, até a linha e a coluna |
| 3 e 4 | criptografia no fio e no disco, e as chaves que fazem ela valer alguma coisa |
| 5 | mudar o próprio dado para que menos dele seja perigoso: mascaramento, tokens, anonimização |
| 6 a 8 | o que são dado pessoal e dado sensível, a LGPD na prática, a GDPR e o AI Act europeu |
| 9 e 10 | governança: qualidade, linhagem, responsabilidade, retenção e trilha de auditoria |
| 11 | combinar com outros times o que um conjunto de dados é, e manter o combinado |

**Lei e técnica são ensinadas juntas**, porque uma é incompleta sem a outra. Uma base legal para
o tratamento não adianta nada se todo analista lê todas as colunas, e um esquema de permissões
perfeito continua ilegal se ninguém tinha motivo para coletar o dado.

::: track bi
Na trilha de BI, o mais provável é que você seja quem recebe o acesso, não quem concede. É nessa
cadeira que a governança mais se quebra por acidente: uma exportação para planilha, um painel
compartilhado por link, um join que reidentifica alguém. As aulas são escritas do lado da
engenharia porque é ali que os controles são construídos, e você vai precisar saber para que
serve cada um quando pedir uma exceção a ele.
:::

::: track data-platform
Na trilha de plataforma de dados, você é quem constrói os controles. Quase tudo o que vem a
seguir é seu para operar: os papéis, a criptografia, a gestão de chaves, os jobs de retenção e a
auditoria. As aulas jurídicas estão aqui porque é o time de plataforma que ouve, numa sexta à
tarde, se um pedido do encarregado dá para ser atendido até segunda.
:::

::: track *
Seja qual for o seu lado da permissão, as aulas são escritas do lado que constrói os controles,
porque é ali que dá para vê-los funcionando. Se você costuma ser quem pede acesso, ao menos vai
saber para que serve cada controle quando pedir uma exceção a ele.
:::

## O que ele não cobre

A criptografia em si — como o AES ou um handshake TLS funcionam por dentro — é o curso
`cryptography`. A aula 3 daqui usa criptografia e explica o bastante para escolher onde
aplicá-la. Ataques não são ensinados em lugar nenhum deste curso: toda aula é escrita do lado de
quem defende, sobre como um controle é construído, como é verificado e como uma falha é notada.
