---
title: A curva famosa, e de onde vieram os números
version: 1
---

**Quase todo curso de teste mostra o mesmo gráfico: o custo de corrigir um defeito subindo forte com a
fase em que ele é achado.** Achado nos requisitos custa 1; no projeto, 5; no código, 10; no teste, de 20 a
50; depois da entrega, 100 ou mais. As razões mudam de slide para slide, a forma não, e a conclusão tirada
dela é sempre a mesma: ache os defeitos cedo.

A conclusão é sólida. Os números são bem mais frágeis do que os slides sugerem, e quem testa e os cita
para um gerente cético precisa saber por quê.

## De onde vem a curva

A fonte mais conhecida é **Barry Boehm**, cujo livro *Software Engineering Economics* (1981) reuniu dados de
grandes projetos dos anos 1970, muitos deles para a indústria de defesa dos EUA, construídos em longas
fases sequenciais. Nesses projetos, um requisito corrigido depois da entrega podia significar revisar
documentos, reprojetar interfaces de hardware e recertificar um sistema, e as razões de custo que Boehm
relatou eram grandes.

Vinte anos depois, em 2001, Boehm e Victor Basili publicaram uma lista curta dos dez fatos mais úteis
sobre reduzir defeitos de software. O primeiro item é o que todo mundo cita: achar e corrigir um problema
depois da entrega é **muitas vezes 100 vezes** mais caro do que nos requisitos e no projeto. A frase
seguinte é a que quase ninguém cita: para sistemas **pequenos e não críticos** a razão fica **mais perto de
5 para 1**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 300\" role=\"img\" data-fig=\"l03-two-curves\" aria-label=\"Um gráfico com cinco fases no eixo horizontal: requisitos, projeto, código, teste, depois da entrega. O eixo vertical é o custo relativo de corrigir um defeito, em escala logarítmica de 1 a 100. Uma curva, para um sistema grande e crítico, sobe de 1 a 100. Uma segunda curva, para um sistema pequeno e não crítico, sobe de 1 a 5.\"><path d=\"M80.0 240.0 L560.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M80.0 170.1 L560.0 170.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"170.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M80.0 140.0 L560.0 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M80.0 40.0 L560.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M80.0 40.0 L80.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 240.0 L560.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requisitos</text><text x=\"200.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">projeto</text><text x=\"320.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">código</text><text x=\"440.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">teste</text><text x=\"560.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois da entrega</text><text x=\"80.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">custo relativo da correção, escala log</text><path d=\"M80.0 240.0 L83.0 239.9 L86.0 239.8 L89.0 239.7 L92.0 239.5 L95.0 239.2 L98.0 239.0 L101.0 238.7 L104.0 238.3 L107.0 238.0 L110.0 237.6 L113.0 237.2 L116.0 236.8 L119.0 236.4 L122.0 235.9 L125.0 235.5 L128.0 235.0 L131.0 234.5 L134.0 233.9 L137.0 233.4 L140.0 232.8 L143.0 232.2 L146.0 231.6 L149.0 231.0 L152.0 230.4 L155.0 229.7 L158.0 229.1 L161.0 228.4 L164.0 227.7 L167.0 227.0 L170.0 226.3 L173.0 225.5 L176.0 224.8 L179.0 224.0 L182.0 223.2 L185.0 222.4 L188.0 221.6 L191.0 220.8 L194.0 220.0 L197.0 219.1 L200.0 218.2 L203.0 217.4 L206.0 216.5 L209.0 215.6 L212.0 214.7 L215.0 213.7 L218.0 212.8 L221.0 211.8 L224.0 210.9 L227.0 209.9 L230.0 208.9 L233.0 207.9 L236.0 206.9 L239.0 205.9 L242.0 204.8 L245.0 203.8 L248.0 202.7 L251.0 201.6 L254.0 200.6 L257.0 199.5 L260.0 198.4 L263.0 197.2 L266.0 196.1 L269.0 195.0 L272.0 193.8 L275.0 192.7 L278.0 191.5 L281.0 190.3 L284.0 189.1 L287.0 187.9 L290.0 186.7 L293.0 185.5 L296.0 184.3 L299.0 183.0 L302.0 181.8 L305.0 180.5 L308.0 179.2 L311.0 177.9 L314.0 176.6 L317.0 175.3 L320.0 174.0 L323.0 172.7 L326.0 171.4 L329.0 170.0 L332.0 168.7 L335.0 167.3 L338.0 165.9 L341.0 164.5 L344.0 163.2 L347.0 161.8 L350.0 160.3 L353.0 158.9 L356.0 157.5 L359.0 156.1 L362.0 154.6 L365.0 153.1 L368.0 151.7 L371.0 150.2 L374.0 148.7 L377.0 147.2 L380.0 145.7 L383.0 144.2 L386.0 142.7 L389.0 141.1 L392.0 139.6 L395.0 138.1 L398.0 136.5 L401.0 134.9 L404.0 133.4 L407.0 131.8 L410.0 130.2 L413.0 128.6 L416.0 127.0 L419.0 125.4 L422.0 123.7 L425.0 122.1 L428.0 120.4 L431.0 118.8 L434.0 117.1 L437.0 115.5 L440.0 113.8 L443.0 112.1 L446.0 110.4 L449.0 108.7 L452.0 107.0 L455.0 105.3 L458.0 103.5 L461.0 101.8 L464.0 100.0 L467.0 98.3 L470.0 96.5 L473.0 94.8 L476.0 93.0 L479.0 91.2 L482.0 89.4 L485.0 87.6 L488.0 85.8 L491.0 84.0 L494.0 82.2 L497.0 80.3 L500.0 78.5 L503.0 76.6 L506.0 74.8 L509.0 72.9 L512.0 71.0 L515.0 69.1 L518.0 67.3 L521.0 65.4 L524.0 63.5 L527.0 61.5 L530.0 59.6 L533.0 57.7 L536.0 55.8 L539.0 53.8 L542.0 51.9 L545.0 49.9 L548.0 47.9 L551.0 46.0 L554.0 44.0 L557.0 42.0 L560.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M80.0 240.0 L83.0 240.0 L86.0 239.9 L89.0 239.9 L92.0 239.8 L95.0 239.7 L98.0 239.6 L101.0 239.5 L104.0 239.4 L107.0 239.3 L110.0 239.2 L113.0 239.0 L116.0 238.9 L119.0 238.7 L122.0 238.6 L125.0 238.4 L128.0 238.2 L131.0 238.1 L134.0 237.9 L137.0 237.7 L140.0 237.5 L143.0 237.3 L146.0 237.1 L149.0 236.9 L152.0 236.6 L155.0 236.4 L158.0 236.2 L161.0 235.9 L164.0 235.7 L167.0 235.5 L170.0 235.2 L173.0 234.9 L176.0 234.7 L179.0 234.4 L182.0 234.1 L185.0 233.9 L188.0 233.6 L191.0 233.3 L194.0 233.0 L197.0 232.7 L200.0 232.4 L203.0 232.1 L206.0 231.8 L209.0 231.5 L212.0 231.1 L215.0 230.8 L218.0 230.5 L221.0 230.2 L224.0 229.8 L227.0 229.5 L230.0 229.1 L233.0 228.8 L236.0 228.4 L239.0 228.1 L242.0 227.7 L245.0 227.3 L248.0 227.0 L251.0 226.6 L254.0 226.2 L257.0 225.8 L260.0 225.4 L263.0 225.1 L266.0 224.7 L269.0 224.3 L272.0 223.9 L275.0 223.5 L278.0 223.1 L281.0 222.6 L284.0 222.2 L287.0 221.8 L290.0 221.4 L293.0 221.0 L296.0 220.5 L299.0 220.1 L302.0 219.6 L305.0 219.2 L308.0 218.8 L311.0 218.3 L314.0 217.9 L317.0 217.4 L320.0 216.9 L323.0 216.5 L326.0 216.0 L329.0 215.5 L332.0 215.1 L335.0 214.6 L338.0 214.1 L341.0 213.6 L344.0 213.1 L347.0 212.7 L350.0 212.2 L353.0 211.7 L356.0 211.2 L359.0 210.7 L362.0 210.2 L365.0 209.6 L368.0 209.1 L371.0 208.6 L374.0 208.1 L377.0 207.6 L380.0 207.0 L383.0 206.5 L386.0 206.0 L389.0 205.5 L392.0 204.9 L395.0 204.4 L398.0 203.8 L401.0 203.3 L404.0 202.7 L407.0 202.2 L410.0 201.6 L413.0 201.1 L416.0 200.5 L419.0 199.9 L422.0 199.4 L425.0 198.8 L428.0 198.2 L431.0 197.6 L434.0 197.1 L437.0 196.5 L440.0 195.9 L443.0 195.3 L446.0 194.7 L449.0 194.1 L452.0 193.5 L455.0 192.9 L458.0 192.3 L461.0 191.7 L464.0 191.1 L467.0 190.5 L470.0 189.9 L473.0 189.2 L476.0 188.6 L479.0 188.0 L482.0 187.4 L485.0 186.7 L488.0 186.1 L491.0 185.5 L494.0 184.8 L497.0 184.2 L500.0 183.5 L503.0 182.9 L506.0 182.3 L509.0 181.6 L512.0 180.9 L515.0 180.3 L518.0 179.6 L521.0 179.0 L524.0 178.3 L527.0 177.6 L530.0 177.0 L533.0 176.3 L536.0 175.6 L539.0 174.9 L542.0 174.2 L545.0 173.6 L548.0 172.9 L551.0 172.2 L554.0 171.5 L557.0 170.8 L560.0 170.1\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"98.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">sistema grande e crítico: muitas vezes 100 para 1</text><text x=\"554.0\" y=\"227.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">sistema pequeno e não crítico: cerca de 5 para 1</text></svg>", "caption": "As duas razões da lista de Boehm e Basili de 2001. A primeira é a que todo mundo cita; a segunda está na frase seguinte do mesmo artigo. Os pontos entre as pontas estão desenhados para mostrar a forma, não foram medidos."}
```

## O que os críticos acharam

**Laurent Bossavit**, em *The Leprechauns of Software Engineering*, foi atrás dos dados originais por trás
do gráfico que aparece em tantos livros. O que achou foi uma corrente de citações: um livro citando um
artigo citando uma palestra citando um número, com os valores mudando a cada passo e, em alguns casos,
nenhum dado rastreável no começo da corrente. Estudos posteriores de projetos feitos em ciclos curtos
acharam curvas bem mais planas que os dados dos anos 1970; em alguns, um defeito achado tarde custava
pouco mais que um achado cedo.

Nada disso diz que a curva é falsa. Diz três coisas que vale a pena guardar:

- **A razão depende do projeto.** Um defeito num software que controla um equipamento médico, certificado
  uma vez e instalado em hospitais, é caríssimo de corrigir tarde. Um defeito numa página web que pode ser
  publicada de novo em dez minutos talvez não seja.
- **A razão depende do defeito.** Um rótulo com erro de grafia custa mais ou menos o mesmo para corrigir em
  qualquer fase. Uma suposição errada no projeto de como os assentos são reservados custa mais a cada
  semana em que se constrói código em cima dela.
- **Ninguém deveria citar "100 vezes" como lei.** É uma observação de um tipo particular de projeto, e
  recitá-la para um time que entrega todo dia convida a resposta de que a experiência deles diz o
  contrário, o que vai ser verdade.

## Então por que achar cedo

Porque o **mecanismo** por trás da curva não depende da década nem do projeto, e é sobre o mecanismo a
próxima seção. Um defeito achado tarde custa mais por motivos que se podem nomear: mais coisa foi
construída em cima dele, mais gente topou com ele, e menos gente lembra por que o código é do jeito que é.
Esses motivos valem para a bilheteria do Cine Aurora tanto quanto para um sistema de mísseis dos anos
1970; o que muda é o peso de cada um.

**Argumente pelo mecanismo, não pelo multiplicador.** "Este defeito, se for para produção, vai significar
reembolsar cada aposentado que cobramos a mais e a Célia explicando no balcão" convence um gerente.
"Defeitos custam cem vezes mais depois da entrega" convida um debate sobre um gráfico.
