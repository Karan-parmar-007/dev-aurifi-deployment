#!/bin/bash

ACTION=${1:-"help"}

source .env

case $ACTION in
    "fresh")
        echo "🔄 Fresh deployment (delete everything and restart)..."
        ./scripts/deploy.sh
        ;;
    "restart")
        echo "🔄 Restarting all services..."
        docker compose restart
        ;;
    "stop")
        echo "🛑 Stopping all services..."
        docker compose down
        ;;
    "start")
        echo "▶️  Starting services..."
        docker compose up -d
        ;;
    "logs")
        SERVICE=${2:-""}
        if [ -z "$SERVICE" ]; then
            echo "📋 All service logs:"
            docker compose logs --tail=50
        else
            echo "📋 $SERVICE logs:"
            docker compose logs --tail=50 $SERVICE
        fi
        ;;
    "status")
        echo "📊 Service status:"
        docker compose ps
        echo ""
        echo "💾 Resource usage:"
        docker stats --no-stream
        ;;
    "clean")
        echo "🧹 Cleaning up..."
        docker system prune -a -f
        ;;
    "update")
        SERVICE=${2:-"all"}
        if [ "$SERVICE" = "all" ]; then
            ./scripts/deploy.sh
        else
            echo "🔄 Updating $SERVICE..."
            docker pull ${DOCKERHUB_USERNAME}/aurifi-${SERVICE}:latest
            docker compose up -d --no-deps $SERVICE
            docker compose restart nginx
        fi
        ;;
    "help"|*)
        echo "Usage: $0 [action]"
        echo ""
        echo "Actions:"
        echo "  fresh    - Complete fresh deployment (delete & recreate)"
        echo "  restart  - Restart all services"
        echo "  stop     - Stop all services"
        echo "  start    - Start services"
        echo "  logs     - Show logs (optional: specify service name)"
        echo "  status   - Show service status and resource usage"
        echo "  clean    - Clean up unused containers/images"
        echo "  update   - Update service (specify: frontend/backend/all)"
        echo "  help     - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 fresh"
        echo "  $0 logs nginx"
        echo "  $0 update frontend"
        ;;
esac