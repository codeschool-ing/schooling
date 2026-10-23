---
title: O botão de compartilhar do engenheiro de nuvem
version: 1
---

**O S3 tem o seu próprio *qualquer pessoa com o link*: uma URL pré-assinada.** É um endereço comum
para um objeto, com uma assinatura anexada que foi calculada a partir da chave de acesso de alguém.
Quem tem o endereço consegue baixar aquele objeto, sem conta AWS, até acabar o tempo escrito nele. É a
ferramenta certa para entregar um arquivo a uma pessoa de fora da empresa, e tem todas as
propriedades dos links da seção anterior: é uma chave ao portador, ela viaja, e o bucket não guarda
lista nenhuma dos links que foram feitos.

O caio usa uma para mandar aos pacientes o resultado dos exames. Inicie o moto no primeiro terminal,
leia o `env.sh` nos dois e monte o resultado que ele vai mandar:

```sh
cat > result.txt <<'EOF'
patient: Maria Souza
exam: complete blood count
result: within the reference range
EOF
```

Depois um bucket, com o resultado dentro:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-results --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-results
ana@laptop:~/aws$ aws s3 cp --no-progress result.txt s3://clinic-results/maria-souza/2026-10-23.txt
upload: ./result.txt to s3://clinic-results/maria-souza/2026-10-23.txt
```

O bucket é privado, e um pedido anônimo pelo objeto prova isso:

```
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-results/maria-souza/2026-10-23.txt
403
```

## Fazendo o link

`aws s3 presign` assina o endereço localmente, com a chave do seu ambiente, e o imprime. Não manda
nada à AWS: a assinatura é aritmética sobre a chave, o nome do objeto e a hora.

```
ana@laptop:~/aws$ aws s3 presign s3://clinic-results/maria-souza/2026-10-23.txt --expires-in 900
http://localhost:4567/clinic-results/maria-souza/2026-10-23.txt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261023%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261023T034331Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=8cb1e1853a2701505dd4ffacb3baa056b797ef85712933405fc5890fba667f9b
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l10-presigned\" aria-label=\"As partes da URL pré-assinada que o laboratório imprimiu, uma por linha. O endereço nomeia o bucket e o objeto. X-Amz-Algorithm diz como foi assinada. X-Amz-Credential nomeia a chave de acesso que a assinou, com a data, a região e o serviço: na AWS é o id da chave, que diz de quem é a chave que está entregando o arquivo. X-Amz-Date é quando foi assinada e X-Amz-Expires quantos segundos ela dura a partir daí. X-Amz-SignedHeaders lista o que mais a assinatura cobre. X-Amz-Signature é calculada com a chave secreta sobre tudo acima dela, então mudar qualquer parte a invalida.\"><defs><marker id=\"l10-presigned-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"22.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost:4567/clinic-results/maria-souza/…</text><text x=\"430.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">qual objeto</text><rect x=\"30.0\" y=\"66.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Algorithm=AWS4-HMAC-SHA256</text><text x=\"430.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">como foi assinada</text><rect x=\"30.0\" y=\"110.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Credential=test/20261023/sa-east-1/s3</text><text x=\"430.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">de quem é a chave que assinou</text><rect x=\"30.0\" y=\"154.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Date=20261023T…</text><text x=\"430.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quando foi assinada</text><rect x=\"30.0\" y=\"198.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Expires=900</text><text x=\"430.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">segundos que dura a partir daí</text><rect x=\"30.0\" y=\"242.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-SignedHeaders=host</text><text x=\"430.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que mais é coberto</text><path d=\"M418 22 L424 22 L424 278 L418 278\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"30.0\" y=\"292.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"44.0\" y=\"310.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Signature=…</text><text x=\"430.0\" y=\"302.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">calculada com a chave secreta</text><text x=\"430.0\" y=\"319.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sobre todas as linhas acima</text><path d=\"M424.0 290.0 L424.0 280.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-presigned-af-ah-phosphor)\"></path></svg>", "caption": "Tudo o que quem defende pode saber de um link está nele: a chave que o assinou e quando ele para de funcionar. Nada dele fica guardado no bucket."}
```

**`X-Amz-Credential` nomeia a chave que assinou**, e essa é a alça que quem defende ganha. Aqui é o
`test` do moto; contra a AWS é um id de chave de acesso como `AKIA…`, que não é segredo e é
exatamente o que diz de quem é a chave que está entregando arquivos. `X-Amz-Expires=900` são quinze
minutos, contados a partir de `X-Amz-Date`. A assinatura cobre todos eles, então mudar a validade no
endereço quebra a assinatura, e a AWS recusa a requisição.

Qualquer pessoa com o endereço agora consegue ler o arquivo, sem credencial própria nenhuma:

```
ana@laptop:~/aws$ url=$(aws s3 presign s3://clinic-results/maria-souza/2026-10-23.txt --expires-in 900)
ana@laptop:~/aws$ curl -s "$url"
patient: Maria Souza
exam: complete blood count
result: within the reference range
```

## Onde o laboratório deixa de ser a AWS

Faça um link que dura dez segundos, espere quinze e use-o:

```
ana@laptop:~/aws$ url=$(aws s3 presign s3://clinic-results/maria-souza/2026-10-23.txt --expires-in 10); sleep 15; curl -s -w " %{http_code}\n" "$url"
patient: Maria Souza
exam: complete blood count
result: within the reference range
 200
```

**O moto serviu.** O moto 5.2.3 não verifica a validade de uma URL pré-assinada, e também não
verifica a assinatura. A AWS verifica as duas: depois da validade ela responde `403` com o código de
erro `AccessDenied` e a mensagem *Request has expired*, e um endereço cuja assinatura não confere
recebe `SignatureDoesNotMatch`. **Essas duas recusas vêm da documentação da AWS e não foram
executadas aqui.** O que o laboratório mostra de verdade é a metade que mais importa para quem
defende: até expirar, uma URL pré-assinada funciona para qualquer um, e nada no bucket registra que
ela foi feita.

## Quanto tempo um link vive, e como retirar um

Três regras da documentação da AWS, nenhuma executada aqui:

- **Um link assinado com a chave de longa duração de um usuário do IAM dura no máximo sete dias**,
  604.800 segundos. A linha de comando imprime um mais longo, e a AWS o recusa quando é usado.
- **Um link assinado com credenciais temporárias morre junto com elas.** Uma sessão de papel de uma
  hora faz links que param de funcionar dentro da hora, diga o que disser o `--expires-in`. Esse é um
  motivo para assinar a partir de um papel, e não de um usuário.
- **Um link carrega as permissões de quem o assinou no momento em que é usado, não no momento em que
  foi feito.** Desative ou apague a chave que o assinou, ou tire dessa identidade a permissão de ler
  o objeto, e todo link que ela já assinou para de funcionar. É o único jeito de revogar um, porque
  não existe lista de links de onde apagar.

Por isso a clínica nunca deve assinar links de resultado com a chave pessoal de alguém. **Um papel
dedicado, que pode ler o `clinic-results` e mais nada**, usado só para assinar, pode ser revogado num
passo sem trancar ninguém do lado de fora, e o id da chave dele num log diz na hora para que servia o
link. A aula 6 trata de construir identidades estreitas; esta é uma delas.
