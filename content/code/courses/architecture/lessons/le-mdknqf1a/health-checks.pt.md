---
title: Health checks
version: 1
---

Estar registrada diz que uma instância subiu. Não diz que ela consegue fazer o trabalho agora. Cada
instância deu ao Consul uma URL para chamar a cada dois segundos, `/health`, e uma instância que responde
qualquer coisa diferente de sucesso é marcada como **crítica** e sai da lista de saudáveis. Peça o estoque
ao gateway seis vezes, com um terço de segundo entre elas:

```
ana@vm:~/lab/gateway$ for i in $(seq 6); do curl -s localhost:8080/stock/coffee; sleep 0.3; done
stock-3: coffee 12
stock-1: coffee 12
stock-2: coffee 12
stock-1: coffee 12
stock-2: coffee 12
stock-3: coffee 12
```

O gateway espalhou as requisições pelas três instâncias. Agora faça o `stock-2` se declarar doente,
espere cinco segundos, e olhe de novo:

```
ana@vm:~/lab/gateway$ curl -s -X POST localhost:8002/sick
stock-2: sick
ana@vm:~/lab/gateway$ sleep 5; $D stock
2 healthy instance(s) of stock
  stock-1 at 172.18.0.6:8000
  stock-3 at 172.18.0.3:8000
ana@vm:~/lab/gateway$ for i in $(seq 6); do curl -s localhost:8080/stock/coffee; sleep 0.3; done
stock-3: coffee 12
stock-1: coffee 12
stock-3: coffee 12
stock-1: coffee 12
stock-3: coffee 12
stock-1: coffee 12
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo do stock-2. Ele se registra no Consul, que confere a saúde dele a cada dois segundos e recebe 200 toda vez. Então a instância começa a responder 503. Na próxima conferência o Consul a marca como crítica, e o gateway, que atualiza as rotas a cada dois segundos, para de mandar requisições para ela. Requisições nesse meio-tempo ainda podem chegar a ela.\"><defs><marker id=\"l19-health-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-health-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M40 120 L680 120\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l19-health-ah-wire)\"></path><path d=\"M60 112 L60 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"60\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200</text><path d=\"M130 112 L130 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"130\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200</text><path d=\"M200 112 L200 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"200\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200</text><path d=\"M270 112 L270 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"270\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200</text><path d=\"M340 112 L340 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"340\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">503</text><path d=\"M410 112 L410 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"410\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">503</text><path d=\"M480 112 L480 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"480\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">503</text><path d=\"M550 112 L550 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"550\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">503</text><text x=\"60\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">registrado</text><text x=\"300\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">começa a falhar</text><path d=\"M300 70 L300 88\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-health-ah-amber)\"></path><text x=\"410\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">crítico: fora das rotas</text><path d=\"M410 150 L410 132\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-health-ah-amber)\"></path><rect x=\"300\" y=\"176\" width=\"110\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"355\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ainda roteado</text><text x=\"560\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conferências a cada 2 s</text></svg>", "caption": "Um health check transforma uma instância quebrada numa que o registro sabe que está quebrada. O tempo entre as duas coisas é uma janela em que ela ainda recebe tráfego."}
```

A conferência seguinte do Consul achou o `stock-2` falhando, o registro o tirou da lista de saudáveis, e o
gateway, que lê o registro a cada dois segundos, parou de mandar requisições para ele. O processo continua
rodando, e nada foi reiniciado; ele foi tirado **de rotação** até se recuperar. Entre o momento em que
adoeceu e o momento em que o gateway percebeu, alguns segundos no laboratório, requisições ainda podiam
chegar a ele, e é por isso que os retries da aula 11 pertencem à frente de qualquer coisa descoberta
desse jeito.

Parar uma instância de forma limpa é mais rápido ainda, porque ela se desregistra ao sair em vez de
esperar falhar numa conferência:

```
ana@vm:~/lab/gateway$ docker compose stop stock-3; $D stock
 Container gateway-stock-3-1 Stopping 
 Container gateway-stock-3-1 Stopped 
1 healthy instance(s) of stock
  stock-1 at 172.18.0.6:8000
```

O que um health check deveria testar é uma decisão com dois lados. **Raso demais**, um check que só prova
que o processo responde HTTP, e uma instância com a conexão do banco quebrada continua em rotação e falha
toda requisição de verdade. **Fundo demais**, um check que chama toda dependência, e uma dependência lenta
faz falhar os checks de todas as instâncias de uma vez, e o registro se esvazia sozinho, uma falha em
cascata causada pelos checks. O Kubernetes separa as duas perguntas: uma sonda de **liveness** pergunta
"este processo deveria ser reiniciado?", e uma de **readiness** pergunta "esta instância deveria receber
tráfego agora?". O `/health` do laboratório é um check de readiness.
