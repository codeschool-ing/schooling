---
title: O que bloqueia a thread principal, e como cada sistema reclama
version: 1
---

**A thread principal é bloqueada por qualquer trabalho que leve mais que um quadro, e num app esse
trabalho vem de dois tipos: calcular e esperar.** Calcular é o processador ocupado com o seu
código. Esperar é a thread sem fazer nada enquanto um disco ou a rede responde. O segundo é o que
passa despercebido, porque o código é curto e o processador está parado, e o quadro se perde do
mesmo jeito.

| tipo | no planner de estudos | por que é lento |
|---|---|---|
| calcular | interpretar um ano de sessões baixado como um único documento JSON grande | o parser lê cada caractere antes de retornar |
| calcular | ordenar ou agrupar milhares de sessões para a visão da semana | uma ordenação compara os itens muitas vezes |
| esperar | ler o plano salvo de um arquivo no aparelho | o armazenamento responde no tempo dele, e um celular ocupado é mais lento |
| esperar | buscar a lista de cursos num servidor | uma rede pode levar segundos, ou nunca responder (aula 14) |

**A documentação da Apple lista as mesmas coisas.** A página dela sobre encerramentos pelo watchdog
cita a rede síncrona e o processamento de grandes volumes de dados, *como arquivos JSON grandes*,
entre as formas comuns de um app bloquear a thread principal. O guia do Android sobre ANRs mostra
uma ordenação escrita dentro de uma função Compose que desenha uma lista, onde ela roda de novo
toda vez que a lista é desenhada.

## Android: StrictMode, uma exceção e a caixa de ANR

O Android dá dois avisos ao desenvolvedor antes de o usuário ver qualquer coisa. O **StrictMode** é
uma ferramenta de desenvolvimento que o app liga no build de depuração; a documentação dele diz que
ele serve principalmente para pegar acesso acidental a disco ou rede na thread principal, e pode
escrever cada ocorrência no log na hora em que ela acontece. O acesso à rede é pego até sem ele: um
app que abre uma conexão de rede na thread principal recebe uma `NetworkOnMainThreadException`, que
o Android lança para todo app que mira a versão Honeycomb ou posterior.

**O aviso do usuário é a caixa de ANR.** A documentação do Android sobre ANRs diz que um ANR é
disparado quando o app não responde a um evento de entrada, uma tecla ou um toque, em 5 segundos. A
caixa deixa o usuário esperar ou fechar o app, e o guia do Android sobre processos e threads
acrescenta que o usuário pode acabar desinstalando o app.

## iOS: o watchdog

O iOS não tem caixa de diálogo. **Ele tem um watchdog**: uma parte do sistema que observa quanto
tempo um app leva para abrir e para responder, e encerra o que não responde. A documentação da
Apple diz que o relatório de falha de um encerramento pelo watchdog traz o código `0x8badf00d`, lido como "ate bad food". A descrição do relatório também diz se o app não desenhou o primeiro
quadro a tempo ou se parou de atualizar a interface porque a thread principal estava ocupada
demais. A documentação não publica um limite fixo para um app que já está rodando, e esta aula
não inventa um.

Para o usuário, os dois parecem diferentes e querem dizer o mesmo. No Android o app pede para ser
fechado; no iOS ele some. Os dois são o sistema avisando ao desenvolvedor que a thread principal
ficou presa muito além do orçamento.

## React Native: uma thread de JavaScript ocupada

No React Native os sinais de alerta são os da thread de JavaScript. **Um laço longo num tratador
segura todos os outros tratadores, todos os timers e toda renderização**, porque uma thread roda
todos eles, e o exemplo da documentação, de 200 ms de trabalho derrubando 12 quadros, é essa
thread. Interpretar uma resposta grande com `JSON.parse` e ordenar um array longo são tão síncronos
num app React Native quanto em qualquer programa JavaScript; eles rodam até o fim antes que
qualquer outra coisa rode nessa thread. E a thread principal nativa ainda pode ser bloqueada por
baixo, por código nativo que uma biblioteca roda nela.

A aula 14 trata de um pedido que nunca volta. Aqui o ponto é mais estreito: onde quer que esse
pedido espere, ele não pode esperar na thread que desenha.
