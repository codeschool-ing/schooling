---
title: Para onde os dados vão
version: 1
---

Tudo numa requisição sai dos seus servidores: o prompt de sistema, a conversa, os documentos
recuperados para ela, os resultados de ferramentas. **Mandar isso a um provedor é entregar a outra
empresa**, sob os termos dessa empresa. Esta seção é a lista de perguntas a responder antes de uma
funcionalidade sair, porque as respostas mudam por provedor, por produto e por plano, e mudam com o
tempo.

O curso não cita aqui os termos de nenhum provedor. Eles são longos, mudam, e uma paráfrase numa
aula fica desatualizada sem avisar. Leia o texto atual do plano em que você está.

## As perguntas

- **Os dados são usados para treinar modelos?** Pergunte isso do plano de API que você paga. Os apps
  de consumidor do mesmo provedor podem ter outros termos, então o nome do produto não resolve nada.
- **Por quanto tempo são guardados, e por quê?** Um provedor pode guardar requisições por um tempo
  para procurar abuso, e alguns planos oferecem retenção menor ou nenhuma, às vezes por acordo e não
  por uma configuração.
- **Onde são processados?** Um provedor pode processar uma requisição num país diferente daquele em
  que o usuário está. Leis de dados pessoais, como a LGPD no Brasil ou o GDPR na União Europeia,
  podem exigir que você saiba e informe isso.
- **Quem mais encosta neles?** Um modelo acessado por uma plataforma de nuvem ou um gateway passa por
  essa empresa também, sob os termos dela.
- **O que o seu próprio log guarda?** As requisições que o seu relay registra são a sua cópia dos
  mesmos dados, e as mesmas perguntas valem para elas.

## O que fazer no código

- **Mande menos.** O jeito mais barato de proteger dados é não mandá-los: um número de pedido em vez
  do nome e do endereço do cliente, os três trechos relevantes do manual em vez do manual inteiro.
- **Tire o que o modelo não precisa**, antes da requisição. A aula 11 faz isso com segredos e dados
  pessoais que escapam para dentro de prompts.
- **Escreva as respostas onde o código está.** Uma nota curta ao lado do adaptador dizendo que
  provedor, que plano, que região e que retenção dá à próxima pessoa algo para conferir quando os
  termos mudarem.
