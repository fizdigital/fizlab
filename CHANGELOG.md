# Changelog

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
