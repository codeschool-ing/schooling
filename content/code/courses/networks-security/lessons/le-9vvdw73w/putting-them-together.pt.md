---
title: Duas visões parciais formam um quadro
version: 1
---

Nenhum dos sensores conta sozinho a história inteira desta aula. Lado a lado, os registros deles da
mesma tarde ficam assim:

| momento | sensor de rede na DMZ | sensor de host no `www` |
|---|---|---|
| requisição 1 | alerta 1000101, `/admin/` por HTTP, respondida com 200 | log de acesso: `/admin/`, 200 |
| requisição 2 | uma conexão TLS para `www.example.com`, nada mais | log de acesso: `/admin/`, 200 |
| mudança de configuração | nada | AIDE: `sites-enabled/shop` alterado, de 602 bytes para 744 |
| novo listener | nada, até alguém se conectar | porta 8081, do `socat` |

**O host viu mais, e a rede viu de forma independente.** Se o `www` estivesse comprometido, o log de
acesso e os relatórios do AIDE dele poderiam ser editados para esconder as quatro linhas; o registro
do sensor de rede sobre a requisição 1 e sobre a conexão TLS não, porque o intruso nunca tocou no
`sensor`. Esse é o argumento para rodar os dois e para mandar os registros do host para fora do host.

**Correlação** é o nome de juntar as linhas, e é dela que vem a maior parte do valor da detecção. Um
sinal fraco na rede mais um sinal fraco no host, ao mesmo tempo, sobre a mesma máquina, é um sinal
forte. Fazer isso à mão, como esta tabela faz, funciona por uma tarde. Para fazer isso numa empresa
existe uma plataforma central de logs, um **SIEM**, e a aula 23 decide o que alimentar nela.

Um último ponto prático: **um HIDS em cada host é muito agente para manter**, e os hosts que mais
precisam de um raramente são aqueles em que é mais fácil instalá-lo. Impressoras, câmeras, appliances de rede e
sistemas industriais antigos não rodam agente nenhum. Para eles, o sensor de rede é a única
testemunha que existe.
