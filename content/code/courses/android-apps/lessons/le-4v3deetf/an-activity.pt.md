---
title: Uma activity é uma janela que o sistema empresta
version: 1
---

**Você nunca cria uma activity.** Quem cria é o sistema. Quando alguém toca no ícone do planner, o
Android lê o manifesto, acha a activity cujo `<intent-filter>` diz `LAUNCHER`, faz uma instância
daquela classe com o construtor dela, e depois chama métodos nela conforme as coisas acontecem com a
tela. O seu código roda dentro dessas chamadas e em nenhum outro lugar. Uma activity é hóspede do
sistema, e as chamadas são como o sistema conta a ela o que está acontecendo.

Essas chamadas se chamam **callbacks do ciclo de vida**: `onCreate`, `onStart`, `onResume`,
`onPause`, `onStop` e `onDestroy`, mais `onSaveInstanceState`, que a seção 04 vai usar. Para
observá-las, a `MainActivity` da aula 1 ganha uma linha de log em cada uma:

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/MainActivity.kt", "parts": [
{"code": "package com.example.planner\n\nimport android.os.Bundle\nimport android.util.Log\nimport androidx.activity.ComponentActivity\nimport androidx.activity.compose.setContent\nimport androidx.compose.material3.MaterialTheme\nimport androidx.compose.material3.Surface\nimport androidx.compose.material3.Text\nimport androidx.compose.ui.res.stringResource\n\nprivate const val TAG = \"Lifecycle\"", "note": "`Log.d` escreve no log do sistema, que o `adb logcat` lê num celular. A tag é o rótulo pelo qual filtrar."},
{"code": "object ProcessWide {\n    var created = 0\n}", "note": "Um `object` do Kotlin vive enquanto o processo vive. Ele conta quantas activities este processo criou, e a seção 05 precisa disso."},
{"code": "class MainActivity : ComponentActivity() {\n    override fun onCreate(savedInstanceState: Bundle?) {\n        super.onCreate(savedInstanceState)\n        ProcessWide.created++\n        Log.d(TAG, \"onCreate: instance ${ProcessWide.created} in this process, saved state: ${savedInstanceState != null}\")\n        setContent {\n            MaterialTheme {\n                Surface {\n                    Text(stringResource(R.string.welcome))\n                }\n            }\n        }\n    }", "note": "`onCreate` roda uma vez por instância. `savedInstanceState` é nulo num início do zero, e é um `Bundle` quando o sistema está reconstruindo uma activity que ele mesmo destruiu. Todo callback precisa chamar `super`, ou o framework lança `SuperNotCalledException`."},
{"code": "    override fun onStart() { super.onStart(); Log.d(TAG, \"onStart\") }\n    override fun onResume() { super.onResume(); Log.d(TAG, \"onResume\") }\n    override fun onPause() { Log.d(TAG, \"onPause\"); super.onPause() }\n    override fun onStop() { Log.d(TAG, \"onStop\"); super.onStop() }", "note": "Quatro chamadas em dois pares: visível e invisível, na frente e não. As que descem registram antes do `super`, para o log ficar na ordem em que as coisas acontecem."},
{"code": "    override fun onSaveInstanceState(outState: Bundle) {\n        super.onSaveInstanceState(outState)\n        Log.d(TAG, \"onSaveInstanceState\")\n    }\n\n    override fun onDestroy() {\n        Log.d(TAG, \"onDestroy: finishing $isFinishing, configuration change $isChangingConfigurations\")\n        super.onDestroy()\n    }\n}", "note": "`isFinishing` diz que a activity está indo embora de vez; `isChangingConfigurations` diz que o sistema vai criar outra logo em seguida. A seção 04 mostra o segundo caso."}
]}
```

**`ComponentActivity` é a classe a estender.** A `Activity` do próprio Android é a base de tudo, e
`androidx.activity` acrescenta por cima o que o código moderno precisa: um objeto `Lifecycle` que
outro código pode observar, o botão voltar como callback, o `setContent` do Compose e o mecanismo de
estado salvo de que o `ViewModel` da aula 10 depende. Projetos mais antigos estendem
`AppCompatActivity`, que acrescenta a barra de ferramentas e os temas de antes do Compose sobre a
mesma classe; um app em Compose não precisa dela.

## Três coisas que uma activity não é

**Ela não é o app.** Um app é um processo, e uma activity é um objeto dentro dele; um app pode ter
várias activities, ou nenhuma na tela enquanto continua rodando. A seção 05 é sobre o processo.

**Ela não é algo que você chama.** Escrever `MainActivity()` no seu código compila, e entrega um
objeto do qual o sistema não sabe nada: sem janela, sem ciclo de vida, e uma falha na primeira vez
que ele tocar em qualquer um dos dois. Iniciar uma activity é um pedido ao sistema, o assunto da
seção 07.

**Ela não é onde os dados moram.** O sistema destrói e reconstrói activities quando quer, a seção 04
mostra com que frequência, e tudo o que fica só nos campos de uma activity vai junto. A aula 10 tira
os dados do planner dali.
