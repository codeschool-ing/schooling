---
title: ITIL e DevOps
version: 1
---

O ITIL e os movimentos ágil e DevOps foram apresentados por anos como opostos: um, o mundo dos comitês de aprovação e dos tickets; o outro, dos pipelines automatizados e das mudanças pequenas e frequentes. A oposição é em parte real e em parte uma leitura errada, e a evidência num ponto é extraordinariamente clara.

## O que a pesquisa encontrou

A pesquisa State of DevOps, resumida por Nicole Forsgren, Jez Humble e Gene Kim em *Accelerate* (2018), ouviu milhares de profissionais de tecnologia ao longo de vários anos e mediu como as organizações deles entregam software. Sobre aprovação de mudanças a conclusão foi direta. Exigir aprovação de mudanças por um **órgão externo**, como um comitê consultivo de mudanças ou um gestor sênior, estava associado a uma entrega **pior** — lead times mais lentos, deploys menos frequentes, recuperação mais longa — e **não estava associado a uma taxa menor de mudanças com falha**. Os autores concluíram que essa aprovação era pouco melhor que nenhuma, e recomendaram aprovação leve, perto do trabalho, como revisão por pares, combinada com testes automatizados para pegar mudanças ruins antes de chegarem à produção.

Isso não é uma conclusão contra controlar mudanças. É uma conclusão de que uma reunião semanal de pessoas longe do código é um jeito ruim de fazê-lo.

## Onde eles se encontram

Lidos com cuidado, o ITIL 4 e o DevOps dizem coisas compatíveis:

- Os princípios orientadores do ITIL 4 incluem *progrida iterativamente com feedback* e *otimize e automatize*, e a prática de habilitação de mudanças pede autoridade perto do trabalho.
- Um pipeline de deploy automatizado com testes, revisão por pares e capacidade de reverter é um **procedimento de mudança padrão**: aprovado uma vez, executado toda vez.
- Gerenciamento de incidentes e de problemas, níveis de serviço e requisições continuam necessários, faça o time deploy como fizer. Times DevOps que operam os próprios serviços os descobrem com outros nomes: plantão, revisões pós-incidente, orçamentos de erro.

## O que um líder deve fazer numa organização com ITIL

Um arquiteto ou líder que chega a uma organização com um comitê semanal de mudanças tem um caminho prático. Mostre o histórico de uma classe de mudança — o mesmo deploy automatizado, feito muitas vezes, com a taxa de falha — e peça que ela vire **mudança padrão**. Cada classe que sai do comitê encurta o lead time sem tirar nenhum controle real, e a atenção do comitê fica para as mudanças de fato novas. A aula 13 mede o efeito com as quatro métricas DORA, que vêm da mesma pesquisa.
