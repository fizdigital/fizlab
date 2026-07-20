# FizLab

> Infrastructure Automation Toolkit for Android, Linux, VPS and Home Servers.

FizLab é uma plataforma open source desenvolvida pela **Fiz Digital** para provisionar, configurar, monitorar e manter servidores de forma padronizada.

O projeto nasceu utilizando um Samsung Galaxy A15 com Termux como primeiro ambiente de testes, mas foi projetado para funcionar em qualquer ambiente Linux compatível.

---

# Objetivos

- Provisionamento automatizado
- Configuração padronizada
- Atualizações simplificadas
- Monitoramento
- Backups
- Dashboard Web
- Acesso remoto seguro
- Instalação modular de serviços

---

# Plataformas

| Plataforma | Status |
|------------|--------|
| Android (Termux) | ✅ Em desenvolvimento |
| Ubuntu | 🚧 Planejado |
| Debian | 🚧 Planejado |
| Raspberry Pi OS | 🚧 Planejado |
| Mini PC Linux | 🚧 Planejado |
| VPS Linux | 🚧 Planejado |

---

# Estrutura

```
install.sh
lib/
profiles/
scripts/
config/
templates/
docs/
```

---

# Estado atual

Implementado:

- Estrutura inicial
- Install
- Update
- Doctor
- Startup
- Boot (Termux)

Em desenvolvimento:

- Dashboard Web inicial
- API de status
- Monitoramento
- Backups
- Nginx multiplataforma
- Python e SQLite
- MariaDB
- Tailscale

---

# Instalação

```bash
git clone https://github.com/fizdigital/fizlab.git

cd fizlab

./install.sh
```

---

# Roadmap

Veja:

[ROADMAP.md](ROADMAP.md)

## Dashboard e API

Depois da instalação, inicie os serviços:

```bash
fizlab-start
```

O dashboard fica disponível por padrão em:

```text
http://IP_DO_SERVIDOR:8080
```

A API oferece os endpoints `/api/v1/health`, `/api/v1/system`,
`/api/v1/services`, `/api/v1/doctor`, `/api/v1/status`, `/api/v1/monitoring`,
`/api/v1/logs` e `/api/v1/events`.

Comandos operacionais:

```bash
fizlab-watchdog
fizlab-maintenance --dry-run
fizlab-maintenance
```

---

# Licença

MIT License

---

# Desenvolvido por

**Fiz Digital**

https://github.com/fizdigital
