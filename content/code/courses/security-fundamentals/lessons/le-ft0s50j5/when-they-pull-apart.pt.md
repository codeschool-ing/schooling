---
title: Quando as três puxam em sentidos opostos
version: 1
---

Seria cômodo se todo controle deixasse as três propriedades mais fortes. **Muitos controles compram
uma propriedade com outra**, e o iniciante que não enxerga a troca acaba defendendo o vértice do
triângulo para o qual por acaso está olhando.

```schooling-figure
{"svg": "<svg id=\"sf-tradeoffs\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três tensões entre as propriedades. Cifrar o banco protege a confidencialidade e deixa a disponibilidade dependendo de uma chave. Guardar mais cópias protege a disponibilidade e dá à confidencialidade mais lugares para falhar. Bloquear uma conta depois de três senhas erradas protege a confidencialidade e deixa qualquer um que saiba o nome de usuário tornar aquela conta indisponível.\"><text x=\"20\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o controle</text><text x=\"270\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o que compra</text><text x=\"500\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o que pode custar</text><rect x=\"20\" y=\"34\" width=\"220\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cifrar o banco</text><rect x=\"260\" y=\"34\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">protege a confidencialidade</text><rect x=\"490\" y=\"34\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">perdeu a chave, perdeu os dados</text><path d=\"M240 56 L260 56\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M470 56 L490 56\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><rect x=\"20\" y=\"104\" width=\"220\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">guardar cinco cópias</text><rect x=\"260\" y=\"104\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">protege a disponibilidade</text><rect x=\"490\" y=\"104\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cinco lugares de onde vazar</text><path d=\"M240 126 L260 126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M470 126 L490 126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><rect x=\"20\" y=\"174\" width=\"220\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bloquear após 3 senhas erradas</text><rect x=\"260\" y=\"174\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">protege a confidencialidade</text><rect x=\"490\" y=\"174\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">qualquer um pode trancar você fora</text><path d=\"M240 196 L260 196\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M470 196 L490 196\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path></svg>", "caption": "Um controle que protege uma propriedade pode custar outra. A pergunta de projeto é qual custo é aceitável."}
```

Três casos que aparecem o tempo todo:

**Criptografia e disponibilidade.** Cifrar o banco de pedidos faz um disco roubado ser inútil para
o ladrão, o que protege a confidencialidade. Também faz a loja precisar da chave toda vez que lê
os próprios dados. Perca a chave, ou deixe um ransomware cifrar a única cópia dela, e a loja se
trancou para fora tão bem quanto qualquer atacante faria. Cifrar continua sendo a decisão certa;
só muda o problema para **manter a chave disponível**, e alguém precisa ser dono desse problema.

**Cópias e confidencialidade.** A disponibilidade gosta de cópias: um backup, uma réplica, um
notebook reserva com os arquivos. Cada cópia também é mais um lugar de onde os dados podem vazar.
O HD de backup na gaveta tem a mesma lista de clientes que o banco, e em geral muito menos proteção
em volta. A aula 12 trata de backups que dão para restaurar e ao mesmo tempo estão protegidos.

**Bloqueio e disponibilidade.** Bloquear uma conta depois de três senhas erradas protege a
confidencialidade contra quem tenta adivinhar. Também dá a qualquer um que saiba um nome de usuário
um jeito de trancar o dono para fora, de propósito e quantas vezes quiser. É por isso que muitos
sistemas desaceleram falhas repetidas em vez de bloquear de vez, e por isso a aula 9 prefere um
segundo fator a um bloqueio mais rígido.

### Qual propriedade pesa mais depende da informação

Não existe ordem fixa. A tríade fica útil quando você ordena as três **para uma informação
específica**, porque essa ordem diz qual troca aceitar:

| informação na livraria | primeira preocupação | por quê |
|---|---|---|
| a lista de clientes | confidencialidade | um vazamento prejudica os clientes e viola a lei (aula 17) |
| a lista de preços | integridade | ela já é pública; um preço errado custa dinheiro em cada venda |
| a página inicial da loja | disponibilidade | é pública por projeto; fora do ar, nada vende |
| a folha de pagamento | confidencialidade, depois integridade | um vazamento constrange; um salário alterado é fraude |

Repare na lista de preços. A confidencialidade dela não vale quase nada, já que todo visitante vê
os preços, então gastar dinheiro para escondê-la seria desperdício. A integridade dela vale muito.
**O mesmo arquivo pode ser público e crítico ao mesmo tempo**, e a tríade é o que permite dizer
isso com precisão, em vez de chamá-lo de "sensível" e tratá-lo como todo o resto.

Essa ordem é o primeiro passo de toda avaliação de risco das aulas 2 e 3. A informação é
classificada pelo que a perda dela custaria em cada propriedade, e os controles saem da
classificação, e não do hábito.
