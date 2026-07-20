# Homologação da Sprint 5 — Acesso remoto seguro

Este roteiro valida a administração privada do FizLab no Samsung Galaxy A15,
usando o aplicativo oficial do Tailscale para Android e sem abrir portas no
roteador.

## Resultado da homologação — Galaxy A15

Homologado em 20/07/2026 no Samsung Galaxy A15 com Termux.

- suíte `./tests/run.sh` aprovada;
- Doctor aprovado com 31 verificações, 0 avisos e 0 falhas;
- Tailscale configurado como VPN sempre ativa, sem restrições de bateria e com
  reconexão automática após a reinicialização do Android;
- SSH validado pela Tailnet na porta `8022` com chave privada protegida por senha;
- autenticação por senha recusada após a aplicação da política SSH;
- dashboard validado pela Tailnet em `http://100.118.0.46:8080`;
- dashboard pela LAN (`192.168.1.20:8080`) bloqueado com `403 Forbidden`;
- conexão SSH e dashboard testados também por hotspot móvel;
- API mantida internamente em `127.0.0.1:8765`.

Status: **aprovado**.

## Escopo

- SSH do Termux pela Tailnet, na porta `8022`;
- dashboard Nginx na porta `8080`, restrito à Tailnet;
- API FizLab mantida apenas em `127.0.0.1:8765`;
- auditoria de portas e política SSH por chaves.

Esta Sprint **não** publica sites, APIs ou Minecraft para a internet pública.
Tailscale é a camada de administração privada do servidor.

## Pré-requisitos

1. O código do A15 está atualizado na `main` ou na branch da Sprint 5.
2. O Termux e Termux:Boot não possuem restrição de bateria.
3. O aplicativo Tailscale foi instalado pela Play Store no Galaxy A15 e em um
   segundo dispositivo confiável, como o notebook Lenovo.
4. Os dois dispositivos estão autenticados na mesma Tailnet e aparecem como
   conectados no painel do Tailscale.
5. Não há redirecionamento de portas no roteador para `8022`, `8080` ou `8765`.

## 1. Atualizar e verificar o FizLab

No A15:

```bash
cd ~/server/git/working/fizlab
git switch sprint-5/secure-remote-access
git pull --ff-only
./tests/run.sh
fizlab-doctor
fizlab-remote status
```

Antes da política final, o Doctor deve apenas alertar que o dashboard ainda está
na LAN e que a política SSH não foi aplicada. Esses avisos são esperados nesta
fase. Em Android sem root, a auditoria pode informar `Visibilidade limitada`:
isso ocorre quando o sistema não permite ao Termux enumerar as portas em escuta.
Nesse caso, os testes reais de SSH, dashboard e API abaixo são a validação
autoritativa da exposição.

## 2. Testar SSH pela Tailnet

No notebook, obtenha o nome MagicDNS ou IP atribuído ao A15 pelo aplicativo ou
painel do Tailscale. Em seguida, teste:

```bash
ssh -p 8022 u0_a332@NOME_OU_IP_TAILSCALE_DO_A15
```

Repita o teste usando outra conexão de internet (por exemplo, hotspot móvel).
Não prossiga se o SSH pela Tailnet não funcionar de forma estável.

## 3. Validar chave SSH antes de desabilitar senha

No notebook, crie uma chave caso ainda não exista e copie somente a chave pública
para o A15. Confirme que uma nova sessão abre sem solicitar senha:

```bash
ssh -p 8022 -o PreferredAuthentications=publickey -o PasswordAuthentication=no \
  u0_a332@NOME_OU_IP_TAILSCALE_DO_A15
```

No A15, confirme a existência da chave:

```bash
test -s ~/.ssh/authorized_keys && echo "Chave autorizada encontrada"
```

## 4. Restringir primeiro o dashboard

No A15, edite `~/server/config/fizlab.env` e defina:

```bash
FIZLAB_DASHBOARD_ACCESS=tailnet
```

Em seguida:

```bash
cd ~/server/git/working/fizlab
bash services/nginx/configure.sh
fizlab-remote audit
```

Valide no notebook:

```text
http://NOME_OU_IP_TAILSCALE_DO_A15:8080
```

O endereço `http://192.168.1.20:8080` deve retornar acesso negado após a regra
ser aplicada. A porta `8765` nunca deve responder fora do próprio A15.

## 5. Aplicar a política SSH

Mantenha uma sessão local do Termux aberta no A15. Somente após a validação da
chave e do dashboard pela Tailnet, execute:

```bash
fizlab-remote secure-ssh --apply
```

O comando cria `~/server/config/sshd_config`, valida a sintaxe antes de salvar e
marca a política para o próximo boot. A política resultante:

- aceita somente chave pública;
- desabilita senha e autenticação interativa;
- limita novas sessões SSH às faixas da Tailnet;
- preserva o encaminhamento necessário para ferramentas como VS Code Remote SSH.

Reinicie o A15. Depois do boot, valide novamente uma sessão SSH pela Tailnet e
confirme que uma tentativa por senha é recusada.

## 6. Auditoria final e reversão

Depois do boot:

```bash
fizlab-doctor
fizlab-remote status
fizlab-remote audit
```

Critérios de aprovação:

- SSH por chave funciona pela Tailnet em uma rede externa;
- senha SSH é recusada;
- dashboard abre somente pela Tailnet;
- dashboard pela LAN é negado;
- API continua exclusiva de `127.0.0.1:8765`;
- nenhuma porta foi encaminhada no roteador;
- Doctor não possui falhas e os testes automatizados são aprovados;
- após reiniciar o A15, Tailscale, SSH, API e Nginx permanecem disponíveis.

Se for necessário reverter o dashboard antes da política SSH, defina
`FIZLAB_DASHBOARD_ACCESS=lan` e execute `bash services/nginx/configure.sh` no
Termux. Para qualquer problema com SSH, use o Termux local no A15 para ajustar
`~/server/config/fizlab.env`, remover `~/server/config/sshd_config` e reiniciar
o aparelho. Nunca aplique a política SSH sem antes testar uma chave pela
Tailnet.
