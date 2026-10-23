---
title: Um caminho, com postos de controle
version: 1
---

**Um fluxo de publicação é o caminho combinado entre uma mudança que alguém escreveu e uma mudança
rodando na conta. A segurança dele vem de duas propriedades ao mesmo tempo: toda mudança no caminho
passa pelos mesmos postos de controle, e não existe outro caminho.** A aula 12 montou os postos à mão:
um plano que uma pessoa lê, um scanner que lê os arquivos. Esta aula os põe numa ordem fixa, faz uma
máquina rodá-los e pergunta quem segura as chaves no fim.

A imagem errada comum é a de que um pipeline é uma conveniência: poupa alguém de digitar `terraform
apply`. Aí as verificações dentro dele são uma gentileza, e no dia em que atrapalham alguém roda o
apply do notebook. **Um pipeline só merece lugar num curso de segurança quando é a única entrada**, o
que é tanto uma questão de permissões quanto de scripts.

## As etapas

Uma mudança na infraestrutura da clínica viaja nesta ordem. Cada etapa é mais barata que a seguinte,
então as baratas vêm primeiro e uma mudança que falha cedo não desperdiça o tempo de ninguém:

| etapa | o que pergunta | quanto custa |
|---|---|---|
| format | o código está escrito do jeito combinado? | menos de um segundo |
| validate | o Terraform o entende? | um ou dois segundos |
| scan | algum recurso quebra uma regra que importa? | segundos, e nenhuma conta |
| plan | o que exatamente a AWS vai ser chamada a fazer? | uma chamada à conta, só de leitura |
| revisão | uma pessoa que não escreveu concorda? | a atenção de uma pessoa |
| apply | fazer, exatamente como planejado | acesso de escrita à conta |

Duas das seis não são como as outras. **A revisão é a única etapa que precisa de um humano**, e fica
depois das máquinas para que o humano leia um plano que já passou por tudo o que uma máquina consegue
verificar. **O apply é a única etapa que muda alguma coisa**, e ele aplica o plano salvo que quem
revisou leu, não um novo, calculado depois, que ninguém viu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"l14-flow\" aria-label=\"O fluxo de publicação como uma fileira de seis etapas, de uma mudança até a conta: format, validate, scan e plan rodam numa máquina; a revisão é feita por uma pessoa; o apply é feito pelo papel do pipeline, usando o plano salvo. Uma seta tracejada âmbar passa por baixo, das credenciais da própria pessoa direto para a conta, sem passar por nenhuma etapa: o caminho em volta do caminho, que tirar o acesso de escrita das pessoas fecha e a aula 16 detecta.\"><defs><marker id=\"l14-flow-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-flow-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-flow-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"8.0\" y=\"90.0\" width=\"72.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma mudança</text><rect x=\"92.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"132.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">format</text><path d=\"M81.0 115.0 L91.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"184.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"224.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">validate</text><path d=\"M173.0 115.0 L183.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"276.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"316.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">scan</text><path d=\"M265.0 115.0 L275.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"368.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"408.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">plan</text><path d=\"M357.0 115.0 L367.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"460.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"500.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">revisão</text><path d=\"M449.0 115.0 L459.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"552.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"592.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">apply</text><path d=\"M541.0 115.0 L551.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"644.0\" y=\"80.0\" width=\"70.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"679.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">conta</text><path d=\"M633.0 115.0 L643.0 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-phosphor)\"></path><path d=\"M92.0 76.0 L448.0 76.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"270.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma máquina, nesta ordem</text><text x=\"500.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma pessoa</text><text x=\"592.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o papel do</text><text x=\"592.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pipeline</text><text x=\"592.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">plan.bin</text><rect x=\"8.0\" y=\"200.0\" width=\"140.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"78.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as credenciais</text><text x=\"78.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">da própria pessoa</text><path d=\"M150.0 223.0 L679.0 223.0 L679.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-flow-af-ah-amber)\"></path><text x=\"400.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">o caminho em volta do caminho</text><text x=\"400.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">fechado tirando o acesso de escrita; achado pela aula 16</text></svg>", "caption": "Toda etapa pode parar uma mudança, e as baratas vêm primeiro. Nenhuma delas para uma mudança que nunca entra no caminho."}
```

## O caminho em volta do caminho

A seta tracejada da figura é o motivo de isto ser um assunto de segurança. Qualquer pessoa cujas
próprias credenciais podem escrever na conta consegue mudá-la pelo console ou pela linha de comando, e
essa mudança não passa por nenhuma das etapas. Foi assim que a maioria dos erros anteriores da clínica
foi feita: a política de bucket da aula 1 custou uma requisição de uma pessoa.

Então um fluxo tem duas metades. A metade visível é o pipeline, que as duas próximas seções montam. A
metade que lhe dá sentido é **tirar das pessoas o acesso de escrita**, para que a identidade do
pipeline seja a única que consegue aplicar, que é o assunto da última seção. O que ainda escapa das
duas, uma mudança feita numa emergência ou por um papel esquecido, é achado lendo a conta como ela é; a
aula 16 faz isso.

::: track devsecops
O curso `secure-pipeline` montou o lado da aplicação deste caminho: análise estática, varredura de
dependências, varredura de imagens, e o endurecimento dos próprios runners. Esta aula acrescenta a
parte própria da infraestrutura de nuvem: um plano como a coisa revisada, e uma identidade capaz de
aplicá-lo.
:::

::: track *
A aplicação que roda sobre esta infraestrutura tem um pipeline próprio, com análise estática,
varredura de dependências e varredura de imagens, que é o assunto do curso `secure-pipeline`. Esta
aula é a parte própria da infraestrutura de nuvem: um plano como a coisa revisada, e uma identidade
capaz de aplicá-lo.
:::
