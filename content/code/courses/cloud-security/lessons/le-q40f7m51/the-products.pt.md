---
title: As ferramentas que fazem isso por profissão
version: 1
---

**Todo provedor vende o ciclo desta aula como serviço, e várias ferramentas de código aberto o rodam
nas três nuvens.** Nenhuma foi executada para este curso: os serviços dos provedores exigem contas
reais, e os scanners de código aberto foram escritos contra as APIs reais, e não contra o moto. O que
segue vem da documentação de cada projeto, e o motivo de lê-la é reconhecer as mesmas quatro partes
que você montou — o inventário, as regras, os achados e as exceções — com outros nomes.

## Dentro da AWS

| serviço | o que é, nos termos desta aula |
|---|---|
| **AWS Config** | o inventário com memória. Registra cada mudança na configuração de um recurso, então sabe dizer *quando* um bucket ficou público, o que o `scan.py` não sabe. As **Config rules** são as regras, rodadas a cada mudança ou num horário fixo, e um **conformance pack** é um conjunto delas implantado junto |
| **AWS Security Hub** | os achados num lugar só. As verificações de postura dele rodam padrões como o CIS AWS Foundations Benchmark e as Foundational Security Best Practices da própria AWS, e ele junta achados de outros serviços, entre eles o GuardDuty |
| **AWS Organizations** | não é scanner, mas é o que deixa os dois de cima cobrirem todas as contas de uma empresa de um lugar só, em vez de uma conta por vez |

O Config é cobrado por item de configuração registrado e por avaliação de regra, o que é de novo o
ponto da aula 1 sobre a fatura: **a visibilidade existe, fica desligada até você ligar, e custa
dinheiro quando você liga.**

## Nas outras duas nuvens

- O **Microsoft Defender for Cloud** avalia assinaturas do Azure contra as recomendações dele e o
  Microsoft cloud security benchmark, e as soma num **secure score**. Ele também lê contas da AWS e do
  Google Cloud depois de conectadas a ele.
- O **Google Security Command Center** reúne achados de uma organização; o **Security Health
  Analytics** é a parte que lê configuração, com detectores como um bucket aberto para `allUsers` ou
  uma regra de firewall aberta para o mundo.

## Código aberto, entre nuvens

- O **Prowler** roda centenas de verificações contra a AWS, e também Azure, Google Cloud e
  Kubernetes, mapeadas para os CIS Benchmarks e para referências como ISO 27001 e PCI DSS. Ele roda de
  um notebook com credenciais só de leitura.
- O **ScoutSuite**, da NCC Group, lê uma conta pela API e escreve um relatório que você abre no
  navegador, organizado por serviço.

Os dois são o `scan.py` com os limites preenchidos: toda região, todo serviço, centenas de regras,
relatórios em formatos que outras ferramentas leem. Os dois precisam do mesmo que o `scan.py`: **um
papel que lê tudo e não muda nada**. As políticas gerenciadas `SecurityAudit` e `ViewOnlyAccess` da
AWS existem para isso, e dar a um scanner mais do que isso transforma a ferramenta que procura
exposição numa exposição ela mesma.

## Escolhendo, para uma clínica

Uma empresa de quatro pessoas com uma conta não precisa de um produto no primeiro dia. Precisa das
quatro regras desta aula rodando toda manhã e de uma caixa de entrada que as leia. O serviço do
provedor justifica o preço quando as contas se multiplicam, quando o auditor da aula 17 pede um
histórico de mudanças, ou quando ninguém tem tempo de manter atualizada uma lista de regras caseira.
**Qualquer que seja a ferramenta, o trabalho depois do achado é o mesmo**: um dono, uma correção ou
uma exceção com data, e uma segunda varredura como prova.
