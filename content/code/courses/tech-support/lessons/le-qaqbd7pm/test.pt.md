---
title: Testar: uma mudança, um resultado
version: 1
---

Um nome que o computador resolve sozinho, sem perguntar a um servidor DNS, vem do `/etc/hosts`, a aula
sobre nomes do curso de redes. Então a hipótese é específica: **o `/etc/hosts` do `pc1` tem o endereço
errado para `intranet`**. Primeiro olhe, depois mude uma coisa:

```
ana@pc1:~$ grep -n intranet /etc/hosts
10:10.30.0.200 intranet
ana@pc1:~$ sudo sed -i 's/^10.30.0.200 intranet$/10.30.0.31 intranet/' /etc/hosts && grep -n intranet /etc/hosts
10:10.30.0.31 intranet
```

A linha 10 diz `10.30.0.200`, um endereço onde nada responde: a intranet morou ali um dia, e esta linha
nunca foi atualizada quando ela mudou. A mudança troca esse único endereço por `10.30.0.31`, e não mexe em mais
nada.

**Uma mudança** é a regra que faz um teste valer a pena. Se o mesmo passo também tivesse reiniciado a rede
e limpado o cache do navegador, uma página funcionando depois não diria qual dos três consertou, e da
próxima vez ninguém saberia qual fazer.
