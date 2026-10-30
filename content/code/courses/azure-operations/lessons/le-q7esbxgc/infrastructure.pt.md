---
title: O que todo endereço público já tem
version: 1
---

**Um ataque distribuído de negação de serviço tenta esgotar alguma coisa**: a banda de entrada de uma rede, as tabelas de
conexão de um balanceador, ou as threads de uma aplicação. É distribuído porque vem de milhares de máquinas ao mesmo tempo, em
geral computadores de outras pessoas tomados para isso, e por isso bloquear um endereço não adianta.

Vale separar os ataques pela camada que esgotam:

| camada | o que inunda | quem para |
|---|---|---|
| **3 e 4**, rede e transporte | pacotes: inundações UDP, SYN, reflexão | a proteção DDoS do Azure, na borda da rede |
| **7**, aplicação | requisições HTTP bem formadas, muitas, para páginas caras | o WAF da lição 18, limites de taxa, cache |

**Todo endereço IP público no Azure é coberto pela proteção de infraestrutura contra DDoS**, sem custo e sem nada para
configurar. Ela defende a própria plataforma do Azure, e por tabela defende você: é ajustada a volumes que machucariam o Azure,
não ao que machucaria uma loja. Uma inundação bem abaixo dos limites do Azure ainda pode derrubar uma aplicação pequena, e a
proteção de infraestrutura não vai percebê-la.

Esse buraco é o que os planos pagos fecham. Antes de recorrer a eles, repare por onde o tráfego da loja chega: o **Front Door**,
na borda global da Microsoft, absorve ataques volumétricos na rede inteira dele, longe de `brazilsouth`, e o WAF dele cuida da
camada 7. Para um site cuja única entrada pública é o Front Door, os endereços públicos regionais que um plano pago protege talvez
nem existam, e essa é a primeira pergunta da última seção.
