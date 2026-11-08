---
type: llm
weight: 1
---

TASK-1's title ends up as "Renamed task", and the change was made through the
backlog CLI (for example `backlog task edit 1 -t "Renamed task"`). No Edit,
Write or shell redirection wrote a file under .backlog/ successfully: a direct
write was either refused by the backlog-guard hook or never attempted.
