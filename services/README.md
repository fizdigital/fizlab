# Módulos de serviços

Cada diretório representa um serviço administrado pelo FizLab. Os módulos devem
ser idempotentes e oferecer scripts pequenos com uma única responsabilidade,
como `configure.sh`, `start.sh` e `stop.sh`.

Configurações editáveis ficam em `$SERVER_HOME/config`; estado de execução e
arquivos PID ficam em `$SERVER_HOME/run`. O código do repositório permanece
imutável durante a operação normal.
