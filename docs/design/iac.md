---
format: 5
course: iac
---

# iac

**Infrastructure as Code** · `co-14jj5rd1` · 80 h declared · intermediate · 20 lessons · `infra` · paid

## Reach

In **4 tracks** — `cloud-engineering`(8), `devops`(11), `networks-infra`(11), `software-architecture`(7).

**Depends on it:** `aws-operations`, `azure-operations`, `gcp-operations`, `gitops`

## Assumes, and leaves ready

**Assumes:** `cloud` — providers, regions and managed services.

**Leaves ready:** describing infrastructure in files, for the three `*-operations` courses and `gitops`.

## Shape

| | |
|---|---|
| declared hours | 80 h |
| lessons | 20 |
| **hours per lesson** | **4.00** |
| section budget | ~171, about 8.6 a lesson |
| exercises | ~800, at the catalogue's density |


## Execution

| | |
|---|---|
| runtime | **shell + a provisioning tool**, and the split matters — see the flag |
| browser · database | no · no |
| exercises **blocked** | **0** |
| exercises that would **improve** | ~half. `validate` and `plan` are `expected-output` on a shell and need nothing else |
| diagrams to draw | ~30 — state, the plan/apply cycle, module boundaries |

## Ageing

**Low to moderate.** The CLI and the language are stable; provider resources move.

## Flags

**1 ·** **The one course whose sandbox need splits in two.** Writing a description, validating it and reading a plan need a shell and nothing more. *Applying* it needs a real account with a real bill. So roughly half of its practice is reachable by the same sandbox that serves `git`, and the other half is not reachable at all — which is a much better position than the vendor courses, where none of it is.
