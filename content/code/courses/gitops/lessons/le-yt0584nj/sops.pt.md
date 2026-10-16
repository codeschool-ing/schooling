---
title: SOPS e age
version: 1
---

**O SOPS cifra os valores de um arquivo YAML e deixa as chaves legíveis.** Um pull request que troca
um token mostra então que `token` mudou, em qual arquivo, e nada sobre o valor. Quem pode decifrar é
decidido pelas chaves para as quais o arquivo é cifrado: um serviço de gestão de chaves da nuvem,
uma chave PGP ou uma chave **age**, a mais simples delas, uma ferramenta pequena e moderna feita
exatamente para isso.

Os dois são binários únicos das páginas de release; o `sops` tem um arquivo de checksums e o `age` é
um tarball:

```
ana@laptop:~/setup$ curl -fsSLO https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.linux.$ARCH
ana@laptop:~/setup$ curl -fsSL https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.checksums.txt | grep " sops-v3.13.3.linux.$ARCH$" | sha256sum --check
sops-v3.13.3.linux.amd64: OK
ana@laptop:~/setup$ sudo install -m 0755 sops-v3.13.3.linux.$ARCH /usr/local/bin/sops && rm sops-v3.13.3.linux.$ARCH
ana@laptop:~/setup$ curl -fsSLO https://github.com/FiloSottile/age/releases/download/v1.3.2/age-v1.3.2-linux-$ARCH.tar.gz
ana@laptop:~/setup$ tar -xzf age-v1.3.2-linux-$ARCH.tar.gz && sudo install -m 0755 age/age age/age-keygen /usr/local/bin/ && rm -r age age-v1.3.2-linux-$ARCH.tar.gz
ana@laptop:~/setup$ sops --disable-version-check --version; age --version
sops 3.13.3
v1.3.2
```

Uma chave age é uma linha de chave privada, guardada no arquivo em que o SOPS procura por padrão, e
uma chave pública derivada dela que começa com `age1`:

```
ana@laptop:~$ mkdir -p ~/.config/sops/age && age-keygen -o ~/.config/sops/age/keys.txt
Public key: age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx
ana@laptop:~$ stat -c '%A %n' ~/.config/sops/age/keys.txt
-rw------- /home/ana/.config/sops/age/keys.txt
ana@laptop:~$ AGE=$(age-keygen -y ~/.config/sops/age/keys.txt); echo $AGE
age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx
```

O arquivo da chave privada só pode ser lido por você, do jeito que o `age-keygen` o criou. O `$AGE`
guarda a chave pública para o próximo arquivo.

O SOPS lê as regras do `.sops.yaml` na raiz do repositório: quais arquivos, quais partes deles e
quais chaves. Este cifra o `data` e o `stringData` de qualquer arquivo dentro de um diretório
`production` cujo nome termine em `.sops.yaml`, para uma chave age. A sua chave pública vai no lugar
de `AGE_PUBLIC_KEY`. Salve isto como `.sops.yaml`:

```yaml
creation_rules:
- path_regex: apps/.*/production/.*\.sops\.yaml$
  encrypted_regex: ^(data|stringData)$
  age: AGE_PUBLIC_KEY
```

```
ana@laptop:~/fleet$ git switch --quiet -c production-token
ana@laptop:~/fleet$ cat .sops.yaml
creation_rules:
- path_regex: apps/.*/production/.*\.sops\.yaml$
  encrypted_regex: ^(data|stringData)$
  age: age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx
ana@laptop:~/fleet$ TOKEN=$(openssl rand -hex 16)
ana@laptop:~/fleet$ kubectl -n production create secret generic bulletin-token --from-literal=token=$TOKEN --dry-run=client -o yaml > apps/bulletin/production/token.sops.yaml
ana@laptop:~/fleet$ sops --encrypt --in-place apps/bulletin/production/token.sops.yaml
ana@laptop:~/fleet$ cat apps/bulletin/production/token.sops.yaml
apiVersion: v1
data:
    token: ENC[AES256_GCM,data:q+RtdAW+bDo1BHHmFz/Ur1wzy9n2jULlz1YHM9R1sp2EepISC5KDfStrkys=,iv:yq2Adsl4qnyLSsFBLXN631rzBFPX63n8QFJi0OBSh94=,tag:jdkgtgoGzgQ5Zzyml4VCfg==,type:str]
kind: Secret
metadata:
    name: bulletin-token
    namespace: production
sops:
    age:
        - enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBtbDBHOG5qdjcwT1p3Q1ZH
            TzEzUS8zT3dtUFFHZzE1YUxObUdlWVE0WndBCnlxNDJwdVdZOGxDV1liVysyalli
            VHcxTU4yV2ZjcnFVM0FZdXYzNFpkV0UKLS0tIFZQUmZYblFHUEdGTlljQWNGeVpv
            UmQvRzlTcTBWUDByQzRXTWt1RCtSb00Kcy77a2V3QY1Xx1t9EWt4w1A5C11Pvn5U
            442sbXgBGS6lHFYCpxhjyF4S0fMnsWkNA/UqFzcRHt5Fj1XhxlAWUQ==
            -----END AGE ENCRYPTED FILE-----
          recipient: age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx
    encrypted_regex: ^(data|stringData)$
    lastmodified: "2026-10-16T00:47:16Z"
    mac: ENC[AES256_GCM,data:0OtBmdHS11AhKDruf+WItP53xkBVbgw9N7xPujAye2GNlXBubwEk8/YxeElZ7d1PaGqJVqEe1b225FIHZIR7gc6vxVnEEFPTewEU0TrUjZPFd8o0rhV37t/DSl6oA5Xbg/dgZgmfzmgSBdWofh6NQ1ixlany+uaRlyki6jhNNZY=,iv:ESOB0OAcaowZkey1/f/YhUPMlTu6cCVymho4LE3GD1M=,tag:x6rAVVJsvxQMsaiXSuhJ9w==,type:str]
    version: 3.13.3
```

O valor de `token` agora é `ENC[...]`, e todo o resto se lê como antes: o tipo, o nome, o namespace.
O bloco `sops` no fim é do próprio SOPS: a chave de dados, cifrada para a chave age, e um MAC sobre
o arquivo inteiro, para que uma edição feita sem o SOPS seja detectada em vez de decifrada.

Quem tem a chave privada lê o valor de volta, e é assim que alguém de plantão confere o que a
produção tem sem ir ao cluster:

```
ana@laptop:~/fleet$ sops --decrypt --extract '["data"]["token"]' apps/bulletin/production/token.sops.yaml | base64 -d | sha256sum | cut -c1-12
252c569e030c
```

Essa é a impressão digital que o `bulletin` vai mostrar para este token, calculada só a partir do
arquivo.

## A checagem encontra um arquivo cifrado

O kustomization da produção lista o `token.sops.yaml` entre os recursos, e o branch vai para
revisão. A checagem roda primeiro:

```
ana@laptop:~/fleet$ git add .sops.yaml apps && git commit --quiet -m "production: a token encrypted with SOPS"
ana@laptop:~/fleet$ git push --quiet -u origin production-token 2>/dev/null
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 2 resources found in 1 file - Valid: 2, Invalid: 0, Errors: 0, Skipped: 0
Summary: 4 resources found in 1 file - Valid: 2, Invalid: 0, Errors: 0, Skipped: 2
/tmp/tmp.I2wSNQEKy3/out.yaml - Secret bulletin-token is invalid: problem validating schema. Check JSON formatting: jsonschema validation failed with 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.37.0-standalone-strict/secret-v1.json#' - at '': additional properties 'sops' not allowed
Summary: 5 resources found in 1 file - Valid: 4, Invalid: 1, Errors: 0, Skipped: 0
Summary: 5 resources found in 1 file - Valid: 4, Invalid: 0, Errors: 0, Skipped: 1
validate: failure
```

Staging e produção montaram e foram validados, e o Secret da produção foi recusado pelo esquema
estrito: `additional properties 'sops' not allowed`. A checagem postou `failure`, e o pull request
não pode entrar.

O `kubeconform -strict` recusa qualquer campo que um objeto do Kubernetes não tem, e o SOPS
acrescentou um: `sops`, com a chave de dados cifrada e um checksum do arquivo. O Flux o remove
quando decifra, então o que chega ao cluster é um Secret comum. A checagem deve validar a mesma
coisa, então o `validate.sh` descarta o bloco `sops` antes de validar. No `~/setup/validate.sh`, a
linha do `elif` vira estas duas:

```sh
  elif ! awk '/^sops:/ { s = 1; next } /^[^ ]/ { s = 0 } !s' "$work/out.yaml" |
       kubeconform -strict -summary -skip HelmRelease,OCIRepository,SealedSecret -kubernetes-version 1.37.0; then
```

O `awk` pula de uma linha `sops:` até a próxima linha que começa na margem, a próxima chave ou o
próximo `---`, e o `kubeconform` lê o que sobra da entrada. Nada é decifrado: **a checagem nunca tem
a chave**, e esse é o ponto.

## O Flux decifra

O cluster precisa da chave privada para decifrar, e ela é o único segredo que não pode vir do Git: é
ela que abre todo o resto. Ela entra à mão, uma vez, como um Secret em `flux-system`, e o
`clusters/lab/production.yaml` ganha as linhas que dizem ao Flux para usá-la, dentro de `spec`:

```yaml
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

```
ana@laptop:~/fleet$ kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=$HOME/.config/sops/age/keys.txt
secret/sops-age created
ana@laptop:~/fleet$ git diff | grep '^[-+] '
+  decryption:
+    provider: sops
+    secretRef:
+      name: sops-age
ana@laptop:~/fleet$ git commit --quiet -am "production: Flux decrypts with sops-age"
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.1
message: Welcome to the bulletin.
pod: bulletin-bdddf5d46-7rgfw
token: sha256:252c569e030c
ana@laptop:~/fleet$ kubectl -n production get secret bulletin-token -o jsonpath="{.data.token}" | base64 -d | sha256sum | cut -c1-12
252c569e030c
```

Os pods da produção tinham subido antes de o Secret existir, com o volume marcado como opcional e
vazio; o kubelet preencheu o arquivo numa sincronização posterior do volume, sem reiniciar nada, e a
página mostra a impressão digital que o `sops --decrypt` calculou a partir do arquivo.

O Flux monta o overlay, decifra todo valor que o SOPS cifrou e aplica o resultado. O texto em claro
existe no Secret do cluster e na memória do controlador, e em lugar nenhum do Git.
