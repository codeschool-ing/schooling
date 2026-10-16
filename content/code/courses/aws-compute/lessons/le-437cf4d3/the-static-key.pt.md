---
title: A chave estática, e por que ela é a resposta errada
version: 1
---

Um pod no cluster EKS da loja redimensiona fotos de produtos, e precisa lê-las de um bucket S3.
Então ele precisa de credenciais da AWS. A resposta que a maioria das equipes encontra primeiro é
rápida: criar um usuário do IAM, dar a ele uma chave de acesso, pôr a chave num Secret do Kubernetes
e entregar o Secret ao pod como duas variáveis de ambiente. **Funciona na primeira tarde, e tudo o
que há de errado nela acontece nos dias seguintes.** Esta seção é sobre esses dias, vistos do lado
de quem tem de manter a conta segura.

## Uma chave que não termina

Crie o usuário e a chave do jeito que essa resposta cria. O `--query` deixa a metade secreta fora
da tela, um hábito que vale a pena ter mesmo com o moto:

```
ana@laptop:~/aws$ aws iam create-user --user-name shop-app --query User.Arn
"arn:aws:iam::123456789012:user/shop-app"
ana@laptop:~/aws$ aws iam create-access-key --user-name shop-app --query "AccessKey.[Status,CreateDate]" --output text
Active	2026-10-16T16:29:03.368272+00:00
ana@laptop:~/aws$ aws iam list-access-keys --user-name shop-app --query "AccessKeyMetadata[0]" | grep -v AccessKeyId
{
    "UserName": "shop-app",
    "Status": "Active",
    "CreateDate": "2026-10-16T16:29:03.368272+00:00"
}
ana@laptop:~/aws$ aws sts get-session-token --query "Credentials.Expiration"
"2026-10-17T04:29:04.409027+00:00"
```

O registro da chave tem um status e uma data de nascimento, e mais nada. **Não existe campo para
quando ela deixa de funcionar, porque ela não deixa.** Vale até alguém desativá-la ou apagá-la, o
que na prática quer dizer até alguém se lembrar. O último comando pede ao STS uma credencial
temporária, e essa traz um `Expiration` doze horas à frente. Toda credencial que o resto desta aula
produz é do segundo tipo, e quase tudo o que vem a seguir é sobre como um pod recebe uma sem que
ninguém guarde chave nenhuma.

## Um Secret é um envelope, não um cofre

O Secret que a resposta rápida escreve é assim. Os dois valores são a palavra `test`, as credenciais
que o moto aceita e a AWS recusa:

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: photos-aws
  namespace: shop
data:
  AWS_ACCESS_KEY_ID: dGVzdA==
  AWS_SECRET_ACCESS_KEY: dGVzdA==
```

As strings em `data` parecem embaralhadas, e essa é toda a proteção que têm:

```
ana@laptop:~/aws$ grep SECRET secret.yaml
  AWS_SECRET_ACCESS_KEY: dGVzdA==
ana@laptop:~/aws$ grep SECRET secret.yaml | awk '{print $2}' | base64 -d; echo
test
```

**Base64 é uma codificação, e qualquer um a desfaz com um comando que toda máquina Linux tem.** Um
Secret do Kubernetes fica guardado no banco de dados do cluster e é entregue aos pods que o montam.
Quem pode lê-lo é decidido pelas permissões do Kubernetes, e a AWS criptografa os discos por baixo;
nenhuma das duas coisas impede a chave de sair pelas pessoas e programas que têm permissão para
vê-la. Conte onde esta vai parar:

- **no manifesto**, se o `secret.yaml` algum dia entrou no repositório, e então em cada clone e cada
  fork dele;
- **no cluster**, legível por qualquer um com permissão de `get secrets` no namespace, e por todo pod
  que o monta;
- **nos lugares para onde uma chave vaza por acidente**: um log de CI que imprimiu o ambiente, o
  histórico do shell de um laptop, um chamado de suporte com um erro colado.

Cada cópia vale tanto quanto o original, enquanto a chave viver, e a captura acima diz que é para
sempre.

## Um usuário para todos os pods

Três réplicas do redimensionador, um pod de depuração que alguém subiu no mês passado e o laptop de
um desenvolvedor apresentam todos a mesma chave. No CloudTrail cada chamada deles é feita por
`user/shop-app`, então o registro de quem leu um bucket não distingue um pod de um laptop. E trocar
a chave, porque vazou ou porque uma política manda trocar a cada noventa dias, é um pequeno projeto.
Exige uma segunda chave, um Secret novo e um rollout de cada deployment que a lê, depois apagar a
chave velha e torcer para que mais ninguém tivesse uma cópia.

## A outra resposta errada: o role do nó

A segunda resposta que aparece é dar a permissão ao nó. A aula 10 de `aws-foundations` mostrou
como um instance profile entrega um role a uma instância EC2, e um nó do EKS é uma instância EC2 que
já tem um: o role do nó, que deixa o kubelet entrar no cluster e baixar imagens do ECR. Acrescente
`s3:GetObject` a ele e o redimensionador consegue ler o bucket, sem chave em lugar nenhum.

**E também consegue todo outro pod agendado naquele nó**, seja ele qual for e tenha sido escrito por
quem for, porque as credenciais do nó vêm do serviço de metadados da instância e qualquer processo
da máquina pode pedi-las. A permissão é dada a uma máquina, enquanto a necessidade é de uma carga
de trabalho. A defesa está na aula 7: com IMDSv2 obrigatório e limite de saltos 1, a resposta ao
pedido de token não consegue dar o salto a mais até um contêiner na sua própria rede, então os pods
não alcançam o role do nó de jeito nenhum. A orientação do próprio EKS é bloquear desse jeito e dar
a cada carga de trabalho um role seu.

## O que a alternativa precisa fazer

Ponha as falhas lado a lado e os requisitos se escrevem sozinhos. A credencial deve pertencer a
**uma carga de trabalho**, identificada pela sua service account do Kubernetes, e não a um nó ou a
um usuário. Deve **expirar** sozinha, em horas. Não deve ficar **guardada em lugar nenhum** de onde
uma pessoa possa copiá-la. E o CloudTrail deve conseguir dizer **qual carga de trabalho** fez a
chamada.

A aula 10 de `aws-foundations` deu nome ao mecanismo que faz as quatro coisas: **IAM roles for
service accounts**, o IRSA. As próximas três seções o montam peça por peça e executam no seu laptop
a troca que está no centro dele. A última mostra o EKS Pod Identity, o jeito mais novo de chegar ao
mesmo resultado.

Se o seu cluster já tem chaves como a de `shop-app`, dá para encontrá-las: `aws iam
list-access-keys` para cada usuário, como acima, e `aws iam get-access-key-last-used`, que diz
quando uma chave foi usada pela última vez e para qual serviço. Uma chave velha, ativa e usada a
partir de um pod é a primeira a substituir.
