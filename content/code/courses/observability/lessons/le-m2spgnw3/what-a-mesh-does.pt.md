---
title: O que um service mesh faz
version: 1
---

Todo sinal deste curso foi produzido pelo próprio código da loja: um contador no `web.py`, um span
aberto à mão, uma linha de log com um trace id. **Um service mesh produz um conjunto de sinais que o
código nunca menciona**, porque fica onde o código não alcança: no caminho de rede entre os serviços.

O mecanismo é um proxy ao lado de cada serviço. Toda requisição sai pelo proxy de quem chama e chega
pelo proxy de quem é chamado, e os dois proxies podem fazer tudo o que um proxy faz:

| | o que o proxy faz | o que isso substitui no código |
|---|---|---|
| telemetria | conta e cronometra toda requisição, por origem e destino | o contador e o histograma do `web.py`, para HTTP |
| novas tentativas e timeouts | repete uma chamada que falhou, desiste depois de um prazo | laços de nova tentativa e timeouts em todo cliente |
| criptografia e identidade | TLS mútuo entre proxies, com um certificado por workload | configuração de TLS por serviço |
| controle de tráfego | manda 5% para uma versão nova, espelha tráfego, troca de destino em falha | regras do balanceador |

Um mesh tem duas metades. O **plano de dados** são os proxies, que levam toda requisição. O **plano de
controle** os configura: entrega a cada proxy as rotas, os certificados e as políticas dele. No Istio
os proxies são o Envoy e o plano de controle é o `istiod`; no Linkerd o proxy é um pequeno, escrito em
Rust para esse fim.

O que um mesh não consegue fazer importa tanto quanto. **Ele vê requisições, não significado.** Ele sabe
que o `orders` chamou o `payments` e recebeu um 503 em 400 ms. Ele não sabe que produto foi comprado,
que cliente era, nem que o 503 era uma rede de cartões recusando. Os spans de dentro do código, os
atributos da aula 2 e os campos de log da aula 8 ainda levam tudo o que importa ao negócio. Um mesh
acrescenta uma camada uniforme de sinais de rede por baixo deles; ele não os substitui.

Ele também não rastreia sozinho. Os proxies registram spans, mas juntá-los num rastro exige que o
cabeçalho `traceparent` da aula 4 seja passado de uma requisição que chega para a que sai. Só a
aplicação sabe que chamada de saída pertence a que requisição de entrada.
