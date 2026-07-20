# Changelog

## 0.5.0-alpha.1 — Sprint 5

### Adicionado

- Diagnóstico da superfície de rede com identificação de portas e serviços conhecidos.
- Comando `fizlab-remote` para status, auditoria e preparação da política SSH.
- Modo de dashboard `tailnet`, que permite apenas localhost e os intervalos privados do Tailscale.
- Política SSH validada antes de aplicar: chave obrigatória, senha desativada e acesso limitado à Tailnet.
- Endpoint `/api/v1/remote-access` e resumo de acesso remoto no dashboard.
- Testes de auditoria de portas, API e regras Nginx.

### Segurança

- Nenhuma restrição é ativada automaticamente durante a atualização.
- O SSH só entra em modo endurecido após `fizlab-remote secure-ssh --apply` validar uma chave autorizada.
- A API continua vinculada a `127.0.0.1` e não é exposta pela Tailnet.

### Homologação

- Galaxy A15 / Termux: aprovada em 20/07/2026.
- Doctor: 31 aprovações, 0 avisos e 0 falhas.
- Tailscale reconectou automaticamente após reinicialização do Android.
- SSH por chave e dashboard validados pela Tailnet e por hotspot móvel.
- Login SSH por senha e dashboard pela LAN foram bloqueados conforme esperado.

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
