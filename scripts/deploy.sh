#!/bin/bash

set -e

echo "🚀 Starting Aurifi Full Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Load environment variables
if [ ! -f .env ]; then
    print_error ".env file not found!"
    exit 1
fi

source .env

print_status "Environment loaded successfully"
print_status "Docker Hub Username: ${DOCKERHUB_USERNAME}"

# Function to wait for service
wait_for_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to respond..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            print_status "$service_name is ready! ✅"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    print_warning "$service_name failed to respond after $max_attempts attempts ⚠️"
    return 1
}

# Main deployment
main() {
    print_step "Starting complete fresh deployment..."
    
    print_step "1. Stopping all services..."
    docker compose down --remove-orphans
    
    print_step "2. Cleaning up containers and images..."
    docker container prune -f
    docker image prune -a -f
    docker volume prune -f
    
    print_step "3. Pulling latest images..."
    docker pull ${DOCKERHUB_USERNAME}/dev-aurifi-frontend:latest
    docker pull ${DOCKERHUB_USERNAME}/dev-aurifi-backend:latest
    docker pull nginx:alpine
    
    print_step "4. Starting fresh services..."
    docker compose up -d
    
    print_step "5. Waiting for services to initialize..."
    sleep 20
    
    print_step "6. Service status check:"
    docker compose ps
    
    print_step "7. Running connectivity tests..."
    
    # Test individual services first
    wait_for_service "Frontend (direct)" "http://localhost:3000"
    wait_for_service "Backend (direct)" "http://localhost:5000/api/v1/user/"
    
    # Test via nginx
    sleep 10
    wait_for_service "Frontend (via nginx)" "http://localhost/"
    wait_for_service "Backend API (via nginx)" "http://localhost/api/v1/user/"
    
    print_step "8. Final system status:"
    echo ""
    echo "📊 Container Status:"
    docker compose ps
    echo ""
    echo "💾 Resource Usage:"
    docker stats --no-stream
    echo ""
    
    print_status "🎉 Full deployment completed successfully!"
    echo ""
    echo "🌐 Access Points:"
    echo "   Frontend: http://139.59.26.29"
    echo "   Backend API: http://139.59.26.29/api/v1"
    echo "   Direct Frontend: http://139.59.26.29:3000"
    echo "   Direct Backend: http://139.59.26.29:5000"
    echo ""
    echo "📅 Deployed at: $(date)"
}

# Handle interruption
trap 'print_error "Deployment interrupted!"; exit 1' INT TERM

# Run deployment
main