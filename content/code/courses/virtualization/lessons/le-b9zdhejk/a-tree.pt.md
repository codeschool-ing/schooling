---
title: Vários deles
version: 1
---

Snapshots podem ser tirados um depois do outro, e formam uma árvore, cada um filho do que era o atual
quando foi tirado:

```
ana@host:~$ virsh snapshot-create-as vm1 configured >/dev/null && virsh snapshot-create-as vm1 tested >/dev/null && virsh snapshot-list vm1 --tree
clean
  |
  +- configured
      |
      +- tested
        

ana@host:~$ virsh snapshot-delete vm1 tested && virsh snapshot-list vm1 --tree
Domain snapshot tested deleted

clean
  |
  +- configured
    
```

O `configured` foi tirado depois do `clean` e o `tested` depois do `configured`, e o `--tree` desenha a
linha entre eles. Dá para reverter para qualquer um, e tirar um novo depois de reverter para um mais
antigo começa um galho novo ao lado da linha velha. Apagar o `tested` removeu só aquele estado; os outros
não foram tocados.

A árvore é onde os laboratórios ficam bagunçados. **Mantenha poucos, dê nomes pelo que protegem, e apague
os que já tiveram a mudança julgada**: depois que a atualização rodou uma semana sem problema, o snapshot
de antes dela só ocupa espaço e, na próxima seção, deixa o disco mais lento.
