---
title: What a lookup sends
version: 1
---

The customer file has a CEP for nearly everyone, and there are public web services that take a CEP
and return the street, the neighbourhood and the city. Calling one for each customer looks like the
obvious enrichment. **This lesson does not do it, and nothing in this section was run.** The
reasons are the point.

**A CEP sent to a web service is personal data leaving the company.** On its own a postcode narrows a
person down to a street or a building, and the request also carries the time, the company's network
address and, if the code loops over customers, the order in which they appear. Under the LGPD,
handing customers' data to a third party needs a legal basis and has to be covered by what the
company told its customers. That is a question for whoever is responsible for data protection,
before the first request, not after the hundredth.

Even where it is allowed, an API call has three properties a local file does not:

- **It changes.** The same request next month can return a different answer, and an analysis that
  cannot be rerun with the same inputs cannot be checked.
- **It fails.** A timeout, a rate limit or a service that has been switched off turns into blanks,
  and blanks from an enrichment are lesson 3's problem in a new place.
- **It leaves no record** unless you make one. Which version of the service answered, on which day,
  is exactly the provenance the previous section asked for.

So the safe pattern, when outside data really is needed, is the one the lab already follows:

1. **Prefer a downloaded reference file to a per-record lookup.** IBGE publishes its codes as files,
   and postcode directories are distributed as files too. A file is fetched once, sends nothing
   about your customers, and can be stored next to the analysis.
2. **When a lookup is unavoidable, send the least you can**: a CEP and never a name, an e-mail or a
   customer code.
3. **Store what came back, with its date**, and enrich from the stored copy. The analysis then
   depends on a file you keep, not on a service you do not control.
