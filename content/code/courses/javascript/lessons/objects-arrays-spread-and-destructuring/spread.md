---
title: Spreading and gathering
---

The same three dots do opposite things depending on which side they are on: on the right they **spread**, on the left they **gather**.

```schooling-example
{
  "language": "javascript",
  "file": "spread.js",
  "parts": [
    {
      "code": "const base = { theme: \"dark\", language: \"pt\" };\nconst fresh = { ...base, language: \"en\" };\nconsole.log(fresh);",
      "note": "A copy with a change, without touching the original. The order decides who wins: the last repeated key overwrites — which is why `language` comes out as `en`."
    },
    {
      "code": "const a = [1, 2];\nconst b = [0, ...a, 3];\nconsole.log(b);",
      "note": "The same for an array, keeping the order. It replaces `concat` and the old `push.apply`."
    },
    {
      "code": "function sum(...numbers) {\n  return numbers.reduce((t, n) => t + n, 0);\n}\nconsole.log(sum(1, 2, 3, 4));",
      "note": "On the other side: here the dots GATHER the arguments into a real array. It is the replacement for `arguments`, which was not an array and does not exist in an arrow function."
    },
    {
      "code": "const orig = { owner: { name: \"Ana\" } };\nconst copy = { ...orig };\ncopy.owner.name = \"Bia\";\nconsole.log(orig.owner.name);",
      "note": "The gotcha: the copy is SHALLOW. The inner object is still the same one, and changing it changes both. For a deep copy there is `structuredClone`."
    }
  ],
  "output": "{ theme: 'dark', language: 'en' }\n[ 0, 1, 2, 3 ]\n10\nBia"
}
```
