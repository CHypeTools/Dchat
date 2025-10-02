#!/bin/bash

# 🚀 Dchat - Script auxiliar para Docker/Portainer
# Detecta automaticamente o container do Chatwoot e executa o desbloqueio

set -e

echo "🚀 === Dchat - Desbloqueio Chatwoot Enterprise (Docker) ==="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para detectar container do Chatwoot
detect_chatwoot_container() {
    echo "🔍 Procurando container do Chatwoot..."

    # Tenta encontrar por nome comum
    CONTAINER=$(docker ps --format '{{.Names}}' | grep -i chatwoot | grep -v postgres | grep -v redis | head -n 1)

    if [ -z "$CONTAINER" ]; then
        # Tenta encontrar por imagem
        CONTAINER=$(docker ps --format '{{.Names}}' --filter ancestor=chatwoot/chatwoot | head -n 1)
    fi

    if [ -z "$CONTAINER" ]; then
        echo -e "${RED}❌ Container do Chatwoot não encontrado!${NC}"
        echo ""
        echo "Containers disponíveis:"
        docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
        echo ""
        echo -e "${YELLOW}💡 Execute manualmente:${NC}"
        echo "   docker exec -it <NOME_DO_CONTAINER> bash -c \"wget -qO- https://raw.githubusercontent.com/LuizBranco-ClickHype/Dchat/main/unlock_permanent.rb | bundle exec rails runner -\""
        exit 1
    fi

    echo -e "${GREEN}✅ Container encontrado: $CONTAINER${NC}"
    echo ""
}

# Função principal
main() {
    detect_chatwoot_container

    echo "🔓 Executando desbloqueio permanente..."
    echo ""

    # Executa o script dentro do container
    docker exec -it "$CONTAINER" bash -c "wget -qO- https://raw.githubusercontent.com/LuizBranco-ClickHype/Dchat/main/unlock_permanent.rb | bundle exec rails runner -"

    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 Desbloqueio concluído com sucesso!${NC}"
        echo ""
        echo -e "${YELLOW}🔄 Reinicie o container para aplicar as mudanças:${NC}"
        echo "   docker restart $CONTAINER"
        echo ""
        echo "Ou pelo Portainer:"
        echo "   Stacks > Seu Stack > Restart"
    else
        echo ""
        echo -e "${RED}❌ Erro ao executar desbloqueio${NC}"
        exit $EXIT_CODE
    fi
}

# Verifica se Docker está disponível
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não encontrado!${NC}"
    echo "Instale o Docker ou execute este script no host onde o Docker está instalado."
    exit 1
fi

main
