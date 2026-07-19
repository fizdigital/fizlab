# Homologação da Sprint 3 no Galaxy A15

Data: a preencher
Responsável: a preencher
Commit testado: a preencher

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

- [ ] Instalação aprovada
- [ ] Reinstalação aprovada
- [ ] Testes automatizados aprovados
- [ ] Boot automático aprovado
- [ ] Dashboard no próprio A15 aprovado
- [ ] Dashboard em outro dispositivo aprovado
- [ ] API aprovada
- [ ] SSH e cron sem regressões
- [ ] Atualização aprovada

Observações, consumo de memória, armazenamento e eventuais erros:

```text
Preencher após os testes reais.
```
