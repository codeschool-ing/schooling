---
title: Medindo sob carga, e escolhendo os números
version: 1
---

O pod `probe` agora manda à loja um fluxo constante de requisições, uma depois da outra, cada uma
pedindo 200 milissegundos de trabalho. Depois de um minuto e quinze disso:

```
ana@laptop:~/shop$ kubectl top pods -l app=shop
NAME                   CPU(cores)   MEMORY(bytes)   
shop-c8d475877-qb528   227m         2Mi             
shop-c8d475877-t5vqk   355m         7Mi             
shop-c8d475877-zd49p   404m         1Mi             
ana@laptop:~/shop$ kubectl top pods -l app=shop --containers --sort-by=cpu | head -n 2
POD                    NAME   CPU(cores)   MEMORY(bytes)   
shop-c8d475877-zd49p   shop   404m         1Mi             
```

**Entre 227m e 404m por cópia, cerca de uma CPU no total**, que é o que um cliente mandando uma
requisição de cada vez consegue manter ocupado. A memória quase não se mexeu. `--sort-by=cpu` põe o
mais ocupado primeiro, que é como achar o único pod em duzentos que importa.

Diante desses números, os dois requests estavam errados em medidas opostas:

| | pedido | usado sob carga | veredito |
|---|---|---|---|
| CPU | 500m | 227m a 404m | mais ou menos certo, com alguma folga |
| memória | 256 MiB | 1 a 7 MiB | trinta vezes demais |

Um request deve cobrir o que o pod usa sob a sua carga pesada normal, com uma margem; um limit de
memória deve ficar acima do maior valor já visto, porque alcançá-lo mata. Para a loja isso sugere algo
como 400m de CPU e 32 MiB de memória. São números para este laptop e este teste, não para a loja em
produção.

## O que o `kubectl top` não consegue dizer

**É uma amostra, de poucos segundos atrás.** O metrics-server não guarda histórico, então um pico às
três da manhã já sumiu quando alguém olha. Escolher requests precisa dos maiores valores ao longo de
dias, o que exige um sistema de monitoramento que os guarde; a lição 41 é sobre eles. O Vertical Pod
Autoscaler da lição 34 automatiza exatamente essa conta e pode aplicá-la.

Por baixo, o `kubectl top` é uma leitura comum da API:

```
ana@laptop:~/shop$ kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes/shop-worker | head -c 300; echo
{"kind":"NodeMetrics","apiVersion":"metrics.k8s.io/v1beta1","metadata":{"name":"shop-worker","creationTimestamp":"2026-10-06T17:53:52Z","labels":{"beta.kubernetes.io/arch":"amd64","beta.kubernetes.io/os":"linux","kubernetes.io/arch":"amd64","kubernetes.io/hostname":"shop-worker","kubernetes.io/os":"
```

Os primeiros 300 caracteres são a identidade e os rótulos do nó; os números de uso vêm mais adiante no
mesmo objeto. Qualquer coisa que leia a API, um autoscaler inclusive, lê os mesmos números assim.
