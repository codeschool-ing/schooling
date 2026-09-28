---
title: O que se promete e o que se consegue entregar
version: 1
---

O número de um contrato costuma ser decidido numa reunião de vendas, e o número que a arquitetura consegue
entregar é decidido pela arquitetura. **Nada obriga os dois a concordarem**, e a distância entre eles é
onde os créditos da primeira seção são pagos.

A primeira verificação é uma conta que a aula 14 já fez. O programa dela deu ao data center do laboratório,
com dois balanceadores e três servidores web mas um enlace de provedor e um servidor DNS, uma
disponibilidade de 99,79990%, cerca de 1051,7 minutos fora do ar por ano com as suposições dele. Uma
promessa de 99,9% permite 525,6 minutos por ano. **Uma empresa que assina 99,9% para esse projeto prometeu
metade do tempo fora do ar que a própria conta prevê**, antes de acontecer qualquer coisa fora do comum. As
partes em série se multiplicam, e a promessa não pode ser mais forte do que o produto delas.

## As partes que não são suas

A corrente inclui coisas que ninguém da empresa opera: o banco de dados do provedor de nuvem, o provedor
de DNS, o gateway de pagamento, o provedor de internet. Cada um tem o próprio SLA, e **uma promessa feita
em cima deles não pode ser mais forte do que os deles multiplicados**. Uma loja que promete 99,99% enquanto
o fornecedor do banco de dados promete 99,9% está prometendo o que não comprou, e quando o fornecedor erra,
o crédito que a loja recebe é uma fração da mensalidade do fornecedor, enquanto o crédito que a loja deve é
uma fração do que os clientes dela pagam. Os dois não se anulam.

## A recuperação faz parte da arquitetura

A aula 14 dividiu a disponibilidade em falhar menos e voltar mais cedo, e a segunda metade decide quais
promessas são possíveis:

| promessa em 30 dias | o orçamento | o que o projeto precisa |
|---|---|---|
| 99% | 432,00 min | um servidor, um backup testado e uma pessoa de plantão |
| 99,9% | 43,20 min | redundância para as falhas comuns; uma pessoa pode intervir cerca de uma vez por mês |
| 99,95% | 21,60 min | failover automático para toda falha comum |
| 99,99% | 4,32 min | failover automático em tudo, nenhum ponto único, mudanças testadas antes de chegarem à produção |

O degrau que importa fica entre a segunda e a terceira linhas. **Acima de uns 99,9% por mês, qualquer
falha que espera uma pessoa quebra a promessa sozinha**, então todo modo de falha que importa precisa ser
resolvido por uma máquina, e cada um deles precisa ter sido visto funcionando.

Essa última parte é o motivo de as aulas 15 e 16 terem puxado cabos e matado processos com um relógio
correndo em vez de confiar na configuração. Um failover que nunca foi exercitado é uma esperança, e o dia
em que ele é exercitado pela primeira vez não deveria ser o dia em que ele é necessário. Equipes que
prometem números altos agendam esse exercício, um teste de failover ou um "game day", numa tarde calma com
gente olhando, e medem o buraco do jeito que o ping da aula 15 mediu.
