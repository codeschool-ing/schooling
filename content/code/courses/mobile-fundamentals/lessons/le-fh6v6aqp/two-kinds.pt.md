---
title: Dois tipos de link, e quem pode responder a cada um
version: 1
---

**Um deep link é um link que abre uma tela específica dentro de um app, e existem dois tipos: um com o
esquema próprio do app, e um endereço `https` comum que o app provou ser seu.** O primeiro se parece com
`planner://course/sql`, o segundo com `https://planner.example.com/course/sql`. Os dois podem deixar a
aluna na mesma tela. Eles diferem em quem pode responder a eles, e no que acontece quando o app não
está lá.

## Um esquema próprio: fácil, e de qualquer um

**Um app declara um esquema seu, e o sistema lhe entrega todo link que começa com ele.** O planner diz
que trata `planner:`, e um toque em `planner://course/sql` numa conversa abre o planner. Nada precisa
existir na web, e é por isso que um esquema próprio é a primeira coisa que a maioria dos apps tenta.

**O problema é que a reivindicação não é conferida.** Qualquer app pode declarar `planner:` também. A
documentação da Apple sobre esquemas de URL próprios diz que um nome em DNS reverso "não impede que
outros apps registrem o mesmo esquema e tratem os links associados", e recomenda universal links no
lugar. A documentação do Android sobre deep links diz que um esquema próprio ainda pode fazer aparecer
o *diálogo de desambiguação*, a lista "abrir com" do sistema, quando outro app registra o mesmo. De um
jeito ou de outro, um link que o planner envia pode abrir o app de outra pessoa, e a aluna não é
avisada.

**A mesma página da Apple acrescenta a regra em que o parser desta aula se apoia: um link é entrada
vinda de fora.** Ela pede para validar todo parâmetro, descartar links malformados e limitar o que um
link pode fazer a ações que não põem em risco nenhum dado da pessoa. Um link abre uma tela. Ele nunca
apaga um curso nem envia nada para lugar nenhum, seja quem for que o montou.

## Um link verificado: um endereço web que o site garante

**Um link verificado é uma URL `https` comum, mais um arquivo naquele site que nomeia o app autorizado a
abri-la.** No Android eles são *App Links*, e no iOS *universal links*. Quando o app é instalado, o
sistema busca o arquivo no domínio e o confere com o app; só se baterem um toque no endereço abre o app
diretamente. Qualquer um pode reivindicar `planner:`, mas só quem controla `planner.example.com`
consegue pôr um arquivo lá.

A metade do app é uma declaração de qual domínio ele quer dizer. No Android é um intent filter no
manifest, com `autoVerify` pedindo ao sistema que confira o site:

```xml
<!-- AndroidManifest.xml: the planner claims its own website's links -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="http" />
    <data android:scheme="https" />
    <data android:host="planner.example.com" />
</intent-filter>
```

No iOS é a capability Associated Domains, acrescentada no Xcode, que escreve uma entrada por domínio
nos entitlements do app no formato `<service>:<domain>`. Para universal links o serviço é `applinks`,
então a entrada do planner é `applinks:planner.example.com`. Os dois fragmentos seguem a documentação
de cada plataforma, e **nenhum foi construído nem rodado num aparelho para este curso**: não há SDK do
Android nem Mac na máquina em que ele foi gravado. A metade do site, os dois arquivos, é a parte que
esta aula roda de fato, numa seção mais adiante.

| | esquema próprio | link verificado |
|---|---|---|
| tem esta cara | `planner://course/sql` | `https://planner.example.com/course/sql` |
| quem pode reivindicá-lo | qualquer app que o declare | só um app que o arquivo do site nomeie |
| app não instalado | o link não leva a lugar nenhum | o navegador abre a página web |
| nome no Android | um deep link | um App Link, desde o Android 6 |
| nome no iOS | um esquema de URL próprio | um universal link |

**No Android 12 e mais novos, um link web não verificado abre o navegador.** A documentação do Android
sobre deep links, lida em 30 de outubro de 2026, diz que um intent web só chega a um app se o app
estiver aprovado para aquele domínio, e senão vai para o navegador padrão da pessoa. Então um app que
declara `https://planner.example.com` sem um arquivo válido no site não recebe os links dele; recebe o
mesmo tratamento de um app que nunca pediu.

**A verificação também é o motivo de os dois tipos envelhecerem de jeitos diferentes.** Um esquema
próprio continua funcionando do mesmo jeito enquanto o app estiver instalado. Um link verificado
depende de um arquivo que alguém precisa continuar servindo, num domínio que alguém precisa continuar
renovando, e a seção sobre os dois arquivos mostra o que as plataformas conferem quando o buscam.
