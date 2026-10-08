---
title: A maleta de resposta
version: 1
---

A **maleta de resposta** (jump bag) é tudo de que quem responde precisa, pronto antes de ser necessário, para
que a primeira hora de um incidente seja gasta respondendo, e não procurando. O nome vem da mala física; boa
parte dela hoje é digital, e tudo é conferido num calendário.

| item | por que precisa existir de antemão |
|---|---|
| **o plano, a lista de contatos e os playbooks, em papel ou offline** | os sistemas que os guardam podem ser justamente os que caíram |
| **uma estação de análise** fora da rede afetada | evidência não deve ser examinada numa máquina que o invasor pode controlar |
| **armazenamento limpo e apagado**, grande o bastante para imagens de disco, e um **bloqueador de escrita** de hardware | a aula 16 precisa dos dois, e comprá-los durante um incidente leva dias |
| **ferramentas forenses, instaladas e testadas**: imagem, hash, análise, captura de pacotes | aprender uma ferramenta durante um P1 é como a evidência se estraga |
| **comunicação fora de banda**: um grupo de mensagens ou uma ponte telefônica que não dependa das contas da empresa | se o e-mail estiver comprometido, o invasor lê a resposta |
| **contas de emergência**: acesso de administrador lacrado, usado só numa crise e auditado quando aberto | trancar todos os administradores do lado de fora durante a contenção é uma parada clássica causada por quem responde |
| **formulários de custódia e um modelo de registro** | a cadeia de custódia da aula 3 começa na primeira coleta |

O laboratório que você montou na aula 1 é uma versão pequena da segunda e da quarta linhas: uma máquina com
as ferramentas do curso instaladas e testadas. Numa empresa, a maleta tem um dono e uma conferência mensal,
porque uma maleta que ninguém abre desde o ano passado guarda licenças vencidas, baterias descarregadas e
telefones de pessoas que já saíram.
