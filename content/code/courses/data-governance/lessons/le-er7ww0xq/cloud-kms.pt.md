---
title: Os mesmos trabalhos numa nuvem
version: 1
---

A maioria das empresas não roda o próprio serviço de chaves para os dados na nuvem; usa o do
provedor. Os conceitos desta aula passam um para um, e só os comandos mudam:

| esta aula | AWS KMS | Google Cloud KMS | Azure Key Vault |
|---|---|---|---|
| uma chave do transit | uma chave do KMS | uma chave num key ring | uma chave num vault |
| uma política num caminho | uma key policy e IAM | papéis do IAM na chave | access policies ou Azure RBAC |
| `transit/encrypt` | `Encrypt` | `encrypt` | `encrypt` |
| `transit/datakey` | `GenerateDataKey` | nenhum: cifre uma chave que você gerou | nenhum: embrulhe uma chave que você gerou |
| rotação, versões | rotação automática anual | agenda de rotação, versões de chave | política de rotação, versões de chave |
| o arquivo de auditoria | CloudTrail | Cloud Audit Logs | logs do Azure Monitor |

Os dois comandos abaixo são os equivalentes, na AWS e no Google, da chave de dados da seção 9 e da
cifração da seção 6. **Eles não foram executados**: nenhuma conta nessas nuvens é alcançável de onde
este curso foi gravado. Eles vêm da documentação de cada provedor e estão aqui para serem
reconhecidos, não copiados.

```sh
aws kms generate-data-key --key-id alias/ipe-backup --key-spec AES_256
gcloud kms encrypt --key ipe-cpf --keyring ipe --location southamerica-east1 \
  --plaintext-file cpf.txt --ciphertext-file cpf.enc
```

## Quem tem a chave, de novo

Um KMS de nuvem levanta uma pergunta que o OpenBao na sua VM não levanta: **o provedor opera o
hardware onde as chaves moram.** Três arranjos respondem de jeitos diferentes:

- **Chaves geradas e guardadas pelo provedor** — o padrão, e suficiente para a maioria dos dados: o
  pessoal do provedor não usa uma chave sem passar pelas mesmas políticas e auditoria que você.
- **Traga sua própria chave (BYOK)** — você gera o material da chave e o importa, então tem uma
  cópia fora do provedor e consegue provar de onde a chave veio.
- **Guarde sua própria chave (HYOK)**, ou um gerenciador de chaves externo — a chave fica num
  serviço que você controla e a nuvem pede a ele a cada uso; você corta o provedor recusando.

Quanto mais controle, mais do problema de disponibilidade da seção 3 vira seu. **Uma chave externa
inalcançável é um banco na nuvem que não pode ser lido**, por você tanto quanto por qualquer outro.
A escolha cabe a quem sabe dizer qual risco a empresa prefere carregar, e fica escrita onde a
próxima pessoa a encontre.
