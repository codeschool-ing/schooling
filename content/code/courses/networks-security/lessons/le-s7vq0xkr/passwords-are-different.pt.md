---
title: Senhas precisam de um hash lento
version: 1
---

Um sistema que confere senhas não deveria guardá-las; ele guarda algo calculado a partir de cada uma,
e confere um login calculando de novo. A escolha tentadora é o SHA-256, e **ela é a errada, porque ele
é rápido**. A aula 10 mediu esta máquina cifrando 12,5 gigabytes por segundo; um hash rápido está na
mesma faixa, que é exatamente o que quer quem tem uma cópia roubada dos valores guardados. Ele calcula
o hash de cada senha comum e de cada variação dela, e compara.

A defesa tem três partes:

| parte | o que faz |
|---|---|
| um **salt**, aleatório por senha | a mesma senha guardada duas vezes dá dois valores diferentes, então um cálculo não pode ser comparado contra todas as contas de uma vez |
| uma função **lenta** | cada palpite custa uma quantidade deliberada de tempo e de memória: Argon2id, scrypt, bcrypt, ou PBKDF2 com um número alto de iterações |
| parâmetros guardados ao lado do valor | o custo pode ser aumentado depois para senhas novas sem quebrar as antigas |

A cifragem de arquivos da aula 10 usou `-pbkdf2 -iter 600000` exatamente por isso: quando uma chave é
derivada de algo que uma pessoa digitou, cada palpite deveria custar 600.000 rodadas de hash em vez
de uma.

Para equipamentos de rede a lição é prática. Roteadores, switches e firewalls guardam as próprias
senhas de administrador, e formatos de configuração mais antigos usam codificações fracas ou
reversíveis. As configurações de alguns fabricantes ainda mostram senhas numa forma que pode ser
revertida sem esforço, o que quer dizer que um backup da configuração é uma lista de senhas. Confira
qual formato um equipamento usa, prefira o mais forte dele, e trate backups de configuração como
segredos.
