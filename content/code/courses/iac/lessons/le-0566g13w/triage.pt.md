---
title: Triagem, e o que deve quebrar o build
version: 1
---

O relatório de um scanner é uma lista de fatos sobre o texto, e a lista é longa. Depois das supressões
e da variável, é assim que os três estão:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact | sed -n 3p
Passed checks: 23, Failed checks: 9, Skipped checks: 3
ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep "^Failures"
Failures: 10 (UNKNOWN: 0, LOW: 3, MEDIUM: 2, HIGH: 5, CRITICAL: 0)
ana@laptop:~/shop$ tfsec --no-colour . 2> /dev/null | tail -n 2
  3 passed, 12 potential problem(s) detected.
```

Nove, dez e doze achados sobre uma VPC, uma sub-rede, um security group, um bucket e um volume. Um
pipeline que falha por qualquer achado falha em todo pull request, e um check que sempre falha é
desligado em uma semana. **Triagem é decidir quais achados impedem um merge**, e o scanner não faz isso
por você, porque a única coisa que ele não conhece é o seu sistema.

## Severidade não é exposição

Olhe duas linhas da lista do Trivy na seção dele. `AWS-0107`, SSH aberto para qualquer endereço, é
`HIGH`. `AWS-0132`, um bucket que não é criptografado com uma chave gerida pela própria loja, também é
`HIGH`. O primeiro é uma porta que atende qualquer um na internet, em todo servidor que um dia entrar
no grupo. O segundo é a escolha de chave para fotos que o site da loja mostra a todo visitante de
qualquer jeito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Um gráfico com dois eixos. Na horizontal, a severidade que a regra atribui: LOW, MEDIUM, HIGH. Na vertical, a exposição do recurso. Seis achados do Trivy sobre a loja estão nele. AWS-0107, SSH aberto para qualquer endereço, é HIGH e está no alto. AWS-0086, sem bloqueio de acesso público, é HIGH e está no meio. AWS-0132, sem chave gerida pelo cliente num bucket de fotos de produtos, também é HIGH e está perto do chão. AWS-0090, sem versionamento, e AWS-0178, sem flow logs, são MEDIUM e baixos. AWS-0089, sem log de acesso, é LOW e está no chão.\"><defs><marker id=\"tg-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M110 262 L110 24\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tg-ah-wire)\"></path><path d=\"M110 262 L700 262\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tg-ah-wire)\"></path><text x=\"122.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">exposição</text><text x=\"100.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alta</text><text x=\"100.0\" y=\"236.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">baixa</text><text x=\"220.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">LOW</text><text x=\"400.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MEDIUM</text><text x=\"580.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HIGH</text><text x=\"400.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a severidade que a regra atribui</text><rect x=\"505\" y=\"43\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">AWS-0107</text><text x=\"580.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">SSH de qualquer endereço</text><rect x=\"505\" y=\"121\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0086</text><text x=\"580.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem bloqueio público</text><rect x=\"505\" y=\"199\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0132</text><text x=\"580.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem chave própria, fotos</text><rect x=\"325\" y=\"157\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0090</text><text x=\"400.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem versionamento</text><rect x=\"325\" y=\"209\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0178</text><text x=\"400.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem flow logs</text><rect x=\"145\" y=\"209\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0089</text><text x=\"220.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem log de acesso</text></svg>", "caption": "A severidade é a estimativa de quem escreveu a regra para qualquer recurso daquele tipo. A exposição é o que você sabe sobre este, e dois achados HIGH podem ficar em pontas opostas dela.", "same": ["LOW", "MEDIUM", "HIGH"]}
```

**A severidade é a estimativa de quem escreveu a regra para qualquer recurso daquele tipo**, feita antes
de o seu recurso existir. **A exposição é o que você sabe sobre este**: se dá para alcançá-lo pela
internet, o que ele guarda, o que um atacante ganha com ele. Um achado alto nos dois eixos é o que se
corrige antes do merge. Um alto em severidade e baixo em exposição é uma decisão a registrar, que é o
que foram as supressões da seção 06.

## Quando uma regra está simplesmente errada

Um dos resultados do tfsec diz *Bucket does not have encryption enabled*. O check do Checkov para a
mesma propriedade aprova o bucket:

```
ana@laptop:~/shop$ checkov -d . --skip-download --compact --check CKV_AWS_19 | grep -A1 assets
	PASSED for resource: aws_s3_bucket.assets
	File: /main.tf:45-49
```

e o Trivy ainda carrega o check, mas só como obsoleto, relatado quando se pede:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q --include-deprecated-checks . | grep -E "^AWS-008[89]"
AWS-0088 (HIGH): Bucket does not have encryption enabled
AWS-0089 (LOW): Bucket has logging disabled
```

Desde janeiro de 2023 o S3 criptografa todo objeto novo por padrão, então um bucket sem nenhuma
configuração de criptografia é criptografado mesmo assim. A regra descreve uma AWS mais antiga. **Esse é
o falso positivo mais comum**: uma regra que era verdade quando foi escrita, aplicada a uma plataforma
que mudou.

## O portão

Um portão é um comando que sai com código diferente de zero. O Trivy aceita uma lista de severidades e
um código de saída, e a resposta depende inteiramente de onde você traça a linha:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q --severity CRITICAL --exit-code 1 . > /dev/null; echo "exit $?"
exit 0
ana@laptop:~/shop$ trivy config --skip-check-update -q --severity HIGH,CRITICAL --exit-code 1 . > /dev/null; echo "exit $?"
exit 1
```

Um portão em `CRITICAL` aprova esta configuração, com as falhas do bucket e tudo, porque o Trivy não
classifica nada aqui como `CRITICAL`. Um portão em `HIGH,CRITICAL` reprova. O Checkov tem a mesma
ideia em `--hard-fail-on`, e offline ela tem uma armadilha:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --hard-fail-on HIGH > /dev/null; echo "exit $?"
exit 0
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --hard-fail-on CKV_AWS_24,CKV2_AWS_6 > /dev/null; echo "exit $?"
exit 1
```

**`--hard-fail-on HIGH` sai com 0.** As severidades do Checkov vêm do download que `--skip-download`
desliga, então nenhum achado é `HIGH`, nada casa, e o portão aprova tudo, em silêncio. Uma lista de ids
de check não tem essa dependência e falha como deve. Se o seu Checkov roda sem a plataforma, use ids no
portão.

## Começar de onde você está

A última peça é como ligar um portão num repositório que já tem achados. Corrigir todos primeiro
significa que o portão nunca chega. Um **baseline** registra os achados de hoje como conhecidos, e daí
em diante só os novos falham:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --create-baseline | tail -n 1
Created a checkov baseline file at /home/ana/shop/.checkov.baseline
```

Então alguém acrescenta um bucket de backups, com todas as lacunas que o bucket de fotos tinha:

```hcl
resource "aws_s3_bucket" "backups" {
  bucket = "shop-backups-123456789012"
}
```

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --baseline .checkov.baseline; echo "exit $?"
terraform scan results:

Passed checks: 0, Failed checks: 7, Skipped checks: 0

Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Baseline analysis report using .checkov.baseline - only new failed checks with respect to the baseline are reported
exit 1
```

Os nove achados antigos nos outros recursos não estão no relatório. Os sete do bucket novo estão, e o
código de saída é 1. **Código novo cumpre as regras; código antigo é uma lista que você vai
esvaziando**, tirando entradas do baseline à medida que as corrige.

Juntando tudo, um portão que a Ana consegue defender é curto. Falhar pelos achados altos nos dois
eixos, citados por id, mais `HIGH` e `CRITICAL` do scanner que tem severidade. Registrar cada exceção em
linha, com um motivo e, quando for uma promessa, uma data. Pôr o resto no baseline e manter o relatório
à vista. A aula 15 coloca esse portão num pipeline, ao lado do plan que ele protege.
