---
title: O que um DMS faz que uma pasta compartilhada não faz
version: 1
---

A imagem comum de gestão de documentos é um drive compartilhado com nomes de pasta bem pensados.
**Uma pasta guarda arquivos; um sistema de gestão de documentos os controla**, e a diferença aparece
no dia em que alguém precisa provar qual versão estava em vigor. Na Serra Alta esse dia chega várias
vezes por ano, quando um auditor da FSSC 22000 ou um fiscal federal para diante de um procedimento no
chão de fábrica e pede para ver que ele é o aprovado.

## A pasta, e o que dá errado nela

A fábrica de queijos de Alagoa veio com a Queijaria Mantiqueira em 2021, e os documentos de qualidade
dela ainda vivem no servidor de arquivos da planta, uma pasta por processo. Na sala de salga está
pendurado um procedimento impresso cujo arquivo se chama `POP-salmoura_v3_FINAL_revisado.docx`. A
pasta tem quatro arquivos com nomes parecidos. Ninguém sabe dizer qual foi aprovado, por quem nem
quando, porque a pasta não registra nada disso. Ela sabe um nome, a data da última alteração e quem
pode abrir a pasta.

Toda falha da pasta vem dessa pobreza. Duas pessoas abrem o mesmo arquivo, as duas editam, e quem
salva por último ganha sem que nenhuma das duas saiba. "Final" vira "final2". A cópia impressa em
2023 continua na parede depois que o procedimento muda. Uma busca por *salmoura* encontra nomes de
arquivo, e não a frase dentro deles. As permissões seguem a pasta, então ou todo mundo da Qualidade
pode editar todos os procedimentos, ou alguém inventa uma pasta para cada exceção.

## O que um DMS acrescenta

Um DMS (*document management system*, sistema de gestão de documentos) guarda o arquivo e, ao lado
dele, um objeto que o descreve. **Tudo o que um DMS acrescenta mora nesse objeto, não no arquivo**, e
é por isso que copiar o arquivo para fora do sistema perde tudo isso.

| capacidade | o que significa | o que a pasta faz no lugar |
|---|---|---|
| check-out e check-in | uma pessoa segura o documento para editar; as outras leem a última versão e não podem sobrescrevê-la | quem salva por último ganha |
| versões | cada check-in cria uma versão nova, e as antigas ficam, numeradas | arquivos renomeados `v3_FINAL` |
| uma versão aprovada | um rótulo ou um estado marca a versão em vigor | uma pessoa lembra |
| metadados | atributos tipados: planta, processo, tipo de documento, responsável, data da próxima revisão | o caminho da pasta, que comporta uma classificação só |
| renditions | um PDF gerado a partir do Word original, que é o que as pessoas leem e imprimem | alguém exporta um PDF à mão, e esquece da próxima vez |
| busca no texto completo | as palavras de dentro, combinadas com os atributos | nomes de arquivo |
| acesso por documento | quem pode ler, editar, aprovar ou excluir este documento | permissões na pasta |
| workflow | o documento é encaminhado a revisores e a um aprovador, com prazos | um e-mail com anexo |
| trilha de auditoria | cada leitura, alteração, aprovação e exclusão, com quem e quando | a data da última alteração |

Duas linhas merecem um segundo olhar. **Metadados são o que permite a um documento pertencer a várias
coisas ao mesmo tempo.** O procedimento de pasteurização da linha 2 em Juiz de Fora diz respeito a uma
planta, a uma linha de produção, a uma etapa do processo, a uma família de produtos e a uma norma. Um
caminho de pasta comporta uma dessas coisas; atributos comportam as cinco, e uma busca por qualquer
delas encontra o documento. E **a trilha de auditoria é a capacidade que o auditor de fato testa**,
porque "quem aprovou isto, e quando" é uma pergunta sobre o passado que o arquivo não responde sobre
si mesmo.

## Um número de versão carrega um significado

A maioria dos sistemas numera versões em duas partes. O Documentum deixa cada check-in escolher um
incremento menor (de 1.0 para 1.1) ou maior (de 1.0 para 2.0). As equipes de
qualidade acrescentam uma convenção por cima disso: versões menores são rascunhos de trabalho, versões maiores são as que foram
liberadas. O número passa a dizer o estado a quem lê. Quem vê 1.2 sabe que está diante de um rascunho
do que vai virar 2.0, e que a 1.0 continua sendo a que a linha segue.

Um número não diz se uma versão é a mais recente. Para isso o sistema guarda uma marca à parte: o
Documentum chama essas marcas de *version labels* e mantém uma chamada `CURRENT` na versão mais
recente, enquanto outros produtos usam um indicador ou um estado. **A versão mais recente e a versão
aprovada são duas coisas diferentes**, e a distância entre elas é justamente o ponto. Enquanto a 1.2
está em revisão, a linha roda com a 1.0.

## A vida de um procedimento

A equipe de Cláudia Mendes é dona de cerca de 2.300 documentos controlados no Documentum:
procedimentos, instruções de trabalho, formulários e especificações. O repositório também guarda os
certificados de que tratam as próximas seções. Acompanhe um procedimento pela vida inteira: o
POP-JF-PAS-004, pasteurização na linha 2 de Juiz de Fora, aprovado como 1.0 em 2019.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l05-lifecycle\" aria-label=\"Duas partes. Em cima, os estados de um documento controlado: rascunho, em revisão, aprovado e substituído, em fila, com retirado abaixo de aprovado. O rascunho vai para revisão quando é enviado; a revisão volta para rascunho quando é devolvida, ou segue para aprovado; o aprovado vira substituído quando uma nova versão entra em vigor, ou retirado quando não há sucessor. Embaixo, a história do procedimento POP-JF-PAS-004 em duas linhas do tempo. A versão mais recente passa por 1.0, 1.1, 1.2 e 2.0. A versão em vigor na linha 2 continua 1.0 durante os dois rascunhos e a aprovação, e só passa a 2.0 na data de vigência, uma semana depois da aprovação.\"><defs><marker id=\"l05-lifecycle-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-lifecycle-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"32.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">rascunho</text><rect x=\"210.0\" y=\"32.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">em revisão</text><rect x=\"390.0\" y=\"32.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">aprovado</text><rect x=\"570.0\" y=\"32.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">substituído</text><rect x=\"390.0\" y=\"112.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">retirado</text><path d=\"M152.0 44.0 L208.0 44.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-lifecycle-es-ah-phosphor)\"></path><text x=\"180.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">enviar</text><path d=\"M208 62 C190 82 170 82 152 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l05-lifecycle-es-ah-paper-dim)\"></path><text x=\"180.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">devolvido</text><path d=\"M332.0 50.0 L388.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-lifecycle-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aprovar</text><path d=\"M512.0 50.0 L568.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-lifecycle-es-ah-phosphor)\"></path><text x=\"540.0\" y=\"77.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sucessor</text><text x=\"540.0\" y=\"90.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em vigor</text><path d=\"M450.0 70.0 L450.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-lifecycle-es-ah-paper-dim)\"></path><text x=\"442.0\" y=\"92.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem sucessor</text><path d=\"M20.0 168.0 L700.0 168.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POP-JF-PAS-004</text><text x=\"150.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">versão mais recente</text><text x=\"150.0\" y=\"262.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">em vigor na linha 2</text><path d=\"M160.0 214.0 L700.0 214.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"290.0\" cy=\"214.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"290.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.1</text><circle cx=\"400.0\" cy=\"214.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"400.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.2</text><circle cx=\"500.0\" cy=\"214.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"500.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2.0</text><circle cx=\"170.0\" cy=\"214.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"170.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.0</text><rect x=\"160.0\" y=\"252.0\" width=\"430.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1.0 em vigor</text><rect x=\"590.0\" y=\"252.0\" width=\"110.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2.0 em vigor</text><path d=\"M500.0 220.0 L500.0 249.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M500.0 275.0 L500.0 296.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"500.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aprovada</text><path d=\"M590.0 220.0 L590.0 296.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"596.0\" y=\"306.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">data de vigência</text><text x=\"345.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">rascunhos em revisão: a linha ainda segue a 1.0</text></svg>", "caption": "Rascunho, revisão, aprovação, e depois substituído ou retirado. A versão mais recente não é a que está em vigor: a 2.0 existe uma semana antes de a linha passar a segui-la."}
```

Em 2026 o laboratório descobre que o termômetro do tubo de retenção deriva entre uma verificação e
outra, então o procedimento precisa passar a dizer que a verificação é diária, e não semanal. Uma
analista de qualidade faz check-out da versão 1.0, edita o arquivo Word e faz check-in como 1.1, um
**rascunho**. Nada muda no chão de fábrica.

Ela envia o documento para **revisão**. O supervisor da linha e a coordenadora de qualidade da planta
recebem cada um uma tarefa com prazo. O supervisor objeta que uma verificação diária precisa de um
formulário onde ser registrada, então o documento volta para rascunho, ganha uma referência ao
formulário novo e retorna como 1.2. Esse vaivém, para a revisão e de volta, é o caminho mais comum de
qualquer workflow de documentos, e o sistema guarda cada volta dele.

Cláudia **aprova** a 1.2. O sistema a transforma em 2.0, gera a rendition em PDF, registra a
assinatura eletrônica dela e a data, e define uma data de vigência uma semana depois, para que os
operadores sejam treinados na mudança antes de ela valer. Nessa data a 2.0 passa a ser a versão que a
linha segue, e a 1.0 vira **substituída**: continua no repositório, somente leitura, encontrável, e
marcada como fora de vigor.

**Substituído não é excluído.** Um fiscal que pergunta em 2027 o que o procedimento dizia no dia em
que um lote foi produzido, em março de 2026, está perguntando sobre a 1.0, e a resposta tem de ser o
texto exato, não a lembrança de alguém. Essa é a ponte para a próxima seção: depois de substituído,
um procedimento deixa de ser uma instrução e passa a ser prova.

Um procedimento também pode ser **retirado** sem sucessor, quando o processo que ele descreve deixa
de existir. A planta de Alagoa fechou uma das suas câmaras de maturação em 2024, e os três
procedimentos da câmara seguiram esse caminho. Retirado ou substituído, um documento sai da lista do
que está em vigor e fica no repositório.

## Cópias impressas

Uma fábrica de alimentos lê seus procedimentos no papel, na parede, com as mãos molhadas. O DMS não
alcança essa cópia, então a prática de qualidade acrescenta uma regra. A rendition traz um rodapé
como "cópia não controlada quando impressa: confira a versão no sistema", e as cópias que de fato
ficam nas paredes são numeradas, entregues pela equipe de qualidade e recolhidas quando uma versão
nova entra em vigor. **Um sistema de gestão de documentos controla as cópias que conhece**, e parte
do trabalho de implantá-lo é fazer as outras cópias serem conhecidas.

## O que ele não é

Três vizinhos dividem vocabulário com um DMS e fazem outros trabalhos. Uma wiki ou um site do SharePoint é bom para páginas que as pessoas escrevem juntas, e mais leve em
aprovação e controle de registros, a menos que alguém o configure para isso. O Microsoft 365, que a
Serra Alta tem, traz recursos de retenção, e a aula 3 descreve o ambiente Microsoft da empresa. Uma suíte de BPM
encaminha trabalho em geral, e a aprovação de um documento é um tipo dele; a aula 6 trata dessas
suítes. E um ERP guarda transações, não documentos, embora precise apontar para eles, que é a última
seção desta aula.

Ninguém consegue baixar o Documentum para experimentar, então, se você quiser ver essas ideias
funcionando, o caminho é um sistema de código aberto. O Alfresco Community Edition é gratuito e tem
check-out, versões, metadados, regras e workflows simples. Instalá-lo é opcional, e nada neste curso
depende dele.
