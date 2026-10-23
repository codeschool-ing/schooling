---
title: O script que monta o laboratório
version: 1
---

O laboratório inteiro é um script, `hostlab.sh`. Crie um diretório para ele no seu home, no
computador que você escolheu, abra ali um arquivo novo e cole o script dentro. O botão de copiar no
código abaixo entrega o arquivo inteiro, sem as notas.

```sh
mkdir ~/hostlab && cd ~/hostlab
nano hostlab.sh
```

```schooling-example
{"language": "sh", "file": "hostlab.sh", "parts": [{"code": "#!/bin/bash\n# hostlab.sh: the course's machines, as containers on one Ubuntu 24.04 computer.\n#   sudo bash hostlab.sh build              once: the two images, from Ubuntu's archive\n#   sudo bash hostlab.sh up [MACHINE...]    fresh copies, booted; every machine if none is named\n#   sudo bash hostlab.sh down\n#   sudo bash hostlab.sh sh MACHINE         a shell on MACHINE, as you\n#   sudo bash hostlab.sh root MACHINE       a shell on MACHINE, as root\n#   sudo bash hostlab.sh exec MACHINE USER 'command'\nset -euo pipefail\n\nLAB=/var/lib/hostlab\nME=${SUDO_USER:-}\nMIRROR=http://archive.ubuntu.com/ubuntu\nexport SYSTEMD_NSPAWN_UNIFIED_HIERARCHY=1", "note": "O laboratório é um computador Linux fingindo ser sete. Cada máquina é um **contêiner**: uma cópia de um sistema Ubuntu 24.04, iniciada pelo seu próprio systemd, então `systemctl`, `journalctl` e os serviços se comportam como num servidor de verdade. Rode com `sudo`, a partir da sua própria conta: essa conta é a que você vai ter em todas as máquinas."}, {"code": "#        machine address        image\nMACHINES=\"\nsw      192.168.60.2   base\nweb     192.168.60.10  web\ndesk    192.168.60.20  base\nadmin   192.168.60.30  base\njump    192.168.60.40  base\ndns     192.168.60.53  base\ntrap    192.168.60.66  base\n\"\nPACKAGES=\"openssh-server sudo nftables iproute2 iputils-ping curl netcat-openbsd python3 nano\nless rsyslog cron lynis ansible-core usbguard fail2ban clamav yara firejail aide auditd acl\nunattended-upgrades unbound bind9-dnsutils inotify-tools strace file binutils wpasupplicant\nhostapd tcpdump jq socat lsof psmisc procps ca-certificates nmap snmp apt-utils git ufw\nopenscap-scanner ssg-debderived bubblewrap xxd\"\nEXTRAS=\"nginx vsftpd openbsd-inetd inetutils-telnetd rpcbind avahi-daemon snmpd\"", "note": "A rede inteira é esta tabela. Cada máquina tem um endereço num único segmento, 192.168.60.0/24, e `sw` é o switch em que todas estão ligadas. Duas imagens: `base` para seis máquinas, e `web`, que é a `base` mais o portal e tudo o que o administrador anterior deixou para trás."}, {"code": "die() { echo \"$*\" >&2; exit 1; }\nneed() {\n  [ -n \"$ME\" ] && [ \"$ME\" != root ] || die \"run it with sudo, from your own account\"\n  for c in debootstrap systemd-nspawn ip; do\n    command -v \"$c\" >/dev/null || die \"install first: sudo apt install debootstrap systemd-container iproute2\"\n  done\n}\nin_image() { systemd-nspawn -q --register=no --keep-unit --timezone=off -D \"$LAB/images/$1\" --pipe bash -c \"$2\"; }", "note": "Ele se recusa a começar sem os três programas de que precisa e diz quais pacotes os trazem. `in_image` roda um comando dentro de uma imagem antes de qualquer boot: é assim que as imagens são preenchidas."}, {"code": "build() {\n  need\n  rm -rf \"$LAB/images\"; mkdir -p \"$LAB/images\"\n  debootstrap --variant=minbase --include=systemd,systemd-sysv,dbus noble \"$LAB/images/base\" \"$MIRROR\"\n  local B=$LAB/images/base\n  printf 'deb %s noble main universe\\ndeb %s noble-updates main universe\\ndeb %s noble-security main universe\\n' \\\n    \"$MIRROR\" \"$MIRROR\" \"$MIRROR\" > \"$B/etc/apt/sources.list\"\n  rm -f \"$B/etc/resolv.conf\"; cp -L /etc/resolv.conf \"$B/etc/resolv.conf\"\n  ln -sf /usr/share/zoneinfo/America/Sao_Paulo \"$B/etc/localtime\"\n  in_image base \"export DEBIAN_FRONTEND=noninteractive\n    apt-get update -q && apt-get install -y -q --no-install-recommends $(echo $PACKAGES)\n    systemctl disable auditd usbguard usbguard-dbus unbound\n    useradd -m -s /bin/bash -G sudo $ME\n    echo '$ME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$ME\n    install -d -m 700 -o $ME -g $ME /home/$ME/.ssh\n    runuser -u $ME -- ssh-keygen -q -t ed25519 -N '' -f /home/$ME/.ssh/id_ed25519\n    cp /home/$ME/.ssh/id_ed25519.pub /home/$ME/.ssh/authorized_keys\n    printf 'Host *\\n    StrictHostKeyChecking accept-new\\n    LogLevel ERROR\\n' > /home/$ME/.ssh/config\n    chown $ME: /home/$ME/.ssh/*; apt-get clean\"", "note": "`build` faz a imagem base: um Ubuntu 24.04 mínimo do repositório, os pacotes do curso e a sua conta, com uma chave em que todas as máquinas confiam. Quatro serviços são desligados: `auditd`, `usbguard` e o seu companheiro de D-Bus porque um contêiner não consegue rodá-los, o que as aulas 8 e 5 explicam, e `unbound` porque só o `dns` o roda, a partir da aula 14. Baixa cerca de 200 MB, e levou uns dois minutos e meio no computador em que o curso foi gravado."}, {"code": "  cp -a \"$B\" \"$LAB/images/web\"\n  in_image web \"export DEBIAN_FRONTEND=noninteractive\n    apt-get install -y -q --no-install-recommends $(echo $EXTRAS) && apt-get clean\n    useradd -r -m -d /srv/portal -s /bin/bash portal\n    useradd -m -s /bin/bash estagio; echo estagio:Jatoba2019 | chpasswd\n    echo 'estagio ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/estagio\n    useradd -o -u 0 -g 0 -M -d /root -s /bin/bash suporte; echo suporte:suporte123 | chpasswd\n    printf 'PermitRootLogin yes\\nPasswordAuthentication yes\\n' > /etc/ssh/sshd_config.d/50-old.conf\n    echo 'telnet stream tcp nowait root /usr/sbin/telnetd telnetd' > /etc/inetd.conf\n    printf 'agentaddress udp:161\\nrocommunity public\\n' > /etc/snmp/snmpd.conf\n    sed -i 's/^listen=NO/listen=YES/; s/^listen_ipv6=YES/listen_ipv6=NO/' /etc/vsftpd.conf\"", "note": "A imagem `web` é o portal de clientes de um pequeno escritório de contabilidade, a Jatobá Contabilidade, do jeito que foi entregue. Tudo depois da linha do `apt-get` é uma decisão que alguém tomou anos atrás e ninguém desfez: a conta de um estagiário com senha e `sudo` completo, uma segunda conta com id de usuário 0, root podendo entrar com senha, telnet e SNMP respondendo a qualquer um que diga `public`. A aula 1 encontra tudo isso olhando de fora, como você faria num servidor que não montou."}, {"code": "  mkdir -p \"$LAB/images/web/opt/portal\"\n  cat > \"$LAB/images/web/opt/portal/portal.py\" <<'PY'\n#!/usr/bin/env python3\n\"\"\"Jatobá Contabilidade's client portal: one page and a health check.\"\"\"\nimport http.server\n\nclass Portal(http.server.BaseHTTPRequestHandler):\n    def do_GET(self):\n        pages = {\"/\": \"Jatobá Contabilidade: client portal\\n\", \"/healthz\": \"ok\\n\"}\n        if self.path not in pages:\n            return self.send_error(404)\n        body = pages[self.path].encode()\n        self.send_response(200)\n        self.send_header(\"Content-Type\", \"text/plain; charset=utf-8\")\n        self.end_headers()\n        self.wfile.write(body)\n\nhttp.server.ThreadingHTTPServer((\"127.0.0.1\", 8080), Portal).serve_forever()\nPY\n  printf '[Unit]\\nDescription=Jatoba client portal\\n[Service]\\nUser=portal\\nExecStart=/usr/bin/python3 /opt/portal/portal.py\\nRestart=on-failure\\n[Install]\\nWantedBy=multi-user.target\\n' \\\n    > \"$LAB/images/web/etc/systemd/system/portal.service\"\n  printf 'server {\\n    listen 80 default_server;\\n    location / { proxy_pass http://127.0.0.1:8080; }\\n}\\n' \\\n    > \"$LAB/images/web/etc/nginx/sites-available/default\"\n  printf '#!/bin/sh\\ntar czf /var/backups/portal.tgz /srv/portal\\n' > \"$LAB/images/web/opt/portal/backup.sh\"\n  chmod 777 \"$LAB/images/web/opt/portal/backup.sh\"\n  echo '30 2 * * * root /opt/portal/backup.sh' > \"$LAB/images/web/etc/cron.d/portal-backup\"\n  in_image web \"systemctl enable portal\"\n  echo \"images built: $(du -sh \"$LAB/images\" | cut -f1)\"\n}", "note": "O portal em si tem menos de vinte linhas da biblioteca padrão do Python atrás do nginx, rodando com um usuário próprio. As últimas linhas deixam um script de backup que o root roda toda noite e que qualquer um pode editar, assunto da aula 6."}, {"code": "leader() { local p; p=$(cat \"$LAB/run/$1.pid\" 2>/dev/null) && pgrep -P \"$p\" -x systemd | head -1; }\nrunning() { [ -n \"$(leader \"$1\" 2>/dev/null)\" ]; }\ninside() { local m=$1 l; shift; l=$(leader \"$m\") || die \"$m is not running: sudo bash hostlab.sh up $m\"\n  nsenter -t \"$l\" -a env -i TERM=\"${TERM:-dumb}\" LANG=C.UTF-8 \"$@\"; }", "note": "Uma máquina em execução é uma árvore de processos com o seu próprio systemd no topo. `inside` entra nos namespaces dessa máquina, e é assim que `sh`, `root` e `exec` chegam até ela sem nenhum caminho de rede a partir do seu computador."}, {"code": "down() {\n  for m in $(echo \"$MACHINES\" | awk 'NF{print $1}'); do\n    local p; p=$(cat \"$LAB/run/$m.pid\" 2>/dev/null) || continue\n    kill \"$p\" 2>/dev/null || true\n    for _ in $(seq 50); do kill -0 \"$p\" 2>/dev/null || break; sleep 0.2; done\n    rm -f \"$LAB/run/$m.pid\"\n  done\n  for n in $(ip netns list | awk '/^hostlab-/{print $1}'); do ip netns del \"$n\"; done\n}\nup() {\n  need; [ -d \"$LAB/images/web\" ] || die \"build the images first: sudo bash hostlab.sh build\"\n  local want; want=$(echo \"${*:-$(echo \"$MACHINES\" | awk 'NF{print $1}')}\" | tr ' ' '\\n' | grep -vx sw || true)\n  down; mkdir -p \"$LAB/run\" \"$LAB/machines\"\n  ip netns add hostlab-sw; ip -n hostlab-sw link set lo up\n  ip -n hostlab-sw link add br0 address 52:54:00:a8:3c:02 type bridge; ip -n hostlab-sw link set br0 up\n  ip -n hostlab-sw addr add 192.168.60.2/24 dev br0", "note": "`up` começa do zero toda vez: as máquinas antigas são paradas, e o switch é um namespace de rede novo com uma bridge dentro. Nada no laboratório está ligado à rede do seu computador, então nada do que ele roda pode ser alcançado de fora, e nada dentro dele alcança a internet."}, {"code": "  local hosts; hosts=$(echo \"$MACHINES\" | awk 'NF{printf \"%s\\t%s.jatoba.example %s\\n\", $2, $1, $1}')\n  for m in sw $want; do\n    local addr img; read -r addr img < <(echo \"$MACHINES\" | awk -v m=\"$m\" '$1 == m {print $2, $3}')\n    [ -n \"$addr\" ] || die \"no machine called $m\"\n    local M=$LAB/machines/$m; rm -rf \"$M\"; cp -a \"$LAB/images/$img\" \"$M\"\n    echo \"$m\" > \"$M/etc/hostname\"; : > \"$M/etc/machine-id\"\n    printf '127.0.0.1\\tlocalhost\\n127.0.1.1\\t%s\\n%s\\n' \"$m\" \"$hosts\" > \"$M/etc/hosts\"\n    rm -f \"$M/etc/resolv.conf\"; printf 'nameserver 192.168.60.53\\nsearch jatoba.example\\n' > \"$M/etc/resolv.conf\"\n    rm -f \"$M\"/etc/ssh/ssh_host_*; chroot \"$M\" ssh-keygen -A >/dev/null", "note": "Cada máquina é uma cópia nova da sua imagem, com nome próprio, chaves de host SSH próprias e a tabela de endereços em `/etc/hosts`. Uma aula que quebra uma máquina não custa nada: o próximo `up` joga a cópia fora."}, {"code": "    if [ \"$m\" != sw ]; then\n      ip netns add \"hostlab-$m\"; ip -n \"hostlab-$m\" link set lo up\n      ip link add \"hl-$m\" type veth peer name hl-tmp\n      ip link set hl-tmp netns \"hostlab-$m\"; ip -n \"hostlab-$m\" link set hl-tmp name eth0\n      ip -n \"hostlab-$m\" link set eth0 address \"$(printf '52:54:00:a8:3c:%02x' \"${addr##*.}\")\"\n      ip -n \"hostlab-$m\" addr add \"$addr/24\" dev eth0; ip -n \"hostlab-$m\" link set eth0 up\n      ip link set \"hl-$m\" netns hostlab-sw\n      ip -n hostlab-sw link set \"hl-$m\" name \"port-$m\"; ip -n hostlab-sw link set \"port-$m\" master br0 up\n    fi", "note": "O cabo: um par de placas de rede virtuais, uma ponta dentro da máquina como `eth0` e a outra no switch como `port-web`, `port-desk` e assim por diante. A placa de dentro recebe um endereço de hardware fixo que termina no último número do seu endereço IP escrito em hexadecimal, `52:54:00:a8:3c:0a` para o web em `.10`, para que um endereço num log diga de que máquina veio. `sw` não precisa de cabo, porque vive dentro do próprio namespace do switch."}, {"code": "    setsid systemd-nspawn -q -b --console=passive --register=no --keep-unit --timezone=off \\\n      --network-namespace-path=\"/run/netns/hostlab-$m\" -D \"$M\" --machine \"$m\" \\\n      </dev/null >\"$LAB/run/$m.log\" 2>&1 &\n    echo $! > \"$LAB/run/$m.pid\"\n  done\n  for m in sw $want; do\n    local state=\n    for _ in $(seq 100); do\n      state=$(running \"$m\" && inside \"$m\" systemctl is-system-running --wait 2>&1) || true\n      case $state in running|degraded) break ;; esac; sleep 0.3\n    done\n    printf '%-6s %s\\n' \"$m\" \"${state:-not started}\"\n  done\n}", "note": "Depois cada cópia dá boot, e `up` espera o systemd de cada máquina dizer que terminou de subir. A última coisa que ele imprime é esse estado por máquina: `running` é o que você quer, e `degraded` quer dizer que um serviço falhou, e `systemctl --failed` nessa máquina diz qual."}, {"code": "case \"${1:-}\" in\n  build) build ;;\n  up) shift; up \"$@\" ;;\n  down) down ;;\n  sh) inside \"${2:?which machine?}\" su -l \"$ME\" ;;\n  root) inside \"${2:?which machine?}\" su -l root ;;\n  exec) inside \"${2:?which machine?}\" su -l \"${3:?which user?}\" -c \"${4:?which command?}\" ;;\n  *) sed -n '2,8s/^# \\{0,1\\}//p' \"$0\"; exit 1 ;;\nesac", "note": "As últimas linhas são os comandos. Rodado sem argumento, ele imprime o uso que está no topo do arquivo."}]}
```

**Confira o que você colou antes de rodar.** Um script que roda como root merece o mesmo olhar que
você daria a um que alguém mandou por e-mail, e este não é exceção. O arquivo com que os transcritos
foram gravados tem este checksum e este número de linhas; o seu deve bater nos dois, e se não bater,
a cópia perdeu ou ganhou alguma coisa:

```
$ sha256sum hostlab.sh; wc -l hostlab.sh
8191e0e38f8aed3a9db090ab78b9c9b9df719bd21b603ce0353afc4bb22f336e  hostlab.sh
158 hostlab.sh
$ time sudo bash hostlab.sh build > build.log 2>&1; tail -1 build.log

real	2m20.108s
user	0m39.539s
sys	0m21.831s
images built: 1.8G
```

`build` roda uma vez só. Baixa cerca de 200 MB do repositório do Ubuntu e deixa duas imagens em
`/var/lib/hostlab/images`, 1,8 GB juntas. A saída dele é longa, então o comando acima a manda para
`build.log` e mostra a última linha; quando alguma coisa dá errado, o motivo está perto do fim desse
arquivo.

Depois vem o `up`, que você vai digitar no começo de toda aula:

```
$ time sudo bash hostlab.sh up
sw     running
web    running
desk   running
admin  running
jump   running
dns    running
trap   running

real	0m42.035s
user	0m4.568s
sys	0m22.176s
```

Todas as máquinas dizem `running`. No computador em que o curso foi gravado, as sete juntas usaram
menos de 1 GB de memória e 6,4 GB de disco. `up` com nomes, `sudo bash hostlab.sh up web desk`, sobe
só essas duas e o switch, o que é mais rápido e é o que a maioria das aulas pede.

**Toda aula começa com um laboratório novo.** O que a aula anterior mudou some depois do `up`, de
propósito: cada aula diz de onde parte, e partir do mesmo lugar que os transcritos é o que torna a
sua saída comparável com a deles.

Para trabalhar numa máquina, abra um shell nela. O prompt diz quem você é e onde está:

```
$ sudo bash hostlab.sh sh web
ana@web:~$ hostname; id
web
uid=1000(ana) gid=1000(ana) groups=1000(ana),27(sudo)
ana@web:~$ ping -c1 -W1 desk | head -2
PING desk.jatoba.example (192.168.60.20) 56(84) bytes of data.
64 bytes from desk.jatoba.example (192.168.60.20): icmp_seq=1 ttl=64 time=0.490 ms
ana@web:~$ exit
logout
```

`sh` dá a você a sua própria conta naquela máquina, com `sudo`; `root` dá um shell de root direto;
`exit` traz você de volta ao computador do laboratório. A sua conta pode usar `sudo` sem senha em
todas as máquinas, o que um servidor de verdade não permitiria e que a seção desta aula sobre contas
aponta. Isso deixa os transcritos sem pedidos de senha. Dentro do laboratório as máquinas se
alcançam pelo nome, inclusive `ssh web` a partir do `desk`, com uma chave que o script fez para você
no `build`.
