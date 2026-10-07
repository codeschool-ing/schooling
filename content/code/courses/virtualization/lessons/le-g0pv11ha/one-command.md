---
title: Every guest after this one, in one command
version: 1
---

Making vm1 took a seed, an overlay, `virt-install`, a wait, a line in `/etc/hosts` and a first ssh.
Every later lesson starts with one or more fresh guests, and doing all of that by hand each time is
how a step gets skipped. So here is the same work as one script. Save it as `newvm.sh` in your home
folder; the copy button takes the whole program without the notes.

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# newvm.sh NAME [NETWORK] [MEMORY_MB] [VCPUS]: a guest from the lab's base disk\nset -euo pipefail\nname=${1:?usage: newvm.sh NAME [NETWORK] [MEMORY_MB] [VCPUS]}\nnet=${2:-default} mem=${3:-1024} cpus=${4:-2}\nimages=/var/lib/libvirt/images", "note": "The name is required, and `${1:?...}` stops with the usage line when it is missing. The network, the memory and the processors default to what vm1 had. `set -euo pipefail` stops the script at the first command that fails, instead of making a guest out of half the steps."}, {"code": "cat > /tmp/$name-user-data <<EOF\n#cloud-config\nhostname: $name\nusers:\n  - name: $USER\n    sudo: ALL=(ALL) NOPASSWD:ALL\n    shell: /bin/bash\n    ssh_authorized_keys: [ \"$(cat ~/.ssh/id_ed25519.pub)\" ]\nEOF\nsudo cloud-localds $images/$name-seed.img /tmp/$name-user-data", "note": "The seed disk from section 05, written for the new name. `$USER` is whoever runs the script, so the guest gets an account with your name and your key."}, {"code": "sudo qemu-img create -q -f qcow2 -b $images/lab-base.qcow2 -F qcow2 $images/$name.qcow2 8G\nsudo virt-install --name $name --memory $mem --vcpus $cpus --import \\\n  --disk $images/$name.qcow2,bus=virtio --disk $images/$name-seed.img,bus=virtio,format=raw \\\n  --os-variant ubuntu24.04 --network network=$net --graphics none --noautoconsole >/dev/null 2>&1", "note": "The overlay and `virt-install` from section 06. There is no `--virt-type`: `virt-install` uses KVM when the host offers it and falls back to QEMU's imitation when it does not. Its output is thrown away, warning included, because you have read it once."}, {"code": "address() {\n  { virsh domifaddr $name --source $1 2>/dev/null || true; } |\n    awk '/ipv4/ && $4 !~ /^127\\./ { sub(/\\/.*/, \"\", $4); print $4; exit }'\n}\nip=\nfor i in $(seq 120); do\n  ip=$(address lease); [ -n \"$ip\" ] || ip=$(address agent)\n  [ -n \"$ip\" ] && break\n  sleep 5\ndone\n[ -n \"$ip\" ] || { echo \"$name has no address after ten minutes\" >&2; exit 1; }\nsudo sed -i \"/ $name\\$/d\" /etc/hosts\necho \"$ip $name\" | sudo tee -a /etc/hosts >/dev/null", "note": "First the address libvirt handed out, its DHCP **lease**, and failing that the address the **guest agent** reports from inside. The second is how a guest is found on a network libvirt does not run, which lesson 11 builds. 120 tries five seconds apart is ten minutes. The name then goes into `/etc/hosts`, replacing any older line for the same name."}, {"code": "ssh-keygen -R $name >/dev/null 2>&1 || true\nready=no\nfor i in $(seq 60); do\n  if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \\\n       $name cloud-init status --wait >/dev/null 2>&1; then ready=yes; break; fi\n  sleep 5\ndone\n[ $ready = yes ] || { echo \"$name has an address but does not let you in\" >&2; exit 1; }", "note": "A guest made earlier under the same name left its key in `~/.ssh/known_hosts`, and ssh refuses a different key under a known name, so the old one is forgotten first. `accept-new` trusts a key it has never seen: fine for a guest you made a minute ago on your own computer, not a habit for anything else. `cloud-init status --wait` only returns once the guest has finished setting itself up."}, {"code": "virsh detach-disk $name vdb --persistent >/dev/null\nsudo rm -f $images/$name-seed.img /tmp/$name-user-data\necho \"$name is ready at $ip\"", "note": "The seed has done its work, so it is detached and deleted, and the guest is only its own disk from then on."}]}
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

Two minutes, nearly all of them the guest's first boot. The name vm1 was used again on purpose, which is
the case the `ssh-keygen -R` line exists for: without it, ssh would have refused the new vm1 for
presenting a different key from the old one.

**Every later lesson starts this way**, with `bash newvm.sh NAME` for each guest it needs, and says so.
Run `bash newvm.sh` with no name and it prints its usage line and stops.
