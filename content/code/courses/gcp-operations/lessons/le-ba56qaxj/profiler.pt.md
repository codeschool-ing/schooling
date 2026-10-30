---
title: Cloud Profiler, e para onde vai a CPU
version: 1
---

**Um profiler responde a uma pergunta que nem métricas nem traces respondem: dentro do processo, que funções
usam a CPU e a memória.** Um trace diz que a API passou 2,3 segundos nela mesma; um perfil diz que esses
segundos foram gastos num codificador JSON serializando a mesma lista de produtos a cada requisição. O Cloud
Profiler coleta perfis de serviços em execução continuamente, alguns segundos por vez de cada instância, com um
custo de desempenho que o Google declara pequeno o bastante para produção, e os desenha como flame graph.
**Nada nesta seção foi executado**: ela precisa do agente do Profiler falando com o Google, e não tem emulador.

## Como se liga

O Profiler é um agente dentro do processo, uma biblioteca importada na inicialização:

```python
import googlecloudprofiler

googlecloudprofiler.start(service="shop-api", service_version="a1b2c3d")
```

A conta de serviço com que o processo roda precisa de `roles/cloudprofiler.agent`. O agente suporta Go, Java,
Node.js e Python, cada um com os tipos de perfil que o runtime consegue medir: tempo de CPU e tempo de relógio,
heap e memória alocada, threads e contenção, nem todos em toda linguagem.

## Lendo um flame graph

Cada barra é uma função; a largura é a parte do recurso medido gasta nela e no que ela chamou; uma barra fica em
cima de quem a chamou. **Leia pela largura, não pela altura.** Uma torre alta e estreita é uma pilha de chamadas
profunda que custa pouco. Uma barra larga perto do topo é uma função só que custa muito sozinha, e é onde olhar
primeiro.

O Profiler também compara: dois intervalos de tempo, ou duas versões pelo `service_version`, lado a lado. Um
release que deixou a API 30% mais lenta aparece como uma barra que cresceu, o que é muito mais rápido de achar do
que lendo o diff.

## Qual dos três usar

| a pergunta | a ferramenta |
|---|---|
| que erro é novo, e com que frequência acontece? | Error Reporting |
| onde esta requisição lenta gastou o tempo? | Cloud Trace |
| em que o processo gasta a CPU, no geral? | Cloud Profiler |
| está pior que o normal agora? | uma métrica e um alerta (lições 8, 10, 14) |

Os três primeiros investigam; o quarto percebe. Nenhum substitui os outros, e a ordem em que um incidente os usa
(perceber, depois achar a requisição, depois achar a função) é a ordem da lição 15.
