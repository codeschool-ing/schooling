---
title: Onde os logs realmente estão
version: 1
---

O `kubectl logs` parece perguntar à aplicação. **Ele está lendo um arquivo no nó.** O runtime de
containers escreve tudo o que o processo imprime na saída padrão e de erro num arquivo por container,
em `/var/log/pods`:

```
ana@laptop:~/shop$ docker exec shop-worker2 ls /var/log/pods | grep shop
default_shop-774b84ff8c-5tnl8_32daf685-6666-4ec3-b909-65de42637038
ana@laptop:~/shop$ docker exec shop-worker2 sh -c 'tail -n 2 /var/log/pods/default_shop-774b84ff8c-5tnl8_*/shop/0.log'
2026-10-06T21:38:49.667945636Z stderr F 2026-10-06T21:38:49Z GET / from 10.244.1.4:49178
2026-10-06T21:38:49.67266958Z stderr F 2026-10-06T21:38:49Z GET / from 10.244.1.4:49212
ana@laptop:~/shop$ kubectl logs shop-774b84ff8c-5tnl8 --tail=2
2026-10-06T21:38:49Z GET / from 10.244.1.4:49178
2026-10-06T21:38:49Z GET / from 10.244.1.4:49212
```

O arquivo tem cada linha embrulhada duas vezes: o timestamp do próprio runtime, o fluxo (`stderr`,
porque a loja registra ali) e uma marca, depois a linha exatamente como a loja a escreveu, que é o que o
`kubectl logs` devolve. **O arquivo é apagado quando o pod é**, e é rotacionado por tamanho enquanto o
pod vive, então um nó só guarda logs recentes dos pods que roda agora.

É por isso que clusters rodam um coletor de logs, normalmente como DaemonSet da lição 12: um pod por nó
lê esses arquivos e manda as linhas a um armazenamento central, onde elas sobrevivem aos pods e podem
ser buscadas em todos eles de uma vez. Um programa que escreve os logs num arquivo dentro do container,
em vez da saída padrão, é invisível para tudo isso.
