---
title: Escolhendo um, e o que custa
version: 1
---

**Escolher um balanceador é responder às três perguntas da primeira seção em ordem**, e a maioria das escolhas
é feita pela primeira resposta que descarta alguma coisa.

| o caso do planner | o fato decisivo | o balanceador |
|---|---|---|
| o site público e a API dele | HTTP, clientes em todo lugar, TLS na borda | Application externo global |
| um serviço de relatórios que outras equipes chamam por dentro | HTTP, ninguém de fora, uma região | Application interno regional |
| um parceiro manda arquivos por SFTP | TCP, não HTTP, da internet | Network proxy externo |
| um pool interno de bancos de dados | TCP, por dentro, o banco precisa ver o endereço de quem chama | Network passthrough interno |
| um servidor de jogo em UDP | UDP, e os próprios pacotes do cliente | Network passthrough externo |

Duas regras práticas ficam atrás da tabela. **Se é HTTP, use um Application Load Balancer**, porque o mapa de
URL, o CDN e o Cloud Armor só estão ali. **Se o backend precisa ver o endereço real do cliente no pacote, é
passthrough**, porque todo proxy, por ser um, o substitui; os Application Load Balancers repassam o endereço
original no cabeçalho `X-Forwarded-For`, o que basta para uma aplicação HTTP e para nada mais.

Balanceadores regionais feitos com Envoy, os Application regionais e os Network proxy, precisam de mais uma
coisa na rede: uma **sub-rede só de proxy** na região deles, uma faixa reservada para os proxies que o Google
roda em nome do cliente. É um `/23` ou coisa assim da aritmética da lição 15, mantido fora de todo o resto, e
esquecê-la é o motivo de costume para o primeiro balanceador regional se recusar a ser criado.

## O que custa

A página de preços do Cloud Load Balancing, lida em 30 de outubro de 2026, cobra o Application Load Balancer
externo global em duas partes:

| parte | preço |
|---|---|
| **regras de encaminhamento** | 0,025 USD por hora para as cinco primeiras juntas, 0,01 para cada uma depois disso; contadas por projeto, e regras globais e regionais à parte |
| **dados processados** | cobrados na região em que o tráfego é processado; para Iowa, o padrão da página, 0,008 USD por GiB na entrada e 0,008 na saída |

São Paulo tem o próprio valor na mesma tabela, escolhido pelo seletor de região da página, que não é texto que
esta lição conseguisse ler. A aritmética tem a mesma forma de um jeito ou de outro. A regra de encaminhamento
do planner o mês todo é 730 horas a 0,025, **18,25 dólares**, qualquer que seja o tráfego. Um terabyte servido
por ela soma a cobrança de processamento à saída da lição 1, e **o Cloud CDN é a alavanca**: uma resposta servida
do cache na borda nunca passa pelo balanceador, então ninguém a processa e ela é cobrada como saída de CDN.

**As cinco primeiras regras custam o mesmo que uma.** A regra HTTPS do planner precisa de uma segunda na porta
80 só para redirecionar HTTP simples para HTTPS, o que ele quer, e a segunda regra não custa nada a mais. As duas
estão dentro das cinco primeiras, e o próprio exemplo da página de preços diz que uma regra e três regras custam
0,025 por hora.
