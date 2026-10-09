---
title: Todo convidado depois deste, num comando só
version: 1
---

Fazer a vm1 levou um seed, um overlay, o `virt-install`, uma espera, uma linha no `/etc/hosts` e um
primeiro ssh. Toda aula seguinte começa com um ou mais convidados novos, e fazer tudo isso à mão a cada
vez é como um passo acaba pulado. Então aqui está o mesmo trabalho como um script. Salve-o como
`newvm.sh` na sua pasta pessoal; o botão de copiar leva o programa inteiro, sem as notas.

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# newvm.sh NAME [NETWORK] [MEMORY_MB] [VCPUS]: a guest from the lab's base disk\nset -euo pipefail\nname=${1:?usage: newvm.sh NAME [NETWORK] [MEMORY_MB] [VCPUS]}\nnet=${2:-default} mem=${3:-1024} cpus=${4:-2}\nimages=/var/lib/libvirt/images", "note": "O nome é obrigatório, e o `${1:?...}` para com a linha de uso quando ele falta. A rede, a memória e os processadores têm como padrão o que a vm1 teve. O `set -euo pipefail` para o script no primeiro comando que falhar, em vez de fazer um convidado com metade dos passos."}, {"code": "cat > /tmp/$name-user-data <<EOF\n#cloud-config\nhostname: $name\nusers:\n  - name: $USER\n    sudo: ALL=(ALL) NOPASSWD:ALL\n    shell: /bin/bash\n    ssh_authorized_keys: [ \"$(cat ~/.ssh/id_ed25519.pub)\" ]\nEOF\nsudo cloud-localds $images/$name-seed.img /tmp/$name-user-data", "note": "O disco seed da seção 05, escrito para o nome novo. O `$USER` é quem roda o script, então o convidado ganha uma conta com o seu nome e a sua chave."}, {"code": "sudo qemu-img create -q -f qcow2 -b $images/lab-base.qcow2 -F qcow2 $images/$name.qcow2 8G\nsudo virt-install --name $name --memory $mem --vcpus $cpus --import \\\n  --disk $images/$name.qcow2,bus=virtio --disk $images/$name-seed.img,bus=virtio,format=raw \\\n  --os-variant ubuntu24.04 --network network=$net --graphics none --noautoconsole >/dev/null 2>&1", "note": "O overlay e o `virt-install` da seção 06. Não há `--virt-type`: o `virt-install` usa o KVM quando o host oferece e volta para a imitação do QEMU quando não. A saída dele é jogada fora, aviso incluído, porque você já a leu uma vez."}, {"code": "address() {\n  { virsh domifaddr $name --source $1 2>/dev/null || true; } |\n    awk '/ipv4/ && $4 !~ /^127\\./ { sub(/\\/.*/, \"\", $4); print $4; exit }'\n}\nip=\nfor i in $(seq 120); do\n  ip=$(address lease); [ -n \"$ip\" ] || ip=$(address agent)\n  [ -n \"$ip\" ] && break\n  sleep 5\ndone\n[ -n \"$ip\" ] || { echo \"$name has no address after ten minutes\" >&2; exit 1; }\nsudo sed -i \"/ $name\\$/d\" /etc/hosts\necho \"$ip $name\" | sudo tee -a /etc/hosts >/dev/null", "note": "Primeiro o endereço que o libvirt distribuiu, a **concessão** do DHCP dele, e na falta dela o endereço que o **agente do convidado** informa lá de dentro. O segundo é como se acha um convidado numa rede que o libvirt não roda, que a aula 11 monta. 120 tentativas com cinco segundos entre elas são dez minutos. O nome então vai para o `/etc/hosts`, no lugar de qualquer linha antiga do mesmo nome."}, {"code": "ssh-keygen -R $name >/dev/null 2>&1 || true\nready=no\nfor i in $(seq 60); do\n  if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \\\n       $name cloud-init status --wait >/dev/null 2>&1; then ready=yes; break; fi\n  sleep 5\ndone\n[ $ready = yes ] || { echo \"$name has an address but does not let you in\" >&2; exit 1; }", "note": "Um convidado feito antes com o mesmo nome deixou a chave dele no `~/.ssh/known_hosts`, e o ssh recusa uma chave diferente sob um nome conhecido, então a antiga é esquecida primeiro. O `accept-new` confia numa chave que nunca viu: tudo bem para um convidado que você fez um minuto atrás no seu próprio computador, não é hábito para mais nada. O `cloud-init status --wait` só volta quando o convidado terminou de se configurar."}, {"code": "virsh detach-disk $name vdb --persistent >/dev/null\nsudo rm -f $images/$name-seed.img /tmp/$name-user-data\necho \"$name is ready at $ip\"", "note": "O seed fez o trabalho dele, então é desconectado e apagado, e o convidado passa a ser só o próprio disco."}]}
```

```
ana@host:~$ time bash newvm.sh vm1
vm1 is ready at 192.168.122.227

real	2m5.669s
user	0m1.041s
sys	0m0.378s
ana@host:~$ ssh vm1 hostname; tail -1 /etc/hosts
vm1
192.168.122.227 vm1
```

Dois minutos, quase todos do primeiro boot do convidado. O nome vm1 foi usado de novo de propósito, que
é o caso para o qual a linha do `ssh-keygen -R` existe: sem ela, o ssh teria recusado a vm1 nova por
apresentar uma chave diferente da antiga.

**Toda aula seguinte começa assim**, com `bash newvm.sh NOME` para cada convidado de que precisa, e diz
isso. Rode `bash newvm.sh` sem nome e ele imprime a linha de uso e para.
