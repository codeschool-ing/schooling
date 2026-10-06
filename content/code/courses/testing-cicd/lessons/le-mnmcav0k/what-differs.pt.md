---
title: As diferenças que são de propósito
version: 1
---

Algumas diferenças entre ambientes são o motivo inteiro de tê-los. Diante da mesma pergunta, os três
dão duas respostas:

```
ana@laptop:~/shipquote$ for port in 8100 8200 8300; do curl -s "http://127.0.0.1:$port/quote?cep=01310-100&weight=1200&subtotal=5000"; echo; done
{"cep": "01310-100", "zone": "SP", "cents": 2190, "price": "R$ 21,90"}
{"cep": "01310-100", "zone": "SP", "cents": 1860, "price": "R$ 18,60"}
{"cep": "01310-100", "zone": "SP", "cents": 1860, "price": "R$ 18,60"}
```

O desenvolvimento respondeu **R$ 21,90**, pela tabela da loja, porque não tem transportadora.
Homologação e produção responderam **R$ 18,60**, pelas transportadoras delas. É o comportamento
pretendido, e traz um aviso: **a homologação só diz algo sobre a produção na medida em que as duas
estão configuradas de forma parecida.** Um teste que passa no desenvolvimento não diz nada sobre o
caminho da transportadora, porque o desenvolvimento nunca o percorre.

## Diferenças legítimas

| o quê | desenvolvimento | homologação | produção |
|---|---|---|---|
| o artefato | qualquer build, muitas vezes `dev-…` | um candidato a release | o release |
| integrações | nenhuma, ou fakes | as sandboxes dos fornecedores | os fornecedores reais |
| segredos | descartáveis | credenciais de sandbox | credenciais de produção, muito guardadas |
| dados | semeados, sintéticos | semeados, com a forma dos da produção | os dos clientes |
| escala | um processo | pequena | o que o tráfego pede |
| quem pode mudar | quem desenvolve | a equipe, pelo pipeline | só o pipeline |

Cada linha é uma diferença que alguém escolheu, e cada uma é um lugar onde a homologação pode
discordar da produção. A sandbox de uma transportadora é o caso mais claro: é o sistema de teste do
próprio fornecedor, e pode aceitar requisições que a API real recusa, responder mais rápido do que a
API real jamais responde, ou ficar atrasada em relação a uma mudança que a API real já fez. Os testes de
contrato da aula 2 são como uma equipe fica de olho nessa diferença.

## Diferenças que não são de propósito

A diferença que machuca é a que ninguém escolheu: uma versão do Python, um fuso horário, uma
configuração mudada numa máquina e não na outra, um arquivo editado à mão. As três próximas seções são
sobre isso: o que *paridade* quer dizer, o que a homologação consegue e não consegue dizer, e como o
desvio acontece e é achado.
