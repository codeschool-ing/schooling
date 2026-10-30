---
title: A identidade da própria máquina
version: 1
---

Um programa no servidor web da loja precisa ler um bucket e escrever no Pub/Sub. **O jeito errado é
um arquivo de chave: um JSON com a chave privada de uma conta de serviço, copiado para a máquina.**
Funciona, nunca expira, e uma cópia dele funciona de qualquer lugar do mundo enquanto ninguém
perceber que foi levada. O Compute Engine oferece algo melhor, e ele já está rodando.

## Uma conta de serviço presa à máquina

Toda instância pode levar uma **conta de serviço**, dada no bloco `service_account`. O servidor de
metadados então entrega a qualquer processo da máquina um token de acesso daquela conta em
`instance/service-accounts/default/token`. O token dura pouco, cerca de uma hora, e o servidor de
metadados o troca antes de expirar. As bibliotecas cliente do Google e o gcloud o pedem sozinhos; o
seu código nunca vê uma chave.

O `meta/main.tf` da seção 02 já cria uma conta dedicada, `shop-web`, e a prende à máquina:

```
ana@laptop:~/gcp/meta$ terraform plan -no-color | grep -E '# google|email|member|auth/'
  # google_compute_instance.web will be created
          + email  = "shop-web@planner-dev.iam.gserviceaccount.com"
              + "https://www.googleapis.com/auth/cloud-platform",
  # google_service_account.web will be created
      + email           = "shop-web@planner-dev.iam.gserviceaccount.com"
      + member          = "serviceAccount:shop-web@planner-dev.iam.gserviceaccount.com"
```

**O e-mail é conhecido na hora do plan**, porque é montado com o id da conta e o projeto:
`shop-web@planner-dev.iam.gserviceaccount.com`. A linha `member` é a mesma identidade escrita do
jeito que as associações do IAM a nomeiam, assunto do `gcp-foundations` e que a lição 15 usa de novo.

Por que não a padrão? Um projeto novo tem uma **conta de serviço padrão do Compute Engine**, chamada
`PROJECT_NUMBER-compute@developer.gserviceaccount.com`, e uma instância criada sem bloco
`service_account` a recebe. Em projetos mais antigos essa conta ganhou o papel Editor no projeto
inteiro, o que quer dizer que toda máquina podia mudar quase tudo. Organizações criadas desde 2024
bloqueiam essa concessão por política, mas muitos projetos são anteriores a isso. **Uma conta
dedicada por tipo de máquina, só com os papéis de que aquela máquina precisa**, é a regra que
sobrevive a um incidente: um token roubado da `web-1` lê o que um servidor web lê, e nada mais.

## Como uma biblioteca encontra as credenciais

As bibliotecas do Google seguem uma ordem de busca só, chamada **Application Default Credentials**,
e ela é a mesma num laptop e numa máquina. Este programa pede as credenciais e imprime o que
encontrou. Salve como `meta/adc.py`:

```python
# meta/adc.py
import google.auth
from google.auth.exceptions import DefaultCredentialsError

try:
    credentials, project = google.auth.default()
    print('found', type(credentials).__name__, 'for project', project)
except DefaultCredentialsError as e:
    print('no credentials:', e)
```

O `google-auth` veio junto com o cliente de Pub/Sub no ambiente virtual da lição 1. Rode duas
vezes, a segunda apontando para um arquivo de chave que não existe:

```
ana@laptop:~/gcp/meta$ time python3 adc.py
no credentials: Your default credentials were not found. To set up Application Default Credentials, see https://cloud.google.com/docs/authentication/external/set-up-adc for more information.

real	0m3.044s
user	0m0.171s
sys	0m0.008s
ana@laptop:~/gcp/meta$ GOOGLE_APPLICATION_CREDENTIALS=~/gcp/meta/key.json python3 adc.py
no credentials: File /home/ana/gcp/meta/key.json was not found.
```

A ordem aparece no que cada execução diz. **Primeiro**, a variável
`GOOGLE_APPLICATION_CREDENTIALS`: quando ela existe, a biblioteca lê aquele arquivo e mais nada, e é
por isso que a segunda execução falhou no arquivo em vez de continuar procurando. **Segundo**, o
arquivo que o `gcloud auth application-default login` escreve na sua pasta pessoal, que este
laboratório nunca tem. **Terceiro**, o servidor de metadados: a biblioteca tenta alcançá-lo, e só
quando falha ela desiste. Neste laptop a busca inteira levou uns três segundos, a maior parte gasta
com o servidor de metadados que não está lá.

Numa máquina do Compute Engine com conta presa, as duas primeiras não acham nada e a terceira
responde: o mesmo `google.auth.default()` devolve as credenciais da máquina sem arquivo nenhum. É
esse o sentido da ordem: **código escrito assim não muda entre um laptop e uma máquina**, e nunca
precisa de arquivo de chave em nenhum dos dois.
