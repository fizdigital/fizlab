# Android com Termux

## Requisitos

- Termux e Termux:Boot instalados pela mesma origem confiável.
- Termux aberto ao menos uma vez.
- Restrições de bateria removidas para os dois aplicativos.
- Wi-Fi de 5 GHz e IP reservado no roteador.

## Atualização da Sprint 3

No Galaxy A15:

```bash
cd ~/server/git/working/fizlab
git fetch origin
git switch sprint-3/core-services-dashboard
git pull --ff-only
./tests/run.sh
./install.sh
source ~/.bashrc
fizlab-start
fizlab-doctor
```

Abra no celular e depois em outro dispositivo da rede:

```text
http://IP_DO_A15:8080
```

## Logs

```bash
tail -n 100 ~/server/logs/python/fizlab-api.log
tail -n 100 ~/server/logs/nginx/error.log
ls -lt ~/server/logs/system
```

## Portas padrão

- `8022`: SSH do Termux.
- `8080`: dashboard via Nginx.
- `8765`: API interna; aceita conexões apenas de `127.0.0.1`.

Não exponha a porta `8080` diretamente à internet. O acesso remoto seguro será
tratado na etapa de Tailscale/HTTPS.
