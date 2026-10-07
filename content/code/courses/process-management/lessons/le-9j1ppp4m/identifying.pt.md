---
title: Encontrando os riscos
version: 1
---

Os riscos que um projeto gerencia são só os que alguém percebeu. A maioria das técnicas de identificação de riscos existe para vencer os obstáculos à percepção: o otimismo, a relutância em dizer algo desanimador numa reunião e a visão estreita da própria parte de cada um.

## Pergunte a quem vai fazer o trabalho

Desenvolvedores, testadores e operadores sabem onde o trabalho é incerto, e raramente são perguntados. Uma sessão curta no começo do projeto, e de novo a cada ponto de planejamento, com uma pergunta — *o que pode fazer isto sair diferente do plano?* — produz a maioria dos riscos que importam. Escrever as respostas em cartões antes de discuti-las funciona pelo mesmo motivo que as cartas escondidas do planning poker funcionaram na aula 10: a primeira ideia dita em voz alta ancora as outras.

## Use listas de verificação e o passado

Toda organização que já tocou projetos tem uma história do que deu errado. Uma lista de verificação construída a partir dela — integrações com terceiros, migrações de dados, aprovações regulatórias, um especialista único, uma tecnologia nova — faz as pessoas considerarem categorias em que não teriam pensado. As **suposições** são uma fonte especialmente rica: todo plano se apoia nelas, e cada uma é um risco se se revelar falsa. "O ambiente de testes do provedor vai estar disponível desde a primeira semana" é uma suposição da estimativa da aula 9, e listá-la a torna visível como risco.

Alguns times guardam tudo isso junto num **registro RAID**: riscos, suposições (assumptions), questões (issues) e dependências num lugar só, revisados na mesma reunião, porque cada tipo tende a virar outro.

## O pré-mortem

A técnica isolada mais eficaz é o **pré-mortem**, descrito por Gary Klein em 2007. O time imagina que está alguns meses no futuro e que o projeto **fracassou**. Cada pessoa então escreve, em particular, os motivos do fracasso. As respostas são reunidas e discutidas.

Funciona porque muda a pergunta de *o que pode dar errado?*, que convida a tranquilizar, para *por que deu errado?*, que convida a explicar. Dizer que a integração de um colega pode atrasar é constrangedor; explicar por que um fracasso imaginado aconteceu não é. O pré-mortem dá às pessoas permissão para dizer o que já as preocupava.

Para o agendamento online do time Agenda, um pré-mortem produziu os cinco riscos desta aula em vinte minutos, entre eles o que ninguém tinha dito em voz alta antes: que só um desenvolvedor entende a integração de faturamento.

## Olhe a arquitetura

Riscos técnicos se escondem no projeto, e um arquiteto deveria procurá-los de propósito. Eles ficam nas partes novas para o time, nas integrações com sistemas fora do controle dele, nos lugares em que um requisito de qualidade — tempo de resposta, disponibilidade — está perto do limite do que o projeto consegue entregar. A oitava seção desta aula volta a eles, porque são os riscos que um arquiteto está mais bem posicionado para encontrar e reduzir.
