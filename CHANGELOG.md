# Changelog

## 0.4.0-alpha.1 — Sprint 4

### Adicionado

- Watchdog portátil com lock, cooldown e recuperação de API/Nginx.
- Manutenção segura com simulação, rotação e retenção de logs.
- Agendamentos idempotentes no cron.
- Histórico operacional no SQLite.
- Catálogo e leitura limitada de logs pela API.
- Painel de monitoramento e visualização de logs no dashboard.
- Testes de segurança de caminhos, retenção e concorrência.

### Segurança

- A API aceita somente identificadores de logs cadastrados.
- Limites de linhas e bytes impedem respostas excessivas.
- Configurações, bancos, backups e arquivos do usuário não entram na limpeza.

### Homologação

- Galaxy A15 / Termux: aprovada em 20/07/2026.
- Doctor: 29 aprovações, 0 avisos e 0 falhas.
- Recuperação automática de API e Nginx, cron, manutenção, logs, dashboard e boot real aprovados.

## 0.3.0-alpha.1 — Sprint 3

### Adicionado

- Fundação modular de serviços.
- Configuração portável por `$SERVER_HOME`.
- Coletor JSON de informações do sistema.
- Integração JSON do FizLab Doctor.
- Nginx na porta configurável `8080`.
- API Python somente leitura.
- Dashboard responsivo.
- Banco SQLite com migração idempotente.
- Inicialização automática da API e do Nginx.
- Testes de instalação, API, Nginx, SQLite e regressão do boot.

### Decisões

- PHP permanece opcional e não é dependência do dashboard.
- MariaDB será um módulo opcional após avaliação de recursos no Galaxy A15.

### Homologação

- Galaxy A15 com Termux e Python 3.14.6.
- Testes automatizados integralmente aprovados.
- Boot automático de SSH, cron, API e Nginx aprovado após reinicialização real.
- FizLab Doctor com 26 aprovações, 0 avisos e 0 falhas.
- API e dashboard acessíveis após o boot sem abertura manual do Termux.
- Dashboard aprovado com identidade visual oficial da Fiz Digital.
