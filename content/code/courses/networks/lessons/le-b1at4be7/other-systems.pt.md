---
title: Certificados no Windows e no macOS
version: 1
---

As ideias são as mesmas em todo lugar; os repositórios e as ferramentas, não:

```sh
certlm.msc                                   # Windows: the computer's certificate stores
certmgr.msc                                  # Windows: the signed-in user's stores
certutil -addstore Root office-ca.crt        # Windows, as administrator: trust a root for the whole PC
Get-ChildItem Cert:\LocalMachine\Root       # Windows PowerShell: the trusted roots
security find-certificate -a -c "Example" /Library/Keychains/System.keychain   # macOS
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain office-ca.crt   # macOS
```

**Nenhum deles foi rodado para esta aula.** No Windows, o `certlm.msc` abre os repositórios do
computador e o `certmgr.msc` os do usuário atual; uma raiz confiável para o PC inteiro vai em
*Autoridades de Certificação Raiz Confiáveis* do computador, que é o que o `certutil -addstore Root`
faz. Num escritório com domínio Windows, raízes como a CA do escritório são empurradas para cada PC pela
Política de Grupo em vez de instaladas à mão.

No Mac, o *Acesso às Chaves* mostra o mesmo, e o comando `security` acrescenta uma raiz ao keychain do
sistema. Em qualquer navegador, o cadeado (ou o ícone ao lado do endereço) abre o certificado que o
site mandou: os nomes, as datas e a cadeia, as três coisas de que tratam as falhas da seção 06.
