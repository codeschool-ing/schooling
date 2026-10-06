---
title: Forense e AppSec
version: 1
---

As duas últimas famílias ficam em pontas opostas da vida de um sistema: uma investiga depois que algo deu
errado, a outra trabalha para que não dê errado.

### Forense digital

**Forense digital** é reconstruir o que aconteceu a partir das evidências que um sistema deixou: imagens de
disco, capturas de memória, logs, gravações de rede. É a investigação que vem depois de um incidente, e o
resultado dela pode acabar num tribunal, o que molda a disciplina inteira.

| princípio | por quê |
|---|---|
| **preserve a evidência** antes de analisá-la | analisar o original o altera; trabalhe numa cópia verificada |
| **verifique toda cópia** com um hash | o checksum da aula 1 e a prova da aula 12, usados para mostrar que a cópia é o original |
| **mantenha a cadeia de custódia** | um registro de quem segurou a evidência, quando, e o que fez com ela, para ninguém poder dizer que foi alterada |
| **relate fatos, não palpites** | o relatório diz o que a evidência mostra e com que grau de confiança |

O trabalho é cuidadoso e lento de propósito. O primeiro emprego de um analista forense costuma ser num SOC
ou numa equipe de resposta a incidentes, com a especialização vindo depois; alguns vêm da polícia. As aulas
16 a 18 de `soc-response` cobrem aquisição de imagem, análise e análise de tráfego.

### Segurança de aplicações

**AppSec** é segurança embutida no software: ajudar desenvolvedores a escrever código que resiste a ataque,
revisar desenhos e código, e rodar testes de segurança no pipeline de build para que os problemas sejam
achados antes da entrega, e não depois.

| tarefa | o que quer dizer | aulas |
|---|---|---|
| **modelagem de ameaças** | antes de construir, perguntar o que pode dar errado e desenhar contra isso | 2, 3 |
| **revisão de código seguro** | ler código procurando os erros que atacantes usam, como a verificação que faltava na aula 8 | 8 |
| **testes de segurança no pipeline** | verificações automáticas a cada mudança, como o checklist da aula 16 rodando toda noite | 16 |
| **capacitação dos desenvolvedores** | bibliotecas, orientação e treinamento que tornam o caminho seguro o caminho fácil | 4 |

Quem trabalha com AppSec quase sempre é desenvolvedor que se interessou por segurança, ou gente de segurança
que aprendeu a programar bem. É um papel vizinho do **DevSecOps**, aonde leva a trilha `devsecops`.
`secure-code` ensina o lado do desenvolvedor e `threat-modeling` o lado do desenho.
