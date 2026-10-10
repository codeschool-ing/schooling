---
title: O que o processo a mais custa
version: 1
---

Cada padrão desta aula acrescenta alguma coisa que roda em toda requisição, e cada um custa algo que dá
para medir:

| padrão | o que acrescenta | o custo | vale a pena quando |
| --- | --- | --- | --- |
| fachada strangler | um salto de proxy em toda requisição | um pouco de latência, mais uma coisa que tem de ficar no ar | há um sistema a substituir e ele não pode parar |
| sidecar | um processo a mais por instância de serviço, um salto a mais na entrada | memória e CPU vezes o número de instâncias; no laboratório cada requisição repassada levou uns 2 ms, serviço incluído | muitos serviços, em várias linguagens, precisam do mesmo trabalho transversal |
| ambassador | um processo a mais ao lado de cada chamador | o mesmo, na saída | uma dependência precisa de um tratamento especial que vários serviços implementariam cada um |

A linha da memória é a que cresce em silêncio. Um sidecar de 50 MB ao lado de cada uma de 200 instâncias
de serviço são 10 GB de memória fazendo log e TLS. É um dos motivos de os projetos de mesh estarem tirando
trabalho dos sidecars por pod e levando para um proxy por máquina (o modo ambient do Istio, o plano de
dados eBPF do Cilium): mesma função, menos cópias.

A fachada tem outro custo: **ela sobrevive à migração** se ninguém planejar o fim dela. Um strangler que
para em "o estoque se mudou, o resto depois" deixa uma fachada, um monólito e um serviço novo, três coisas
para rodar onde antes havia uma. A migração termina quando o monólito some ou é mantido de propósito, e
dizer qual dos dois faz parte do plano desde o primeiro dia.

Quando terminar, pare o laboratório:

```sh
docker compose down
```
