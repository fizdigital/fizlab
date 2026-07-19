# FizLab Roadmap

Este documento descreve a evolução planejada do FizLab.

O roadmap é dividido por versões para manter o projeto organizado, testável e reutilizável.

---

# v0.1.0 — Foundation ✅

Objetivo: criar a base do projeto.

## Implementado

- Estrutura do projeto
- Git local
- install.sh
- update.sh
- doctor.sh
- startup.sh
- Perfis Termux e Debian
- Biblioteca comum (`lib/common.sh`)

Status: ✅ Concluído

---

# v0.2.0 — Android Server

Objetivo: transformar o Galaxy A15 em um servidor confiável.

## Planejado

- Corrigir boot automático
- Inicialização dos serviços
- Watchdog
- Atualizações automáticas
- Rotina de limpeza
- Backups automáticos
- Logs centralizados
- Health Check

Status: 🚧 Em desenvolvimento

---

# v0.3.0 — Core Services

Objetivo: instalar os principais serviços através do FizLab.

## Planejado

- Git
- Python
- PHP
- Nginx
- SQLite
- MariaDB
- Node.js
- Cron

Status: 📋 Planejado

---

# v0.4.0 — Dashboard

Objetivo: administrar o servidor via navegador.

## Planejado

- Dashboard Web
- Status dos serviços
- Uso de CPU
- Uso de memória
- Uso de armazenamento
- Logs
- Atualizações
- Backups
- Informações da rede

Status: 📋 Planejado

---

# v0.5.0 — Remote Access

Objetivo: acessar o servidor de qualquer lugar.

## Planejado

- Tailscale
- WireGuard
- DDNS
- HTTPS
- Cloudflare Tunnel (opcional)
- Firewall

Status: 📋 Planejado

---

# v0.6.0 — Modular Installer

Objetivo: instalar serviços através de módulos.

Exemplos:

```bash
fizlab install nginx

fizlab install mariadb

fizlab install python

fizlab install minecraft
```

Status: 📋 Planejado

---

# v1.0.0 — Stable Release

Primeira versão estável do FizLab.

Objetivos:

- Instalação automatizada
- Dashboard completo
- Monitoramento
- Backups
- Atualizações
- Documentação completa
- Compatibilidade com Android, VPS e Linux
