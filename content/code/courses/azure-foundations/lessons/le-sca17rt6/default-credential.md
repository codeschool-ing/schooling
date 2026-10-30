---
title: One line of code, and the order it tries
version: 1
---

**The same program should sign in as the developer on a laptop, as a pipeline in GitHub and as a
managed identity in production, without changing a line.** The Azure Identity library does that with
one class, `DefaultAzureCredential`, which tries a fixed list of credentials in order and uses the
first that works. Knowing the order is knowing why a program signed in as somebody you did not expect.

Save this as `who.py` in `~/azure/identity`:

```schooling-example
{"language": "python", "file": "who.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"who.py: ask for a token for Resource Manager the way an application does, and say what happened.\"\"\"\nimport logging\n\nfrom azure.core.exceptions import ClientAuthenticationError\nfrom azure.identity import DefaultAzureCredential\n\n", "note": "`azure-identity` is the library lesson 1 installed beside the Azure CLI. It is the same in Python, .NET, Java, JavaScript and Go: one name, one order of credentials."}, {"code": "logging.getLogger('azure.identity').setLevel(logging.ERROR)\n\n", "note": "The library logs each failure as a warning as well as raising it. Keeping the log quiet leaves one account of what happened, the exception's."}, {"code": "credential = DefaultAzureCredential()\ntry:\n    token = credential.get_token('https://management.azure.com/.default')\n    print('a token, valid until', token.expires_on)\n", "note": "**`DefaultAzureCredential` is a list of credentials tried in order**, and the first that produces a token wins. The scope is lesson 7's: Resource Manager, with whatever roles the identity has."}, {"code": "except ClientAuthenticationError as e:\n    print(e.message)\n", "note": "When every credential in the list fails, the exception's message says what each one found, in the order it was tried."}]}
```

and run it in the lab, where none of the credentials has anything to work with:

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

**That is the whole list, in the order the library tries it**, each with its reason for giving up:

| credential | what it looks for | where it is the one that answers |
|---|---|---|
| `EnvironmentCredential` | `AZURE_TENANT_ID`, `AZURE_CLIENT_ID` and a secret or certificate in the environment | a program given a service principal's credentials, lesson 7's bottom rungs |
| `WorkloadIdentityCredential` | a token file written by Kubernetes, and its variables | a pod in AKS with workload identity |
| `ManagedIdentityCredential` | the platform's token endpoint of the previous section | anything running on Azure with a managed identity |
| `SharedTokenCacheCredential`, `VisualStudioCodeCredential` | a developer's editor already signed in | a laptop |
| `AzureCliCredential` | `az login` | a laptop, or a pipeline step after the CLI signed in |
| `AzurePowerShellCredential`, `AzureDeveloperCliCredential`, `BrokerCredential` | the other tools and the operating system's sign-in broker | a laptop |

`ManagedIdentityCredential` said it was **unavailable** because there is no platform under the lab to
answer it. `AzureCliCredential` gave the message every command of this course has given: nobody ran
`az login`.

## The first one configured wins, even when it is wrong

Now give the program what `EnvironmentCredential` looks for, with the made-up tenant and client id of
lesson 7:

```
ana@laptop:~/azure/identity$ AZURE_TENANT_ID=aaaabbbb-0000-cccc-1111-dddd2222eeee AZURE_CLIENT_ID=00001111-aaaa-2222-bbbb-3333cccc4444 AZURE_CLIENT_SECRET=not-a-secret python3 who.py
DefaultAzureCredential failed to retrieve a token from the included credentials.
Attempted credentials:
	EnvironmentCredential: Authentication failed: Unable to get authority configuration for https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee. Authority would typically be in a format of https://login.microsoftonline.com/your_tenant or https://tenant_name.ciamlogin.com or https://tenant_name.b2clogin.com/tenant.onmicrosoft.com/policy.  Also please double check your tenant name or GUID is correct.
To mitigate this issue, please refer to the troubleshooting guidelines here at https://aka.ms/azsdk/python/identity/defaultazurecredential/troubleshoot.
```

**This time only one credential was tried.** `EnvironmentCredential` found its three variables and
went to Entra ID with them. Before sending the secret it fetched the tenant's discovery document, the
one lesson 6 fetched with `curl`, and Entra ID refused it with lesson 6's `AADSTS90002`; the library
reports that as an *authority* it cannot configure. It did not go on to the managed identity or the CLI.
**A credential that is configured and fails stops the chain**, on purpose: carrying on would sign the
program in as somebody else and hide the mistake.

That rule explains the classic incident. A developer's leftover `AZURE_CLIENT_SECRET` in a container
image, or a stale variable in a pipeline, makes `EnvironmentCredential` answer first in production, and
the application runs as an old service principal instead of its managed identity, with that
principal's roles. **In production, name the credential you mean.** `ManagedIdentityCredential(client_id=...)`
in place of the default list is one line, and it cannot fall through to anything else; keep
`DefaultAzureCredential` for code that runs in more than one place, and keep stray credentials out of
the environments it runs in.
