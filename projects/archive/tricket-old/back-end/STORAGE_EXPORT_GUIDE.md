# 📦 Guia de Exportação do Storage do Supabase Self-Hosted

## 📋 Métodos de Exportação

### 1. **Exportação Simples (Cópia Direta)**

```bash
# Copiar todo o storage preservando a estrutura
cp -r /home/joaohenrique/workspaces/projects/tricket/back-end/volumes/storage ~/backup-storage-$(date +%Y%m%d)

# Copiar apenas as imagens de produtos
cp -r /home/joaohenrique/workspaces/projects/tricket/back-end/volumes/storage/stub/stub/product-images ~/backup-product-images-$(date +%Y%m%d)
```

### 2. **Usando o Script Python (Recomendado)**

#### **Instalar dependências:**
```bash
# O script usa apenas bibliotecas padrão do Python, sem necessidade de instalação
python3 --version  # Verificar se Python 3 está instalado
```

#### **Exemplos de uso:**

```bash
cd /home/joaohenrique/workspaces/projects/tricket/back-end

# 1. Exportar todo o storage organizando por tipo de arquivo
python3 export_storage.py --source ./volumes/storage --destination ~/exported-storage

# 2. Exportar apenas imagens de produtos
python3 export_storage.py --source ./volumes/storage --destination ~/exported-product-images --bucket product-images

# 3. Exportar preservando a estrutura original
python3 export_storage.py --source ./volumes/storage --destination ~/exported-storage-original --preserve-structure

# 4. Exportar e criar arquivo compactado
python3 export_storage.py --source ./volumes/storage --destination ~/exported-storage --create-archive --archive-name backup-$(date +%Y%m%d)

# 5. Exportar apenas um bucket específico
python3 export_storage.py --source ./volumes/storage --destination ~/exported-app-images --bucket app-images
```

### 3. **Usando tar/zip para Backup Completo**

```bash
cd /home/joaohenrique/workspaces/projects/tricket/back-end

# Criar backup compactado com tar
tar -czf ~/supabase-storage-backup-$(date +%Y%m%d).tar.gz volumes/storage/

# Criar backup compactado com zip
zip -r ~/supabase-storage-backup-$(date +%Y%m%d).zip volumes/storage/

# Apenas as imagens de produtos
tar -czf ~/product-images-backup-$(date +%Y%m%d).tar.gz volumes/storage/stub/stub/product-images/
```

### 4. **Sincronização com rsync**

```bash
# Sincronizar para outro diretório (útil para backups incrementais)
rsync -av --progress /home/joaohenrique/workspaces/projects/tricket/back-end/volumes/storage/ ~/backup-storage/

# Sincronizar apenas imagens de produtos
rsync -av --progress /home/joaohenrique/workspaces/projects/tricket/back-end/volumes/storage/stub/stub/product-images/ ~/backup-product-images/
```

## 🗂️ Estrutura dos Arquivos

O Supabase storage usa a seguinte estrutura:
```
volumes/storage/
└── stub/
    └── stub/
        ├── product-images/
        │   ├── [uuid]/
        │   │   └── [filename]/
        │   │       └── [file-id]  # Arquivo real
        ├── app-images/
        └── emails/
```

## 📊 Estatísticas Atuais

- **Total de arquivos em product-images**: 376 arquivos
- **Buckets disponíveis**: 
  - `product-images` (imagens de produtos)
  - `app-images` (imagens da aplicação)
  - `emails` (arquivos de email)

## 🔧 Opções do Script Python

| Parâmetro | Descrição | Exemplo |
|-----------|-----------|---------|
| `--source` `-s` | Diretório source do storage | `./volumes/storage` |
| `--destination` `-d` | Diretório de destino | `~/exported-files` |
| `--bucket` `-b` | Bucket específico para exportar | `product-images` |
| `--preserve-structure` `-p` | Manter estrutura original | - |
| `--create-archive` `-a` | Criar arquivo compactado | - |
| `--archive-name` | Nome do arquivo compactado | `backup-2025` |

## 💡 Dicas e Boas Práticas

### **1. Verificar espaço em disco:**
```bash
# Verificar tamanho do storage atual
du -sh /home/joaohenrique/workspaces/projects/tricket/back-end/volumes/storage

# Verificar espaço disponível
df -h ~
```

### **2. Fazer backup regular:**
```bash
# Criar um cron job para backup automático
# Editar crontab: crontab -e
# Adicionar linha para backup diário às 2h da manhã:
# 0 2 * * * cd /home/joaohenrique/workspaces/projects/tricket/back-end && tar -czf ~/backups/storage-$(date +\%Y\%m\%d).tar.gz volumes/storage/
```

### **3. Verificar integridade dos arquivos:**
```bash
# Contar arquivos no original
find /home/joaohenrique/workspaces/projects/tricket/back-end/volumes/storage -type f | wc -l

# Contar arquivos no backup
find ~/exported-storage -type f | wc -l
```

### **4. Monitorar o processo:**
```bash
# Usar o comando watch para monitorar o progresso
watch -n 5 'ls -la ~/exported-storage/ | wc -l'
```

## 🆘 Solução de Problemas

### **Erro de permissão:**
```bash
# Verificar permissões
ls -la /home/joaohenrique/workspaces/projects/tricket/back-end/volumes/storage

# Ajustar permissões se necessário
sudo chown -R $USER:$USER /home/joaohenrique/workspaces/projects/tricket/back-end/volumes/storage
```

### **Espaço insuficiente:**
```bash
# Limpar espaço ou usar destino externo
# Exemplo: usar um HD externo montado em /mnt/backup
python3 export_storage.py --source ./volumes/storage --destination /mnt/backup/supabase-export
```

### **Arquivos muito grandes:**
```bash
# Usar compressão mais agressiva
tar -czf backup.tar.gz --best volumes/storage/

# Ou dividir em partes menores
tar -czf - volumes/storage/ | split -b 1G - backup.tar.gz.part
```

## 📝 Logs e Monitoramento

O script Python fornece relatórios detalhados mostrando:
- ✅ Total de arquivos copiados
- 📊 Tipos de arquivo encontrados
- ❌ Erros (se houver)
- 📁 Localização dos arquivos exportados

## 🔄 Restauração

Para restaurar os arquivos:

```bash
# Se manteve a estrutura original
cp -r ~/exported-storage/* /home/joaohenrique/workspaces/projects/tricket/back-end/volumes/storage/

# Se organizou por tipo, será necessário recriar a estrutura manualmente
# ou usar o backup completo com estrutura preservada
```
