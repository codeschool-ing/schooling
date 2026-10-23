---
title: Rotacionar, desativar e apagar uma chave
version: 1
---

**Uma chave gerenciada pelo cliente tem uma vida: ela é rotacionada, pode ser desativada e pode ser
agendada para exclusão. Cada uma dessas mudanças altera o que acontece com cada byte já cifrado
com ela.** Apagar uma chave é a única ação deste curso que ninguém consegue desfazer, nem a AWS: os
dados cifrados com ela viram ruído. Por isso o KMS faz você esperar.

Continue no moto e no terminal da seção anterior, com o id da chave em `k`, o alias
`alias/clinic-records` e o `note.enc`.

## A rotação guarda o material antigo

Rotacionar uma chave no KMS não recifra nada. **Ela acrescenta material novo para as cifragens novas
e guarda todas as versões antigas**, então o texto cifrado no ano passado continua decifrando, e o id
e o alias da chave nunca mudam. A rotação automática fica desligada numa chave nova gerenciada pelo
cliente até você ligá-la; a documentação do KMS dá um ano como período padrão. Uma rotação também
pode ser pedida na hora:

```
ana@laptop:~/aws$ aws kms get-key-rotation-status --key-id "$k" --query KeyRotationEnabled
false
ana@laptop:~/aws$ aws kms enable-key-rotation --key-id "$k"
ana@laptop:~/aws$ aws kms get-key-rotation-status --key-id "$k" --query KeyRotationEnabled
true
ana@laptop:~/aws$ aws kms rotate-key-on-demand --key-id "$k" --output text
3dc44faa-5788-45db-b010-8787db7bf058
ana@laptop:~/aws$ aws kms list-key-rotations --key-id "$k" --query "Rotations[].RotationType" --output text
ON_DEMAND
```

Essa é a resposta certa para *a chave tem um ano*, e a errada para *a chave pode ter vazado*. A
rotação protege os dados cifrados daqui em diante; quem podia usar a chave ontem ainda decifra tudo o
que foi feito antes. Uma chave que pode estar comprometida é uma pergunta sobre **quem pode usá-la**,
e a resposta mora na política da chave e no IAM, não no material dela.

## Desativar: o que a AWS recusa e o moto não

Desativar uma chave impede o uso dela, e ela pode ser reativada. Desative a chave da clínica e peça o
bilhete a ela:

```
ana@laptop:~/aws$ aws kms disable-key --key-id "$k"
ana@laptop:~/aws$ aws kms describe-key --key-id alias/clinic-records --query KeyMetadata.KeyState --output text
Disabled
ana@laptop:~/aws$ aws kms decrypt --ciphertext-blob fileb://note.enc --query Plaintext --output text | base64 -d; echo
door code: 4471
```

**O moto ainda decifrou.** A AWS não decifraria: uma requisição a uma chave desativada é recusada
com `DisabledException`, e toda leitura no S3 de um objeto sob essa chave falha com ela. É esse
comportamento que torna a desativação útil, como um jeito de cortar os dados de uma chave em segundos
enquanto você descobre o que aconteceu. **A recusa vem da documentação do KMS e não foi executada
aqui.** Reative-a antes de seguir:

```
ana@laptop:~/aws$ aws kms enable-key --key-id "$k"
```

## A exclusão espera, de propósito

Uma chave nunca é apagada na hora. O `schedule-key-deletion` inicia um período de espera, entre 7 e
30 dias na AWS e de 30 quando você não diz, e durante ele a chave fica `PendingDeletion`:

```
ana@laptop:~/aws$ aws kms schedule-key-deletion --key-id "$k" --query DeletionDate --output text
2026-11-22T01:10:57.047905-03:00
ana@laptop:~/aws$ aws kms describe-key --key-id alias/clinic-records --query KeyMetadata.KeyState --output text
PendingDeletion
ana@laptop:~/aws$ aws kms decrypt --ciphertext-blob fileb://note.enc --query Plaintext --output text | base64 -d; echo
door code: 4471
ana@laptop:~/aws$ aws kms cancel-key-deletion --key-id "$k" --output text
3dc44faa-5788-45db-b010-8787db7bf058
ana@laptop:~/aws$ aws kms describe-key --key-id alias/clinic-records --query KeyMetadata.KeyState --output text
Disabled
```

A data está trinta dias à frente. Durante a espera, a AWS recusa todo uso da chave com
`KMSInvalidStateException`, e esse é o ponto da espera: **tudo o que ainda depende da chave quebra
agora, ruidosamente, enquanto a exclusão ainda pode ser cancelada**. O moto decifrou o bilhete de
novo, então essa recusa, como os limites de 7 a 30 dias, vem da documentação e não de uma execução.
O cancelamento é a última linha, e ele deixa a chave desativada em vez de ativada, como a AWS também
faz: alguém precisa decidir religá-la.

## O que quem defende vigia

Três chamadas sobre uma chave merecem um alarme próprio, lido dos logs da aula 15: `DisableKey`,
`ScheduleKeyDeletion` e `PutKeyPolicy`. As duas primeiras podem tornar os prontuários da clínica
ilegíveis para a própria clínica, e a terceira pode torná-los legíveis para outra pessoa. **Uma chave
de administrador roubada que agenda a exclusão de toda chave gerenciada pelo cliente de uma conta é um
jeito de manter dados como reféns sem tocar nos dados**, e os trinta dias são o tempo que os donos da
conta têm para perceber. Eles só percebem se alguém estiver vigiando esse nome de evento.
