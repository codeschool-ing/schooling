---
title: Do que a criptografia no aparelho protege, e do que não protege
version: 1
---

**Cifrar dado em repouso o protege de quem tem o armazenamento e não o celular desbloqueado, e de
mais ninguém.** Essa frase decide toda escolha desta aula, então ela vem primeiro. A imagem comum é
a de que criptografia deixa o dado seguro, e ponto. Ela deixa o dado seguro de uma pessoa
específica numa situação específica, e um app que cifra contra a pessoa errada gasta esforço e não
compra nada.

Escreva as situações e a resposta de cada uma fica clara:

| quem tem o quê | a criptografia em repouso ajuda? |
|---|---|
| um ladrão com um **celular perdido**, bloqueado | sim: o armazenamento é ilegível sem a chave que o bloqueio protege |
| alguém com um **backup** do celular, num computador ou na nuvem | sim, se o dado ou o backup estiver cifrado com uma chave que não está nele |
| uma **cópia forense** do armazenamento, tirada de um celular desligado | sim, e é o caso para o qual as plataformas foram desenhadas |
| um **malware rodando como o seu app**, ou código que você publicou por engano | não: ele pede o dado do jeito que o seu código pede, e o recebe decifrado |
| um **celular com root ou jailbreak**, desbloqueado, com um depurador conectado | não: as chaves estão na memória enquanto o app roda |
| a **dona do celular**, com a sessão aberta | não, e nem deveria: o dado é dela |

**As três últimas não são falhas da criptografia.** Código que roda como o app é o app, até onde o
sistema consegue saber. Defender-se dele é outro trabalho: manter poucas dependências, e revisadas,
nunca carregar código de um servidor, e a regra da aula 20 de não manter no aparelho o que não
precisa estar lá.

## O que o planner guarda, contra essa tabela

O planner guarda cursos, sessões e as datas delas. Para a maioria das pessoas isso não é sensível,
e a proteção da própria plataforma, a próxima seção, basta. Duas coisas mudam a resposta:

- **Um planner de sessões de terapia, ou de um curso de medicina com anotações sobre pacientes**,
  guarda dado de saúde, que a lei no Brasil (LGPD) e na Europa (GDPR) trata como categoria
  especial. Perder um celular desbloqueado continua fora de alcance; perder um bloqueado, ou um
  backup, não pode expô-lo.
- **Um token que mantém a pessoa conectada** é a chave de tudo no servidor. A aula 20 o guarda no
  Keystore ou no Keychain e em mais lugar nenhum.

Então a aula constrói três camadas, e cada uma responde a uma linha da tabela. A plataforma cifra o
disco inteiro sob a tela de bloqueio (a próxima seção). O app pode acrescentar a própria
criptografia com uma chave que o hardware guarda, para o dado que um backup não pode expor (a seção
seguinte). E uma biometria pode liberar essa chave só para a pessoa diante do celular (a última
seção).

**Nada disso substitui perguntar se o dado precisa estar no aparelho.** Essa pergunta é da aula 20,
e é a mais barata: dado que não está lá não vaza de um celular perdido, de um backup nem de um
malware.
