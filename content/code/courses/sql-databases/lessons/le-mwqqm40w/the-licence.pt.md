---
title: A licença, que decide mais que o motor
version: 1
---

Esta seção é a segunda em vez da última porque ela explica a maior parte do que de outro modo é
intrigante num sistema Oracle. Qualquer coisa nesta aula que soe como uma escolha de engenharia
estranha costuma ser uma resposta razoável a uma pergunta sobre dinheiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Uma corrente de cinco caixas: dois soquetes, vezes dezesseis núcleos cada, igual a trinta e dois núcleos físicos, vezes um fator de núcleo de zero vírgula cinco para x86, igual a dezesseis licenças de processador, a última caixa acesa. Uma nota diz que o resultado é arredondado para cima e que o fator é publicado por família de processador, então duas máquinas de aparência idêntica podem diferir. Embaixo, dois painéis: Processor, para uma população que você não consegue contar; e Named User Plus, para uma população pequena de usuários conhecidos com um mínimo publicado por processador.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A conta não é o número de máquinas, e também não é o número de núcleos.</text><rect x=\"14\" y=\"48\" width=\"124\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"76\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">2</text><text x=\"76\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">soquetes</text><path d=\"M140 70 L150 70\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M150 70 L144 67 L144 73 Z\" fill=\"var(--wire)\"></path><rect x=\"152\" y=\"48\" width=\"124\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"214\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">× 16</text><text x=\"214\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">núcleos cada</text><path d=\"M278 70 L288 70\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M288 70 L282 67 L282 73 Z\" fill=\"var(--wire)\"></path><rect x=\"290\" y=\"48\" width=\"124\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"352\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">= 32</text><text x=\"352\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">núcleos físicos</text><path d=\"M416 70 L426 70\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M426 70 L420 67 L420 73 Z\" fill=\"var(--wire)\"></path><rect x=\"428\" y=\"48\" width=\"124\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"490\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">× 0.5</text><text x=\"490\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">fator de núcleo, x86</text><path d=\"M554 70 L564 70\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M564 70 L558 67 L558 73 Z\" fill=\"var(--wire)\"></path><rect x=\"566\" y=\"48\" width=\"124\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"628\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">= 16</text><text x=\"628\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">licenças de processador</text><text x=\"14\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e arredondado para cima — o fator é publicado por família de processador, então duas máquinas de aparência idêntica podem diferir</text><rect x=\"14\" y=\"136\" width=\"340\" height=\"70\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Processador</text><text x=\"28\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para uma população que você não consegue contar</text><text x=\"28\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um site público, ou qualquer coisa voltada ao cliente</text><rect x=\"376\" y=\"136\" width=\"330\" height=\"70\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Named User Plus</text><text x=\"390\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para uma população pequena de usuários conhecidos</text><text x=\"390\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com um mínimo publicado por processador</text><text x=\"14\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Qual métrica, em qual edição, com quais opções: essa aritmética decide mais que o motor decide.</text></svg>", "caption": "Cada passo é publicado e nada nisso é negociável, e é por isso que a licença é lida antes de o motor ser instalado e não depois.", "same": ["Named User Plus"]}
```

## Você é licenciado por núcleo, e o núcleo é contado com um fator

A métrica que importa para um servidor é **Processor**. Não é uma contagem de soquetes nem de
máquinas. Você toma os núcleos físicos da máquina, multiplica por um **fator de núcleo** que a
Oracle publica por família de processador — 0,5 para chips x86 comuns, outros valores em outros
lugares — e arredonda para cima. Dois soquetes de dezesseis núcleos são trinta e dois núcleos,
vezes 0,5, são dezesseis licenças de processador.

Para uma população pequena de usuários conhecidos há uma segunda métrica, **Named User Plus**, com
um mínimo publicado por processador. É a resposta certa para um sistema interno com quarenta
usuários e a errada para qualquer coisa que um cliente alcance.

Duas consequências saem direto dessa aritmética, e são as que moldam sistemas:

**Um servidor mais rápido custa mais.** Não em hardware — em licença. Dobrar os núcleos para cortar
pela metade um relatório dobra a licença. A resposta usual é otimizar a consulta, o que é uma boa
resposta, e está sendo dada por um motivo que não é de engenharia.

**Um segundo servidor custa o mesmo de novo.** Um standby, uma réplica de relatório, um ambiente de
teste que alguém quer do tamanho de produção — cada um é outra licença, a menos que se enquadre em
uma das exceções estreitas que a Oracle publica. É por isso que um sistema Oracle corporativo
muitas vezes **não tem réplica de relatório**, e por que relatórios rodam contra a mesma instância
que a aplicação usa, à noite, que é a condição para a qual o conselho da aula 10 foi escrito.

## Os recursos são cobrados à parte, e um deles é a ferramenta de diagnóstico

Esta é a parte que pega os desenvolvedores, porque estes não são complementos exóticos. São coisas
que simplesmente *estão* no PostgreSQL:

| opção | o que faz | o que é no PostgreSQL |
|---|---|---|
| Partitioning | divide uma tabela grande por faixa ou lista | embutido |
| Diagnostics Pack | AWR e ASH: o histórico de desempenho e o amostrador de sessões | `pg_stat_statements`, embutido |
| Tuning Pack | os assessores que recomendam índices e reescritas | sem equivalente, e sem cobrança por não ter um |
| Advanced Compression | comprime os dados da tabela | embutido |
| Real Application Clusters | várias máquinas abrindo um banco | sem equivalente |
| Active Data Guard | um standby de onde você pode ler | uma réplica por streaming, embutida |
| In-Memory | um armazenamento colunar em memória | sem equivalente |
| Advanced Security | criptografia transparente em repouso, mascaramento | criptografia embutida, mascaramento não |

**A linha do Diagnostics Pack é a de lembrar.** O Automatic Workload Repository é como você
descobre qual consulta está lenta no Oracle: é a resposta daquele motor à primeira seção da aula
10. Num sistema sem a licença, consultar as views dele é uma violação de licença e não um erro
técnico. As views estão lá e vão responder; o contrato diz que você não pode perguntar.

Então *"alguém olhou o relatório do AWR"* é uma pergunta com três respostas possíveis numa
organização grande, e só uma delas é sobre o relatório. Ou o pacote é licenciado e alguém deveria
olhar, ou não é e a pergunta é um incidente de conformidade, ou ninguém tem certeza de qual. A
terceira é a mais comum, e é por isso que o DBA é a pessoa a perguntar em vez da pessoa a
contornar.

## A auditoria

A Oracle audita seus clientes, e o contrato lhe dá esse direito. Uma auditoria que encontra uma
opção não licenciada em uso — inclusive uma que foi ligada por um padrão, ou por uma ferramenta,
ou por alguém que experimentou uma vez — produz uma conta pelas licenças mais o suporte
retroativo. Esse é o mecanismo, e é por isso que a cultura em volta de uma instalação Oracle é
mais cuidadosa que a em volta de uma instalação PostgreSQL, e por que um desenvolvedor que pede
para habilitar algo ouve um porquê em vez de um sim.

**Nada disso é motivo para timidez, e é motivo para perguntar.** As pessoas que rodam o sistema
sabem quais opções são licenciadas. Elas já estão respondendo a essa pergunta de qualquer jeito.

## Quanto custa, e como descobrir

A Oracle publica uma lista de preços, e a estrutura é estável mesmo com os números se mexendo: uma
taxa de licença perpétua por processador para a edição, uma porcentagem dessa taxa por ano de
suporte, e uma taxa separada por processador para cada opção. A licença por processador da
Enterprise Edition está na casa das dezenas de milhares de dólares há muitos anos, com suporte
anual perto de um quinto disso, e cada opção significativa acrescenta uma fração substancial por
cima.

**Consulte em vez de confiar num número numa aula** — inclusive nesta. O que vale carregar é a
forma: a licença é por núcleo, o suporte é anual e recorrente, as opções são extras, e um segundo
ambiente é uma segunda conta.

## Por que isto está num curso de SQL

Porque responde a perguntas que de outro modo parecem má engenharia, e um desenvolvedor que não
consegue ler essas respostas vai passar um ano propondo coisas que já são entendidas:

- **por que a lógica de negócio está no banco.** A licença está paga; os servidores de aplicação
  são baratos. A próxima seção é sobre como isso se parece.
- **por que não há réplica de relatório**, e por que relatórios rodam à noite na instância de
  produção.
- **por que o ambiente de teste é menor**, e por que um plano que está bem lá não é evidência.
- **por que ninguém rodou o assessor de otimização.** Pode ser uma opção que ninguém comprou.
- **por que migrar para fora é um projeto com orçamento**, discutido na última seção, e não um fim
  de semana.

Cada uma delas é uma frase de som técnico cujo assunto real é um contrato.
