---
title: Assinaturas digitais, que qualquer um pode conferir
version: 1
---

Uma **assinatura digital** é feita com uma chave privada e conferida com a chave pública
correspondente. Só quem tem a chave privada consegue fazer uma; qualquer um com a chave pública
consegue conferi-la. Isso resolve as duas limitações vistas até aqui: ao contrário de um digest
sozinho, ela não pode ser recalculada por um atacante, e ao contrário de um HMAC, quem confere não
consegue forjá-la.

Quem publica o agente assina cada versão no `admin`, com um par de chaves **Ed25519** criado uma vez:

```
ana@admin:~$ openssl genpkey -algorithm ed25519 -out release.key; openssl pkey -in release.key -pubout -out release.pub; cat release.pub
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEATZYYS8vjlrhJ22IsXQ/grXnj1Llczs89wImxSNp4Bjk=
-----END PUBLIC KEY-----
```

A chave pública é o que se publica, uma vez, em algum lugar em que os usuários já confiam: a
documentação da empresa, o wiki interno, a configuração que instala o agente. Então a versão é
assinada, no `admin`, depois que uma cópia do agente é posta na sua pasta pessoal lá com
`sudo cp /lab/www/var/www/downloads/agent-2.4.1.tar.gz /lab/admin/home/$USER/` e
`sudo chown $USER: /lab/admin/home/$USER/agent-2.4.1.tar.gz` no seu próprio computador:

```
ana@admin:~$ openssl pkeyutl -sign -rawin -inkey release.key -in agent-2.4.1.tar.gz -out agent-2.4.1.tar.gz.sig; wc -c agent-2.4.1.tar.gz.sig
64 agent-2.4.1.tar.gz.sig
```

A assinatura tem 64 bytes, qualquer que seja o tamanho do arquivo. O `laptop` recebe a chave
pública, a assinatura e uma cópia intacta do arquivo, já que o que ele baixou foi alterado na seção
anterior:

```sh
sudo cp /lab/admin/home/$USER/release.pub /lab/admin/home/$USER/agent-2.4.1.tar.gz.sig /lab/admin/home/$USER/agent-2.4.1.tar.gz /lab/laptop/home/$USER/
sudo chown $USER: /lab/laptop/home/$USER/*
```

e confere o arquivo contra elas:

```
ana@laptop:~$ openssl pkeyutl -verify -rawin -pubin -inkey release.pub -in agent-2.4.1.tar.gz -sigfile agent-2.4.1.tar.gz.sig
Signature Verified Successfully
ana@laptop:~$ printf "x" >> agent-2.4.1.tar.gz; openssl pkeyutl -verify -rawin -pubin -inkey release.pub -in agent-2.4.1.tar.gz -sigfile agent-2.4.1.tar.gz.sig; echo "exit $?"
Signature Verification Failure
exit 1
```

`Signature Verified Successfully` para o arquivo como foi assinado, e `Signature Verification Failure`
depois que um byte foi acrescentado. **Agora a conferência vale alguma coisa contra uma pessoa**:
trocar o arquivo no servidor já não basta, porque a troca precisaria de uma assinatura feita com uma
chave que nunca saiu do `admin`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Três verificações de integridade comparadas. Um hash não usa chave: qualquer um o calcula, então só pega acidentes. Um HMAC usa um segredo compartilhado: os dois donos o calculam e conferem, então prova que a mensagem veio de um deles. Uma assinatura usa um par de chaves: só quem tem a chave privada a produz e qualquer um com a chave pública a confere, então prova quem assinou.\"><defs><marker id=\"hs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">sha256sum</text><text x=\"34\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem chave</text><text x=\"34\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qualquer um produz</text><text x=\"34\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pega acidentes</text><path d=\"M34 132 L206 132\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"260\" y=\"20\" width=\"200\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">HMAC</text><text x=\"274\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um segredo compartilhado</text><text x=\"274\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os dois donos produzem</text><text x=\"274\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">prova: um dos dois</text><path d=\"M274 132 L446 132\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"500\" y=\"20\" width=\"200\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Ed25519</text><text x=\"514\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um par de chaves</text><text x=\"514\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só o dono da chave privada</text><text x=\"514\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">prova: quem assinou</text><path d=\"M514 132 L686 132\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path></svg>", "caption": "Quem consegue produzir o valor decide o que conferi-lo prova."}
```

Assinar não é cifrar. O arquivo continuou legível para todo mundo; a assinatura só diz quem responde
por ele e que ele não mudou. Na prática, uma assinatura é feita sobre o digest do arquivo e não sobre
o arquivo, e é por isso que as duas metades desta aula andam juntas.

**Tudo depende de a chave pública ser a certa.** Um usuário que buscou o `release.pub` no mesmo
servidor comprometido que o arquivo conferiria uma versão forjada contra uma chave forjada, e veria
`Signature Verified Successfully`. Como saber de quem é a chave pública que você tem, na escala da internet inteira, é a
aula 12.
