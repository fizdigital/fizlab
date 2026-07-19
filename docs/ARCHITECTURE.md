# Arquitetura do FizLab

## Visão Geral

O FizLab é uma plataforma modular para provisionamento, configuração, monitoramento e manutenção de servidores.

O projeto foi concebido para funcionar em diferentes ambientes, utilizando uma única base de código.

Ambientes suportados:

- Android (Termux)
- Debian
- Ubuntu
- Raspberry Pi OS
- Mini PCs
- VPS Linux

---

# Arquitetura

```
               +----------------------+
               |     install.sh       |
               +----------+-----------+
                          |
                 detect_platform()
                          |
          +---------------+---------------+
          |                               |
      profiles/                      lib/common.sh
          |                               |
          +---------------+---------------+
                          |
                    scripts/
                          |
        +-----------------+-----------------+
        |                 |                 |
     doctor           update            startup
                          |
                     Serviços
                          |
      SSH • Python • PHP • Nginx • MariaDB
```

---

# Estrutura do projeto

```
fizlab/

install.sh

lib/
    common.sh

profiles/
    termux.sh
    debian.sh

scripts/
    doctor.sh
    update.sh
    startup.sh

docs/

templates/

config/
```

---

# Estrutura do servidor

Por padrão:

```
~/server
```

No futuro este caminho poderá ser configurado através da variável:

```
FIZLAB_HOME
```

Assim o servidor poderá ser instalado em qualquer diretório.

---

# Filosofia

Cada módulo deve possuir apenas uma responsabilidade.

Exemplo:

doctor.sh

Responsável apenas pelo diagnóstico.

Não deve instalar pacotes.

Não deve iniciar serviços.

---

update.sh

Responsável apenas pela atualização.

---

startup.sh

Responsável apenas pela inicialização.

---

install.sh

Responsável apenas pela instalação.

---

# Perfis

Cada sistema operacional possui um perfil.

Exemplo:

profiles/

termux.sh

debian.sh

ubuntu.sh

raspberry.sh

Cada perfil sabe instalar os pacotes corretos para aquela plataforma.

---

# Serviços

Todos os serviços serão modulares.

Exemplos:

SSH

Python

PHP

MariaDB

SQLite

Nginx

Docker

Minecraft

Cada serviço possuirá seu próprio instalador.

---

# Dashboard

O Dashboard será apenas um consumidor das informações.

Ele nunca executará comandos diretamente.

Toda comunicação ocorrerá através dos módulos do FizLab.

## Fluxo implementado

```text
Navegador :8080
      |
    Nginx
      |
      +-- /             -> dashboard estático
      +-- /api/v1/*     -> API Python 127.0.0.1:8765
                               |
                         system_info.py
                               |
                  sistema, serviços e Doctor
```

A API escuta apenas no endereço de loopback. O Nginx é o único serviço web
exposto à rede local. O dashboard é somente leitura e não executa comandos do
sistema.

## Estado e configuração

```text
$SERVER_HOME/config/fizlab.env
$SERVER_HOME/config/nginx.conf
$SERVER_HOME/run/
$SERVER_HOME/databases/sqlite/fizlab.db
$SERVER_HOME/logs/nginx/
$SERVER_HOME/logs/python/
```

Os arquivos em `$SERVER_HOME/config` são preservados em reinstalações. Os
módulos de serviço ficam em `services/` e devem ser idempotentes.

---

# Objetivo

O mesmo código deve ser capaz de instalar e administrar servidores em diferentes plataformas sem alterações na estrutura do projeto.
