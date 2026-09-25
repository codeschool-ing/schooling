---
title: O que uma atualização contém de fato
version: 1
---

"Instale as atualizações" esconde várias coisas diferentes: **correções de segurança**, **correções de
bugs**, **recursos novos**, **drivers** novos e **firmware** do próprio hardware. Num servidor Linux, o
primeiro tipo pode ser lido, linha por linha, no changelog de cada pacote:

```
ana@server:~$ apt-cache policy openssl | head -3
openssl:
  Installed: 3.0.13-0ubuntu3.15
  Candidate: 3.0.13-0ubuntu3.15
ana@server:~$ zcat /usr/share/doc/openssl/changelog.Debian.gz | head -12
openssl (3.0.13-0ubuntu3.15) noble-security; urgency=medium

  * SECURITY UPDATE: Excessive Memory Use Buffering DTLS Records for a Future
    Epoch
    - debian/patches/CVE-2026-54874-1.patch: Avoid full read buffer allocation
      when buffering DTLS records in ssl/record/rec_layer_d1.c,
      ssl/record/record.h, ssl/record/ssl3_record.c.
    - debian/patches/CVE-2026-54874-2.patch: ssl/record: lower the DTLS
      unprocessed_rcds queue limit in ssl/record/rec_layer_d1.c,
      ssl/record/record_local.h, ssl/record/ssl3_record.c.
    - CVE-2026-54874
  * SECURITY UPDATE: Heap Buffer Overflow in CMS Key Unwrapping
ana@server:~$ zcat /usr/share/doc/openssl/changelog.Debian.gz | grep -c 'SECURITY UPDATE'
58
```

- O **`apt-cache policy`** mostra a versão instalada, `3.0.13-0ubuntu3.15`, e a candidata, a mesma: nada
  está esperando.
- O **changelog** diz o que essa versão mudou. A entrada do topo, do `noble-security`, lista **SECURITY
  UPDATE** atrás de SECURITY UPDATE, cada uma com um número **CVE**: *Common Vulnerabilities and
  Exposures*, o identificador público de uma falha publicada.
- **58** entradas assim no changelog do openssl, que volta anos atrás, para uma biblioteca. O número da
  versão desta quase não mexeu: o `3.0.13` ficou, e só a parte do
  Ubuntu depois dele subiu. É a versão fixa da aula 6: **correções, não versões novas**.

Um CVE ser público é o que faz a pressa importar. A correção e a descrição da falha saem juntas, e
qualquer um pode ler como a falha funciona. **Uma máquina sem a correção não está em risco em teoria;
está numa lista publicada.**
