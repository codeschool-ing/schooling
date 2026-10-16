---
title: Os seus dados, colados em três planilhas
version: 1
---

**Todo número deste curso é calculado a partir das três tabelas abaixo**, e você vai colá-las numa
pasta de trabalho sua nos próximos dez minutos. São os registros da **Café Serra**, uma pequena
torrefação de Poços de Caldas, Minas Gerais, que não existe. Ela torra grãos de três regiões do
estado, embala em sacos de 250 g e de 1 kg e vende de três jeitos: para cafeterias, lojas e
escritórios (`Wholesale`, o atacado), pela própria loja virtual (`Online`) e no balcão da torrefação
(`Shop`).

## Montando a pasta de trabalho

1. Abra o Excel e comece uma **pasta de trabalho em branco**.
2. Renomeie a primeira planilha para `Sales`: clique duas vezes na guia dela, embaixo, digite o nome
   e tecle Enter.
3. Clique na célula **A1** dessa planilha.
4. Copie o primeiro bloco abaixo com o botão de cópia no canto dele, volte ao Excel e cole com
   **Ctrl+V** (no Mac, **Cmd+V**).
5. Crie mais duas planilhas com o **+** ao lado das guias, chame-as de `Products` e `Customers` e
   cole o segundo e o terceiro blocos na A1 de cada uma.
6. Salve o arquivo como `cafe-serra.xlsx`.

Os blocos são separados por tabulações, e o Excel divide uma linha colada em cada tabulação, então
cada valor cai na sua própria célula. Se tudo cair na coluna A, a seção anterior tem a solução.

### `Sales`: uma linha por venda, de janeiro de 2025 a junho de 2026

```
Sale	Date	Customer	Product	Bags	Price	Channel
S1001	2025-01-02	C03	CER1K	14	104	Wholesale
S1002	2025-01-05	C04	SUL1K	17	116	Wholesale
S1003	2025-01-13	C00	CER1K	1	115	Online
S1004	2025-01-21	C00	DEC250	1	42	Shop
S1005	2025-01-22	C00	CER1K	4	115	Online
S1006	2025-01-27	C00	SUL250	2	38	Online
S1007	2025-02-04	C00	MOG250	4	52	Online
S1008	2025-02-05	C00	SUL250	5	38	Online
S1009	2025-02-10	C00	SUL1K	4	129	Online
S1010	2025-02-11	C04	DEC250	14	38	Wholesale
S1011	2025-02-22	C05	CER1K	5	104	Wholesale
S1012	2025-02-27	C00	MOG250	3	52	Shop
S1013	2025-03-05	C00	SUL1K	4	129	Online
S1014	2025-03-11	C03	SUL1K	13	116	Wholesale
S1015	2025-03-13	C00	DEC250	5	42	Online
S1016	2025-03-15	C07	DEC250	11	38	Wholesale
S1017	2025-03-20	C01	MOG250	6	47	Wholesale
S1018	2025-03-26	C00	DEC250	3	42	Shop
S1019	2025-04-05	C00	DEC250	5	42	Online
S1020	2025-04-11	C06	SUL1K	14	116	Wholesale
S1021	2025-04-19	C00	SUL250	2	38	Shop
S1022	2025-04-22	C00	CER250	2	34	Shop
S1023	2025-04-25	C00	CER1K	3	115	Online
S1024	2025-04-27	C00	SUL1K	4	129	Online
S1025	2025-05-02	C00	CER1K	1	115	Online
S1026	2025-05-04	C00	DEC250	4	42	Online
S1027	2025-05-06	C01	CER1K	13	104	Wholesale
S1028	2025-05-07	C00	SUL250	1	38	Online
S1029	2025-05-18	C00	CER250	5	34	Online
S1030	2025-05-25	C01	DEC250	5	38	Wholesale
S1031	2025-06-04	C04	DEC250	5	38	Wholesale
S1032	2025-06-07	C07	SUL1K	13	116	Wholesale
S1033	2025-06-12	C00	SUL250	2	38	Shop
S1034	2025-06-15	C03	MOG250	12	47	Wholesale
S1035	2025-06-18	C07	SUL1K	6	116	Wholesale
S1036	2025-06-22	C01	SUL1K	5	116	Wholesale
S1037	2025-07-03	C00	CER250	1	34	Shop
S1038	2025-07-10	C00	DEC250	1	42	Shop
S1039	2025-07-13	C00	SUL1K	5	129	Online
S1040	2025-07-15	C03	MOG250	8	47	Wholesale
S1041	2025-07-16	C00	CER250	5	34	Online
S1042	2025-07-24	C00	CER1K	4	115	Online
S1043	2025-08-06	C02	SUL1K	7	116	Wholesale
S1044	2025-08-09	C07	CER1K	15	104	Wholesale
S1045	2025-08-11	C00	DEC250	1	42	Online
S1046	2025-08-16	C00	SUL250	4	38	Online
S1047	2025-08-23	C07	MOG250	11	47	Wholesale
S1048	2025-08-27	C00	SUL1K	1	129	Online
S1049	2025-09-09	C01	SUL1K	9	116	Wholesale
S1050	2025-09-10	C00	MOG250	1	52	Shop
S1051	2025-09-12	C01	SUL1K	13	116	Wholesale
S1052	2025-09-18	C02	CER1K	4	104	Wholesale
S1053	2025-09-20	C00	SUL250	2	38	Shop
S1054	2025-09-25	C00	MOG250	1	52	Shop
S1055	2025-10-05	C00	CER1K	3	115	Online
S1056	2025-10-10	C00	DEC250	4	42	Online
S1057	2025-10-12	C03	CER1K	14	104	Wholesale
S1058	2025-10-21	C03	CER1K	13	104	Wholesale
S1059	2025-10-24	C06	CER1K	9	104	Wholesale
S1060	2025-10-27	C00	SUL250	1	38	Shop
S1061	2025-11-09	C02	CER1K	9	104	Wholesale
S1062	2025-11-10	C00	SUL250	4	38	Online
S1063	2025-11-11	C00	CER1K	4	115	Online
S1064	2025-11-14	C00	CER250	2	34	Shop
S1065	2025-11-18	C00	CER250	1	34	Shop
S1066	2025-11-19	C09	SUL1K	12	116	Wholesale
S1067	2025-12-07	C04	MOG250	14	47	Wholesale
S1068	2025-12-14	C00	MOG250	2	52	Online
S1069	2025-12-17	C00	DEC250	3	42	Shop
S1070	2025-12-21	C00	CER250	1	34	Shop
S1071	2025-12-24	C05	CER1K	12	104	Wholesale
S1072	2025-12-26	C00	DEC250	4	42	Online
S1073	2026-01-02	C09	SUL1K	16	118	Wholesale
S1074	2026-01-04	C04	CER1K	9	106	Wholesale
S1075	2026-01-23	C10	CER1K	16	106	Wholesale
S1076	2026-01-25	C00	MOG250	4	55	Online
S1077	2026-01-26	C00	DEC250	3	45	Shop
S1078	2026-01-27	C00	CER250	3	37	Online
S1079	2026-02-04	C00	MOG250	2	55	Shop
S1080	2026-02-06	C00	SUL250	2	41	Shop
S1081	2026-02-08	C00	DEC250	1	45	Shop
S1082	2026-02-15	C00	CER250	1	37	Shop
S1083	2026-02-18	C03	CER1K	20	106	Wholesale
S1084	2026-02-25	C00	CER1K	4	118	Online
S1085	2026-03-12	C00	SUL1K	5	132	Online
S1086	2026-03-14	C00	SUL250	1	41	Online
S1087	2026-03-20	C02	SUL1K	6	118	Wholesale
S1088	2026-03-21	C02	SUL1K	12	118	Wholesale
S1089	2026-03-22	C00	SUL1K	2	132	Online
S1090	2026-03-24	C08	SUL1K	10	118	Wholesale
S1091	2026-04-02	C00	DEC250	1	45	Online
S1092	2026-04-08	C00	CER1K	1	118	Online
S1093	2026-04-09	C00	SUL250	3	41	Online
S1094	2026-04-21	C00	CER1K	4	118	Online
S1095	2026-04-24	C00	SUL250	3	41	Online
S1096	2026-04-27	C00	DEC250	2	45	Online
S1097	2026-05-08	C00	MOG250	1	55	Online
S1098	2026-05-15	C00	CER250	2	37	Shop
S1099	2026-05-17	C00	CER1K	3	118	Online
S1100	2026-05-18	C00	DEC250	4	45	Online
S1101	2026-05-19	C00	CER1K	3	118	Online
S1102	2026-05-27	C00	CER1K	1	118	Online
S1103	2026-06-02	C07	CER1K	6	106	Wholesale
S1104	2026-06-12	C00	DEC250	2	45	Online
S1105	2026-06-14	C08	CER1K	5	106	Wholesale
S1106	2026-06-20	C00	DEC250	4	45	Online
S1107	2026-06-21	C00	CER250	1	37	Shop
S1108	2026-06-23	C00	DEC250	5	45	Online
```

### `Products`: uma linha por produto, a preços de hoje

```
Code	Product	Origin	Roast	Grams	List price	Unit cost
SUL250	Sul de Minas 250 g	Sul de Minas	Medium	250	41	21
SUL1K	Sul de Minas 1 kg	Sul de Minas	Medium	1000	132	72
CER250	Cerrado 250 g	Cerrado	Dark	250	37	18
CER1K	Cerrado 1 kg	Cerrado	Dark	1000	118	61
MOG250	Mogiana Reserve 250 g	Mogiana	Light	250	55	30
DEC250	Decaf 250 g	Sul de Minas	Medium	250	45	25
```

### `Customers`: uma linha por cliente

```
Customer	Name	Type	City	State	Since
C00	Walk-in and web	Individual			2024-01-02
C01	Café Aroma	Café	Belo Horizonte	MG	2024-03-11
C02	Padaria Central	Retail	Juiz de Fora	MG	2024-05-20
C03	Empório Serra	Retail	Poços de Caldas	MG	2024-02-06
C04	Café do Largo	Café	São Paulo	SP	2024-08-14
C05	Mercado Bom Preço	Retail	Campinas	SP	2025-01-09
C06	Bistrô Lume	Café	Rio de Janeiro	RJ	2025-04-02
C07	Escritório Faro	Office	São Paulo	SP	2025-02-17
C08	Café Grão Fino	Café	Curitiba	PR	2025-07-21
C09	Loja Natural	Retail	Belo Horizonte	MG	2025-10-06
C10	Coworking Ponte	Office	Rio de Janeiro	RJ	2026-01-12
```

## Conferindo se chegou inteiro

Uma colagem que perdeu uma linha parece igualzinha a uma que não perdeu. Três fórmulas dizem qual
das duas você tem. Digite cada uma numa célula vazia da planilha `Sales`, à direita dos dados, por
exemplo em **J1**:

```localised
=CONT.VALORES(A:A)
=SOMA(E:E)
=CONT.NÚM(B:B)
```

`CONT.VALORES` (`COUNTA` no Excel em inglês) conta as células não vazias da coluna A: **109**, o
cabeçalho e 108 vendas. `SOMA` (`SUM`) soma os sacos: **591**. `CONT.NÚM` (`COUNT`) conta só as
células que guardam um número, e a coluna B guarda datas, então responde **108**. Se responder 0, as
datas chegaram como texto, e a seção 08 desta aula explica por que isso importa antes de a aula 6
consertar. Nas outras duas planilhas, `=CONT.VALORES(A:A)` dá **7** em `Products` e **12** em
`Customers`.

Quando os três números baterem, apague as fórmulas de conferência, salve e depois salve uma
**segunda cópia** chamada `cafe-serra-original.xlsx`, que você nunca edita. Várias aulas alteram os
dados de propósito, e uma cópia limpa é como recomeçar sem colar de novo.

## O que as colunas querem dizer

| planilha | coluna | o que guarda |
|---|---|---|
| `Sales` | `Sale` | o código da venda, único, de `S1001` a `S1108` |
| | `Date` | o dia da venda |
| | `Customer` | o código de uma linha de `Customers`; `C00` é todo mundo que compra no balcão ou na loja virtual sem cadastro |
| | `Product` | o código de uma linha de `Products` |
| | `Bags` | quantos sacos foram vendidos |
| | `Price` | quanto custou um saco naquela venda, em reais inteiros |
| | `Channel` | `Wholesale` (atacado), `Online` ou `Shop` (balcão) |
| `Products` | `List price` | o preço de tabela de um saco desde 1º de janeiro de 2026, quando todo preço de tabela subiu R$ 3 |
| | `Unit cost` | quanto um saco custa à Café Serra para torrar e embalar |
| `Customers` | `Since` | o dia em que o cadastro do cliente foi aberto |

Duas coisas nessas tabelas são de propósito e vão importar depois. **O preço está na venda**, e não
só no produto, porque o que um cliente pagou não muda quando a tabela muda: clientes de atacado
pagam menos que a tabela, e toda venda antes de 2026 foi feita aos preços antigos. E **`C00` não tem
cidade**, porque cliente de balcão não tem; a aula 4 mostra o que uma célula vazia faz com uma busca.

Não existe coluna de receita. Receita é sacos vezes preço, e a aula 2 a calcula.
