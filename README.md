# Implantação da Aplicação TCC

Este repositório contém a configuração completa de infraestrutura para implantar a stack da aplicação TCC em produção com certificados SSL e configuração segura.

## 🏗️ Arquitetura

A implantação consiste em:

- **Banco de Dados MySQL** (Bitnami MySQL 8.0) - Persistência de dados
- **API NestJS** (Backend Node.js) - API RESTful com documentação Swagger
- **Aplicação Web Angular** (Frontend) - Single Page Application
- **Nginx** (Proxy reverso) - Balanceador de carga, terminação SSL, servindo arquivos estáticos
- **Certbot** - Gerenciamento automático de certificados SSL via Let's Encrypt

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Nome de domínio configurado e apontando para seu servidor (ex: claucia.com.br)
- Servidor com portas 80 e 443 acessíveis pela internet

## 🚀 Implantação Rápida

### 1. Clonar e Configurar

```bash
git clone <your-repo-url>
cd tcc-infra
```

O arquivo `.env` já deve estar configurado com suas credenciais:

```bash
# Configuração Docker Hub
DOCKERHUB_USERNAME=eduardorfarias
TAG=latest

# Configuração do Banco de Dados
MYSQL_ROOT_PASSWORD=<sua-senha-segura>
MYSQL_PASSWORD=<sua-senha-segura>

# Configuração da API
JWT_SECRET=<seu-jwt-secret-super-seguro>
NODE_ENV=production

# Configuração do Domínio
DOMAIN=claucia.com.br
ADMIN_EMAIL=<seu-email@dominio.com>
```

### 2. Implantação Inicial com SSL

**Para primeira implantação com certificados SSL:**

```bash
# Este script cuida de tudo: certificados temporários, Let's Encrypt e configuração SSL
./scripts/init-letsencrypt.sh
```

O script irá:

- ✅ Baixar parâmetros de segurança TLS
- ✅ Criar certificados SSL temporários para permitir que o nginx inicie
- ✅ Iniciar todos os serviços (MySQL, API, Nginx)
- ✅ Solicitar certificados reais do Let's Encrypt
- ✅ Habilitar configuração SSL e recarregar nginx
- ⚠️ **Nota**: Configuração de renovação automática é separada (veja seção Gerenciamento de Certificados SSL)

### 3. Implantações Regulares

**Para implantações subsequentes (após SSL já configurado):**

```bash
# Script simples de implantação para atualizações
./scripts/deploy.sh
```

## 🔧 Fluxo de Desenvolvimento

### Desenvolvimento Windows (Build & Push de Imagens)

**Quando fazer build e push:**

- ✅ Após mudanças no frontend Angular
- ✅ Após mudanças na API NestJS
- ✅ Após mudanças na configuração nginx
- ❌ Não necessário apenas para mudanças de infraestrutura

**Como fazer build e push:**

**Windows (PowerShell):**

```powershell
# Build e push simples (tag latest)
.\scripts\build-and-push.ps1

# Com tag de versão específica
.\scripts\build-and-push.ps1 -Tag v1.2.0
```

**Linux (Bash):**

```bash
# Build e push simples (tag latest)
./scripts/build-and-push.sh

# Com tag de versão específica
./scripts/build-and-push.sh --tag v1.2.0
```

**O que faz:**

1. 🔨 Faz build do tcc-web (frontend Angular)
2. 🔨 Faz build do tcc-api (backend NestJS)
3. 🔨 Faz build do tcc-nginx (com caminhos de config atualizados)
4. 📤 Envia todas as imagens para Docker Hub

### Implantação Linux

```bash
# Puxa imagens mais recentes e implanta
./scripts/deploy.sh

# Ou manualmente:
docker compose pull
docker compose up -d
```

## 🌐 URLs dos Serviços

Após implantação bem-sucedida, sua aplicação estará disponível em:

- **🔒 Frontend HTTPS**: https://claucia.com.br
- **🔒 API HTTPS**: https://claucia.com.br/api
- **🔒 Documentação da API**: https://claucia.com.br/api/docs
- **📁 Upload de Arquivos**: https://claucia.com.br/uploads
- **💚 Health Check**: https://claucia.com.br/health

_Requisições HTTP redirecionam automaticamente para HTTPS_

## 🗄️ Acesso ao Banco de Dados

### Para DBeaver/Ferramentas de Banco Externas

O banco MySQL está exposto na porta 3306 para debug:

**Configurações de Conexão:**

- **Host:** `claucia.com.br`
- **Porta:** `3306`
- **Banco:** `claucia`
- **Usuário:** `claucia`
- **Senha:** `<do arquivo .env>`

**Acesso Root:**

- **Usuário:** `root`
- **Senha:** `<MYSQL_ROOT_PASSWORD do .env>`

**🔒 Segurança:** Porta 3306 é protegida por regras de firewall baseadas em IP (apenas lista de permitidos).

### Segurança do Firewall

A porta 3306 do banco é protegida por regras de firewall baseadas em IP:

- Apenas IPs na lista de permitidos podem acessar MySQL
- Acesso SSH (porta 22) também é restrito por IP
- HTTP/HTTPS (portas 80/443) estão abertas para acesso web público

Para modificar acesso ao banco, atualize sua lista de IPs permitidos no firewall ao invés de alterar a configuração Docker.

## 🔐 Gerenciamento de Certificados SSL

### Configuração de Renovação Automática

**🔍 Verificar se a renovação automática já está configurada:**

```bash
# Verificar se o timer systemd existe e está ativo
systemctl status tcc-ssl-renewal.timer
```

Se o timer estiver **ativo**, está tudo pronto! Caso contrário, ou se for um servidor novo, configure:

**⚙️ Configurar renovação automática (configuração única por servidor):**

```bash
# Criar serviço systemd
cat > /etc/systemd/system/tcc-ssl-renewal.service << 'EOF'
[Unit]
Description=TCC SSL Certificate Renewal
After=network.target docker.service
Requires=docker.service

[Service]
Type=oneshot
WorkingDirectory=/opt/tcc-infra
ExecStart=/bin/bash -c 'cd /opt/tcc-infra && docker compose run --rm certbot renew && docker compose exec nginx nginx -s reload'
User=root
EOF

# Criar timer systemd
cat > /etc/systemd/system/tcc-ssl-renewal.timer << 'EOF'
[Unit]
Description=TCC SSL Certificate Renewal Timer
Requires=tcc-ssl-renewal.service

[Timer]
OnCalendar=daily
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Habilitar e iniciar o timer
systemctl daemon-reload
systemctl enable tcc-ssl-renewal.timer
systemctl start tcc-ssl-renewal.timer
```

**📅 Monitorando renovação automática:**

```bash
# Verificar status do timer
systemctl status tcc-ssl-renewal.timer

# Verificar próxima execução agendada
systemctl list-timers tcc-ssl-renewal.timer

# Ver logs de renovação
journalctl -u tcc-ssl-renewal.service

# Testar renovação manualmente
systemctl start tcc-ssl-renewal.service
```

### Quando Configuração de Renovação Automática é Necessária

✅ **Persiste através de implantações regulares** - `./scripts/deploy.sh`
✅ **Persiste através de recriações de container** - `docker compose up -d`
✅ **Persiste através de reinicializações do Docker**
❌ **Precisa configurar novamente em servidor novo**
❌ **Precisa configurar novamente após reinstalação do SO**

### Renovação Manual de Certificados

```bash
docker compose run --rm certbot renew
docker compose exec nginx nginx -s reload
```

## 📊 Monitoramento & Gerenciamento

### Verificar Status dos Serviços

```bash
# Ver todos os containers
docker compose ps

# Verificar logs
docker compose logs -f          # Todos os serviços
docker compose logs -f nginx    # Serviço específico
docker compose logs -f api
docker compose logs -f mysql
```

### Health Checks

- **Health da API**: `curl https://claucia.com.br/health`
- **Banco de Dados**: Todos os serviços incluem health checks
- **Certificado SSL**: Navegador mostrará ícone de cadeado verde

## 🛠️ Solução de Problemas

### Problemas Comuns & Soluções

1. **Erros de Certificado SSL**

   ```bash
   # Verificar status do certificado
   docker compose logs certbot

   # Reiniciar configuração SSL
   ./init-letsencrypt.sh
   ```

2. **Nginx Não Iniciando**

   ```bash
   # Verificar logs do nginx
   docker compose logs nginx

   # Verificar configuração
   docker compose exec nginx nginx -t
   ```

3. **Documentação da API (Swagger) Não Carregando**

   - Corrigido na configuração atual com prioridade `location ^~ /api/`
   - Assets do Swagger agora fazem proxy corretamente para API ao invés de servir como arquivos estáticos

4. **App Angular Mostra Página Padrão do Nginx**
   - Corrigido na configuração atual com `root /app/browser;`
   - Nginx agora serve app Angular do diretório correto

### Comandos de Debug

```bash
# Inspecionar containers em execução
docker compose exec nginx sh
docker compose exec api sh
docker compose exec mysql mysql -u claucia -p

# Verificar conectividade de rede
docker network inspect tcc-infra_tcc-network

# Testar certificados SSL
openssl s_client -connect claucia.com.br:443 -servername claucia.com.br
```

## 💾 Backup & Recuperação

### Backup do Banco de Dados

```bash
# Criar backup
docker compose exec mysql mysqldump -u claucia -p claucia > backup-$(date +%Y%m%d).sql

# Restaurar backup
docker compose exec -T mysql mysql -u claucia -p claucia < backup-20240101.sql
```

### Backup de Uploads de Arquivos

```bash
# Backup do volume de uploads
docker run --rm -v tcc-infra_uploads_data:/data -v $(pwd):/backup alpine tar czf /backup/uploads-backup-$(date +%Y%m%d).tar.gz -C /data .

# Restaurar uploads
docker run --rm -v tcc-infra_uploads_data:/data -v $(pwd):/backup alpine tar xzf /backup/uploads-backup-20240101.tar.gz -C /data
```

## 🔒 Recursos de Segurança

- ✅ **Apenas HTTPS** - Todo tráfego criptografado com certificados Let's Encrypt
- ✅ **Headers de Segurança** - HSTS, CSP, X-Frame-Options, etc.
- ✅ **Segurança do Banco** - Isolamento de rede interna + senhas fortes + firewall baseado em IP
- ✅ **Proteção SSH** - Acesso apenas por lista de IPs permitidos
- ✅ **Proteção da API** - CORS, limitação de taxa, validação de entrada
- ✅ **Segurança de Upload** - Manipulação e servimento seguro de arquivos

## 📁 Estrutura do Repositório

```
tcc-infra/
├── README.md               # 📖 Documentação principal
├── docker-compose.yml      # 🐳 Arquivo principal de orquestração
├── .env                    # ⚙️  Variáveis de ambiente
├── .env.example            # 📝 Template de ambiente
├── .gitignore              # 🚫 Regras do git ignore
├── scripts/                # 📜 Scripts de implantação
│   ├── deploy.sh           #   └── Implantação Linux
│   ├── init-letsencrypt.sh #   └── Configuração SSL Linux
│   ├── build-and-push.ps1  #   └── Build & push Windows
│   └── build-and-push.sh   #   └── Build & push Linux
├── config/                 # ⚙️  Arquivos de configuração
│   ├── Dockerfile          #   └── Definição da imagem Nginx
│   └── nginx/              #   └── Configurações Nginx
│       ├── nginx.conf      #       ├── Config HTTP (porta 80)
│       └── nginx-ssl.conf  #       └── Config HTTPS (porta 443)
└── certbot/                # 🔒 Certificados SSL (auto-gerados)
    ├── conf/               #   └── Arquivos de certificado
    └── www/                #   └── Arquivos de desafio ACME
```

## 🚦 Fluxo de Implantação

### **Ciclo de Desenvolvimento:**

1. **💻 Desenvolvimento (Windows ou Linux)**:

   - Fazer mudanças no código (Angular/NestJS/configs nginx)
   - **Windows**: `.\scripts\build-and-push.ps1`
   - **Linux**: `./scripts/build-and-push.sh`
   - Imagens enviadas para Docker Hub

2. **🚀 Implantação em Produção Linux**:

   - **Primeira vez**: `./scripts/init-letsencrypt.sh` (configuração SSL)
   - **Atualizações**: `./scripts/deploy.sh` (puxa imagens mais recentes)
   - Automaticamente puxa imagens Docker mais recentes

3. **📊 Monitoramento & Manutenção**:
   - Verificar logs: `docker compose logs -f`
   - Endpoints de health: `https://claucia.com.br/health`
   - Acesso ao banco: DBeaver com credenciais fornecidas
   - **Uma vez**: Configurar renovação automática SSL (veja Gerenciamento de Certificados SSL)

## 📝 Histórico de Versões

- **v2.0** - Automação SSL, correções nginx, acesso ao banco, documentação abrangente
- **v1.0** - Configuração inicial de implantação Docker

---

**🎯 Resultado**: Aplicação TCC pronta para produção com SSL automático, acesso seguro ao banco e monitoramento abrangente em https://claucia.com.br**

## 🚀 Referência de Comandos Rápidos

```bash
# Configuração SSL primeira vez (Linux)
./scripts/init-letsencrypt.sh

# Implantação regular (Linux)
./scripts/deploy.sh

# Build e push (Windows/Linux)
.\scripts\build-and-push.ps1    # Windows
./scripts/build-and-push.sh     # Linux
```
