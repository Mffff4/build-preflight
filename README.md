# build-preflight

Сверка версий окружения с манифестом сборки. Только чтение, без сети и записи.

```
bash preflight.sh            # манифест по умолчанию .build-manifest
bash tests/run.sh            # self-check
```

Выход: 0 — совпало, 1 — расхождение, 2 — нет манифеста.
Сравнение по веткам: python major.minor, node major.
