# Homologação da Sprint 4 no Galaxy A15

Este roteiro valida monitoramento, logs e manutenção no ambiente real do FizLab.

## 1. Atualização e regressão

```bash
cd ~/server/git/working/fizlab
git pull --ff-only
./install.sh
./tests/run.sh
fizlab-doctor
```

## 2. Watchdog saudável

```bash
fizlab-watchdog
fizlab-services status
tail -n 50 ~/server/logs/system/watchdog.log
```

O comando deve terminar sem reiniciar serviços já saudáveis.

## 3. Recuperação da API

```bash
cd ~/server/git/working/fizlab
bash services/api/stop.sh
fizlab-watchdog
curl -fsS http://127.0.0.1:8765/api/v1/health
```

A API deve voltar a responder e registrar `service_recovered`.

## 4. Recuperação do Nginx

```bash
bash services/nginx/stop.sh
fizlab-watchdog
curl -fsS http://127.0.0.1:8080/api/v1/health
```

O dashboard deve voltar sem criar processos duplicados.

## 5. Manutenção segura

```bash
fizlab-maintenance --dry-run
fizlab-maintenance
fizlab-maintenance --status
```

O modo de simulação não pode alterar arquivos. Bancos, backups, configurações,
sites, mídia e repositórios devem permanecer intactos.

## 6. Dashboard

Acesse `http://IP_DO_A15:8080` e confirme:

- datas do último watchdog e da última manutenção;
- volume dos logs;
- seleção e atualização de logs;
- funcionamento em tela de celular e computador.

## 7. Reinicialização e estabilidade

Reinicie o Android e, sem abrir manualmente o Termux, confirme SSH, cron, API,
Nginx, dashboard e uma execução do watchdog em até cinco minutos. Mantenha o
servidor por 24 horas e confirme que não há processos duplicados, ciclos de
reinicialização ou crescimento descontrolado dos logs.
