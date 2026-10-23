---
title: Criptografia de envelope, ou por que o KMS nunca vê os seus dados
version: 1
---

**O KMS não cifra os seus arquivos. Ele cifra chaves pequenas, e essas chaves cifram os seus
arquivos.** O padrão se chama *criptografia de envelope*: os dados são trancados com uma chave de
dados, a chave de dados é trancada com a chave do KMS, e a chave de dados trancada é guardada ao lado
dos dados, como uma carta no envelope. O S3, o EBS e todo outro serviço da AWS que usa o KMS
trabalham assim.

A imagem errada é a de que o S3 manda cada objeto ao KMS para ser cifrado. Não conseguiria: **o KMS
aceita no máximo 4096 bytes de texto claro por requisição.** Inicie o moto vazio, com a verificação
desligada, e recrie a chave da clínica com o mesmo alias de antes:

```
ana@laptop:~/aws$ k=$(aws kms create-key --description "clinic records" --query KeyMetadata.KeyId --output text)
ana@laptop:~/aws$ aws kms create-alias --alias-name alias/clinic-records --target-key-id "$k"
```

O seu laboratório aplica o mesmo limite que a AWS:

```
ana@laptop:~/aws$ head -c 5000 /dev/zero > big.bin && aws kms encrypt --key-id alias/clinic-records --plaintext fileb://big.bin --query KeyId --output text

aws: [ERROR]: An error occurred (ValidationException) when calling the Encrypt operation: 1 validation error detected: Value at 'plaintext' failed to satisfy constraint: Member must have length less than or equal to 4096
```

Quatro kilobytes bastam para uma senha ou uma chave, e estão longe de bastar para um exame
escaneado. A aula 1 do curso `cryptography` descreveu a cifra que faz o trabalho de verdade, o AES; a
criptografia de envelope é como uma nuvem entrega uma chave ao AES sem nunca entregar a chave que
protege todas as outras.

## Cifrando algo pequeno

Um segredo curto pode ir direto ao KMS. Cifre um bilhete, guarde o texto cifrado num arquivo e peça
o bilhete de volta:

```
ana@laptop:~/aws$ printf 'door code: 4471' > note.txt && aws kms encrypt --key-id alias/clinic-records --plaintext fileb://note.txt --query CiphertextBlob --output text | base64 -d > note.enc
ana@laptop:~/aws$ aws kms decrypt --ciphertext-blob fileb://note.enc --query KeyId --output text
arn:aws:kms:sa-east-1:123456789012:key/3dc44faa-5788-45db-b010-8787db7bf058
ana@laptop:~/aws$ aws kms decrypt --ciphertext-blob fileb://note.enc --query Plaintext --output text | base64 -d; echo
door code: 4471
```

**O pedido de decifração não nomeou chave nenhuma.** Um texto cifrado por uma chave simétrica do KMS
carrega uma referência à chave que o fez, e o KMS a lê dali, e por isso a resposta nomeia o ARN da
chave. O texto claro volta em base64, e o `base64 -d` o transforma de novo no bilhete. O moto escreve
essa referência como o id da chave, legível, no começo do texto cifrado; o texto cifrado da AWS tem
um formato próprio, que não foi feito para ser lido.

## Uma chave de dados, para qualquer coisa maior

O `generate-data-key` pede ao KMS uma chave nova de 256 bits, devolvida duas vezes: uma em texto
claro, para usar agora, e uma cifrada com a chave do KMS, para guardar.

```
ana@laptop:~/aws$ aws kms generate-data-key --key-id alias/clinic-records --key-spec AES_256 --query "[KeyId,length(Plaintext),length(CiphertextBlob)]" --output text
arn:aws:kms:sa-east-1:123456789012:key/3dc44faa-5788-45db-b010-8787db7bf058	44	128
```

A chave em claro tem 44 caracteres de base64, que são 32 bytes, que são 256 bits. A cópia cifrada é
mais longa: além dos 32 bytes, ela carrega o que o KMS precisa para decifrá-la, a referência à sua
chave entre outras coisas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l11-envelope\" aria-label=\"Criptografia de envelope. À esquerda, dentro do KMS, a chave do KMS, que nunca sai. O KMS gera uma chave de dados e a devolve duas vezes: em texto claro e cifrada com a chave do KMS. No meio, o serviço cifra os dados com a chave de dados em claro, usando AES, e depois apaga a chave em claro. À direita, o que fica guardado: os dados cifrados com a chave de dados cifrada ao lado, como uma carta no envelope. Para ler de volta, só a chave de dados cifrada vai ao KMS, que verifica a permissão de quem pede antes de devolver a chave em claro.\"><defs><marker id=\"l11-envelope-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-envelope-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"180.0\" height=\"240.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"110.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">KMS</text><rect x=\"40.0\" y=\"90.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">chave do KMS</text><text x=\"110.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">nunca sai</text><text x=\"110.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gera uma</text><text x=\"110.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave de dados</text><text x=\"110.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e a devolve 2 vezes</text><rect x=\"250.0\" y=\"40.0\" width=\"210.0\" height=\"240.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o serviço</text><rect x=\"270.0\" y=\"82.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">chave de dados em claro</text><rect x=\"270.0\" y=\"128.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave de dados cifrada</text><text x=\"355.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AES com a chave em claro</text><text x=\"355.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cifra os dados</text><text x=\"355.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">depois apaga a chave em claro</text><path d=\"M200.0 105.0 L268.0 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-envelope-af-ah-paper-dim)\"></path><path d=\"M200.0 125.0 L268.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-envelope-af-ah-paper-dim)\"></path><rect x=\"510.0\" y=\"40.0\" width=\"190.0\" height=\"240.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o que fica guardado</text><rect x=\"530.0\" y=\"90.0\" width=\"150.0\" height=\"100.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dados cifrados</text><rect x=\"530.0\" y=\"202.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave de dados cifrada</text><path d=\"M460.0 145.0 L528.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-envelope-af-ah-paper-dim)\"></path><path d=\"M460.0 150.0 L528.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-envelope-af-ah-paper-dim)\"></path><path d=\"M605 282 L605 306 L110 306 L110 282\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l11-envelope-af-ah-phosphor)\"></path><text x=\"357.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">para ler: só a chave cifrada volta ao KMS, que verifica quem pede</text></svg>", "caption": "O KMS guarda uma chave e nunca vê os dados; cada objeto carrega a própria chave de dados, trancada sob ela. Toda leitura pergunta de novo ao KMS, com a identidade de quem pede na requisição.", "same": ["KMS"]}
```

O que um serviço faz com o par, em quatro passos:

1. cifrar os dados localmente, com AES e a chave de dados em claro;
2. **apagar da memória a chave de dados em claro**;
3. guardar a chave de dados cifrada ao lado dos dados cifrados;
4. para ler de volta, mandar ao KMS só a chave de dados cifrada, receber a em claro, decifrar, e
   apagá-la de novo.

**Toda leitura é uma chamada `Decrypt` ao KMS, com a identidade de quem pede nela.** É por isso que a
segunda tranca da seção anterior funciona: o KMS é consultado toda vez, e pode dizer não. É também o
que a configuração `BucketKeyEnabled` muda: o S3 guarda por um tempo uma chave intermediária por
bucket em vez de consultar o KMS a cada objeto, o que a AWS documenta como um corte grande no número
de requisições ao KMS, e no custo delas. A aula 14 do curso `cryptography` encontrou o mesmo envelope
na criptografia de disco e de banco de dados, onde a chave de dados cifra um volume inteiro.
