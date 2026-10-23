---
title: Impondo num horário
version: 1
---

**Uma linha de base aplicada uma vez é uma linha de base que foi verdade uma vez.** A resposta da
Política de Grupo é a atualização em segundo plano a cada 90 minutos. A do Ansible, quando ele empurra
a partir de uma máquina de controle, é rodar o playbook num timer ali. No `admin`, duas pequenas
unidades do systemd fazem isso: um serviço que roda o playbook uma vez e um timer que inicia o serviço
a cada hora.

```
ana@admin:~$ cat baseline.service baseline.timer
[Unit]
Description=Put the Jatoba baseline back on every machine

[Service]
Type=oneshot
User=ana
WorkingDirectory=/home/ana
Environment=ANSIBLE_NOCOLOR=1
ExecStart=/usr/bin/ansible-playbook -i hosts.ini baseline.yml
[Unit]
Description=Run the Jatoba baseline every hour

[Timer]
OnCalendar=hourly
RandomizedDelaySec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

O serviço roda como você, a partir do seu home, onde estão o inventário e o playbook, então usa a
mesma chave SSH que você usou à mão. `Type=oneshot` quer dizer que ele roda até o fim e para. O timer
dispara na hora cheia, atrasado em até cinco minutos ao acaso para que uma frota de máquinas de
controle não comece toda junto, que é o mesmo motivo de a Política de Grupo somar até 30 minutos aos
seus 90. `Persistent` roda uma hora perdida assim que a máquina volta, se ela estava desligada.

Instale os dois e ligue o timer:

```
ana@admin:~$ sudo cp baseline.service baseline.timer /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now baseline.timer 2>&1 | sed "s/ → .*//"
Created symlink /etc/systemd/system/timers.target.wants/baseline.timer
ana@admin:~$ systemctl list-timers baseline.timer --no-pager | head -2 | cut -c1-95
NEXT                         LEFT LAST PASSED UNIT           ACTIVATES
Fri 2026-10-23 09:04:10 -03 17min -         - baseline.timer baseline.service
```

O `list-timers` mostra quando ele dispara de novo. Não é preciso esperar: iniciar o serviço à mão
roda exatamente o que o timer vai rodar, e o resumo do playbook cai no journal.

```
ana@admin:~$ sudo systemctl start baseline.service; journalctl -u baseline.service --no-pager -o cat | grep -E "^(desk|jump|web) "
desk                       : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
jump                       : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
web                        : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
ana@desk:~$ grep MaxAuth /etc/ssh/sshd_config.d/10-baseline.conf
MaxAuthTries 3
```

O `desk` informa duas mudanças, o arquivo devolvido e o reload; os outros dois, nenhuma. O desvio da
última seção sumiu, e o journal registra qual execução o desfez, e a que horas. **Essa linha no
journal é a trilha de auditoria**: uma edição à mão que volta toda hora é uma pessoa repetindo-a, e
alguém deveria perguntar a ela por quê.

## Empurrar ou puxar

O timer no `admin` **empurra**: uma máquina alcança todas as outras. Precisa de SSH em cada máquina e
de uma máquina de controle ligada. A alternativa é **puxar**: o `ansible-pull` em cada máquina busca o
playbook num repositório Git e o aplica a si mesma, no próprio timer. Puxar serve a notebooks que
raramente estão na rede do escritório na hora em que o empurrão roda, que é o mesmo problema que a
Microsoft responde com o Intune para máquinas fora do domínio. Nenhum dos dois foi executado para
este curso.

De um jeito ou de outro, a descrição agora mora num lugar só. A próxima coisa a centralizar é o
registro de quem a mudou, e isso é controle de versão: uma linha de base guardada num repositório Git
tem histórico, revisor e caminho de volta, coisas que um diretório no `admin` não tem.
