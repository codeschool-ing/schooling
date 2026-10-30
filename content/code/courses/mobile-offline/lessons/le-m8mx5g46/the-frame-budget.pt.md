---
title: O orçamento de um quadro, e a thread que o gasta
version: 1
---

**Um celular redesenha a tela de 60 a 120 vezes por segundo, e cada redesenho precisa terminar numa
thread só, a thread principal, antes de o próximo vencer.** A 60 Hz isso deixa 16,7 milissegundos
por quadro; a 90 Hz, 11,1; a 120 Hz, 8,3. A mesma thread também recebe cada toque. Qualquer outra
coisa que rode ali, uma consulta, a leitura de um JSON, a leitura de um arquivo, gasta esse
orçamento, e um quadro que não cabe nele é descartado. A pessoa vê a lista engasgar enquanto rola.

A imagem errada é a de que um banco rápido resolve isso. Uma consulta que leva 4 ms no celular novo
do desenvolvedor com cem linhas leva 40 num celular de cinco anos com três anos de sessões, que são
as vinte mil da aula 3. **A pergunta nunca é se a consulta é rápida, e sim qual thread espera por
ela.**

## O que cada plataforma faz quando a thread principal para

| | o que mede | o que acontece |
|---|---|---|
| Android | um evento de entrada não tratado em 5 segundos | o sistema mostra "O app não está respondendo" e oferece fechá-lo: um ANR |
| Android | o `StrictMode`, numa build de depuração | relata cada leitura ou escrita de disco na thread principal, na hora |
| Room | uma consulta na thread principal | recusa com `IllegalStateException`, a não ser que o builder diga `allowMainThreadQueries()` |
| iOS | abrir, voltar ou suspender por tempo demais | o watchdog encerra o app; o relatório de falha traz o código `0x8badf00d` |
| React Native | a thread do JavaScript ocupada | os toques fazem fila e as animações movidas por JavaScript congelam, enquanto as nativas continuam |

Cinco segundos parece generoso, e é o limite para o app ser morto, não para a pessoa perceber.
Alguém percebe um quadro perdido; um ANR é o que ela relata na loja.

## As duas saídas

Existem duas respostas, e esta aula faz as duas.

**Tirar o trabalho da thread principal.** A consulta roda em outro lugar e a tela continua
desenhando enquanto isso; a resposta chega como callback, `Flow` ou `await`. As duas próximas seções
mostram o que é esse "outro lugar" no Node e em cada plataforma.

**Fazer menos dele.** Uma lista que mostra cinquenta linhas não tem uso para vinte mil. Ler uma tela
de cada vez, e a seguinte quando a pessoa rola, mantém cada consulta pequena o bastante para até um
celular lento terminá-la dentro de um quadro. Isso é paginação, a última seção, e ela tem uma
armadilha própria.

As duas não são alternativas. Uma consulta fora da thread principal que lê vinte mil linhas ainda faz
a pessoa esperar pela lista, só que sem o engasgo; uma consulta pequena na thread principal ainda é
uma leitura de disco na thread que desenha. O planner faz as duas coisas, que é para onde o Room e o
SwiftData já empurram você.
