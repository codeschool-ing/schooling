---
title: Um par de chaves seu
version: 1
---

**O `cosign` é a ferramenta com que esta aula assina e verifica.** Ele é do Sigstore, um projeto
aberto da Linux Foundation, e guarda a assinatura no registry ao lado da imagem que assina, então
nada novo precisa rodar para guardá-las. Ele se instala como toda ferramenta deste curso, o binário
e o arquivo de checksums da página de release:

```
ana@laptop:~/setup$ ARCH=$(dpkg --print-architecture)
ana@laptop:~/setup$ curl -fsSLO https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign-linux-$ARCH
ana@laptop:~/setup$ curl -fsSL https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign_checksums.txt | grep " cosign-linux-$ARCH$" | sha256sum --check
cosign-linux-amd64: OK
ana@laptop:~/setup$ sudo install -m 0755 cosign-linux-$ARCH /usr/local/bin/cosign && rm cosign-linux-$ARCH
ana@laptop:~/setup$ cosign version | grep GitVersion
GitVersion:    v3.1.3
```

Um par de chaves são dois arquivos. A chave privada assina e é cifrada com uma senha; a chave pública
verifica e pode ser publicada em qualquer lugar. A senha é um segredo como os tokens do Gitea da aula
2, então vai num arquivo que só você lê, e o `cosign` a lê da variável `COSIGN_PASSWORD` em vez de
perguntar:

```
ana@laptop:~/signing$ openssl rand -base64 24 > ~/cosign.password && chmod 600 ~/cosign.password
ana@laptop:~/signing$ export COSIGN_PASSWORD=$(cat ~/cosign.password)
ana@laptop:~/signing$ cosign generate-key-pair
Private key written to cosign.key
Public key written to cosign.pub
ana@laptop:~/signing$ stat -c '%A %n' cosign.key cosign.pub
-rw------- cosign.key
-rw-r--r-- cosign.pub
ana@laptop:~/signing$ cat cosign.pub
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEYXwkkNjIbexO6LJqHvdwoQMjliUC
LXaA1zXL8TKAHvpvgVMUlXou3Uz277HIUfzoZaz3FasGS2+L2KUSZnJuLA==
-----END PUBLIC KEY-----
```

O `cosign.key` só pode ser lido pelo dono, e foi o próprio `cosign` que cuidou disso. **É o arquivo
sobre o qual repousa toda a garantia desta aula**: quem tiver ele e a senha assina qualquer coisa em
seu nome, e todo verificador aceita. Num time, ele não mora num laptop. Mora no cofre de segredos do
sistema de CI ou, melhor, num serviço de gestão de chaves que assina sob pedido e nunca deixa a chave
sair; o `cosign` usa um desses no lugar do arquivo com `--key` apontando para um endereço como
`awskms://`, `gcpkms://`, `azurekms://` ou `hashivault://`. A aula 9 trata de onde segredos como
este moram.

O `cosign.pub` é o contrário: não serve para nada a um atacante e precisa estar em todo lugar onde
uma verificação acontece. Ele entra no repositório fleet mais adiante nesta aula.
