---
title: Criptografia envelope
version: 1
---

O transit é certo para um CPF: poucos bytes, enviados e devolvidos numa requisição. É errado para
um backup. Mandar 1,8 MB pelo serviço é lento, mandar 180 GB é absurdo, e o serviço veria cada
byte do dado que ele devia nunca ter.

A resposta que todo serviço de gestão de chaves usa é a **criptografia envelope**: o serviço gera
uma **chave de dados** nova para o trabalho e a devolve duas vezes — uma em claro, para cifrar o
dado localmente, e uma **embrulhada**, cifrada com uma chave que nunca sai do serviço. O dado é
cifrado com a chave de dados em claro, que depois é jogada fora; a cópia embrulhada é guardada ao
lado do dado. Para ler o dado, a chave embrulhada volta ao serviço, que a desembrulha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l4-envelope\" aria-label=\"Criptografia envelope de um backup. O serviço de chaves gera uma chave de dados e a devolve duas vezes: em claro, e embrulhada pela chave ipe-backup. A chave de dados em claro cifra o dump e é destruída. O dump cifrado e a chave embrulhada são guardados juntos. Para restaurar, a chave embrulhada volta ao serviço, que a desembrulha.\"><defs><marker id=\"dg-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"170.0\" height=\"200.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">serviço de chaves</text><rect x=\"45.0\" y=\"72.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ipe-backup</text><text x=\"105.0\" y=\"152.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">gera uma</text><text x=\"105.0\" y=\"167.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chave de dados</text><rect x=\"260.0\" y=\"40.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chave em claro</text><text x=\"345.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backup.key</text><rect x=\"260.0\" y=\"160.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chave embrulhada</text><text x=\"345.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backup.key.wrapped</text><path d=\"M190.0 80.0 L258.0 65.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M190.0 180.0 L258.0 185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"40.0\" width=\"200.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cifra o dump,</text><text x=\"600.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">depois destruída</text><path d=\"M430.0 65.0 L498.0 65.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><rect x=\"500.0\" y=\"140.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">guardados juntos</text><rect x=\"515.0\" y=\"170.0\" width=\"170.0\" height=\"26.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">customers.sql.enc</text><rect x=\"515.0\" y=\"200.0\" width=\"170.0\" height=\"24.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">backup.key.wrapped</text><path d=\"M430.0 185.0 L498.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M600.0 90.0 L600.0 138.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path></svg>", "caption": "O dado nunca vai ao serviço de chaves, e a chave que o embrulha nunca sai dele."}
```

Uma chave para backups, e uma chave de dados tirada dela:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-backup
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791343892]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-backup
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao write -f -format=json transit/datakey/plaintext/ipe-backup > datakey.json && python3 -c "import json; d = json.load(open('datakey.json'))['data']; print(sorted(d))"
['ciphertext', 'key_version', 'plaintext']
```

A resposta tem três campos: `plaintext`, a chave de dados em claro; `ciphertext`, a mesma chave
embrulhada por `ipe-backup`; e a versão de `ipe-backup` que a embrulhou.

## Um backup num envelope

```
ana@lab:~/gov$ python3 -c "import json; print(json.load(open('datakey.json'))['data']['ciphertext'])" > backup.key.wrapped
ana@lab:~/gov$ python3 -c "import json; print(json.load(open('datakey.json'))['data']['plaintext'])" > backup.key && rm datakey.json
ana@lab:~/gov$ sudo -u postgres pg_dump -d ipe -t sales.customers | openssl enc -aes-256-cbc -pbkdf2 -pass file:backup.key -out customers.sql.enc
ana@lab:~/gov$ shred -u backup.key && ls -l customers.sql.enc backup.key.wrapped
-rw-r--r-- 1 ana ana      90 Oct  7 00:31 backup.key.wrapped
-rw-r--r-- 1 ana ana 1847744 Oct  7 00:31 customers.sql.enc
ana@lab:~/gov$ grep -c paula.cavalcanti customers.sql.enc
0
```

A chave embrulhada vai para um arquivo; a chave em claro é usada uma vez, pelo `openssl`, para
cifrar o dump a caminho do disco, e depois o **`shred`** a sobrescreve e apaga. O que sobra são
1.847.744 bytes de texto cifrado e uma chave embrulhada de 90 bytes, e o `grep` não acha a Paula
em lugar nenhum do backup — onde o dump da aula 3 a tinha na primeira linha.

Os dois arquivos podem viajar juntos. A chave embrulhada não serve para nada sem o OpenBao, e o
OpenBao não serve para nada sem um token que possa decifrar com `ipe-backup` — uma política que o
operador de backup tem e quem guarda os backups não tem.

## E de volta

```
ana@lab:~/gov$ bao write -field=plaintext transit/decrypt/ipe-backup ciphertext=$(cat backup.key.wrapped) > backup.key
ana@lab:~/gov$ openssl enc -d -aes-256-cbc -pbkdf2 -pass file:backup.key -in customers.sql.enc | grep paula.cavalcanti | cut -f 1-4; shred -u backup.key
1	Paula Cavalcanti Silva	paula.cavalcanti@example.com	372.874.168-09
1097	Paula Cavalcanti Pereira	paula.cavalcanti2@example.com	037.846.602-00
5955	Paula Cavalcanti Cardoso	paula.cavalcanti2@example.org	859.266.865-44
```

A chave embrulhada vai ao OpenBao e volta como a chave de dados em claro, que decifra o backup e é
destruída de novo. As linhas voltam — três clientes chamadas Paula Cavalcanti, a primeira das quais
é a que toda aula até aqui mostrou.

**Toda restauração é uma decifração no log de auditoria do OpenBao**, com o token e a hora. "Quem
restaurou o backup de clientes no mês passado" vira uma pergunta com resposta, o que não era quando
a chave de um backup era uma senha num script.
