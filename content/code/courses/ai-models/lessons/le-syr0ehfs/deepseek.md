---
title: DeepSeek
version: 1
---

DeepSeek is a Chinese company that publishes open weights and also sells an API of its own. Lesson
2 read its licences: the code is MIT, V3's weights are under a model licence with use-based
restrictions, and R1 is MIT for code and weights alike. Its API models, as the sheet records them:

```
ana@desk:~/desk$ sheet compare deepseek/deepseek-v3.2 deepseek/deepseek-v4-flash deepseek/deepseek-v4-pro deepseek/deepseek-r1
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
deepseek/deepseek-v3.2                          163,840   163840     0.28      0.4  .F.CR.
deepseek/deepseek-v4-flash                    1,000,000   393216      0.3      1.2  VFSCR.
deepseek/deepseek-v4-pro                      1,000,000   393216     1.32     3.96  .FSCR.
deepseek/deepseek-r1                             65,536     8192     0.55     2.19  .F.CR.
```

**V4 Flash and V4 Pro** are the current generation, both with a million-token window; V3.2 and R1 are
older and still priced. The names the API used to answer to are gone:

```
ana@desk:~/desk$ sheet retiring --provider deepseek
# LiteLLM model sheet at 21881c57, 4472 entries
4 entries carry a deprecation date
2026-07-24  deepseek-chat                                      deepseek
2026-07-24  deepseek-reasoner                                  deepseek
2026-07-24  deepseek/deepseek-chat                             deepseek
2026-07-24  deepseek/deepseek-reasoner                         deepseek
```

`deepseek-chat` and `deepseek-reasoner` were the API's two aliases, and they were retired on July 24,
2026. A program written against them in 2025 stopped answering that day, which is lesson 2 section
06 happening to an open-weight family: **the weights are open, the maker's API is still a service
with dates**.

## The maker is not the cheapest host

Lesson 2 found that nobody can undercut a closed model's maker. For an open model the opposite
happens. V4 Flash is offered by many hosts:

```
ana@desk:~/desk$ sheet where deepseek-v4-flash | tail -n +3 | wc -l
33
```

```
ana@desk:~/desk$ sheet where deepseek-v4-flash | grep -E "^(deepseek/|azure|tencent|scaleway|novita/deepseek/deepseek-v4-flash )"
azure_ai/deepseek-v4-flash                           azure_ai                       0.19     0.51
deepseek/deepseek-v4-flash                           deepseek                        0.3      1.2
deepseek/deepseek-v4-flash-vision-exp                deepseek                        0.3      1.2
novita/deepseek/deepseek-v4-flash                    novita                         0.14     0.28
scaleway/deepseek-v4-flash-0731                      scaleway                        0.4      0.8
tencent/deepseek-v4-flash                            tencent                        0.14     0.28
```

Thirty-three entries. **DeepSeek's own API, at $0.30 and $1.20, is not the cheapest**: two of the
hosts above offer the same model at $0.14 and $0.28, under half the input price and under a quarter of the
output. The maker competes with everybody who downloaded its weights.

For ana, that turns one question into two. Whether DeepSeek V4 Flash is good enough is lesson 5's
question, answered once. Where to run it is lesson 10 section 05's question, answered per host on
price, latency, precision and, for a Brazilian shop, **where the host processes the data**. For
the maker's own API that means a company based in China; for the others, wherever each of them
says.
