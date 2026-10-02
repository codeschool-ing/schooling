---
title: O que um produto de APM vende
version: 1
---

APM quer dizer *application performance monitoring*, monitoramento de desempenho de aplicações, e o
nome é mais velho que os produtos que o carregam. **O que esses produtos vendem hoje é a pilha que este
curso montou, operada por outra pessoa**: um agente ou SDK que coleta, uma entrada que recebe, um
armazenamento para cada sinal e uma interface sobre todos eles.

A versão do laboratório dessa pilha tem uns vinte contêineres numa máquina. Para rodá-la em produção,
uma equipe também precisa do que o laboratório pula: armazenamento dimensionado para semanas de dados,
atualizações de seis projetos que lançam versões cada um no seu ritmo, backups, alta disponibilidade
para as partes que alertam, e controle de acesso. **Esse trabalho é a primeira coisa que um produto
hospedado substitui**, e para uma equipe pequena muitas vezes é o que decide.

A segunda é o que é difícil de construir. Os produtos acrescentam coisas que as peças de código aberto
não têm ou deixam para você montar:

| | o que é | o mais próximo em código aberto |
|---|---|---|
| monitoramento de usuário real | tempos e erros medidos no navegador ou no aplicativo do cliente | o SDK JavaScript do OpenTelemetry, mais um lugar para onde mandar |
| verificações sintéticas | visitas roteirizadas a partir de vários países, num horário | o blackbox exporter, de um lugar só |
| profiling contínuo | que funções gastam a CPU, o tempo todo, em produção | o Pyroscope, hoje parte do Grafana |
| replay de sessão | uma reconstrução do que o usuário viu antes de um erro | nada comum |
| detecção de anomalias | uma linha de base aprendida por série, e um alerta quando ela quebra | regras de gravação escritas à mão |

A terceira é que **as ligações vêm prontas**. A aula 7 configurou uma fonte de dados por sinal e a aula
11 precisou de mais uma configuração para os exemplares; um produto hospedado tem todo sinal num
armazenamento só, com o trace id ligando logs a rastros por padrão.

O que ele não vende é uma ideia diferente. Os mesmos três sinais, o mesmo trace id, a mesma conta de
cardinalidade: tudo o que da aula 1 à aula 12 foi dito ainda vale, e os produtos são julgados por quão
bem fazem essas coisas e a que preço.
