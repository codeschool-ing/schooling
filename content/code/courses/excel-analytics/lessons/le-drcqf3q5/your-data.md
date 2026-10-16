---
title: Your data, pasted in three sheets
version: 1
---

**Every number in this course is computed from the three tables below**, and you will paste them
into a workbook of your own in the next ten minutes. They are the records of **Café Serra**, a
small coffee roaster in Poços de Caldas, Minas Gerais, which does not exist. It roasts beans from
three regions of the state, packs them in 250 g and 1 kg bags, and sells them three ways: to
cafés, shops and offices (`Wholesale`), through its own web shop (`Online`), and over the counter
of the roastery (`Shop`).

## Making the workbook

1. Open Excel and start a **blank workbook**.
2. Rename the first sheet `Sales`: double-click its tab at the bottom, type the name, press Enter.
3. Click cell **A1** of that sheet.
4. Copy the first block below with the copy button in its corner, go back to Excel and paste with
   **Ctrl+V** (on a Mac, **Cmd+V**).
5. Add two more sheets with the **+** beside the tabs, name them `Products` and `Customers`, and
   paste the second and third blocks into A1 of each.
6. Save the file as `cafe-serra.xlsx`.

The blocks are separated by tabs, and Excel splits a pasted line at every tab, so each value lands
in its own cell. If everything lands in column A instead, the previous section has the fix.

### `Sales`: one row per sale, January 2025 to June 2026

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

### `Products`: one row per product, at today's prices

```
Code	Product	Origin	Roast	Grams	List price	Unit cost
SUL250	Sul de Minas 250 g	Sul de Minas	Medium	250	41	21
SUL1K	Sul de Minas 1 kg	Sul de Minas	Medium	1000	132	72
CER250	Cerrado 250 g	Cerrado	Dark	250	37	18
CER1K	Cerrado 1 kg	Cerrado	Dark	1000	118	61
MOG250	Mogiana Reserve 250 g	Mogiana	Light	250	55	30
DEC250	Decaf 250 g	Sul de Minas	Medium	250	45	25
```

### `Customers`: one row per customer

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

## Checking that it arrived whole

A paste that lost a line looks exactly like a paste that did not. Three formulas tell you which
one you have. Type each in an empty cell of the `Sales` sheet, to the right of the data, for
example in **J1**:

```localised
=COUNTA(A:A)
=SUM(E:E)
=COUNT(B:B)
```

`COUNTA` counts the cells that are not empty in column A: **109**, the header and 108 sales.
`SUM` adds the bags: **591**. `COUNT` counts only the cells holding a number, and column B holds
dates, so it answers **108**. If it answers 0, the dates arrived as text, and lesson 1 section 08
explains why that matters before lesson 6 repairs it. On the other two sheets, `=COUNTA(A:A)`
gives **7** for `Products` and **12** for `Customers`.

Once the three numbers agree, delete the check formulas, save, and then save a **second copy**
called `cafe-serra-original.xlsx` that you never edit. Several lessons change the data on purpose,
and a clean copy is how you start again without pasting.

## What the columns mean

| sheet | column | what it holds |
|---|---|---|
| `Sales` | `Sale` | the sale's own code, unique, from `S1001` to `S1108` |
| | `Date` | the day of the sale |
| | `Customer` | the code of a row in `Customers`; `C00` is everybody who buys in the shop or on the web without an account |
| | `Product` | the code of a row in `Products` |
| | `Bags` | how many bags were sold |
| | `Price` | what one bag cost in that sale, in whole reais |
| | `Channel` | `Wholesale`, `Online` or `Shop` |
| `Products` | `List price` | the price of one bag since 1 January 2026, when every list price rose by R$ 3 |
| | `Unit cost` | what one bag costs Café Serra to roast and pack |
| `Customers` | `Since` | the day the customer's account was opened |

Two things in these tables are deliberate and will matter later. **The price is on the sale**, not
only on the product, because what a customer paid does not change when the list does: wholesale
customers pay less than list, and every sale before 2026 was made at the old prices. And **`C00`
has no city**, because walk-in customers have none; lesson 4 shows what an empty cell does to a
lookup.

There is no revenue column. Revenue is bags times price, and lesson 2 computes it.
