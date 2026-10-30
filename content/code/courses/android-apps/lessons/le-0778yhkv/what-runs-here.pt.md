---
title: O que este curso roda, e a parte que precisa de um celular
version: 1
---

**Quase tudo neste curso roda num computador Linux sem nenhum celular conectado**, e é melhor saber
agora quais partes não rodam do que descobrir na aula 18. Um app Android é compilado, testado e
inspecionado por programas que rodam no seu computador: o plugin Android do Gradle, os compiladores,
os executores de teste. Só *rodar* o app, e vê-lo numa tela que dá para tocar, precisa de um
aparelho Android, real ou emulado.

O curso foi gravado num computador que não conseguia iniciar um emulador. Um emulador é uma máquina
virtual e, no Linux, precisa que a virtualização do processador esteja acessível por `/dev/kvm`. Na
máquina de gravação ela não estava:

```
ana@vm:~$ ls -l /dev/kvm
ls: cannot access '/dev/kvm': No such file or directory
```

**Digite o mesmo comando no seu computador.** Se ele imprimir uma linha começando com `crw`, a
virtualização do seu processador está ligada e um emulador pode rodar; a seção 03 diz o que
instalar para isso. Se imprimir o que você vê acima, ou a opção está desligada no firmware do
computador, ou você está dentro de uma máquina virtual que não a repassa. Um celular com cabo USB
faz o mesmo papel e não precisa de nenhuma das duas coisas.

## Como este curso mostra uma tela sem celular

Duas ferramentas desenham um composable no seu computador, sem aparelho e sem emulador, e este curso
usa as duas:

- O **Robolectric** roda o framework do Android dentro de um teste comum na JVM, e o **Roborazzi**
  salva o que um composable desenhou ali como PNG. Toda captura de tela deste curso é um PNG que um
  desses testes gravou, e a aula 21 explica como elas se mantêm honestas.
- **`android preview render`**, um comando da Android CLI do Google, renderiza numa imagem uma função
  marcada com `@Preview`. A aula 3 usa esse comando.

**O que elas entregam é o desenho, não o aparelho.** Mostram o layout, as cores, o texto e o que
muda quando um teste clica num botão. Não mostram como o app responde ao polegar, quão rápido ele
abre num celular barato, nem o que o sistema faz quando mata o processo. Onde essa diferença
importa, a aula avisa.

## Aula por aula

| aula | o que ela precisa além do seu computador |
|---|---|
| 1 a 17 | nada: build, testes de unidade, testes de Compose e capturas rodam todos na JVM |
| 2 e 10, o processo sendo morto | um aparelho ou emulador para ver acontecer; as aulas mostram em testes e descrevem o caso real |
| 18, WorkManager | um aparelho para ver o trabalho sobreviver a uma reinicialização; a aula roda o trabalho em testes |
| 19 e 20, notificações e permissões | um aparelho ou emulador para ver a caixa de diálogo do sistema e a gaveta de notificações |
| 21, testes instrumentados | um aparelho ou emulador para o `connectedAndroidTest`; a aula roda os mesmos testes no Robolectric |
| 22, a publicação | uma conta de desenvolvedor no Google Play, que é paga, para enviar; tudo até o bundle assinado roda no seu computador |

**Sem aparelho você ainda faz todas as aulas.** As partes da tabela são lidas como material, e não
praticadas, e cada uma está marcada onde aparece com **não executado**, a documentação de onde vem e
nenhuma transcrição. Nada neste curso mostra uma saída que não tenha sido produzida por uma máquina.

## O que este curso não conseguiu rodar

Para ser exato, estes passos não foram executados quando o curso foi gravado, e são descritos a
partir da documentação do Google:

- **o emulador**, pelo motivo acima, e portanto nada instalado ou aberto nele;
- **um celular de verdade pelo `adb`**, porque o computador de gravação não tinha nenhum conectado;
- **testes instrumentados** com `./gradlew connectedAndroidTest`, que precisam de um dos dois;
- **o Android Studio**, cuja janela é um programa de desktop; o curso trabalha num terminal e num
  editor, e a seção 03 diz onde o Studio entra, se você preferir;
- **o Play Console**, que precisa de uma conta paga e de uma pessoa aceitando os termos.

Todos os outros comandos de uma transcrição foram executados, e a saída está colada como voltou.
