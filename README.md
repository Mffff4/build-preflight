# build-preflight

Сверка версий окружения с манифестом сборки. Только чтение, без сети и записи.

```
bash preflight.sh            # манифест по умолчанию .build-manifest
bash tests/run.sh            # self-check
```

Выход: 0 — совпало, 1 — расхождение, 2 — ошибка манифеста.
Сравнение по веткам: python major.minor, node major.
Манифест: только ключи `python` и `node`, без дублей и пустых значений.

CI гоняет тесты `/bin/bash` на macOS 13/14 (bash 3.2) и Ubuntu.
