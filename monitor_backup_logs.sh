## Script para monitorar os logs gerados pelo script de backup, procurando por mensagens contendo erros ou avisos, facilitando a identificação de problemas em servidores Linux.
##
## Funcionalidades:
## - Verifica os arquivos de log do dia atual em /var/log/backup-logs/ com prefixo backup-YYYYMMDD.
## - Busca por padrões de texto “error” e “warning” (case insensitive).
## - Verificação de permissão de leitura antes de processar cada log.
## - Filtro mais preciso por data com -newermt.
## - Timestamp da execução para facilitar auditoria.
## - Contexto de 1 linha ao redor dos erros e avisos com grep -C1.
## - Exibe para cada log encontrado:
## - Se foram encontrados erros ou avisos, mostrando suas linhas.
## - Caso contrário, indica que não há erros ou avisos.
##
## Configurações
## - Diretório dos logs: /var/log/backup-logs (pode ser alterado na variável LOG_DIR).
## - Palavras-chave monitoradas: error e warning (variáveis PADRAO_ERRO e PADRAO_WARN).
##
## Requisitos
## - Permissão para ler os arquivos de log e backups.
## - Bash shell (#!/bin/bash).
## - Utiliza comandos básicos do Linux (find, grep, tar, etc).
##
## Exemplo de comando para uso do script para monitorar logs de backup:
## ./monitor_backup_logs.sh

#!/bin/bash

# Configurações
LOG_DIR="/var/log/backup-logs"
PADRAO_ERRO="error"
PADRAO_WARN="warning"
HOJE=$(date +%Y-%m-%d)
DATA_LOG=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$DATA_LOG] Monitorando logs de backup em $LOG_DIR ..."

# Encontrar logs do dia atual
LOGS_HOJE=$(find "$LOG_DIR" -type f -name "backup-$HOJE*.log" -newermt "$HOJE")

if [ -z "$LOGS_HOJE" ]; then
  echo "[$DATA_LOG] Nenhum log encontrado para hoje ($HOJE)."
  exit 0
fi

for log in $LOGS_HOJE; do
  echo ""
  echo "📄 Verificando log: $log"

  # Verifica permissão de leitura
  if [ ! -r "$log" ]; then
    echo "  ❌ Sem permissão para ler o log $log"
    continue
  fi

  # Buscar padrões com contexto de 1 linha
  ERROS=$(grep -i -C1 "$PADRAO_ERRO" "$log")
  AVISOS=$(grep -i -C1 "$PADRAO_WARN" "$log")

  if [ -n "$ERROS" ]; then
    echo "  ⚠️ Erros encontrados:"
    echo "$ERROS"
  else
    echo "  ✅ Nenhum erro encontrado."
  fi

  if [ -n "$AVISOS" ]; then
    echo "  ⚠️ Avisos encontrados:"
    echo "$AVISOS"
  else
    echo "  ✅ Nenhum aviso encontrado."
  fi
done