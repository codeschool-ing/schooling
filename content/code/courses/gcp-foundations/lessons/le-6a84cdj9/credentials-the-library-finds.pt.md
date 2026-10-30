---
title: As credenciais que uma biblioteca acha
version: 1
---

**O `publish.py` não nomeia credencial nenhuma, e isso é o desenho.** Toda biblioteca cliente do Google procura
credenciais na mesma ordem, chamada **Application Default Credentials**, ADC, e pega a primeira que acha:

1. **`GOOGLE_APPLICATION_CREDENTIALS`**, uma variável de ambiente nomeando um arquivo de credencial: o arquivo de
   federação da lição 9, ou, onde não houver nada melhor, uma chave de conta de serviço, lição 8;
2. **o arquivo que o `gcloud auth application-default login` escreve**, `application_default_credentials.json` no
   diretório do gcloud, que é a credencial de uma pessoa emprestada aos programas que ela roda;
3. **o servidor de metadados**, `169.254.169.254`, quando o programa roda no Google Cloud: uma máquina, um serviço
   do Cloud Run, uma função, cada um respondendo com um token para a conta de serviço presa a ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l24-adc\" aria-label=\"Um programa chama uma biblioteca cliente, que procura credenciais numa ordem fixa e pega a primeira que acha. Primeiro, a variável de ambiente GOOGLE_APPLICATION_CREDENTIALS nomeando um arquivo, que num CI é um arquivo de federação e em último caso uma chave de conta de serviço. Segundo, o arquivo que o gcloud auth application-default login escreve, que num laptop é a credencial da própria pessoa. Terceiro, o servidor de metadados em 169.254.169.254, que no Google Cloud responde pela conta de serviço presa. Se nenhum responde, a biblioteca levanta DefaultCredentialsError, que é o que o laptop do laboratório recebe.\"><defs><marker id=\"l24-adc-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"90.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um programa</text><text x=\"95.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">publish.py</text><rect x=\"240.0\" y=\"20.0\" width=\"460.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1. GOOGLE_APPLICATION_CREDENTIALS</text><text x=\"256.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">CI: um arquivo de federação</text><rect x=\"240.0\" y=\"82.0\" width=\"460.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2. application_default_credentials.json</text><text x=\"256.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um laptop: a pessoa</text><rect x=\"240.0\" y=\"144.0\" width=\"460.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3. 169.254.169.254</text><text x=\"256.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Google Cloud: a conta presa</text><path d=\"M172.0 110.0 L236.0 45.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24-adc-af-ah-phosphor)\"></path><text x=\"470.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nenhum responde: DefaultCredentialsError, como no laptop do laboratório</text><text x=\"360.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o primeiro que responde é usado; o programa não nomeia nenhum</text></svg>", "caption": "A biblioteca procura em três lugares, em ordem; onde ela roda decide o que acha."}
```

O mesmo programa, então, roda como o desenvolvedor num laptop, como a identidade federada do pipeline no CI, e
como a própria conta de serviço em produção, sem mudar uma linha. **O que muda é onde ele roda**, e é lá que mora a
decisão sobre a identidade dele.

## O emulador pula a pergunta

O `publish.py` funcionou na seção anterior sem nenhuma das três: quando o `PUBSUB_EMULATOR_HOST` está definido, a
biblioteca do Pub/Sub não manda credencial nenhuma, porque o emulador não confere nenhuma. Tire a variável, e o
mesmo programa pergunta ao ADC, não acha nada no laptop, e diz isso:

```
ana@laptop:~/gcp$ env -u PUBSUB_EMULATOR_HOST python3 publish.py 2>&1 | tail -1
google.auth.exceptions.DefaultCredentialsError: Your default credentials were not found. To set up Application Default Credentials, see https://cloud.google.com/docs/authentication/external/set-up-adc for more information.
```

**`DefaultCredentialsError`**: nenhuma das três respondeu. O laptop não tem variável, nem arquivo ADC, nem servidor
de metadados. Esse é o estado honesto deste laboratório, e o erro que um programa encontra primeiro em qualquer
máquina nova.

## Apontando o ADC para o arquivo da lição 9

A lição 9 escreveu `~/gcp/federation/credentials.json`, o arquivo que um job de CI usa para trocar o próprio token
pelo do Google. Nomeie-o na variável, e pergunte à biblioteca o que ela acha, sem fazer pedido nenhum:

```
ana@laptop:~/gcp$ GOOGLE_APPLICATION_CREDENTIALS=~/gcp/federation/credentials.json python3 -c 'import google.auth; c, p = google.auth.default(); print(type(c).__module__, type(c).__name__, p)'
google.auth.identity_pool Credentials None
```

**Credenciais `identity_pool`, e nenhum projeto**: a biblioteca reconheceu um arquivo de federação de identidade
de carga de trabalho e montou a credencial que a lição 9 descreveu. O projeto é `None` porque uma identidade
federada não leva nenhum, e é por isso que um programa que confia no ADC deve nomear o seu projeto, como o
`publish.py` faz, em vez de pedir o padrão. Agora rode o programa com ela, contra o Google:

```
ana@laptop:~/gcp$ env -u PUBSUB_EMULATOR_HOST GOOGLE_APPLICATION_CREDENTIALS=~/gcp/federation/credentials.json python3 publish.py 2>&1 | tail -1
google.auth.exceptions.RefreshError: File '/tmp/github-token' was not found.
```

A biblioteca seguiu as instruções do arquivo até o primeiro passo e parou ali: o arquivo diz que o token do próprio
sistema de CI está em `/tmp/github-token`, e num laptop não há nenhum. Num job do GitHub Actions esse arquivo
existe, a troca da lição 9 acontece, e o programa publica como `deployer@`, sem chave em lugar nenhum.

## Qual usar onde

| onde o programa roda | o que o ADC deve achar |
|---|---|
| o laptop de um desenvolvedor | a credencial da própria pessoa, do `gcloud auth application-default login`, ou a impersonação de uma conta de serviço |
| CI fora do Google | um arquivo de federação, lição 9 |
| no Google Cloud | a conta de serviço presa, pelo servidor de metadados; nada a configurar |
| em qualquer lugar, como último recurso | uma chave de conta de serviço no `GOOGLE_APPLICATION_CREDENTIALS`, com os avisos da lição 8 |
