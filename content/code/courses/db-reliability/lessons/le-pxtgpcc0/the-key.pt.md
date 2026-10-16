---
title: A chave, e o backup que ninguém consegue abrir
version: 1
---

Um backup criptografado é exatamente tão recuperável quanto a sua senha. A lição 1 listou
"criptografado com uma chave que ninguém guardou" entre os jeitos de um backup falhar em silêncio, e é
assim que acontece: a senha está no arquivo de configuração do servidor do banco, o servidor do banco
é justamente o que se perdeu, e ninguém anotou a senha em nenhum outro lugar.

Aqui está o segundo repositório visto por uma configuração cuja senha está errada por um caractere, o
que é o mesmo que vê-lo de um servidor novo cuja configuração foi refeita de memória:

```
ana@vm:~$ sudo sed 's/^repo2-cipher-pass=./repo2-cipher-pass=X/' /etc/pgbackrest.conf | sudo tee /tmp/wrong.conf > /dev/null
ana@vm:~$ sudo chown postgres /tmp/wrong.conf
ana@vm:~$ sudo -u postgres pgbackrest --config=/tmp/wrong.conf --stanza=main --repo=2 info | grep -v 'outside of section'
stanza: main
    status: error (other)
            [FormatError] unable to load info file '/srv/offsite/pgbackrest/backup/main/backup.info' or '/srv/offsite/pgbackrest/backup/main/backup.info.copy':
            HINT: backup.info cannot be opened and is required to perform a backup.
            HINT: has a stanza-create been performed?
    cipher: aes-256-cbc
ana@vm:~$ sudo rm /tmp/wrong.conf
```

O pgBackRest não consegue nem ler a lista de backups. **Cada byte está lá e nenhum deles serve para
nada**, e nenhuma ferramenta, contrato de suporte ou quantidade de esforço muda isso: AES com uma
senha longa e aleatória não se quebra na tentativa.

Então a senha faz parte do backup, e é guardada do jeito que se guardam os segredos mais importantes:

- **em algum lugar que sobreviva à perda do servidor do banco**, e também à do armazenamento dos
  backups: um gerenciador de senhas ou cofre em que a organização já confia, com acesso para mais de
  uma pessoa;
- **junto com o procedimento que a usa**, para que quem for restaurar saiba onde encontrá-la (lição
  24);
- **testada**, pelo ensaio: um ensaio que restaura a partir do repositório criptografado numa máquina
  configurada com a senha anotada, e não com uma cópia da configuração antiga, é a única prova de que
  a senha que foi anotada é a certa.

Trocar a senha de um repositório existente não é possível no lugar; uma senha nova significa um
repositório novo, com backups feitos nele do zero, e o antigo mantido até os backups dele vencerem.
Mais um motivo para gerá-la direito da primeira vez.
