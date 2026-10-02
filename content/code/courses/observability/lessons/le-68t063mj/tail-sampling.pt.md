---
title: Decidindo na cauda
version: 1
---

**A amostragem na cauda decide depois de o rastro terminar**, então pode decidir pelo que aconteceu. Os
serviços voltam a registrar todo rastro, e o Collector segura cada um até ele ficar completo, e então o
guarda se alguma das políticas dele mandar. A configuração de amostragem do laboratório,
`otel/collector-sampling.yaml`, tem três:

```
ana@obs:~/shop$ sed -n '/^  tail_sampling:/,/^  memory_limiter:/p' otel/collector-sampling.yaml
  tail_sampling:
    decision_wait: 10s
    num_traces: 20000
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow
        type: latency
        latency: {threshold_ms: 1000}
      - name: a-few-of-the-rest
        type: probabilistic
        probabilistic: {sampling_percentage: 5}
  memory_limiter:
```

- **`errors`**: qualquer span com status de erro guarda o rastro inteiro.
- **`slow`**: um rastro de mais de um segundo é guardado.
- **`a-few-of-the-rest`**: 5% de tudo, para haver rastros comuns com que comparar os lentos. Sem uma
  base, todo rastro no armazenamento é um problema e ninguém sabe dizer como é o normal.

O `decision_wait` é quanto o Collector espera depois do primeiro span de um rastro antes de decidir.
Para as políticas terem o que achar, o payments recebe a ordem de somar 1500 ms a cada vigésima quinta
cobrança e de falhar a cada quadragésima. Depois de dois minutos, as métricas do próprio Collector
dizem o que cada política guardou:

```
ana@obs:~/shop$ ./promq 'sum by (policy) (increase(otelcol_processor_tail_sampling_count_traces_sampled{decision="sampled"}[2m]))'
policy=a-few-of-the-rest  34.285714285714285
policy=errors  13.714285714285714
policy=slow  21.71428571428571
```

```
ana@obs:~/shop$ ./promq 'sum by (decision) (increase(otelcol_processor_tail_sampling_global_count_traces_sampled[2m]))'
decision=not_sampled  475.4285714285714
decision=sampled  65.14285714285714
```

Uns 540 checkouts em dois minutos, e 65 guardados, 12%. `errors` guardou 14, que é cada quadragésima
cobrança; `slow` guardou 22, cada vigésima quinta; `a-few-of-the-rest` guardou 34, perto dos 5% dele.
As três somam mais que 65 porque um rastro pode satisfazer duas políticas ao mesmo tempo, e as
contagens são fracionárias porque o `increase` extrapola até as bordas da janela, como a aula 5 mostrou.

E o que isso faz com o volume:

```
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'
  39.86666666666666
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_exporter_sent_spans{exporter="zipkin"}[1m]))'
  4.933333333333334
```

Chegam quarenta spans por segundo e saem cinco. **Os rastros no armazenamento agora são os que vale
abrir**. Uma busca no Jaeger por erros acha todo erro dos últimos dois minutos, e uma busca por
checkouts lentos acha todo checkout lento, não um em dez.

As políticas são avaliadas juntas e qualquer uma basta. O processador tem mais tipos que esses três:
pelo valor de um atributo, por número de spans, por taxa por segundo, e combinações deles. Uma política
por atributo é como uma equipe guarda todo rastro de um cliente importante, ou de uma versão nova, por
uma semana.
