---
title: Antes de dar por terminado
version: 1
---

**Confira o seu projeto contra a lista abaixo antes de mostrá-lo a alguém.** Cada linha é uma aula deste curso, e
cada uma é algo que um revisor, uma loja ou um desconhecido com um download encontraria.

| verificação | aula |
|---|---|
| o app roda na plataforma, gerado de um commit com tag, e a tag foi enviada | 15 |
| a nota de decisão responde às quatro perguntas, e diz o que não foi gerado | 10, 16 |
| pelo menos um recurso do aparelho ou do desktop, atrás de uma verificação de que ele existe, como faz o `device.ts` | 4, 11, 12 |
| nenhum `server.url`, nenhum `cleartext`, nenhum endereço de desenvolvimento no que é distribuído | 2, 13 |
| o ícone é o do próprio app, em todo tamanho que a plataforma pede | 13 |
| o pacote leva só os arquivos do app | 13 |
| as permissões pedidas são as que o app usa | 4 |
| nenhuma chave, keystore ou senha no repositório, e o `git check-ignore` prova isso | 14 |
| a versão é um número só, mudado por um comando, com um número de build que só cresce | 15 |
| um segundo release, e o primeiro o encontra, ou a loja o mostra | 15 |
| o `SHA256SUMS`, a assinatura dele e a chave pública estão ao lado dos pacotes, e conferem | 14, 16 |
| o README diz o que ele é, o mostra, diz como instalar e conferir, e como foi feito | 16 |
| o teclado e o leitor de tela ainda funcionam no app, como funcionavam no navegador | 6 |

**Duas destas valem ser feitas duas vezes.** Confira o download como um desconhecido conferiria, numa pasta nova,
como a seção anterior fez; e instale o app num computador ou num celular que nunca o teve, pela página de release,
seguindo só o seu README. Esse último passo encontra a linha que falta num guia de instalação mais rápido que
qualquer leitura dele.

**E saiba o que o projeto não prova.** Um release que funciona na sua máquina foi testado numa máquina. Diga nas
notas que sistemas e versões você testou, como este curso disse o que a máquina de gravação conseguia e não
conseguia rodar, e quem lê consegue julgar o resto.
