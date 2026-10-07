---
title: Secrets in a repository
version: 2
---

A playbook directory lives in Git, and lesson 14 runs it from a pipeline. **Passwords and tokens
cannot be in it as text**, and they have to be somewhere the playbook can read. Ansible's answer is
**Vault**: a value or a whole file encrypted with a vault password, decrypted in memory when the
playbook runs.

The vault password is a random string in a file only `ana` can read, made once:

```
ana@ctl:~$ head -c 24 /dev/urandom | base64 > ~/.vault-pass; chmod 600 ~/.vault-pass
```

The service desk's token from lesson 7, encrypted as a variable:

```
ana@ctl:~$ cd net && printf %s "$(cat ~/.desk-token)" | ansible-vault encrypt_string --vault-password-file ~/.vault-pass --stdin-name desk_token > group_vars/all.yaml && cat group_vars/all.yaml
desk_token: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66346237633162386465343739653731323563393738373464616632363465636239366539663962
          3265356464646535666633643332656534666263333161300a613230616438323330653931656165
          35306166656536376236386236333535316531313838653835623332373133663830366261613963
          3532343066393662620a656539656436343764656630373230323565383066613339666533646537
          37663562663862366437656330633233653431316363643739393333656138333130303762393639
          3437666533313738616538323462343731383162633063326262
```

The token came from the file it lives in and went straight into the encrypted variable; it never
appeared on the command line or on the screen. What is written to `group_vars/all.yaml` is safe to
commit: without the vault password it is noise, and the vault password itself stays in
`~/.vault-pass`, readable by `ana` alone, or in the pipeline's secret store.

A playbook that uses it opens a change ticket for the BGP work:

```schooling-example
{
  "language": "yaml",
  "file": "ticket.yaml",
  "parts": [
    {
      "code": "- name: Tell the service desk\n  hosts: localhost\n  gather_facts: false\n  tasks:"
    },
    {
      "code": "    - name: Open a change ticket\n      ansible.builtin.uri:\n        url: https://tickets.example.net/api/tickets\n        method: POST\n        ca_path: /home/ana/lab-ca.pem\n        headers:\n          Authorization: \"Token {{ desk_token }}\"\n        body_format: json\n        body:\n          title: iBGP configured on core1, edge1 and edge2\n          priority: low\n          requester: ansible\n        status_code: 201",
      "note": "**`desk_token` comes from a vault-encrypted file.** Ansible decrypts it in memory when the playbook runs with the vault password, and the file in the repository stays unreadable."
    },
    {
      "code": "      no_log: true\n      register: ticket\n\n    - name: Say which\n      ansible.builtin.debug:\n        msg: \"{{ ticket.json.number }} opened\"",
      "note": "**`no_log` keeps the task's arguments and result out of the output.** Without it, a failed request prints its headers, token included, into the terminal and into any CI log that captures it."
    }
  ]
}
```

Run without the vault password, it fails:

```
ana@ctl:~$ cd net && ansible-playbook ticket.yaml 2>&1 | grep -E "ERROR|fatal"
fatal: [localhost]: FAILED! => {"censored": "the output has been hidden due to the fact that 'no_log: true' was specified for this result"}
```

**And the reason is hidden**, which is `no_log` doing its job in the inconvenient direction: it hides
everything about the task, including why it failed. Asking for the variable outside that task shows
what went wrong:

```
ana@ctl:~$ cd net && ansible localhost -m ansible.builtin.debug -a var=desk_token 2>&1 | cat
localhost | FAILED! => {
    "msg": "Attempting to decrypt but no vault secrets found"
}
```

An encrypted value and no vault password to open it. With the password:

```
ana@ctl:~$ cd net && ansible-playbook ticket.yaml --vault-password-file ~/.vault-pass

PLAY [Tell the service desk] ***************************************************

TASK [Open a change ticket] ****************************************************
ok: [localhost]

TASK [Say which] ***************************************************************
ok: [localhost] => {
    "msg": "INC-1001 opened"
}

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

`INC-1001` was opened. Look at the task's status, though: **`ok`, not `changed`**, although it
created a ticket. `uri` has no way to know that a POST changed something on the other side, so it
reports what it knows. A task like this should say so itself, with `changed_when: true` or a
condition on the status code, or the recap lies and the nightly report of lesson 14 says nothing
happened.
