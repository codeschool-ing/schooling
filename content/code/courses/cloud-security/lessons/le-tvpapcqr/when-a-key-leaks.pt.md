---
title: Quando uma chave vaza
version: 1
---

**Uma chave de acesso vazada não é descoberta pela pessoa que a vazou. Ela é descoberta por um
programa, muitas vezes em minutos, e a única pergunta é de quem é o programa que chega primeiro.**
Repositórios públicos são lidos o tempo todo por varredores automáticos, alguns rodados para proteger
os donos das chaves e outros para usar o que encontram. Uma chave enviada por engano precisa ser
tratada como conhecida por todo mundo desde o momento do envio.

A imagem errada é a de que apagar o arquivo resolve. Um commit que remove uma chave a deixa no commit
anterior, em todo clone e fork feito no meio-tempo, e em qualquer cache que copiou a página. **A única
correção para uma chave vazada é torná-la inútil**, o que quer dizer rotacioná-la, e o resto desta
aula trata de fazer isso sem quebrar a aplicação que a usava.

## Onde as chaves vão parar

Os caminhos habituais são comuns, e nenhum parece um erro enquanto acontece:

- um arquivo de configuração enviado junto com o código, o caso abaixo;
- um valor colado num chamado, num chat ou num pedido de suporte, para mostrar o erro a alguém;
- uma captura de tela de um terminal, postada para explicar outra coisa;
- uma imagem de contêiner montada com a chave copiada para dentro, onde ela fica numa camada mesmo
  depois de uma camada seguinte apagar o arquivo;
- um log de CI que imprimiu o ambiente durante uma depuração.

O caio montou o sistema de agendamento do jeito rápido: um arquivo ao lado do código com a chave dele
dentro. Crie um diretório que faz o papel do repositório da aplicação, e escreva ali o mesmo arquivo a
partir da chave na variável `caio`:

```sh
mkdir -p booking
printf 'AWS_ACCESS_KEY_ID=%s\nAWS_SECRET_ACCESS_KEY=%s\n' \
  "$(echo "$caio" | jq -r .AccessKey.AccessKeyId)" \
  "$(echo "$caio" | jq -r .AccessKey.SecretAccessKey)" > booking/booking.env
```

## Achando uma

**Ids de chave têm um formato, e o formato é o que os varredores procuram.** `AKIA` ou `ASIA`, e
depois dezesseis letras maiúsculas e dígitos. Um `grep` num diretório é o menor varredor que existe:

```
ana@laptop:~/aws$ grep -rnoE 'A(KI|SI)A[A-Z0-9]{16}' booking
booking/booking.env:1:AKIARZPUZDIKKKVVGHFV
```

Ele achou o id em `booking/booking.env`, linha 1. Um varredor de verdade acrescenta o formato do
segredo, que não tem prefixo e é mais difícil de distinguir de texto aleatório, e verifica o
histórico além dos arquivos de hoje. Gitleaks e TruffleHog são dois muito usados, e a aula 16 do curso
`secure-code` defendeu onde o valor deveria ter ido em vez disso.

::: track devsecops
Rodar um deles a cada push, no histórico também, é o que a aula 6 do curso `secure-pipeline` montou no
pipeline que você construiu antes deste curso.
:::

::: track *
Rodar um deles a cada push, no histórico também, é trabalho do pipeline; a aula 6 do curso
`secure-pipeline` monta exatamente isso.
:::

**O GitHub faz a mesma busca em repositórios públicos**, pelo programa de parceiros de varredura de
segredos: quando acha algo com formato de chave da AWS, ele avisa a AWS. Nada disso foi executado
aqui, já que nada neste laboratório é público.

## O que a AWS faz, e o que não faz

Quando a AWS descobre que uma chave está exposta, pelo aviso do GitHub ou por conta própria, ela entra
em contato com a conta e pode anexar ao usuário uma política gerenciada, a **política de quarentena de
chave comprometida** que a aula 6 leu por causa da lista de ações do IAM. Aqui você a anexa à mão,
fazendo as vezes da AWS, e pergunta o que a chave do caio ainda consegue fazer:

```
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3
ana@laptop:~/aws$ with_key "$caio" aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ with_key "$caio" aws iam create-access-key --user-name caio

aws: [ERROR]: An error occurred (AccessDenied) when calling the CreateAccessKey operation: User: arn:aws:iam::123456789012:user/caio is not authorized to perform: iam:CreateAccessKey
ana@laptop:~/aws$ with_key "$caio" aws secretsmanager list-secrets --query "length(SecretList)"
0
```

A listagem de buckets e a criação de uma chave nova foram recusadas: um `Deny` explícito vence a
`PowerUserAccess` que as permite. **A requisição ao Secrets Manager passou.** A quarentena nega as
ações de que mais se abusa, as que custam dinheiro ou criam novas portas de entrada, e não tudo. É um
freio puxado por outra pessoa, e compra tempo para o dono agir.

Então os passos do dono, na ordem documentada pela AWS, são os da próxima seção: trocar a chave por
uma nova, apagar a exposta, e depois ler o que a chave antiga fez enquanto estava solta, nos registros
de que trata a aula 15, antes de tirar a quarentena.
