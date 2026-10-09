---
title: Voltar atrás, e o que voltar atrás não desfaz
version: 1
---

Se a `v1.1.0` tivesse dado errado em produção, o caminho de volta é o mesmo movimento na outra
direção:

```
ana@vm:~/etl-prod$ git checkout -q v1.0.0 && git describe --tags && dbt build --project-dir shop --target prod --quiet; echo "exit status $?"
v1.0.0
exit status 0
ana@vm:~/etl-prod$ git checkout -q v1.1.0 && dbt build --project-dir shop --target prod --quiet; git describe --tags
v1.1.0
done
```

A produção voltou para a `v1.0.0`, foi construída, e veio de novo para a `v1.1.0`. Sem nenhum
código editado à mão, sem palpite sobre qual versão era a boa: **uma tag é uma versão para a
qual se pode voltar**, e isso é quase todo o motivo de valer a pena criar uma.

Voltar o código só volta os dados até onde os dados são reconstruídos a partir do código.
Aqui isso é quase tudo: views são redefinidas, tabelas são refeitas inteiras, e o `fact_sales`
incremental troca os últimos trinta dias a cada execução, então voltar atrás reconstrói esses dias
com o código antigo também. O que isso não alcança é o que for mais antigo que a janela, que pediria
uma recarga completa, e o que já saiu do warehouse — o CSV mandado aos gerentes ontem, um e-mail, um
arquivo enviado a um parceiro. **Código pode voltar atrás; o que foi feito com a saída dele, não.** É a
distinção da lição 15 entre fatos sobre o mundo e atos, encontrada de novo pelo outro lado, e é por
isso que a comparação acontece antes do deploy, e não depois.
