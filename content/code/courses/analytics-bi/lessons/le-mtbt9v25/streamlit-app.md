---
title: The app, part by part
version: 1
---

Make a directory for the app, `mkdir -p ~/revenue/.streamlit`, and three files in it. The first is
the program. Copy it with the button on the code, which copies the whole program without the notes,
and save it as `~/revenue/app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py: Lantern's net revenue by month, read from the semantic layer.\nimport psycopg\nimport streamlit as st", "note": "Two libraries: `psycopg` talks to PostgreSQL, `streamlit` draws the page. Nothing else is needed."}, {"code": "st.set_page_config(page_title=\"Lantern revenue\")\nst.title(\"Lantern Coffee: net revenue\")", "note": "Streamlit runs the file from top to bottom, and each `st.` call puts one element on the page, in that order."}, {"code": "@st.cache_data(ttl=600)\ndef monthly(segments):\n    sql = \"\"\"\n        SELECT date_trunc('month', o.order_date)::date AS month,\n               sum(o.net_revenue)::float AS net_revenue\n        FROM semantic.orders o\n        JOIN semantic.customers c USING (customer_id)\n        WHERE c.segment = ANY(%s)\n        GROUP BY 1\n        ORDER BY 1\n    \"\"\"", "note": "The query reads the layer, never `shop`. `%s` is a parameter: the segments are sent beside the SQL, not pasted into it. `@st.cache_data` keeps the answer for ten minutes per combination of segments, so moving a widget does not query the database each time."}, {"code": "    with psycopg.connect(**st.secrets[\"db\"]) as conn:\n        rows = conn.execute(sql, (list(segments),)).fetchall()\n    return {\"month\": [r[0] for r in rows], \"net_revenue\": [r[1] for r in rows]}", "note": "The connection details come from `st.secrets`, which Streamlit reads from a file that is not part of the program. The result becomes two lists, the shape the chart takes."}, {"code": "segments = st.multiselect(\"Segment\", [\"home\", \"office\"], default=[\"home\", \"office\"])\ndata = monthly(tuple(segments))", "note": "A widget is a variable. Whatever the reader selects is in `segments` on the next run, and every interaction runs the file again from the top."}, {"code": "st.metric(\"Net revenue, whole period\", f\"R$ {sum(data['net_revenue']):,.2f}\")\nst.bar_chart(data, x=\"month\", y=\"net_revenue\")\nst.caption(\"June 2026 holds 17 days. Source: semantic.orders.\")", "note": "A number, a chart and a caption. The caption is not decoration: it is lesson 1's partial month, written where the reader sees it."}]}
```

The second holds what the program must not contain: the password. Save it as
`~/revenue/.streamlit/secrets.toml`, with the password you gave the role:

```toml
[db]
host = "localhost"
dbname = "lantern"
user = "streamlit_app"
password = "a-third-password-to-choose"
```

**A secrets file never goes into version control.** It is a separate file precisely so that the
program can be shared, reviewed and published without the password in it; a team that keeps its apps
in git lists this file in `.gitignore` on the first day.

The third is Streamlit's own configuration, saved as `~/revenue/.streamlit/config.toml`:

```toml
[browser]
gatherUsageStats = false

[server]
address = "0.0.0.0"
headless = true
```

`gatherUsageStats = false` stops Streamlit sending anonymous usage statistics to its company, which it
does by default. `address = "0.0.0.0"` makes it listen on every network interface of the machine, so
the forwarded port 8501 of lesson 1 reaches it; `headless = true` stops it trying to open a browser on
a server that has none. The three files:

```
ana@vm:~/revenue$ find . -type f | sort
./.streamlit/config.toml
./.streamlit/secrets.toml
./app.py
```

Run it from that directory, with the environment's own `streamlit`:

```sh
cd ~/revenue
~/st/bin/streamlit run app.py
```

It prints the addresses it is listening on and keeps running in that terminal until Ctrl+C. From a
second terminal, the machine can ask whether it is up:

```
ana@vm:~$ curl -s -w '\n' http://localhost:8501/_stcore/health
ok
```

Open `http://localhost:8501` in your browser (on UTM, the machine's address). A title, a segment
selector with both segments chosen, a number, a bar chart by month and the caption. The number reads:

```
Segment: home, office
Net revenue, whole period: R$ 1,046,756.40
```

The same R$ 1,046,756.40 the layer holds, by a third route. Remove *home* from the selector and the
whole file runs again with only `office` in `segments`:

```
Segment: office
Net revenue, whole period: R$ 355,821.05
```

R$ 355,821.05, the figure Metabase reached by segment earlier in this lesson. **Three tools, one number**,
because all three read the same column of the same view. That is lesson 3 paying for itself.
