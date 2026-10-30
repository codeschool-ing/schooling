---
title: Lanes que chegam às lojas
version: 1
---

**As actions de loja do Fastlane falam com as APIs das próprias lojas, e cada uma precisa de uma
credencial que não é a senha de uma pessoa.** Nada nesta seção foi rodado para este curso: ela
precisa de uma conta no Play Console, de uma conta de desenvolvedor Apple ou das duas. Ela foi lida
na documentação do Fastlane e nas páginas de API das lojas, outubro de 2026.

## As credenciais

| loja | o que o Fastlane usa | de onde vem |
|---|---|---|
| Google Play | uma **chave de conta de serviço**, um arquivo JSON | criada no Google Cloud e com acesso ao app dado no Play Console, com as permissões da lição 3 |
| App Store Connect | uma **chave de API**, um arquivo `.p8` com um key ID e um issuer ID | criada pelo Account Holder ou por um Admin no App Store Connect, com um papel próprio |

As duas são segredos do pipeline, exatamente como o keystore da lição 10, e as duas merecem o
**menor papel que faz o trabalho**: uma chave que envia para faixas de teste não precisa liberar
para produção.

## A ficha, enviada a partir de arquivos

O `upload_to_play_store` lê uma pasta por idioma com `title.txt`, `short_description.txt`,
`full_description.txt` e uma pasta `changelogs` de notas de versão com o nome do version code. Isso
é o `listing/android/en-US` da lição 4 com uma pasta a mais. O `upload_to_app_store` lê `name.txt`,
`subtitle.txt`, `keywords.txt`, `description.txt`, `release_notes.txt` e o resto, por idioma: o
`listing/ios/en-US` da lição 4. **Os arquivos escritos e conferidos na lição 4 são os arquivos que o
Fastlane manda**, e é por isso que aquela lição os manteve na organização do Fastlane.

## Capturas a partir de testes

O `capture_ios_screenshots`, conhecido como **snapshot**, roda testes de UI do Xcode numa lista de
simuladores e idiomas e salva uma captura onde o teste chamar `snapshot("01-week")`. O
`capture_android_screenshots`, conhecido como **screengrab**, faz o mesmo com testes instrumentados
num emulador. Os dois gravam as imagens nas pastas que as actions de envio leem. *Eles precisam de
um simulador ou de um emulador e não foram rodados aqui; o script da lição 4 confere o tamanho do que
eles produzirem.*

## Promover, e não gerar de novo

A regra da lição 7 tem uma action:

```
lane :promote do
  upload_to_play_store(track: "internal", track_promote_to: "alpha",
                       json_key: ENV.fetch("PLAY_JSON_KEY"), skip_upload_aab: true)
end
```

Ela não envia nada e move o release que uma pessoa escolheu de uma faixa para a seguinte. A API do
Google chama a faixa fechada padrão de `alpha` e a aberta de `beta`, e é por isso que a lane diz
`alpha` onde o console diz teste fechado. No iOS, o
build que já está no TestFlight é o que o `upload_to_app_store` envia para revisão quando recebe o
número do build em vez de um arquivo novo.
