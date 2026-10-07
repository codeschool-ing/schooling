---
title: Lacrado, destrancado, e o token root
version: 1
---

Um OpenBao lacrado tem os dados em disco e nenhum jeito de lê-los: a chave raiz não está na
memória. Toda vez que o servidor sobe — depois de um reboot, de uma queda, de uma atualização — ele
sobe lacrado, e alguém precisa trazer as partes. Duas pessoas, cada uma com a sua:

```
ana@lab:~/gov$ bao operator unseal
Unseal Key (will be hidden): 
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       3
Threshold          2
Unseal Progress    1/2
Unseal Nonce       cabee66e-727c-cdea-1e9e-8a20cdaaf57b
Version            2.5.5
Build Date         2026-06-17T11:18:48Z
Storage Type       file
HA Enabled         false
ana@lab:~/gov$ bao operator unseal
Unseal Key (will be hidden): 
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    3
Threshold       2
Version         2.5.5
Build Date      2026-06-17T11:18:48Z
Storage Type    file
Cluster Name    vault-cluster-3b62ca31
Cluster ID      401a6f67-bc34-7d05-399d-ee48cde70c31
HA Enabled      false
```

A parte é lida num prompt oculto, para não ficar no histórico do shell. Depois da primeira,
`Unseal Progress` é `1/2`; depois da segunda, `Sealed false`, e o servidor está atendendo. A Ana
usou as partes 1 e 3. Quais duas não importa — quaisquer duas reconstroem a mesma chave raiz.

**Lacrado é o estado a que o OpenBao volta quando algo dá errado**, e ele pode ser posto ali de
propósito com `bao operator seal`: uma suspeita de intrusão se responde lacrando o cofre, e depois
disso nada é decifrado até dois guardiões de partes concordarem em reabri-lo. O preço é que um
reboot às três da manhã precisa de duas pessoas acordadas. Ambientes de produção trocam isso por
**auto-unseal**, em que a própria chave raiz é protegida por um KMS de nuvem ou um módulo de
hardware — a mesma ideia um nível abaixo, e o motivo de a seção 12 importar até para um time que
roda o OpenBao.

## O token root

```
ana@lab:~/gov$ bao login -no-print
Token (will be hidden): 
ana@lab:~/gov$ bao token lookup -format=json | python3 -c "import json, sys; d = json.load(sys.stdin)['data']; print(d['policies'], d['ttl'])"
['root'] 0
```

O token digitado no prompt oculto foi o **token root inicial** da saída do init. O `-no-print`
mantém o token fora da tela, e as consultas dizem o que ele é: a política `root`, que permite
tudo, e um `ttl` de 0, que quer dizer que nunca expira. A Ana o usa pelos próximos
minutos para configurar o motor transit e as políticas, porque alguma coisa precisa fazer isso.

**Um token root não deve sobreviver à configuração para a qual foi usado.** O padrão de produção é:
usá-lo para criar uma política de administradores e um jeito de os administradores entrarem pelo
provedor de identidade da empresa (o login único da aula 1, de novo), e depois revogá-lo com
`bao token revoke -self`. Se for preciso um token root de novo, dois guardiões de partes geram um
novo com `bao operator generate-root`. Isso mantém "tudo, para sempre" fora do gerenciador de
senhas de qualquer pessoa. No laboratório a Ana fica com o dela, porque o laboratório é reiniciado
mais vezes do que é atacado — e o comando de revogação não foi executado aqui.
