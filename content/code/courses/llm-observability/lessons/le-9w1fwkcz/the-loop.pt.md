---
title: O ciclo, fechado
version: 1
---

Ponha as peças do curso na ordem em que teriam rodado na sexta, 2 de outubro, se estivessem no lugar:

1. **10h.** A 2026.10.1 vai ao ar. Ela nunca passou pelo portão da aula 15, que a teria parado em cinco
   casos quebrados.
2. **14h.** A regra de Wilson dispara: as recusas das últimas seis horas estão com certeza acima da linha
   de base. O alerta nomeia a versão e tem um link para os traces das respostas recusadas.
3. **Os traces** mostram a busca guardando menos trechos: na árvore da aula 1, o span de busca de uma
   resposta recusada tem `app.search.kept` em 0 e `app.search.floor` em 0.62.
4. **Os sinais de produção** da aula 5 dizem quem é afetado: perguntas de pedido mais que todas, recusadas
   quase duas vezes em três, com os polegares acompanhando.
5. **A coleta** da aula 13 transforma as perguntas da semana postas em dúvida em casos, entre eles as
   formulações por palavra-chave e as mensagens de pedido que o conjunto nunca teve.
6. **O teste de regressão** da aula 14 compara uma correção com a produção no conjunto, caso a caso: o piso
   de volta conserta os cinco casos quebrados.
7. **O portão** da aula 15 sujeita a correção aos orçamentos, e uma pessoa escreve por que o custo pode
   subir: a produção era barata porque recusava.
8. **A 2026.10.3 vai ao ar**, e o painel desta aula mostraria a parcela de recusas voltando à linha de
   base. O alerta se resolveria porque o problema se resolveu.

Cada passo é uma aula, e nenhum é opcional. Sem o alerta, a equipe fica sabendo na segunda; sem os traces,
ela adivinha a causa; sem o conjunto, não sabe dizer se a correção corrigiu alguma coisa; sem o portão, a
próxima versão faz a mesma coisa de novo.

**E o que nada disso faz** é o assunto de onde o curso partiu: a resposta de um modelo não é um stack
trace. Uma resposta errada dada com confiança parece sucesso em todo painel daqui. As avaliações das aulas
8 a 14, e as pessoas da aula 10 que dizem quanto as avaliações valem, são a única parte deste sistema que
lê o que o assistente diz. Todo o resto conta.
