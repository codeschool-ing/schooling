---
title: Endurecendo um serviço que você roda
version: 1
---

**A sandbox mais barata de um servidor é a que fica em volta dos serviços que ele já roda.** O portal
não é suspeito; é o programa do próprio escritório. Mas ele lê pedidos de estranhos o dia inteiro, e
uma falha nele entregaria a quem a achasse tudo o que o serviço dele pode fazer. Hoje isso é muita
coisa, e o systemd mede quanto:

```
ana@web:~$ systemd-analyze security portal | tail -1
→ Overall exposure level for portal.service: 9.2 UNSAFE :-{
ana@web:~$ systemd-analyze security portal | grep -E "PrivateNetwork=|ProtectHome=|ProtectSystem=|CapabilityBoundingSet=~CAP_SYS_ADMIN"
✗ ProtectSystem=                                              Service has full access to the OS file hierarchy                             0.2
✗ ProtectHome=                                                Service has full access to home directories                                  0.2
✗ CapabilityBoundingSet=~CAP_SYS_ADMIN                        Service has administrator privileges                                         0.3
✗ PrivateNetwork=                                             Service has access to the host's network                                     0.5
```

O `systemd-analyze security` confere uma unidade contra as opções de isolamento que o systemd oferece
e dá ao resultado uma nota de 0, totalmente confinado, a 10, nada confinado. O portal tem nota de um
serviço que não recebeu nada, e as linhas abaixo citam algumas das paredes que faltam a ele: uma rede
própria, um home escondido, um sistema somente leitura e a capacidade mais poderosa do root. Salve este
drop-in como `20-sandbox.conf` no seu home no `web`:

```schooling-example
{"language": "ini", "file": "20-sandbox.conf", "parts": [{"code": "[Service]\nProtectSystem=strict\nProtectHome=yes\nPrivateTmp=yes\nPrivateDevices=yes\nNoNewPrivileges=yes\nProtectKernelTunables=yes\nProtectKernelModules=yes\nProtectControlGroups=yes\nRestrictAddressFamilies=AF_INET AF_UNIX\nRestrictNamespaces=yes\nCapabilityBoundingSet=\nSystemCallFilter=@system-service", "note": "Cada linha tira algo que o portal nunca usa: gravar no sistema, os diretórios home, um `/tmp` compartilhado, os dispositivos de hardware, as configurações e os módulos do kernel, toda família de rede menos IPv4 e sockets locais, a criação de namespaces, toda capacidade que o root teria, e toda chamada de sistema fora do conjunto que o systemd lista para serviços comuns."}]}
```

Instale-o ao lado da unidade, reinicie o portal e confira que ele ainda funciona antes de ler a nova
nota:

```
ana@web:~$ sudo mkdir -p /etc/systemd/system/portal.service.d && sudo cp 20-sandbox.conf /etc/systemd/system/portal.service.d/
ana@web:~$ sudo systemctl daemon-reload && sudo systemctl restart portal && sleep 1 && curl -s http://localhost/
Jatobá Contabilidade: client portal
ana@web:~$ systemd-analyze security portal | tail -1
→ Overall exposure level for portal.service: 2.4 OK :-)
```

**Confira o serviço antes da nota.** Uma sandbox que quebra o programa que protege é tirada às pressas
e nunca mais volta, então a ordem é sempre: acrescentar as paredes, confirmar que o trabalho continua
funcionando e só então ler o número. Aqui a página continua respondendo, depois do segundo que o
portal leva para abrir a porta, e a exposição caiu para o número da última linha.

A nota é um guia, não uma meta. Algumas das conferências não se aplicam a um serviço, e algumas
paredes custam mais do que protegem. O que ela faz bem é transformar "este serviço está confinado?"
numa lista que alguém consegue ler numa revisão, e cada opção dessa lista é o mesmo tipo de decisão que
a aula 1 tomou sobre serviços e contas: tirar o que o trabalho não precisa.
