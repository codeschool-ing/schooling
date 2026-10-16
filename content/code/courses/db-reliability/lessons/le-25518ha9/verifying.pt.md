---
title: O manifesto, e o que conferi-lo prova
version: 1
---

Um backup fica semanas num disco antes de alguém precisar dele, e discos, redes e pessoas alteram
arquivos. O manifesto que o `pg_basebackup` escreveu é o meio de descobrir se este diretório ainda é
o que o servidor mandou. O programa que o lê não está no seu `PATH`: o Ubuntu instala as ferramentas
menos comuns do PostgreSQL no diretório da própria versão, então ele é digitado por extenso.

```
ana@vm:~$ /usr/lib/postgresql/16/bin/pg_verifybackup base
backup successfully verified
ana@vm:~$ echo "tampered" | sudo tee -a base/global/pg_control > /dev/null
ana@vm:~$ /usr/lib/postgresql/16/bin/pg_verifybackup base
pg_verifybackup: error: "global/pg_control" has size 8201 on disk but size 8192 in the manifest
```

A primeira execução leu o manifesto, depois cada arquivo, e comparou o tamanho e o checksum de cada
um com o que o servidor registrou ao enviá-lo. Em seguida uma linha de texto foi acrescentada ao
`pg_control`, o arquivinho que guarda o registro que o servidor faz do próprio estado, e **a
verificação falhou apontando o arquivo exato e a diferença exata**. Uma cópia danificada desse jeito
teria subido um servidor que acreditava em algo falso sobre si mesmo, ou que nem subiria.

A cópia danificada vai para o lixo e é tirada de novo:

```
ana@vm:~$ rm -rf base
ana@vm:~$ pg_basebackup -D base -X stream -c fast
ana@vm:~$ /usr/lib/postgresql/16/bin/pg_verifybackup base
backup successfully verified
```

## O que ele prova, e o que não prova

O `pg_verifybackup` responde a uma pergunta: **estes são os bytes que o servidor mandou?** Ele
também confere se o write-ahead log necessário para tornar a cópia consistente está presente e
legível. Isso faz dele a coisa certa para rodar em todo backup, de forma barata, como a segunda das
três verificações da lição 1.

Ele não responde se o banco lá dentro está são. Se o arquivo de uma tabela já estava danificado no
servidor, o backup é uma cópia fiel do estrago e passa na verificação sem problema nenhum. Ele
também não diz se a cópia sobe e responde a consultas. **Só uma restauração responde a isso**, então
um backup verificado continua sendo "uma afirmação até ser restaurado", como na lição 1, com uma
classe de falha descartada.

Há duas verificações do PostgreSQL que vale conhecer ao lado dele, ambas fora desta lição: os data
checksums, que fazem o próprio servidor detectar uma página danificada ao lê-la (estavam como
`disabled` na saída do `initdb` da lição 2, o padrão no Ubuntu, e a ferramenta da lição 5 os confere
quando estão ligados), e o `pg_amcheck`, que inspeciona tabelas e índices atrás de corrupção num
servidor em funcionamento.
