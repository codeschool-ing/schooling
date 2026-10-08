---
title: Objetivos que mentem
version: 2
---

Um SLO é um número em que uma equipe, e muitas vezes os gestores dela, vai confiar sem olhar por baixo.
Isso faz valer a pena conhecer pelo nome os jeitos como ele pode estar errado:

- **Contar os eventos errados.** Sondas, novas tentativas e um teste de carga inflam os eventos bons; a
  seção de indicadores mostrou o `/ready` fazendo isso. Uma subida de tráfego que não é de clientes faz
  uma semana ruim parecer melhor.
- **Medir lá dentro demais.** Um SLI no `orders` não vê a vitrine falhando sozinha, e um SLI na vitrine
  não vê o DNS, o certificado ou a CDN na frente dela. Quanto mais perto do cliente, mais verdadeiro; o
  checkout sintético da aula 14 é o mais perto que uma equipe costuma chegar.
- **Tirar a média do que importa de jeitos diferentes.** Um SLI sobre todas as rotas deixa mil visitas
  bem-sucedidas à página de produto esconderem cinquenta checkouts que falharam. As rotas que levam
  dinheiro, ou uma promessa, ganham o seu próprio.
- **Tráfego de menos.** A dez checkouts por hora, uma falha é uma taxa de erros de dez por cento. Um
  objetivo num serviço quieto precisa de uma janela maior, de uma verificação sintética, ou dos dois.
- **Um objetivo que ninguém descumpriu em um ano.** Um orçamento que nunca é gasto não prova um serviço
  confiável; costuma provar um objetivo frouxo. Aperte-o até significar alguma coisa, ou pare de pagar
  pela confiabilidade de que ninguém precisa.

**E o objetivo não é a meta.** Uma equipe que ajusta o SLI para parecer bem, movendo o limite,
excluindo uma rota ou rotulando uma falha como culpa do cliente, tem um painel verde e os mesmos
clientes insatisfeitos. O SLO só é útil enquanto concorda com o que os clientes dizem. Quando os
dois discordam, quem está errado é o SLO.

Antes da próxima aula, tire as regras do objetivo; a aula 16 escreve as suas:

```sh
rm prometheus/rules/slo.yml
curl -s -X POST localhost:9090/-/reload
```
