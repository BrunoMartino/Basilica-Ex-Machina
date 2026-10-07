---
description: Data sent to LLMs is TOON-formatted; no exceptions
---

# LLM payloads

All data passed to an LLM is **TOON** (Token-Oriented Object Notation). No exceptions.
Never JSON: tokens cost money and JSON spends them on structure.

Spec: https://github.com/toon-format/toon — encode with an official implementation
(`@toon-format/toon` or a port listed at https://toonformat.dev/ecosystem/implementations), never hand-built strings.

- Objects: `key: value`, nesting by 2-space indent
- Inline form: `key[N]: a,b,c`
- Tabular form: `key[N]{f1,f2}:` then one row per item
- Nested field group: `f{sub1,sub2}` in the header, rows stay flat
- Keyed tabular: `key[N:]{f1,f2}:` then `id: v1,v2` per row
- Wrap payloads in ` ```toon ` blocks; when asking the model to produce TOON, show the expected header

```toon
location:
  city: Berlin
  country: DE
  units: metric
alerts[2]: frost,wind
forecast[3]{day,temp{min,max},condition,rainChance}:
  Mon,-2,4,snow,80
  Tue,1,7,cloudy,20
  Wed,3,11,sunny,5
```

```toon
environments[2:]{region,replicas,debug}:
  production: eu-central-1,6,false
  staging: eu-central-1,2,true
```
