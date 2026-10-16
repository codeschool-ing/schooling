---
title: Uma réplica fora
version: 1
---

Uma leitura, depois a réplica parada, depois a mesma leitura:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "replica"}
ana@lab:~/tickets$ docker compose stop replica
 Container tickets-replica-1 Stopping 
 Container tickets-replica-1 Stopped 
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "primary"}
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep 'fell back' | tail -1
{"time": "2026-10-10T19:39:46.379+00:00", "level": "warning", "message": "read fell back", "host": "615b3114daa0", "source": "replica", "error": "terminating connection due to administrator command", "trace_id": "d8058267e23a74fdc1a2f5aef50d4b1d"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Uma leitura tenta quatro coisas em ordem, da esquerda para a direita: a réplica, depois o primário, depois a última resposta que esta cópia viu, que leva a idade dela, e por fim um 503 que pede a quem chama para voltar em cinco segundos. Cada seta para a direita diz 'falha'.\"><rect x=\"20\" y=\"50\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">réplica</text><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">como sempre</text><path d=\"M160 78 L196 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M196 78 L189.7 81.0 L189.7 75.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"178\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">falha</text><rect x=\"198\" y=\"50\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"268\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">primário</text><text x=\"268\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mesmos dados, mais ocupado</text><path d=\"M338 78 L374 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M374 78 L367.7 81.0 L367.7 75.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"356\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">falha</text><rect x=\"376\" y=\"50\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">memória</text><text x=\"446\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">com a idade</text><path d=\"M516 78 L552 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M552 78 L545.7 81.0 L545.7 75.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"534\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">falha</text><rect x=\"554\" y=\"50\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">503</text><text x=\"624\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">volte em 5 s</text><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">leituras se degradam; uma venda precisa do primário e pausa sem ele</text></svg>", "caption": "De onde uma leitura vem, em ordem."}
```

A primeira resposta veio da réplica, a segunda do **primário**, e o comprador não teria como notar a
diferença a não ser pelo campo `source`. O log diz o que aconteceu: a conexão que a bilheteria tinha
com a réplica foi encerrada quando a réplica desligou, então o `read_event` a descartou e passou para
o próximo lugar da lista, no mesmo pedido.

Esse é o caso fácil, e também o que merece atenção. O primário agora carrega toda leitura além de
toda venda. No laboratório são algumas centenas de leituras por segundo a mais num banco que aguenta;
em produção, um primário dimensionado só para as escritas pode não sobreviver ao tráfego das réplicas
chegando de uma vez. Recuar para algo que não aguenta a carga não é degradação, é mudar a queda de
lugar, e as seções de capacidade desta aula são como saber de antemão qual dos dois vai ser.
