---
title: Os dados vão para o DVC
version: 1
---

O `dvc add` tira um arquivo das mãos do Git. Ele copia o arquivo para o cache do DVC, com o nome do
hash do conteúdo, grava ao lado dele um pequeno **arquivo ponteiro**, e põe o original no
`.gitignore`. O Git então versiona o ponteiro, e o ponteiro nomeia os dados com exatidão.

```
ana@dev:~/ml$ dvc add shop.db

To track the changes with git, run:

	git add .gitignore shop.db.dvc

To enable auto staging, run:

	dvc config core.autostage true
ana@dev:~/ml$ cat shop.db.dvc
outs:
- md5: 95a15782c27b9c79017e02ac78df66bf
  size: 5939200
  hash: md5
  path: shop.db
ana@dev:~/ml$ dvc remote add -d store ~/dvc-store
Setting 'store' as a default remote.
ana@dev:~/ml$ git add . && git commit -qm "the lapse pipeline, and the shop it reads" && git log --oneline
4bb4b2d the lapse pipeline, and the shop it reads
```

O `shop.db.dvc` é tudo o que o Git vê: um hash MD5 dos bytes do arquivo, o tamanho e o nome. **Mude
uma linha da loja e o hash muda**, então um commit com este ponteiro nomeia um banco exato. O seu
hash provavelmente vai ser diferente deste mesmo com as mesmas linhas, porque o layout do arquivo
SQLite depende da versão que o gravou; o que importa é que o seu hash nomeia o seu arquivo.

O cache fica em `.dvc/cache`, dentro do projeto, o que não protege nada se o disco morrer. Um
**remoto** é para onde o cache é copiado por segurança: aqui um diretório, `~/dvc-store`, e num time
um bucket num armazenamento de objetos ou um drive compartilhado, nomeado do mesmo jeito. O
`dvc push` copia o que falta no remoto.

**O primeiro commit é o código e o ponteiro, juntos.** Daqui em diante, qualquer commit nomeia uma
versão dos programas e uma versão da loja de uma vez, que é o par que o registro da lição 5 só
conseguia nomear pela metade.
