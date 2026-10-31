---
title: Flutter
version: 1
---

**O Flutter é o framework do Google, escrito em Dart.** Uma tela é uma árvore de **widgets**, que fazem o
papel que os componentes do React fazem aqui: descrições imutáveis, reconstruídas quando o estado muda, com o
framework descobrindo o que repintar. O total da semana do planner, como um widget do Flutter, ficaria mais
ou menos assim:

```java
class WeekTotal extends StatelessWidget {
  const WeekTotal({super.key, required this.done, required this.planned});
  final int done;
  final int planned;

  @override
  Widget build(BuildContext context) {
    return Text(
      'This week: $done of $planned minutes done',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
```

*Isto foi escrito para comparar e não foi compilado; este curso não tem as ferramentas do Flutter.* A
semelhança com um componente React não é acaso: o modelo do Flutter veio da mesma ideia.

**O que o próprio renderizador compra.** Cada pixel é do Flutter, então o app fica idêntico em todo
celular, e design próprio, animação e desenho são de primeira classe: não há ponte até uma view nativa para
deixá-los mais lentos. Ele também roda na web e no desktop com o mesmo código.

**O que ele custa.** Um app Flutter não é feito das views da plataforma, então tudo o que a plataforma
acrescenta aos próprios controles, o comportamento mais novo de seleção de texto, um visual novo do
sistema, detalhes de acessibilidade, o Flutter precisa reimplementar, e chega depois. A linguagem é Dart,
que pouca gente conhece antes do Flutter. E o app leva o motor junto, então o menor app é maior que o menor
app React Native.

**Código nativo** é alcançado por *platform channels* ou pelas ligações *FFI* mais novas, o equivalente dos
módulos da aula 17, com Kotlin e Swift do outro lado como aqui.
