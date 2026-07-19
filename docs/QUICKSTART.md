# Início rápido

```bash
git clone https://github.com/fizdigital/fizlab.git
cd fizlab
./install.sh
source ~/.bashrc
fizlab-start
fizlab-doctor
```

Descubra o IP apresentado pelo Doctor e acesse:

```text
http://IP_DO_SERVIDOR:8080
```

Comandos principais:

```bash
fizlab-doctor
fizlab-doctor --json
fizlab-services status
fizlab-services restart
fizlab-update
```

Configurações locais ficam em `~/server/config/fizlab.env` por padrão.
