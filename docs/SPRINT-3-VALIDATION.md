# Homologação da Sprint 3 no Galaxy A15

Data: 19/07/2026
Responsável: Renan Sales
Commit testado: `d2b8837`

## 1. Preparação

```bash
cd ~/server/git/working/fizlab
git status
git fetch origin
git switch sprint-3/core-services-dashboard
git pull --ff-only
git rev-parse --short HEAD
```

O `git status` deve estar limpo antes da troca de branch.

## 2. Testes e instalação

```bash
./tests/run.sh
./install.sh
source ~/.bashrc
fizlab-start
fizlab-doctor
curl -fsS http://127.0.0.1:8080/api/v1/health
curl -fsS http://127.0.0.1:8080/api/v1/status
```

Critérios:

- Todos os testes mostram `OK`.
- Doctor termina sem falhas.
- Health retorna JSON com `status: healthy`.
- Dashboard abre no A15 e em outro dispositivo da rede.

## 3. Reinicialização

Reinicie o Galaxy A15 normalmente. Aguarde cerca de um minuto e, por SSH:

```bash
fizlab-doctor
fizlab-services status
curl -fsS http://127.0.0.1:8080/api/v1/health
```

Confirme também `http://IP_DO_A15:8080` em outro dispositivo.

## 4. Idempotência e atualização

```bash
./install.sh
fizlab-services restart
fizlab-doctor
git pull --ff-only
./tests/run.sh
```

O arquivo `~/server/config/fizlab.env` e o banco
`~/server/databases/sqlite/fizlab.db` devem permanecer existentes.

## 5. Registro dos resultados

Preencher:

- [x] Instalação aprovada
- [x] Reinstalação aprovada
- [x] Testes automatizados aprovados
- [x] Boot automático aprovado
- [x] Dashboard no próprio A15 aprovado
- [x] Dashboard em outro dispositivo aprovado
- [x] API aprovada
- [x] SSH e cron sem regressões
- [x] Atualização aprovada

Observações, consumo de memória, armazenamento e eventuais erros:

```text
Plataforma: Termux no Samsung Galaxy A15
Python: 3.14.6
IP local reservado: 192.168.1.20
Doctor: 26 aprovados, 0 avisos, 0 falhas
Serviços: ssh, cron, nginx e api saudáveis
Health check: status healthy / node_status healthy
Dashboard: aprovado com identidade visual Fiz Digital
```

Durante a homologação, foram identificadas e corrigidas duas particularidades
do Android/Termux: ausência de `os.getloadavg()` no Python 3.14 e
indisponibilidade de `/usr/bin/env` no contexto inicial do Termux:Boot. O
coletor passou a usar `/proc/loadavg` como alternativa e os módulos internos
passaram a ser executados explicitamente com Bash.
