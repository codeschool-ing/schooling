---
title: A autópsia de uma ferramenta que ninguém usa
version: 1
---

Toda organização de engenharia tem uma. Ela funciona, foi construída com cuidado, foi lançada com
uma demo, e quase ninguém a abre. **A reação de sempre é divulgá-la com mais força** — outra demo, um
guia melhor, um lembrete no canal de engenharia —, partindo da teoria de que as pessoas usariam se
soubessem que ela existe. A Coreto tentou isso. Não mudou nada, porque ninguém tinha ficado longe por
falta de informação.

A reação útil é uma autópsia: um relato escrito do que se esperava, do que aconteceu e de por que as
duas coisas diferem, escrito sem culpados e lido pelas pessoas que vão propor a próxima ferramenta.

## Os fatos

Antes de a Rafaela Nunes liderar o time de Plataforma, ele construiu um portal de deploy. Numa aplicação web, um engenheiro via que versão de cada serviço rodava em staging e em produção, apertava um botão para fazer deploy, outro para fazer rollback, e pedia uma aprovação antes de um deploy em produção.

| | |
|---|---|
| esforço | 1.100 horas de engenharia |
| custo, a R$ 150 a hora | R$ 165.000 |
| como fração de um ano de engenheiro | 1.100 ÷ 1.760 = 0,625 |
| serviços fazendo deploy por ele, seis meses depois do lançamento | 3 de 41 (7%) |
| custo por serviço que o usa | R$ 165.000 ÷ 3 = R$ 55.000 |

A última linha é a desconfortável. Distribuído pelos serviços para os quais foi construído, o portal
teria sido um investimento modesto; distribuído pelos serviços que o escolheram, cada um custou à
Coreto o preço de um projeto pequeno.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"Quarenta e um quadrados, um por serviço da Coreto, seis meses depois do lançamento do portal de deploy. Três estão acesos: esses serviços fazem deploy pelo portal. Trinta e oito estão apagados: fazem deploy como já faziam. Embaixo, o custo do portal: 1.100 horas de engenharia, R$ 165.000.\"><text x=\"360\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Os 41 serviços da Coreto, seis meses depois do lançamento do portal</text><rect x=\"56\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"100\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"144\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"188\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"232\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"276\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"364\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"408\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"452\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"496\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"540\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"584\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"628\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"56\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"144\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"188\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"232\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"276\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"364\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"408\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"452\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"496\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"540\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"584\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"628\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"56\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"144\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"188\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"232\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"276\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"364\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"408\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"452\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"496\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"540\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"584\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"56\" y=\"198\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"78\" y=\"210\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">fazem deploy pelo portal: 3 (7%)</text><rect x=\"396\" y=\"198\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418\" y=\"210\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">fazem deploy como já faziam: 38</text><text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">construído em 1.100 horas de engenharia: R$ 165.000</text></svg>", "caption": "O portal, seis meses depois do lançamento. Trinta e oito serviços da Coreto continuaram fazendo deploy como já faziam; três passaram para o portal, e nenhum dos três tinha pipeline de deploy próprio antes dele."}
```

## O que o portal fazia bem

**Nada na autópsia diz que o portal foi mal construído.** A visão de versões era precisa, o rollback
funcionava, a etapa de aprovação registrava quem aprovou o quê. Os engenheiros que o construíram eram
bons, e resolveram o problema que receberam. É isso que faz o caso valer o estudo: uma ferramenta
que fracassa porque está quebrada ensina sobre testes, e uma ferramenta que funciona e fica sem uso
ensina sobre decidir o que construir.

## Quem usou, e quem não usou

Um dos primeiros movimentos da Rafaela como líder do time foi olhar quem usava o portal, e os três usuários
tinham algo em comum. **Nenhum dos três tinha pipeline de deploy antes de o portal existir.** Eram
serviços cujos donos faziam deploy pedindo à Plataforma no canal de chat, e o portal era uma melhora
real em relação a pedir.

Os outros 38 tinham pipeline. Uma mudança integrada ao branch principal passava pelo build, pelos
testes e pelo deploy sem ninguém abrir um navegador. Para esses times o portal oferecia um botão para
fazer algo que já acontecia sozinho, mais uma etapa de aprovação que deixava o deploy mais lento.
Vários engenheiros tinham experimentado uma vez, na semana do lançamento, e voltado.

Então a distância entre a expectativa e o resultado tinha um formato preciso:

| o que a Plataforma esperava | o que aconteceu | por quê |
|---|---|---|
| os times levariam seus deploys para o portal | os times com pipeline ficaram nele | o portal acrescentava um passo a algo que já era automático |
| o guia e a demo trariam o resto | o uso não se mexeu depois de nenhum dos dois | não faltava informação a ninguém |
| a etapa de aprovação seria bem-vinda | foi o motivo que os engenheiros deram para largar a primeira tentativa | deixava cada deploy em produção mais lento por uma conferência que ninguém tinha pedido |

## O que ele ainda custa

As 1.100 horas foram gastas, e nenhuma decisão tomada hoje recupera qualquer uma delas. **Dinheiro já
gasto é um custo afundado, e ele pertence à autópsia, mas não à próxima decisão.** O argumento
"gastamos R$ 165.000 nele, então os times deveriam ser mandados a usar" é a armadilha. Ele transformaria uma medida em imposição, o que a aula 14 mostrou que esconde a evidência. E gastaria mais tempo dos outros times para justificar um dinheiro que ninguém recupera.

O que o portal custa daqui em diante é outro número, e é o que importa. Ele roda na infraestrutura da
Coreto, depende de bibliotecas que precisam de correções de segurança, guarda credenciais capazes de
fazer deploy em produção, e alguém da Plataforma está de plantão por ele. Uma ferramenta com três
usuários mantém todos esses custos e os divide por três. A decisão sobre esse custo futuro — manter,
encolher ou desligar — é o fim desta aula, e vem depois da pergunta sobre por que um time de
engenheiros capazes o construiu.
