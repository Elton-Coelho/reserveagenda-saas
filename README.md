# 🧭 ReserveAgenda SaaS Installer (v1.2)

Repositório público responsável pela instalação automatizada do sistema ReserveAgenda.

## ⚙️ Estrutura
- **instalar/** → scripts de instalação
- **releases/** → pacote de ferramentas e instalador principal
- **assets/** → logos, banners e áudios

## 🚀 Instalação rápida
Execute o comando abaixo em sua VPS (Ubuntu 22.04+):

```bash
curl -sSL instalar.reserveagenda.com.br | sudo bash
```

## 🔒 Integração com Core Privado
O instalador clona o repositório privado `reserveagenda-core` usando token seguro no `.secrets.env`.

## 📦 Desenvolvido por
Grupo Shark • Super Zapp / ReserveAgenda
