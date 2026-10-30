---
title: Menos movimento, quando é pedido
version: 1
---

**As duas plataformas têm uma configuração que pede menos movimento aos apps**: *Reduzir movimento* no
iOS, *Remover animações* no Android. As pessoas a ligam porque movimento na tela as deixa tontas ou
enjoadas, ou porque as distrai. Um app que a ignora é um app que algumas pessoas não conseguem usar por
muito tempo.

O `AccessibilityInfo.isReduceMotionEnabled()` responde à pergunta. A barra do planner a faz antes de cada
animação e, quando a resposta é sim, usa duração 0: a barra muda na hora, sem se mover. **A informação
fica; só o movimento sai.** A barra continua mostrando 76 por cento, e um leitor de tela continua dizendo
95 de 125.

O `frames.mjs` aceita `--reduced`, que pede ao navegador movimento reduzido do jeito que a configuração
do celular pediria. A segunda execução marca como feita a sessão de spanish do dia 22, e a barra vai de
95 para os 125 todos:

```
ana@dev:~/planner$ node frames.mjs 'http://localhost:8082/?today=2026-10-21' 'Mark 30 min on 2026-10-22 done' --reduced
width every 50 ms: 936 1232 1232 1232 1232 1232 1232 1232 1232 1232 1232
```

**Uma amostra na largura antiga, depois a nova.** Nenhuma subida no meio: a primeira amostra foi tirada
antes de a mudança chegar, e a seguinte a encontrou completa.

## O que reduzir, e o que manter

Reduzir movimento não quer dizer tirar toda mudança. Um fade costuma ser aceitável, um deslize grande ou
um quique não, e tudo que se move sozinho, um fundo animado, um carrossel que gira por conta própria,
deve parar. As transições de navegação são do React Navigation, que segue a configuração em cada
plataforma. Nas suas animações, a pergunta a fazer é se o movimento carrega informação; se carrega, dê a
informação de outro jeito.
