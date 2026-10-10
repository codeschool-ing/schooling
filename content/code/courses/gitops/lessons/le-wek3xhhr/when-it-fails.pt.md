---
title: Quando falha
version: 1
---

Uma verificação tem dois jeitos de falhar, e eles significam coisas diferentes. **Nenhuma assinatura**
é a imagem que ninguém assinou:

```
ana@laptop:~/signing$ cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin:1.1
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no signatures found
error during command execution: no signatures found
```

`no signatures found`: não há nada guardado ao lado do digest da 1.1. Ninguém a assinou, o que neste
curso é verdade, porque a assinatura começou na 1.2.

**Uma assinatura de outra pessoa** é o caso mais sério, porque alguém assinou; só que não com a chave
em que você confia. Aqui um segundo par de chaves, feito para isso, faz o papel desse alguém:

```
ana@laptop:~/signing$ cosign verify --key /tmp/other/cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin@$DIGEST
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no matching attestations: failed to verify signature: could not verify envelope: accepted signatures do not match threshold, Found: 0, Expected 1
error during command execution: no matching attestations: failed to verify signature: could not verify envelope: accepted signatures do not match threshold, Found: 0, Expected 1
```

Desta vez existe uma assinatura, e o erro é outro: a assinatura encontrada não confere com a chave
dada. `Found: 0, Expected 1` é o `cosign` contando as assinaturas que bateram.

E a flag que esta aula vive passando importa. Sem `--insecure-ignore-tlog=true`, o `cosign` espera
que toda assinatura esteja registrada no Rekor, busca a raiz de confiança do Sigstore para conferir
isso e reprova uma assinatura só com chave que nunca foi registrada. Essa execução não está gravada
aqui: esta máquina não alcança o Sigstore de jeito nenhum, então falha um passo antes, ao buscar a
raiz de confiança, e essa não é a falha que você encontraria.

| o que aparece | o que significa | o que fazer |
|---|---|---|
| `no signatures found` | o digest não tem assinatura neste registry | assiná-lo, ou descobrir por que o pipeline não assinou |
| `accepted signatures do not match threshold` | existe assinatura, nenhuma feita pela sua chave | descobrir quem assinou; nunca responder confiando na chave dessa pessoa |
| `no matching signatures were found` no `flux get sources` | o Flux conferiu a assinatura do chart e a recusou | as mesmas duas perguntas, feitas sobre o chart |

**A resposta errada para todas elas é a mesma**: desligar a checagem. Uma verificação desligada no dia
em que falha nunca foi uma checagem, só um atraso. Cada falha acima nomeia um artefato e uma chave, e
a pergunta a responder é sempre qual dos dois está errado.

## Trocando a chave

Chaves precisam mudar: alguém sai, um laptop se perde, uma política manda trocar todo ano. A troca
com um par de chaves são três passos, e a ordem importa:

1. publicar a chave pública nova **ao lado** da antiga, para que os verificadores aceitem as duas. O
   Secret do Flux pode guardar vários arquivos `.pub`, e uma assinatura feita por qualquer um deles
   passa;
2. assinar as releases novas com a chave nova, e reassinar as imagens que ainda estão em produção;
3. remover a chave pública antiga quando nada em execução tiver só a assinatura dela.

Uma chave vazada pula a paciência: a metade pública sai na hora, e toda imagem que ela assinou é
reassinada com a chave nova ou reconstruída. É por isso que **reassinar precisa ser rotina** antes de
virar emergência, e mais um motivo para a assinatura keyless atrair: não há chave de longa duração
para trocar.
