---
title: O client secret, e por que ele é o padrão errado
version: 1
---

A API de pedidos da loja roda no cluster AKS da lição 11, e a partir desta lição ela grava um
recibo de cada pedido num contêiner do Blob Storage. Para isso ela precisa entrar no Microsoft
Entra ID, o diretório por trás de toda identidade do Azure, e obter um token para a conta de
armazenamento. A resposta que a maioria das equipes alcança primeiro é rápida. Registrar um
aplicativo no Entra ID e dar a ele um client secret. Pôr o id do aplicativo, o id do tenant e o
segredo num Secret do Kubernetes, e entregar o Secret ao pod como três variáveis de ambiente. O SDK
do Azure as encontra e entra. **Funciona na primeira tarde, e tudo o que há de errado nisso acontece
nos dias seguintes.** Esta seção é sobre esses dias, vistos do lado de quem tem de manter o tenant
seguro.

## Um Secret é um envelope, não um cofre

O Secret que essa resposta rápida escreve é assim. O client id e o tenant id são os marcadores que a
documentação da Microsoft usa, e o segredo são três palavras que o Entra ID recusaria:

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: orders-entra
  namespace: shop
data:
  AZURE_CLIENT_ID: MTExMTIyMjItYmJiYi0zMzMzLWNjY2MtNDQ0NGRkZGQ1NTU1
  AZURE_TENANT_ID: YWFhYWJiYmItMDAwMC1jY2NjLTExMTEtZGRkZDIyMjJlZWVl
  AZURE_CLIENT_SECRET: bm90LWEtcmVhbC1zZWNyZXQ=
```

As strings em `data` parecem embaralhadas, e essa é toda a proteção delas:

```
ana@laptop:~/azure$ grep CLIENT_SECRET secret.yaml
  AZURE_CLIENT_SECRET: bm90LWEtcmVhbC1zZWNyZXQ=
ana@laptop:~/azure$ grep CLIENT_SECRET secret.yaml | awk '{print $2}' | base64 -d; echo
not-a-real-secret
```

**Base64 é uma codificação, e qualquer um a desfaz com um comando que toda máquina Linux tem.** O
Kubernetes guarda um Secret no etcd e o entrega aos pods que o montam, e o RBAC do Kubernetes decide
quem pode lê-lo. Nenhum dos dois impede que o segredo saia pelas pessoas e pelos programas que têm
permissão de vê-lo. Conte onde este vai parar:

- **no repositório**, se `secret.yaml` foi commitado alguma vez, e depois em cada clone e fork;
- **no cluster**, legível por quem pode fazer `get secrets` no namespace `shop`, e por cada pod que
  o monta;
- **nos lugares para onde um segredo vaza por acidente**: um log de CI que imprimiu o ambiente, o
  histórico do shell de um laptop, um chamado de suporte com um erro colado.

Cada cópia vale tanto quanto a original enquanto o segredo viver, e isso levanta a pergunta de
quanto tempo é isso.

## Um segredo com data de fim

Ao contrário de uma chave que vive até alguém apagá-la, um client secret do Entra ID tem data de
fim. A linha de comando diz quanto ele dura quando ninguém escolhe, na ajuda dos dois comandos que
criam um:

```
ana@laptop:~/azure$ az ad sp create-for-rbac --help | grep -A1 -- "--years"
    --years                             : Number of years for which the credentials will be valid.
                                          Default: 1 year.
ana@laptop:~/azure$ az ad app credential reset --help | grep -A1 -- "--end-date"
    --end-date             : Finer grain of expiry time if '--years' is insufficient, e.g.
                             '2020-12-31T11:59:59+00:00' or '2299-12-31'.
```

**Um ano, a não ser que alguém escolha outra coisa, e a própria ajuda oferece `2299-12-31` a quem
quiser.** Então o segredo falha de uma de duas maneiras. Deixado no padrão, ele para de funcionar
num dia um ano depois de alguém criá-lo, e essa pessoa pode ter mudado de equipe nesse meio-tempo. A
documentação da Microsoft sobre federação de identidade de carga de trabalho cita esse risco com
todas as letras: queda do serviço quando as credenciais expiram. Posto longe no futuro, ele vira
uma senha que funciona por tanto tempo quanto alguém consegue imaginar, em cada cópia listada acima.

Rotacioná-lo é um pequeno projeto, e quem o faz é uma pessoa. Acrescentar um segundo segredo ao
aplicativo; escrevê-lo num Secret novo do Kubernetes; refazer o rollout de cada deployment que o lê;
apagar o segredo antigo do aplicativo; e torcer para que nada mais tivesse uma cópia. A data até a
qual isso tem de ser feito foi marcada um ano antes, por outra pessoa.

## Um aplicativo para todos que o têm

Três réplicas da API de pedidos, um pod de depuração que alguém subiu no mês passado e o laptop de
um desenvolvedor com o segredo colado num arquivo entram todos como o mesmo aplicativo. Os logs de
entrada do Entra ID citam esse aplicativo para cada um deles, então o registro de quem gravou um
recibo não consegue dizer qual deles foi. E o segredo concede o que quer que tenha sido concedido ao
aplicativo, a qualquer um que tenha uma cópia, de qualquer lugar que alcance o Entra ID.

## As outras respostas erradas: a identidade do nó, e a identidade gerenciada por pod

A segunda resposta que as pessoas alcançam não tem segredo nenhum: dar a permissão ao nó. Todo
cluster AKS tem uma **identidade do kubelet**, uma identidade gerenciada da lição 8 de
`azure-foundations` que o AKS cria no grupo de recursos dos nós e associa aos scale sets dos node
pools. O kubelet a usa para puxar imagens do registry da lição 10. Dê a ela um papel na conta de
armazenamento e a API de pedidos consegue gravar recibos, pedindo um token ao Instance Metadata
Service em `169.254.169.254`, sem nada guardado em lugar nenhum.

**E também consegue todo outro pod agendado nesses nós.** A documentação da Microsoft diz isso numa
frase: por padrão, todos os pods que rodam num cluster AKS alcançam o Instance Metadata Service, e
por ele os tokens das identidades que o nó carrega. A permissão é dada a uma máquina, enquanto a
necessidade pertence a uma carga de trabalho. O AKS tem uma configuração em preview que bloqueia o
serviço para todo pod que não esteja na rede do host, e o que a documentação dela manda esses pods
usarem no lugar é o assunto desta lição.

A terceira resposta tem uma história, e você ainda a encontra em clusters e artigos mais antigos. A
**identidade gerenciada por pod do Microsoft Entra** tentou tornar seguro o caminho do nó. Um
DaemonSet chamado NMI interceptava o pedido de cada pod ao serviço de metadados e respondia só pelas
identidades ligadas àquele pod, enquanto um controlador associava essas identidades ao scale set do
node pool. Ela nunca saiu do preview. A documentação da Microsoft, lida em 30 de outubro de 2026, diz
que o projeto de código aberto foi descontinuado em 24 de outubro de 2022 e arquivado em setembro de
2023, e que o add-on do AKS teve suporte até setembro de 2025, para dar aos usuários tempo de passar
para o Microsoft Entra Workload ID.

## O que o substituto tem de fazer

Ponha as falhas lado a lado e os requisitos se escrevem sozinhos. A credencial deve pertencer a
**uma carga de trabalho**, identificada pela sua service account do Kubernetes, e não a um
aplicativo que qualquer um com uma cópia pode ser, nem a um nó. Ela deve **expirar sozinha**, em
horas e não numa data de calendário. Deve estar **guardada em lugar nenhum** de onde uma pessoa possa
copiá-la. E ninguém deve ter de **rotacionar** nada à mão.

O **Microsoft Entra Workload ID**, chamado daqui em diante de workload identity, faz as quatro
coisas. O pod prova quem é com um token que o cluster assina, e o Entra ID lhe dá um token de acesso
porque foi avisado de antemão em qual assinatura acreditar. A próxima seção lê o token que o
Kubernetes já dá a um pod; a seguinte escreve a confiança do lado do Azure; a última acompanha a
troca entre os dois.

Se o cluster já tem segredos como o de `orders-entra`, dá para encontrá-los. O comando `az ad app
credential list --id <application id>` lista os metadados dos segredos de um aplicativo, datas de
fim incluídas. Um segredo antigo, usado a partir de um pod e que expira no próximo trimestre é o
primeiro a substituir.
