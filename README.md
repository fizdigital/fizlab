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

- Dashboard
- Monitoramento
- Backups
- Nginx
- Python
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

```
docs/ROADMAP.md
```

---

# Licença

MIT License

---

# Desenvolvido por

**Fiz Digital**

https://github.com/fizdigital
