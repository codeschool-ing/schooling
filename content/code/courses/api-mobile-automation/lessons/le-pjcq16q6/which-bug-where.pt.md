---
title: Que defeito aparece onde
version: 1
---

**Antes de escolher onde testar, nomeie o defeito que você teme. A tabela diz então onde ele pode
ser visto.** Quem pergunta "funciona num aparelho real?" pergunta largo demais para receber uma
resposta útil. "O lembrete sobrevive à economia de bateria de um Xiaomi?" tem uma, e ela é um
celular específico.

*Mostra* quer dizer que o defeito aparece como apareceria para um usuário. *Se configurado* quer
dizer que a ferramenta consegue mostrá-lo depois que você a configura para isso, e só tão bem quanto
a imitação. *Esconde* quer dizer que ele não vai aparecer ali de jeito nenhum.

| o defeito | emulador | iOS Simulator | aparelho real |
|---|---|---|---|
| um campo errado da API na tela | mostra | mostra | mostra |
| um layout quebrado numa tela pequena | mostra, qualquer tamanho | mostra, os tamanhos que a Apple lista | só o tamanho daquele celular |
| texto cortado em português | mostra | mostra | mostra |
| HTTP puro recusado pela plataforma | mostra | mostra | mostra |
| o pedido de permissão e o caminho da recusa | mostra | mostra | mostra |
| o app perdendo a lista depois de encerrado em segundo plano | mostra (lição 21) | mostra | mostra |
| uma requisição falhando quando a rede cai | se configurado (lição 22) | se configurado | mostra, do jeito real |
| uma falha quando a memória acaba | se configurado, com menos memória | esconde | mostra num celular com pouca |
| rolagem lenta num celular barato | esconde | esconde | mostra naquele celular |
| um lembrete que nunca dispara numa marca | esconde | não é desta plataforma | só naquela marca |
| uma falha de desenho numa família de GPUs | esconde | esconde | só naqueles celulares |
| ler um QR code com a câmera | se configurado, uma cena desenhada | esconde | mostra |
| uma posição que deriva dentro de casa | esconde | esconde | mostra |
| um app que não instala, assinado errado | não é desta plataforma | esconde | mostra |

Leia a última coluna de cima a baixo e ela diz *mostra* em toda parte, que é o argumento a favor dos
aparelhos reais. Leia as seis primeiras linhas de lado e o emulador e o simulador também dizem
*mostra*. Esse é o argumento para fazer a maior parte do trabalho neles: **essas linhas são a maioria
dos defeitos que uma equipe encontra**. Elas são encontradas mais rápido onde um aparelho volta ao
estado inicial num segundo.

## Relatando um defeito de um aparelho

Quando um defeito só aparece num celular real, o relatório precisa dizer qual celular, porque a
próxima pessoa vai tentar em outro e não ver nada. `manual-testing` ensinou o formato de um
relatório de defeito. Para um aparelho ele leva o fabricante, o modelo, a versão do Android e o build
do app. No Android tudo isso está em *Configurações › Sobre o telefone*, e o adb lê de um celular
conectado sem ninguém digitar:

```sh
adb shell getprop ro.product.manufacturer
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.build.fingerprint
```

A última nomeia o build exato do Android do fabricante, que é o que decide se o próximo celular do
mesmo modelo se comporta igual. Esses comandos precisam de um aparelho. A máquina de gravação não
tinha nenhum, então as respostas deles não aparecem. Num iPhone os mesmos dados estão em *Ajustes ›
Geral › Sobre*.
