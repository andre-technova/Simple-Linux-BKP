## Script de criação de Backup em servidores Linux
##
## Objetivos deste script:
## - Backups completos no domingo
## - Backups incrementais nos outros dias
## - Logs separados por execução, ex: backup-202506111930.log
## - Logs com mais de 14 dias compactados automaticamente para .gz
##
## Resultado esperado
## - Backup:
## - Domingo: /backups/full-2025-06-15.tar.gz
## - Outros dias: /backups/incremental-2025-06-16.tar.gz
##
## Logs:
## - /var/log/backup-logs/backup-202506150200.log
## - Após 14 dias: /var/log/backup-logs/backup-202506150200.log.gz
##
## Instruções rápidas:
## - Salve o script em: /usr/local/bin/backup.sh
## - Dê permissão de execução com o comando: sudo chmod +x /usr/local/bin/backup.sh
## - Agende no crontab do root com o comando: sudo crontab -e
## - Adicione: ## 0 2 * * * /usr/local/bin/backup.sh
##
## Com isso, o backup será feito sempre às 2h da manhã, full aos domingos e incremental nos demais dias,
## com logs organizados e compactação automática dos logs com mais de 14 dias.
## 
## | Sistema / Distro                | Funciona?                                             | Observação                        |
## | ------------------------------- | ----------------------------------------------------- | --------------------------------- |
## | Ubuntu (LTS e versões recentes) | Sim                                                   | Padrão GNU tar + bash disponível  |
## | Debian                          | Sim                                                   | Padrão GNU tar + bash disponível  |
## | CentOS / Rocky Linux / RHEL     | Sim                                                   | Padrão GNU tar                    |
## | Fedora                          | Sim                                                   | Padrão GNU tar                    |
## | openSUSE                        | Sim                                                   | Padrão GNU tar                    |
## | Arch Linux                      | Sim                                                   | Padrão GNU tar                    |
## | Alpine Linux                    | Não (por padrão, busybox tar não suporta incremental) | Pode instalar GNU tar manualmente |
## ===============================================================================================================================
##
## Sobre a compatibilidade do script de backup com tar --listed-incremental
##
## O que o script usa de recursos principais?
## - Comando tar com opção --listed-incremental
## - Comandos básicos: mkdir, date, find, gzip
## - Bash shell (#!/bin/bash)
## - Diretórios padrão do Linux (ex: /run/user, /backups)

#!/bin/bash

### === CONFIGURAÇÕES === ###
DESTINO="/backups"
LOG_DIR="/var/log/backup-logs"
RETENCAO_DIAS=14

# Criar diretórios se não existirem
mkdir -p "$DESTINO"
mkdir -p "$LOG_DIR"

# Formatação de datas e variáveis
DATA_LOG=$(date +%Y%m%d%H%M)   # Ex: 202506111930
DATA_ARQUIVO=$(date +%Y-%m-%d) # Ex: 2025-06-11
DIA_SEMANA=$(date +%u)          # 1=Segunda ... 7=Domingo

SNAPSHOT="$DESTINO/backup.snar"
FULL_BACKUP="$DESTINO/full-$DATA_ARQUIVO.tar.gz"
INCR_BACKUP="$DESTINO/incremental-$DATA_ARQUIVO.tar.gz"
LOGFILE="$LOG_DIR/backup-$DATA_LOG.log"

### === EXCLUSÕES PADRÃO para evitar erros de permissão e evitar backups desnecessários === ###
EXCLUDE_OPTS=(
  --exclude="$DESTINO"
  --exclude="/run/user/*/gvfs"
  --exclude="/run/user/*/doc"
  --exclude="/proc"
  --exclude="/sys"
  --exclude="/dev"
  --exclude="/tmp"
  --exclude="/var/tmp"
  --exclude="/mnt"
  --exclude="/media"
)

### === FUNÇÃO DE LOG === ###
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

### === FUNÇÕES DE BACKUP === ###
backup_full() {
    log "Iniciando backup FULL de todo o sistema..."
    tar --listed-incremental="$SNAPSHOT" -czpf "$FULL_BACKUP" "${EXCLUDE_OPTS[@]}" /
    log "Backup FULL concluído: $FULL_BACKUP"
}

backup_incremental() {
    log "Iniciando backup incremental do sistema..."
    tar --listed-incremental="$SNAPSHOT" -czpf "$INCR_BACKUP" "${EXCLUDE_OPTS[@]}" /
    log "Backup incremental concluído: $INCR_BACKUP"
}

### === FUNÇÃO PARA COMPACTAR LOGS ANTIGOS === ###
compactar_logs_antigos() {
    log "Compactando logs com mais de $RETENCAO_DIAS dias..."
    find "$LOG_DIR" -type f -name "*.log" -mtime +$RETENCAO_DIAS -exec gzip -9 {} \;
    log "Compactação de logs antigos concluída."
}

### === EXECUÇÃO === ###
INICIO=$(date +%s)

if [ "$DIA_SEMANA" -eq 7 ]; then
    backup_full
else
    backup_incremental
fi

FIM=$(date +%s)
DURACAO=$((FIM - INICIO))
MIN=$((DURACAO / 60))
SEG=$((DURACAO % 60))

log "Tempo total de execução: ${MIN}m ${SEG}s"
log "Backup finalizado com sucesso."

compactar_logs_antigos
