---
title: As primeiras lanes, rodadas no seu computador
version: 1
---

**Um Fastfile é Ruby, mas se lê como uma lista**: lanes, e dentro de cada lane as actions na ordem
em que rodam. O Fastlane o procura numa pasta chamada `fastlane` no projeto, e roda cada lane **de
dentro dessa pasta**, que é o detalhe que pega todo mundo uma vez: um caminho numa lane é relativo a
`fastlane/`, e não ao projeto.

## O Fastfile do planner

Salve isto como `Fastfile` em `~/planner/fastlane`:

```
# Fastfile: the planner's lanes. Fastlane runs each lane from inside the fastlane folder.
default_platform(:android)

desc "Every check that runs without a store: lessons 2, 4, 5 and 6"
lane :checks do
  sh("cd .. && node preflight.ts")
end

platform :android do
  desc "Check, then upload the signed bundle and the listing to the internal track"
  lane :internal do
    checks
    upload_to_play_store(
      track: "internal",
      aab: ENV.fetch("AAB"),
      json_key: ENV.fetch("PLAY_JSON_KEY"),
      metadata_path: "../listing/android",
      skip_upload_screenshots: true
    )
  end
end

platform :ios do
  desc "Check, then build, sign and send to TestFlight"
  lane :beta do
    checks
    match(type: "appstore", readonly: true)
    build_app(scheme: "Planner", export_method: "app-store")
    upload_to_testflight(skip_waiting_for_build_processing: true)
  end
end
```

O `lanes` lista o que o arquivo define, com cada `desc` ao lado da lane dele. Ele lê o arquivo e não
roda nada, então funciona no Linux para as lanes iOS também:

```
ana@dev:~/planner$ bundle exec fastlane lanes
------------------------------
--- Step: default_platform ---
------------------------------

--------- general---------
----- fastlane checks
Every check that runs without a store: lessons 2, 4, 5 and 6


--------- android---------
----- fastlane android internal
Check, then upload the signed bundle and the listing to the internal track


--------- ios---------
----- fastlane ios beta
Check, then build, sign and send to TestFlight

Execute using `fastlane [lane_name]`
```

## Rodando as checagens

A `checks` roda a barreira da lição 6. O planner ainda tem os dois problemas que aquela lição
deixou, então a lane deveria parar. A saída de uma lane que falha é longa, com uma tabela de resumo
e uma pilha de chamadas; o comando abaixo imprime a parte do passo até o resultado dele, e depois o
status de saída do próprio Fastlane:

```
ana@dev:~/planner$ bundle exec fastlane checks 2>&1 | sed -n '/Step: cd/,/reason(s)/p'; echo "exit status ${PIPESTATUS[0]}"
--- Step: cd .. && node preflight.ts ---
----------------------------------------
$ cd .. && node preflight.ts
STOP  store listing within limits
go    privacy inventory complete
STOP  no certificate expiring within 30 days
go    api https://api.planner.example is production
go    debug menu is off
go    review notes carry a demo account
2 reason(s) to stop before submitting 1.4.0 (42)
exit status 1
```

**A lane parou na barreira, e o status de saída dela é 1**, que é o que o pipeline da lição 10 lê.
Uma lane que chama `checks` primeiro, como a `internal` e a `beta`, nunca chega ao envio enquanto a
barreira diz pare, e esse é todo o motivo de a barreira ter sido escrita como um script com status
de saída.

## Rodando uma lane de uma plataforma

Uma lane dentro de `platform :android` roda como `bundle exec fastlane android internal`. Ela pararia
na `checks` aqui pelo mesmo motivo, e depois dela precisa de duas coisas que este curso não tem: um
bundle assinado em `AAB` e uma chave de conta de serviço do Google Play em `PLAY_JSON_KEY`. O
`ENV.fetch` faz a lane se recusar a começar sem elas, com um erro nomeando a variável que falta, em
vez de não enviar nada em silêncio.
