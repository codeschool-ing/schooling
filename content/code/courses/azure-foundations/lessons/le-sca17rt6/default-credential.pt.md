---
title: Uma linha de código, e a ordem em que ela tenta
version: 1
---

**O mesmo programa deveria entrar como a desenvolvedora num laptop, como um pipeline no GitHub e como
uma identidade gerenciada em produção, sem mudar uma linha.** A biblioteca Azure Identity faz isso com
uma classe, `DefaultAzureCredential`, que tenta uma lista fixa de credenciais em ordem e usa a primeira
que funciona. Saber a ordem é saber por que um programa entrou como alguém que você não esperava.

Salve isto como `who.py` em `~/azure/identity`:

```schooling-example
{"language": "python", "file": "who.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"who.py: ask for a token for Resource Manager the way an application does, and say what happened.\"\"\"\nimport logging\n\nfrom azure.core.exceptions import ClientAuthenticationError\nfrom azure.identity import DefaultAzureCredential\n\n", "note": "`azure-identity` é a biblioteca que a lição 1 instalou ao lado da CLI do Azure. Ela é a mesma em Python, .NET, Java, JavaScript e Go: um nome, uma ordem de credenciais."}, {"code": "logging.getLogger('azure.identity').setLevel(logging.ERROR)\n\n", "note": "A biblioteca registra cada falha como aviso além de levantá-la. Deixar o log quieto fica com um só relato do que aconteceu, o da exceção."}, {"code": "credential = DefaultAzureCredential()\ntry:\n    token = credential.get_token('https://management.azure.com/.default')\n    print('a token, valid until', token.expires_on)\n", "note": "**`DefaultAzureCredential` é uma lista de credenciais tentadas em ordem**, e a primeira que produz um token vence. O scope é o da lição 7: o Resource Manager, com os papéis que a identidade tiver."}, {"code": "except ClientAuthenticationError as e:\n    print(e.message)\n", "note": "Quando todas as credenciais da lista falham, a mensagem da exceção diz o que cada uma encontrou, na ordem em que foi tentada."}]}
```

e rode-o no laboratório, onde nenhuma das credenciais tem com que trabalhar:

```
ana@laptop:~/azure/identity$ python3 who.py
DefaultAzureCredential failed to retrieve a token from the included credentials.
Attempted credentials:
	EnvironmentCredential: EnvironmentCredential authentication unavailable. Environment variables are not fully configured.
Visit https://aka.ms/azsdk/python/identity/environmentcredential/troubleshoot to troubleshoot this issue.
	WorkloadIdentityCredential: WorkloadIdentityCredential authentication unavailable. The workload options are not fully configured. See the troubleshooting guide for more information: https://aka.ms/azsdk/python/identity/workloadidentitycredential/troubleshoot. Missing required arguments: 'tenant_id', 'client_id', 'token_file_path'.
	ManagedIdentityCredential: ManagedIdentityCredential authentication unavailable.
	SharedTokenCacheCredential: SharedTokenCacheCredential authentication unavailable. No accounts were found in the cache.
	VisualStudioCodeCredential: VisualStudioCodeCredential requires the 'azure-identity-broker' package to be installed. You must also ensure you have the Azure Resources extension installed and have signed in to Azure via Visual Studio Code.
	AzureCliCredential: Please run 'az login' to set up an account
	AzurePowerShellCredential: PowerShell is not installed
	AzureDeveloperCliCredential: Azure Developer CLI could not be found. Please visit https://aka.ms/azure-dev for installation instructions and then,once installed, authenticate to your Azure account using 'azd auth login'.
	BrokerCredential: InteractiveBrowserBrokerCredential unavailable. The 'azure-identity-broker' package is required to use brokered authentication.
To mitigate this issue, please refer to the troubleshooting guidelines here at https://aka.ms/azsdk/python/identity/defaultazurecredential/troubleshoot.
```

**Essa é a lista inteira, na ordem em que a biblioteca a tenta**, cada uma com o seu motivo para
desistir:

| credencial | o que ela procura | onde é ela que responde |
|---|---|---|
| `EnvironmentCredential` | `AZURE_TENANT_ID`, `AZURE_CLIENT_ID` e um segredo ou certificado no ambiente | um programa que recebeu as credenciais de um service principal, os degraus de baixo da lição 7 |
| `WorkloadIdentityCredential` | um arquivo de token escrito pelo Kubernetes, e as variáveis dele | um pod no AKS com workload identity |
| `ManagedIdentityCredential` | o endpoint de token da plataforma, da seção anterior | qualquer coisa rodando no Azure com uma identidade gerenciada |
| `SharedTokenCacheCredential`, `VisualStudioCodeCredential` | o editor de uma desenvolvedora já logado | um laptop |
| `AzureCliCredential` | `az login` | um laptop, ou um passo de pipeline depois que a CLI fez login |
| `AzurePowerShellCredential`, `AzureDeveloperCliCredential`, `BrokerCredential` | as outras ferramentas e o intermediário de login do sistema operacional | um laptop |

A `ManagedIdentityCredential` disse que estava **indisponível** porque não há plataforma debaixo do
laboratório para respondê-la. A `AzureCliCredential` deu a mensagem que todo comando deste curso deu:
ninguém rodou `az login`.

## A primeira configurada vence, mesmo quando está errada

Agora dê ao programa o que a `EnvironmentCredential` procura, com o tenant e o client id inventados da
lição 7:

```
ana@laptop:~/azure/identity$ AZURE_TENANT_ID=aaaabbbb-0000-cccc-1111-dddd2222eeee AZURE_CLIENT_ID=00001111-aaaa-2222-bbbb-3333cccc4444 AZURE_CLIENT_SECRET=not-a-secret python3 who.py
DefaultAzureCredential failed to retrieve a token from the included credentials.
Attempted credentials:
	EnvironmentCredential: Authentication failed: Unable to get authority configuration for https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee. Authority would typically be in a format of https://login.microsoftonline.com/your_tenant or https://tenant_name.ciamlogin.com or https://tenant_name.b2clogin.com/tenant.onmicrosoft.com/policy.  Also please double check your tenant name or GUID is correct.
To mitigate this issue, please refer to the troubleshooting guidelines here at https://aka.ms/azsdk/python/identity/defaultazurecredential/troubleshoot.
```

**Desta vez só uma credencial foi tentada.** A `EnvironmentCredential` achou as três variáveis e foi ao
Entra ID com elas. Antes de mandar o segredo ela buscou o documento de descoberta do tenant, o mesmo
que a lição 6 buscou com `curl`, e o Entra ID o recusou com o `AADSTS90002` da lição 6; a biblioteca
informa isso como uma *authority* que ela não consegue configurar. Ela não seguiu para a identidade
gerenciada nem para a CLI. **Uma credencial que está configurada e falha para a corrente**, de
propósito: seguir adiante faria o programa entrar como outra pessoa e esconderia o erro.

Essa regra explica o incidente clássico. Um `AZURE_CLIENT_SECRET` esquecido por uma desenvolvedora numa
imagem de contêiner, ou uma variável velha num pipeline, faz a `EnvironmentCredential` responder
primeiro em produção, e a aplicação roda como um service principal antigo em vez da sua identidade
gerenciada, com os papéis desse principal. **Em produção, nomeie a credencial que você quer.**
`ManagedIdentityCredential(client_id=...)` no lugar da lista padrão é uma linha, e não tem como cair em
mais nada; guarde a `DefaultAzureCredential` para código que roda em mais de um lugar, e mantenha
credenciais perdidas fora dos ambientes onde ele roda.
