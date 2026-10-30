---
title: No que agir primeiro
version: 1
---

**A ordem é dada pelo que um atacante conseguiria alcançar, e não pelo tamanho da lista nem pelos pontos.** Toda recomendação
tem uma **severidade** do Defender, e a severidade sozinha não basta: um achado de severidade alta numa VM de teste sem caminho
de rede para nada é menos urgente que um médio no banco por trás do checkout. A loja ordena por três perguntas, nesta ordem:

1. **Dá para alcançar pela internet?** Um recurso com endpoint público é onde um ataque começa.
2. **O que ele guarda ou alcança?** Dados de clientes, segredos, ou a identidade que muda a produção.
3. **Há um jeito conhecido de entrar?** Uma vulnerabilidade com exploit publicado, uma chave que nunca expira, uma regra
   aberta para `0.0.0.0/0`.

Um achado que responde sim às três vai primeiro, sejam quais forem os pontos. **A análise de caminhos de ataque do Defender
CSPM** é esse raciocínio feito pela ferramenta: ela monta um grafo de recursos, identidades e caminhos de rede e mostra as
cadeias que levam da internet a algo sensível. Onde o plano pago está ligado, essa lista é o ponto de partida da loja; onde
não está, as três perguntas são.

Um exemplo, escrito pelo curso, de como a loja ordenaria quatro achados:

| achado | alcançável | guarda | jeito de entrar | ordem |
|---|---|---|---|---|
| a conta `stshopexports` permite acesso público a blobs | sim | exportações de pedidos | leitura anônima | 1 |
| o firewall do SQL `sql-shop` permite serviços do Azure | indiretamente | dados de clientes | o app de qualquer tenant do Azure | 2 |
| o Key Vault `kv-shop-prod` sem proteção contra purga | não | segredos | deleção, não roubo | 3 |
| a VM `vm-reports` sem proteção de endpoint | não | nada sensível | nenhum conhecido | 4 |

Dois desdobramentos fazem a ordem durar. **Conserte o template, não o recurso**: uma recomendação consertada à mão no portal
volta com o próximo deploy, então a correção vai para o Bicep, e as lições 17 e 20 fazem exatamente isso com o cofre e o
banco. E **use o Azure Policy para impedir o próximo**: depois de consertado o acesso público a blobs, uma política que o nega
o mantém consertado. A lição 24 escreve uma política.
