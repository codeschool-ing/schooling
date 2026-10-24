---
title: O que o relatório ainda diz
version: 1
---

**A nota é cem e o relatório ainda lista três insights.** Eles já estavam na página de três cursos, e
nenhum vale um ponto neste tamanho. Vale entender cada um, porque numa página maior cada um vale:

| insight | o que achou | onde se corrige |
|---|---|---|
| **Render-blocking requests** | a folha de estilo: o navegador não pinta até tê-la, então ela custa uma ida e volta antes da primeira pintura | aula 7, que embute o CSS de que a primeira tela precisa |
| **Use efficient cache lifetimes** | o script e a folha de estilo vão sem tempo de cache, então uma segunda visita os pede de novo | aula 9, cabeçalhos de cache |
| **Network dependency tree** | a corrente de requisições: o HTML, depois os arquivos que ele cita | a seção "Cascatas", nesta aula |

## Lendo uma economia estimada

**Uma economia estimada é a resposta de um modelo a "e se isto não existisse"**, em milissegundos ou em
kilobytes. Serve para ordenar, e não é uma promessa: os 150 milissegundos da folha de estilo supõem um
celular lento numa rede lenta, e não virariam todos LCP, porque o HTML tem de chegar de qualquer jeito.
Corrija primeiro a maior economia, meça e leia o relatório de novo; às vezes um insight some porque um
maior foi corrigido.

## Quando parar

**Nem todo insight vale a correção.** Uma folha de estilo de menos de meio kilobyte, numa página cujo
LCP é um segundo, é um achado para anotar e deixar; embuti-la é uma mudança no build que precisa ser
mantida. A nota é um jeito de perceber, e cem não é a meta. A meta são os três números da aula 5, para
visitantes reais, e um insight merece a correção quando mexe num deles.

E um achado não está em insight nenhum: **o plano de cinco mil cursos continua em toda página**,
comprimido agora, mas lido por todo visitante que abre um curso. Não é uma configuração a mudar, e sim
uma decisão sobre o que a página precisa, e a aula 8, sobre carregar sob demanda, é onde ela é tomada.
