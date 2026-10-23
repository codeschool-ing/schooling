---
title: "No pipeline: um diagrama quebrado faz o build falhar"
version: 1
---

**A recompensa dos diagramas como texto é que uma máquina pode verificá-los a cada mudança.** Um
script pequeno que renderiza todos os diagramas do repositório e falha se algum deles não renderizar
transforma *os diagramas estão atualizados* de esperança em regra, que é a função de fitness da
aula 11 aplicada à própria documentação.

## O script

Salve isto como `check-diagrams.sh` na pasta `diagrams`:

```sh
#!/bin/sh
# Render every diagram source in this folder; fail if any of them does not render.
failed=0
for f in *.mmd; do
  npx mmdc --quiet -i "$f" -o "/tmp/check-${f%.mmd}.svg" > /dev/null 2>&1 \
    && echo "ok      $f" || { echo "FAILED  $f"; failed=1; }
done
for f in *.puml; do
  java -jar plantuml-1.2026.9.jar -checkonly "$f" > /dev/null 2>&1 \
    && echo "ok      $f" || { echo "FAILED  $f"; failed=1; }
done
exit $failed
```

Ele percorre os arquivos Mermaid, renderiza cada um num arquivo descartável e informa o resultado;
depois pergunta ao PlantUML, com `-checkonly`, se cada arquivo `.puml` renderizaria, o que é mais
rigoroso que `-syntax`: também recusa um arquivo sem nenhum diagrama completo dentro. Qualquer falha
põe o código de saída em 1, que é o que deixa um pipeline vermelho.

## Rodando

Com os dois arquivos quebrados de antes ainda na pasta, ele falha e diz quais são:

```
ana@vm:~/diagrams$ sh check-diagrams.sh; echo "exit status $?"
FAILED  broken.mmd
ok      ticket.mmd
FAILED  broken.puml
ok      hold.puml
ok      purchase.puml
exit status 1
```

Remova-os, e ele passa:

```
ana@vm:~/diagrams$ rm broken.mmd broken.puml
ana@vm:~/diagrams$ sh check-diagrams.sh; echo "exit status $?"
ok      ticket.mmd
ok      hold.puml
ok      purchase.puml
exit status 0
```

## Num pipeline de verdade

Num repositório, o mesmo script roda como um passo do pipeline de integração contínua que já faz o
build do código: instala as versões fixadas, roda o script e bloqueia o merge quando ele falha. Três
hábitos fazem isso funcionar:

- **Fixe as versões no pipeline também.** O pipeline deve renderizar com exatamente as versões que a
  equipe usa, senão um diagrama que renderiza num notebook falha na CI, ou o contrário.
- **Verifique, e publique o que renderizar.** O mesmo passo pode publicar os SVGs renderizados no
  site de documentação, para que as imagens que as pessoas leem sejam sempre as que as fontes
  descrevem.
- **Falhe no modelo, não só na sintaxe.** Para o Structurizr, `validate` verifica o modelo: relações
  com elementos que não existem, nomes duplicados. É uma verificação mais funda do que a de qualquer
  parser.
