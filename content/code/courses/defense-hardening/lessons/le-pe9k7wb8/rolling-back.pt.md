---
title: Revertendo, e quando não reverter
version: 1
---

**Uma atualização que dá errado tem de sair mais rápido do que entrou.** Essa é a outra metade de
corrigir rápido: uma equipe que desfaz uma atualização ruim em minutos pode se dar ao luxo de instalar
atualizações cedo, e uma que não consegue vai esperar. No `desk`, a versão `1.1` está instalada; voltar
para a `1.0` é uma instalação com a versão nomeada:

```
ana@admin:~$ ssh desk "sudo apt-get install -y -q --allow-downgrades jatoba-health=1.0 2>&1 | grep -E \"^(Unpacking|Setting)|downgrad\"; jatoba-health"
0 upgraded, 0 newly installed, 1 downgraded, 0 to remove and 0 not upgraded.
dpkg: warning: downgrading jatoba-health from 1.1 to 1.0
Unpacking jatoba-health (1.0) over (1.1) ...
Setting up jatoba-health (1.0) ...
jatoba-health 1.0
portal 200
ana@admin:~$ ssh desk "grep jatoba-health /var/log/dpkg.log | grep -E \" (install|upgrade) \""
2026-10-23 09:29:20 install jatoba-health:all <none> 1.0
2026-10-23 09:29:22 upgrade jatoba-health:all 1.0 1.1
2026-10-23 09:29:24 upgrade jatoba-health:all 1.1 1.0
```

O apt pede `--allow-downgrades` porque instalar uma versão mais velha não é algo que ele faz por
padrão; o dpkg avisa que está voltando de versão, desempacota a `1.0` sobre a `1.1` e a configura. O
programa roda e o portal responde. O log do dpkg guarda o histórico todo, uma linha por mudança, e uma
volta de versão aparece ali como um `upgrade` da versão mais nova para a mais velha.

A reversão funcionou porque a versão antiga ainda estava no repositório. **Um repositório que guarda só
a versão mais recente é um de onde não dá para reverter**, e isso é motivo para manter versões antigas
no espelho do escritório enquanto alguma máquina puder precisar delas.

## Quando reverter é o movimento errado

Um pacote pode ser revertido. O que a atualização fez enquanto esteve instalada às vezes não pode:

- **uma migração de banco de dados**: a versão nova mudou um esquema ou converteu dados guardados, e a
  versão antiga não consegue lê-los;
- **um formato de configuração alterado**: a versão nova reescreveu o arquivo de configuração, e a
  antiga o recusa;
- **uma correção de segurança**: reverter reabre a falha que a atualização fechou, então a reversão é
  uma exceção no sentido da aula 16, com motivo, controle compensatório e data.

Para os dois primeiros, a proteção é um snapshot tirado antes da atualização: da máquina virtual, do
banco de dados, do diretório de configuração. A aula 1 recomendou montar o laboratório numa máquina
virtual em parte por isso, e o Multipass consegue tirar snapshot de uma máquina parada. **Seguir em
frente**, instalando uma versão nova corrigida em vez da antiga, muitas vezes é a resposta melhor, e os
anéis existem para que uma atualização ruim chegue a poucas máquinas, de modo que qualquer uma das
duas escolhas seja rápida.
