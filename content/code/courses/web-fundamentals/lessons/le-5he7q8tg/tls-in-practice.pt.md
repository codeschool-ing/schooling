---
title: Onde o certificado de fato termina
version: 1
---

A aula seis explicou o que um certificado prova. Esta é sobre a parte que quebra: quem obtém, quem
renova, e onde no caminho a criptografia de fato para.

## Grátis e automático mudou tudo

Certificados eram comprados, uma vez por ano, por alguém preenchendo um formulário. A renovação era uma
anotação no calendário, e a anotação no calendário era a falha.

Uma autoridade emissora gratuita com um protocolo automatizado mudou o formato do problema. Um programa
na sua máquina prova que controla o nome, recebe um certificado válido por um período curto, e se renova
bem antes de vencer. Validade curta é o ponto: ela obriga a automação a funcionar, porque nada dura o
bastante para sobreviver com base em atenção.

Provar controle acontece de dois jeitos, e vale reconhecer os dois.

**Por HTTP** — a autoridade pede um arquivo específico num caminho específico do seu site, por HTTP
puro. Simples, e exige que a porta 80 continue alcançável, e é por isso que *redirecionamos tudo para
HTTPS e a renovação parou* é uma falha comum e confusa.

**Por DNS** — a autoridade pede que você publique um registro, usando o mecanismo da aula anterior. Mais
lento, exige que seu provedor de DNS tenha uma interface que um programa use, e é o único jeito de obter
um certificado **curinga** cobrindo todos os subdomínios de uma vez.

## Onde ele termina, que é a pergunta que as pessoas pulam

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Sem nada na frente, a criptografia vai de ponta a ponta. Com uma borda na frente, a conexão termina ali e uma segunda conexão é aberta até a origem, que pode ser pura, cifrada, ou cifrada e verificada.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">nada na frente: um salto, e o cadeado descreve tudo</text> <rect x=\"20\" y=\"36\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o navegador</text> <path d=\"M226 56 L474 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path> <text x=\"350\" y=\"46\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">cifrado, de ponta a ponta</text> <rect x=\"480\" y=\"36\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"590\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu servidor</text> <text x=\"20\" y=\"118\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">uma borda na frente: dois saltos, e só o primeiro é o que o visitante vê</text> <rect x=\"20\" y=\"128\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"105\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o navegador</text> <path d=\"M196 148 L274 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path> <rect x=\"280\" y=\"128\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"365\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a borda, com um certificado</text> <path d=\"M456 148 L534 148\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path> <rect x=\"540\" y=\"128\" width=\"160\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"620\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu servidor</text> <rect x=\"20\" y=\"190\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">o segundo salto é puro, ou cifrado, ou cifrado e verificado — alguém escolheu</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o cadeado descreve o salto que o navegador fez, e nada além dele</text> </svg>", "caption": "Dois saltos, e o visitante vê apenas um deles. O outro é uma configuração."}
```

Se uma requisição vai direto ao seu servidor, a criptografia é de ponta a ponta e há um certificado para
pensar.

Ponha qualquer coisa na frente — uma CDN, um balanceador, o roteador de uma plataforma — e o arranjo
habitual é que a conexão **termina** ali. A borda decifra, lê o suficiente para fazer o trabalho dela, e
abre uma segunda conexão até a sua origem. Agora há dois saltos, e eles não são necessariamente cifrados
do mesmo jeito.

Três arranjos existem, e os nomes aparecem nas configurações de todo provedor.

**Terminado na borda, puro até a origem.** Rápido de configurar. O segundo salto cruza a rede de alguém
sem cifra, e o cadeado que o visitante vê descreve apenas o primeiro salto.

**Terminado na borda, cifrado até a origem sem conferi-la.** Melhor, e impede que alguém leia o segundo
salto, sem provar nada sobre quem está respondendo lá.

**Terminado na borda, cifrado e verificado até a origem.** O arranjo a mirar, e o que precisa de um
certificado no seu próprio servidor também.

O instinto que vale guardar: **o cadeado descreve o salto que o navegador fez.** Tudo atrás dele é um
conjunto de escolhas que alguém fez num painel de configuração, e vale olhar para elas uma vez.

## O que de fato quebra

Quatro falhas, e entre elas respondem por quase todo incidente de certificado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro falhas de certificado: a renovação parou e ninguém notou, o certificado cobre os nomes errados, ele foi renovado mas o servidor nunca foi recarregado, e a cadeia está incompleta, então funciona em alguns navegadores e não em outros.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a renovação parou semanas atrás, e o primeiro aviso é o vencimento</text> <rect x=\"20\" y=\"80\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">ele cobre um nome e o visitante pediu o outro</text> <rect x=\"20\" y=\"126\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">renovado em disco, e o processo em execução ainda tem o antigo</text> <rect x=\"20\" y=\"172\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">uma cadeia incompleta: bem no seu notebook, quebrada num celular</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">alerte por dias restantes, e confira com algo que não seja seu navegador</text> </svg>", "caption": "Quatro falhas, e a última é a pior de achar porque funciona justamente onde você está olhando."}
```

**A renovação parou e ninguém notou.** A automação falhou semanas atrás, em silêncio, e a primeira
notificação é um aviso do navegador no dia em que vence. A correção não é um calendário melhor; é
monitoramento que alerta por *dias restantes*, que é uma checagem que qualquer serviço de monitoramento
oferece.

**Os nomes errados.** Um certificado é emitido para os nomes que você pediu. `example.com` e
`www.example.com` são dois nomes, e um certificado que cobre um deles produz um aviso no outro — que é a
divergência de nome da aula seis, chegando por uma configuração em vez de por um ataque.

**Renovado e não recarregado.** O arquivo novo está em disco e o processo em execução ainda tem o antigo
em memória. Ele vence no prazo, com um certificado correto ao lado. O que renova tem que avisar o
servidor para pegá-lo.

**Uma cadeia incompleta.** O servidor manda o próprio certificado e deixa de fora o intermediário acima
dele. Navegadores que já viram o intermediário em outro lugar completam e funcionam; outros não. O
resultado é um site que está bem no seu notebook e quebrado no celular de alguém, que é a pior forma
possível de isto se apresentar.

## O que cada arranjo de hospedagem faz por você

Vale pôr ao lado do resto da aula, porque quanto disto é problema seu é exatamente a linha que o vídeo
de abertura traçou.

Em **hospedagem compartilhada**, o painel obtém e renova, e você não faz nada. Numa **plataforma** ou
atrás de uma **CDN**, o provedor faz o mesmo na borda, e o segundo salto é a configuração acima. Em
**hospedagem estática**, vem incluído e invisível.

Numa **máquina sua**, tudo é seu: obter, renovar, recarregar, e o monitoramento que avisa quando um
desses parou. São talvez vinte minutos de configuração e então nada por anos — bem até o dia em que os
vinte minutos foram feitos por alguém que já saiu.

Esse é o padrão inteiro desta aula, num assunto pequeno: o trabalho não desaparece quando você o entrega,
e não aparece do nada quando você o assume. Ele sempre esteve ali, e a única pergunta era de quem seria a
manhã.

## Duas coisas para arranjar no primeiro dia

**Alerte por dias restantes**, e não por falha. Uma renovação que falha em silêncio tem semanas em que
poderia ser consertada, e o custo inteiro desta categoria é que ninguém olha durante elas.

**Confira com uma ferramenta que não seja o seu navegador.** Seu navegador tem um cache de
intermediários, opiniões sobre quais avisos mostrar, e memória deste site. Um verificador que parte do
zero vê o que um estranho vê, que é a única opinião que importa.
