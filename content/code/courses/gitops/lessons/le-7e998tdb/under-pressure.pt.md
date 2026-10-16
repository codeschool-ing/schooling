---
title: O mesmo fluxo, sob pressão
version: 1
---

**O fluxo desta aula leva minutos quando todo mundo está na mesa. Durante um incidente às três da
manhã ele é o que fica entre quem está de plantão e a correção**, e se for lento demais, as pessoas
dão a volta nele. A aula 1 mostrou o que dar a volta consegue: uma mudança manual que o agente desfaz
na passada seguinte. Então a pergunta não é se o fluxo se mantém durante um incidente, e sim como
deixá-lo rápido o bastante.

## Deixe o caminho normal curto

- **Diffs pequenos.** Uma mudança de uma linha em `replicas` é revisada em segundos. O hábito de pull
  requests pequenos em tempos normais é o que torna possível uma revisão rápida nos ruins.
- **Alguém para aprovar.** Uma escala de plantão com duas pessoas, ou um acordo de que qualquer
  engenheiro pode aprovar uma mudança de emergência, põe a aprovação a uma mensagem de distância, e
  não numa espera até de manhã.
- **Checagens rápidas.** O `kubeconform` neste repositório leva bem menos de um segundo. Uma
  checagem que leva dez minutos vai ser pulada na primeira vez que importar.
- **Um intervalo curto, ou um gatilho.** O laço aqui espera quinze segundos. O Argo CD da aula 3 e o
  Flux da aula 4 podem ser mandados olhar na hora, por um webhook do servidor Git ou por um comando.

## Quebre o vidro, com registro

Algumas situações precisam mesmo de uma mudança sem uma segunda pessoa: a única pessoa acordada, a
própria ferramenta de revisão fora do ar. A resposta é um **caminho de emergência estreito, raro e
barulhento**, nunca uma regra afrouxada em silêncio:

- uma conta dedicada, e não a de uso diário de uma pessoa, com permissão para push na `main` (a
  proteção do Gitea tem uma lista de permissão de push exatamente para isso:
  `enable_push_whitelist` com usuários nomeados);
- as credenciais dela guardadas onde usá-las já é um evento: um envelope lacrado, um cofre que
  registra cada leitura;
- e cada uso seguido de um pull request depois do fato que o explique, revisado como qualquer outro.

A mudança continua passando pelo Git, então o agente a mantém e o histórico a registra. O que a
emergência pula é a espera, nunca o registro.

## O que nunca é opção

**Pausar o agente e mudar o cluster à mão.** Parece mais rápido e é a única escolha que deixa o
cluster e o repositório discordando sem ninguém acompanhar. A próxima pessoa a retomar o agente,
talvez dias depois, desfaz a correção sem saber que ela estava ali.
