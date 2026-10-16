---
title: Quando falha
version: 1
---

Cada ferramenta desta aula falha fechada: sem a chave certa ou a identidade certa, nada é decifrado
e nada é entregue. Essa é a propriedade que vale ter, e quer dizer que as falhas parecem recusas.
Mais duas, além do selo copiado, da checagem estrita e do Vault selado já vistos.

**Um colega sem a chave.** Alguém clona o `fleet` e tenta ler o token da produção. A máquina dele
não tem chave age no lugar em que o SOPS procura:

```
ana@laptop:~/fleet$ HOME=/tmp sops --decrypt apps/bulletin/production/token.sops.yaml
Failed to get the data key required to decrypt the SOPS file.

Group 0: FAILED
  age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx: FAILED
    - | failed to load age identities. Did not find keys in
      | locations 'SOPS_AGE_SSH_PRIVATE_KEY_FILE',
      | 'SOPS_AGE_SSH_PRIVATE_KEY_CMD', '/tmp/.ssh/id_ed25519',
      | '/tmp/.ssh/id_rsa', 'SOPS_AGE_KEY', 'SOPS_AGE_KEY_FILE',
      | 'SOPS_AGE_KEY_CMD', and '/tmp/.config/sops/age/keys.txt'.

Recovery failed because no master key was able to decrypt the file. In
order for SOPS to recover the file, at least one key has to be successful,
but none were.
```

O SOPS lista todo lugar em que procurou uma chave age, não acha nenhuma, e recusa. **Não há resposta
parcial**: sem uma chave que abra a chave de dados, o arquivo é texto cifrado.

**Um pod do namespace errado.** Um token de ServiceAccount do staging, apresentado ao role feito
para a produção:

```
ana@laptop:~$ vault write auth/kubernetes/login role=bulletin-production jwt=$(kubectl -n staging create token default)
Error writing data to auth/kubernetes/login: Error making API request.

URL: PUT http://127.0.0.1:8200/v1/auth/kubernetes/login
Code: 403. Errors:

* service account name not authorized
```

`service account name not authorized`: o token é genuíno, e o API server confirmou, mas o role
nomeia o `bulletin` em `production`, e este é o `default` em `staging`.

| o que aparece | onde | o que significa |
|---|---|---|
| `ErrUnsealFailed` | os eventos do SealedSecret | um selo usado com um nome ou namespace para o qual não foi feito |
| `additional properties 'sops' not allowed` | `validate.sh` | o bloco `sops` chegou a uma checagem estrita de esquema |
| `Failed to get the data key` | `sops --decrypt` | nenhuma chave nesta máquina abre o arquivo |
| `Vault is sealed`, código 503 | qualquer comando do Vault | o Vault reiniciou e ninguém o destrancou |
| `service account name not authorized` | um login no Vault | a ServiceAccount ou o namespace não é o que o role nomeia |

**Uma chave que falta não é um defeito a contornar.** Cada uma destas é o sistema fazendo o trabalho
dele, e a resposta nunca é afrouxá-lo até o erro sumir: um selo feito para o cluster inteiro, um
role ligado a todo namespace, um CI que recebe a chave age "só para validar". Cada afrouxamento é um
novo grupo de pessoas ou programas que leem o segredo, e nenhum aparece num diff como segredo.
