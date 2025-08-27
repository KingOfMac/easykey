# EasyKey Usage Examples & Workflows

Real-world examples and workflows for using EasyKey in different scenarios.

## Table of Contents

- [Development Workflows](#development-workflows)
- [CI/CD Integration](#cicd-integration)
- [Production Deployment](#production-deployment)
- [Team Collaboration](#team-collaboration)
- [Migration Scenarios](#migration-scenarios)
- [Automation Scripts](#automation-scripts)

## Development Workflows

### Local Development Setup

**Scenario:** Setting up a development environment with multiple API keys and database credentials.

```bash
#!/bin/bash
# setup-dev-env.sh

echo "Setting up development environment..."

# Store development secrets
easykey set DEV_DATABASE_URL "postgresql://localhost:5432/myapp_dev" \
  --reason "Local development setup"

easykey set OPENAI_API_KEY "sk-dev-xxxxxxxxxxxx" \
  --reason "Local AI features testing"

easykey set STRIPE_TEST_KEY "sk_test_xxxxxxxxxxxx" \
  --reason "Payment testing"

easykey set REDIS_URL "redis://localhost:6379/0" \
  --reason "Local caching"

easykey set AWS_ACCESS_KEY "AKIA..." \
  --reason "S3 development bucket access"

easykey set AWS_SECRET_KEY "secret..." \
  --reason "S3 development bucket access"

# Verify setup
echo "Development secrets stored:"
easykey list --verbose

echo "Environment ready!"
```

**Usage in application startup:**

```bash
#!/bin/bash
# start-dev-server.sh

# Load secrets into environment
export DATABASE_URL=$(easykey get DEV_DATABASE_URL --quiet --reason "Starting dev server")
export OPENAI_API_KEY=$(easykey get OPENAI_API_KEY --quiet --reason "Starting dev server")
export STRIPE_PUBLISHABLE_KEY=$(easykey get STRIPE_TEST_KEY --quiet --reason "Starting dev server")
export REDIS_URL=$(easykey get REDIS_URL --quiet --reason "Starting dev server")

# Start application
echo "Starting development server with secrets loaded..."
npm run dev
```

### Environment-Specific Secrets

**Scenario:** Managing different secrets for dev, staging, and production environments.

```bash
# Development
easykey set DEV_API_ENDPOINT "https://api-dev.example.com" \
  --reason "Development environment"
easykey set DEV_API_KEY "dev-key-12345" \
  --reason "Development API access"

# Staging
easykey set STAGING_API_ENDPOINT "https://api-staging.example.com" \
  --reason "Staging environment"
easykey set STAGING_API_KEY "staging-key-67890" \
  --reason "Staging API access"

# Production
easykey set PROD_API_ENDPOINT "https://api.example.com" \
  --reason "Production environment"
easykey set PROD_API_KEY "prod-key-abcdef" \
  --reason "Production API access"
```

**Environment switcher script:**

```bash
#!/bin/bash
# switch-env.sh

ENV=${1:-dev}

case $ENV in
  dev)
    export API_ENDPOINT=$(easykey get DEV_API_ENDPOINT --quiet --reason "Switch to dev")
    export API_KEY=$(easykey get DEV_API_KEY --quiet --reason "Switch to dev")
    echo "Switched to development environment"
    ;;
  staging)
    export API_ENDPOINT=$(easykey get STAGING_API_ENDPOINT --quiet --reason "Switch to staging")
    export API_KEY=$(easykey get STAGING_API_KEY --quiet --reason "Switch to staging")
    echo "Switched to staging environment"
    ;;
  prod)
    export API_ENDPOINT=$(easykey get PROD_API_ENDPOINT --quiet --reason "Switch to prod")
    export API_KEY=$(easykey get PROD_API_KEY --quiet --reason "Switch to prod")
    echo "Switched to production environment"
    ;;
  *)
    echo "Usage: $0 {dev|staging|prod}"
    exit 1
    ;;
esac

# Run application with selected environment
exec "$@"
```

## CI/CD Integration

### GitHub Actions Workflow

**Scenario:** Using EasyKey secrets in GitHub Actions (running on self-hosted macOS runners).

```yaml
# .github/workflows/deploy.yml
name: Deploy Application

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: [self-hosted, macOS]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Load Deployment Secrets
      id: secrets
      run: |
        # Load secrets into environment
        echo "API_KEY=$(easykey get PROD_API_KEY --quiet --reason 'GitHub Actions deploy')" >> $GITHUB_ENV
        echo "DATABASE_URL=$(easykey get PROD_DATABASE_URL --quiet --reason 'GitHub Actions deploy')" >> $GITHUB_ENV
        echo "DEPLOY_TOKEN=$(easykey get DEPLOY_TOKEN --quiet --reason 'GitHub Actions deploy')" >> $GITHUB_ENV
    
    - name: Build Application
      run: |
        npm install
        npm run build
    
    - name: Deploy to Production
      run: |
        ./scripts/deploy.sh
      env:
        API_KEY: ${{ env.API_KEY }}
        DATABASE_URL: ${{ env.DATABASE_URL }}
        DEPLOY_TOKEN: ${{ env.DEPLOY_TOKEN }}
    
    - name: Clear Secrets
      if: always()
      run: |
        unset API_KEY DATABASE_URL DEPLOY_TOKEN
```

### Jenkins Pipeline

**Scenario:** Jenkins pipeline using EasyKey for secret management.

```groovy
// Jenkinsfile
pipeline {
    agent { label 'macos' }
    
    environment {
        EASYKEY_REASON = "Jenkins Pipeline Build #${BUILD_NUMBER}"
    }
    
    stages {
        stage('Load Secrets') {
            steps {
                script {
                    // Load secrets into Jenkins environment
                    env.API_KEY = sh(
                        script: "easykey get PROD_API_KEY --quiet --reason '${EASYKEY_REASON}'",
                        returnStdout: true
                    ).trim()
                    
                    env.DATABASE_URL = sh(
                        script: "easykey get PROD_DATABASE_URL --quiet --reason '${EASYKEY_REASON}'",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm run build'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh './scripts/deploy.sh'
            }
        }
    }
    
    post {
        always {
            // Clear secrets from environment
            script {
                env.API_KEY = null
                env.DATABASE_URL = null
            }
        }
    }
}
```

### Docker Integration

**Scenario:** Building and running Docker containers with secrets from EasyKey.

```bash
#!/bin/bash
# docker-deploy.sh

echo "Building application with secrets..."

# Build Docker image with secrets as build args
docker build \
  --build-arg API_KEY="$(easykey get PROD_API_KEY --quiet --reason 'Docker build')" \
  --build-arg DATABASE_URL="$(easykey get PROD_DATABASE_URL --quiet --reason 'Docker build')" \
  -t myapp:latest .

# Run container with secrets as environment variables
docker run -d \
  --name myapp-prod \
  -e API_KEY="$(easykey get PROD_API_KEY --quiet --reason 'Docker run')" \
  -e DATABASE_URL="$(easykey get PROD_DATABASE_URL --quiet --reason 'Docker run')" \
  -e REDIS_URL="$(easykey get PROD_REDIS_URL --quiet --reason 'Docker run')" \
  -p 8080:8080 \
  myapp:latest

echo "Application deployed to Docker container"
```

**Docker Compose with secrets:**

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    environment:
      - API_KEY=${API_KEY}
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    ports:
      - "8080:8080"
    depends_on:
      - redis
      - postgres
  
  postgres:
    image: postgres:14
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

```bash
#!/bin/bash
# docker-compose-up.sh

# Load secrets into environment for docker-compose
export API_KEY=$(easykey get PROD_API_KEY --quiet --reason "Docker Compose deploy")
export DATABASE_URL=$(easykey get PROD_DATABASE_URL --quiet --reason "Docker Compose deploy")
export REDIS_URL=$(easykey get PROD_REDIS_URL --quiet --reason "Docker Compose deploy")
export DB_PASSWORD=$(easykey get POSTGRES_PASSWORD --quiet --reason "Docker Compose deploy")

# Start services
docker-compose up -d

# Clear secrets from environment
unset API_KEY DATABASE_URL REDIS_URL DB_PASSWORD

echo "Services started with EasyKey secrets"
```

## Production Deployment

### Blue-Green Deployment

**Scenario:** Blue-green deployment with different secret sets for each environment.

```bash
#!/bin/bash
# blue-green-deploy.sh

ENVIRONMENT=${1:-blue}
VERSION=${2:-latest}

echo "Deploying to $ENVIRONMENT environment..."

# Load environment-specific secrets
case $ENVIRONMENT in
  blue)
    export API_KEY=$(easykey get BLUE_API_KEY --quiet --reason "Blue environment deploy")
    export DATABASE_URL=$(easykey get BLUE_DATABASE_URL --quiet --reason "Blue environment deploy")
    export LOAD_BALANCER_CONFIG="blue"
    ;;
  green)
    export API_KEY=$(easykey get GREEN_API_KEY --quiet --reason "Green environment deploy")
    export DATABASE_URL=$(easykey get GREEN_DATABASE_URL --quiet --reason "Green environment deploy")
    export LOAD_BALANCER_CONFIG="green"
    ;;
  *)
    echo "Usage: $0 {blue|green} [version]"
    exit 1
    ;;
esac

# Deploy application
echo "Deploying version $VERSION to $ENVIRONMENT..."
kubectl apply -f k8s/$ENVIRONMENT/
kubectl set image deployment/app-$ENVIRONMENT app=myapp:$VERSION

# Wait for deployment
kubectl rollout status deployment/app-$ENVIRONMENT

# Switch traffic if deployment successful
if [ $? -eq 0 ]; then
  echo "Switching traffic to $ENVIRONMENT..."
  kubectl patch service app-service -p '{"spec":{"selector":{"environment":"'$ENVIRONMENT'"}}}'
  echo "Deployment complete!"
else
  echo "Deployment failed!"
  exit 1
fi

# Clear secrets
unset API_KEY DATABASE_URL LOAD_BALANCER_CONFIG
```

### Rolling Updates

**Scenario:** Rolling update deployment with secret rotation.

```bash
#!/bin/bash
# rolling-update.sh

echo "Starting rolling update with secret rotation..."

# Rotate API key
OLD_KEY=$(easykey get API_KEY --quiet --reason "Pre-rotation backup")
NEW_KEY="new-api-key-$(date +%s)"

# Update external service with new key
curl -X POST https://api.example.com/rotate-key \
  -H "Authorization: Bearer $OLD_KEY" \
  -d '{"new_key": "'$NEW_KEY'"}'

# Store new key in EasyKey
easykey set API_KEY "$NEW_KEY" --reason "Rolling update key rotation"

# Deploy with new key
export API_KEY=$NEW_KEY
kubectl set image deployment/app app=myapp:latest
kubectl rollout status deployment/app

# Verify deployment
if kubectl get deployment app -o jsonpath='{.status.readyReplicas}' | grep -q "3"; then
  echo "Rolling update successful"
  # Remove old key from external service
  curl -X DELETE https://api.example.com/revoke-key \
    -H "Authorization: Bearer $NEW_KEY" \
    -d '{"old_key": "'$OLD_KEY'"}'
else
  echo "Rolling update failed, rolling back..."
  easykey set API_KEY "$OLD_KEY" --reason "Rollback to previous key"
  kubectl rollout undo deployment/app
  exit 1
fi

unset API_KEY OLD_KEY NEW_KEY
```

## Team Collaboration

### Shared Development Setup

**Scenario:** Team members sharing common development secrets while maintaining individual access logs.

```bash
#!/bin/bash
# team-setup.sh

DEVELOPER_NAME=${1:-$(whoami)}

echo "Setting up development environment for $DEVELOPER_NAME..."

# Common development secrets
easykey set SHARED_DEV_DATABASE_URL "postgresql://dev-server:5432/shared_dev" \
  --reason "Team development setup for $DEVELOPER_NAME"

easykey set SHARED_TEST_API_KEY "test-key-12345" \
  --reason "Team development setup for $DEVELOPER_NAME"

# Developer-specific secrets
easykey set "${DEVELOPER_NAME}_PERSONAL_API_KEY" "personal-key-for-$DEVELOPER_NAME" \
  --reason "Personal development key for $DEVELOPER_NAME"

# List current secrets for verification
echo "Secrets configured for $DEVELOPER_NAME:"
easykey list --verbose --reason "Setup verification for $DEVELOPER_NAME"

echo "Development environment ready for $DEVELOPER_NAME"
```

### Secret Handoff Process

**Scenario:** Secure handoff of secrets between team members.

```bash
#!/bin/bash
# secret-handoff.sh

FROM_USER=$1
TO_USER=$2
SECRET_NAME=$3

if [ $# -ne 3 ]; then
  echo "Usage: $0 <from_user> <to_user> <secret_name>"
  echo "Example: $0 alice bob PROD_API_KEY"
  exit 1
fi

echo "Secret handoff: $SECRET_NAME from $FROM_USER to $TO_USER"

# Current user must be the TO_USER
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "$TO_USER" ]; then
  echo "Error: This script must be run by the receiving user ($TO_USER)"
  echo "Current user: $CURRENT_USER"
  exit 1
fi

# Verify the secret exists and get it
if SECRET_VALUE=$(easykey get "$SECRET_NAME" --quiet --reason "Handoff from $FROM_USER to $TO_USER"); then
  echo "Secret retrieved successfully"
  
  # Store with handoff documentation
  easykey set "$SECRET_NAME" "$SECRET_VALUE" \
    --reason "Received from $FROM_USER on $(date '+%Y-%m-%d')"
  
  echo "Secret handoff complete"
  echo "Previous owner: $FROM_USER"
  echo "New owner: $TO_USER"
  echo "Secret: $SECRET_NAME"
  echo "Handoff date: $(date)"
  
  # Clear from memory
  unset SECRET_VALUE
else
  echo "Error: Could not retrieve secret $SECRET_NAME"
  echo "Possible reasons:"
  echo "- Secret does not exist"
  echo "- Authentication failed"
  echo "- Access denied"
  exit 1
fi
```

## Migration Scenarios

### From Environment Variables

**Scenario:** Migrating existing secrets from environment variables to EasyKey.

```bash
#!/bin/bash
# migrate-from-env.sh

ENV_FILE=${1:-.env}

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Environment file $ENV_FILE not found"
  exit 1
fi

echo "Migrating secrets from $ENV_FILE to EasyKey..."

# Read environment file and store secrets
while IFS='=' read -r key value; do
  # Skip comments and empty lines
  [[ $key =~ ^#.*$ ]] && continue
  [[ -z $key ]] && continue
  
  # Remove quotes from value if present
  value=$(echo "$value" | sed 's/^["'\'']//' | sed 's/["'\'']$//')
  
  # Store in EasyKey
  echo "Migrating: $key"
  easykey set "$key" "$value" --reason "Migration from $ENV_FILE on $(date '+%Y-%m-%d')"
  
done < "$ENV_FILE"

echo "Migration complete!"
echo "Stored secrets:"
easykey list --verbose --reason "Post-migration verification"

echo ""
echo "IMPORTANT: Securely delete $ENV_FILE after verifying migration"
echo "Recommended: rm -P $ENV_FILE"
```

### From Other Secret Managers

**Scenario:** Migrating from HashiCorp Vault to EasyKey.

```bash
#!/bin/bash
# migrate-from-vault.sh

VAULT_PATH=${1:-secret/myapp}
VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}

echo "Migrating secrets from Vault path: $VAULT_PATH"
echo "Vault address: $VAULT_ADDR"

# Authenticate to Vault (assuming token auth)
if [ -z "$VAULT_TOKEN" ]; then
  echo "Error: VAULT_TOKEN environment variable not set"
  exit 1
fi

# Get list of secrets from Vault
SECRET_LIST=$(vault kv list -format=json "$VAULT_PATH" | jq -r '.[]')

for secret in $SECRET_LIST; do
  echo "Migrating secret: $secret"
  
  # Get secret from Vault
  SECRET_DATA=$(vault kv get -format=json "$VAULT_PATH/$secret")
  
  # Extract key-value pairs
  echo "$SECRET_DATA" | jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"' | while IFS='=' read -r key value; do
    # Create EasyKey name
    EASYKEY_NAME="${secret}_${key}"
    
    echo "  Storing: $EASYKEY_NAME"
    easykey set "$EASYKEY_NAME" "$value" \
      --reason "Migration from Vault $VAULT_PATH/$secret on $(date '+%Y-%m-%d')"
  done
done

echo "Migration from Vault complete!"
easykey list --verbose --reason "Post-Vault migration verification"
```

### Backup and Restore

**Scenario:** Creating backups and restoring EasyKey secrets.

```bash
#!/bin/bash
# backup-secrets.sh

BACKUP_DIR=${1:-./easykey-backups}
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="$BACKUP_DIR/easykey_backup_$TIMESTAMP.json"

mkdir -p "$BACKUP_DIR"

echo "Creating EasyKey backup..."
echo "Backup file: $BACKUP_FILE"

# Create backup with metadata
{
  echo "{"
  echo "  \"backup_timestamp\": \"$(date -u '+%Y-%m-%dT%H:%M:%S.000Z')\","
  echo "  \"backup_version\": \"1.0\","
  echo "  \"secrets\": ["
  
  # Get list of secrets and create backup entries
  easykey list --json --reason "Backup operation $TIMESTAMP" | jq -c '.[]' | while read -r secret_info; do
    secret_name=$(echo "$secret_info" | jq -r '.name')
    secret_created=$(echo "$secret_info" | jq -r '.createdAt')
    
    echo "Backing up: $secret_name"
    secret_value=$(easykey get "$secret_name" --quiet --reason "Backup operation $TIMESTAMP")
    
    echo "    {"
    echo "      \"name\": \"$secret_name\","
    echo "      \"value\": \"$secret_value\","
    echo "      \"created_at\": \"$secret_created\","
    echo "      \"backed_up_at\": \"$(date -u '+%Y-%m-%dT%H:%M:%S.000Z')\""
    echo "    },"
  done | sed '$s/,$//'  # Remove trailing comma from last entry
  
  echo "  ]"
  echo "}"
} > "$BACKUP_FILE"

echo "Backup complete: $BACKUP_FILE"
echo "WARNING: This backup contains secret values in plain text!"
echo "Store securely and delete when no longer needed."
```

```bash
#!/bin/bash
# restore-secrets.sh

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file $BACKUP_FILE not found"
  echo "Usage: $0 <backup_file.json>"
  exit 1
fi

echo "Restoring EasyKey secrets from: $BACKUP_FILE"

# Verify backup file format
if ! jq empty "$BACKUP_FILE" 2>/dev/null; then
  echo "Error: Invalid JSON in backup file"
  exit 1
fi

# Get backup metadata
BACKUP_TIMESTAMP=$(jq -r '.backup_timestamp' "$BACKUP_FILE")
SECRET_COUNT=$(jq '.secrets | length' "$BACKUP_FILE")

echo "Backup timestamp: $BACKUP_TIMESTAMP"
echo "Secrets to restore: $SECRET_COUNT"

read -p "Continue with restore? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Restore cancelled"
  exit 0
fi

# Restore secrets
jq -c '.secrets[]' "$BACKUP_FILE" | while read -r secret; do
  secret_name=$(echo "$secret" | jq -r '.name')
  secret_value=$(echo "$secret" | jq -r '.value')
  
  echo "Restoring: $secret_name"
  easykey set "$secret_name" "$secret_value" \
    --reason "Restore from backup $BACKUP_TIMESTAMP"
done

echo "Restore complete!"
easykey list --verbose --reason "Post-restore verification"
```

## Automation Scripts

### Automated Secret Rotation

**Scenario:** Automated rotation of API keys with external service integration.

```bash
#!/bin/bash
# auto-rotate-secrets.sh

ROTATION_CONFIG=${1:-./rotation-config.json}

if [ ! -f "$ROTATION_CONFIG" ]; then
  echo "Error: Rotation config file not found: $ROTATION_CONFIG"
  exit 1
fi

echo "Starting automated secret rotation..."

# Example rotation config:
# {
#   "secrets": [
#     {
#       "name": "API_KEY",
#       "service": "example_api",
#       "rotation_endpoint": "https://api.example.com/rotate",
#       "interval_days": 30
#     }
#   ]
# }

jq -c '.secrets[]' "$ROTATION_CONFIG" | while read -r config; do
  secret_name=$(echo "$config" | jq -r '.name')
  service=$(echo "$config" | jq -r '.service')
  endpoint=$(echo "$config" | jq -r '.rotation_endpoint')
  interval=$(echo "$config" | jq -r '.interval_days')
  
  echo "Processing: $secret_name"
  
  # Get current secret
  current_secret=$(easykey get "$secret_name" --quiet --reason "Rotation check for $secret_name")
  
  # Call service API to rotate
  echo "Rotating $secret_name via $endpoint..."
  new_secret=$(curl -s -X POST "$endpoint" \
    -H "Authorization: Bearer $current_secret" \
    -H "Content-Type: application/json" \
    -d '{"rotate": true}' | jq -r '.new_key')
  
  if [ "$new_secret" != "null" ] && [ -n "$new_secret" ]; then
    # Store new secret
    easykey set "$secret_name" "$new_secret" \
      --reason "Automated rotation for $service on $(date '+%Y-%m-%d')"
    
    echo "✓ Rotated: $secret_name"
    
    # Revoke old secret
    curl -s -X POST "$endpoint/revoke" \
      -H "Authorization: Bearer $new_secret" \
      -d '{"old_key": "'$current_secret'"}' > /dev/null
    
  else
    echo "✗ Failed to rotate: $secret_name"
  fi
  
  unset current_secret new_secret
done

echo "Automated rotation complete!"
easykey status --reason "Post-rotation status check"
```

### Health Monitoring

**Scenario:** Monitoring EasyKey vault health and secret accessibility.

```bash
#!/bin/bash
# monitor-vault-health.sh

ALERT_EMAIL=${ALERT_EMAIL:-admin@example.com}
EXPECTED_SECRET_COUNT=${EXPECTED_SECRET_COUNT:-10}

echo "EasyKey Vault Health Check - $(date)"
echo "============================================"

# Check vault accessibility
if ! easykey status --reason "Health check $(date '+%Y-%m-%d %H:%M')" > /dev/null; then
  echo "❌ CRITICAL: Cannot access EasyKey vault"
  # Send alert
  echo "EasyKey vault inaccessible at $(date)" | mail -s "EasyKey Critical Alert" "$ALERT_EMAIL"
  exit 1
fi

# Get vault status
STATUS_OUTPUT=$(easykey status --reason "Health check $(date '+%Y-%m-%d %H:%M')")
SECRET_COUNT=$(echo "$STATUS_OUTPUT" | grep "secrets:" | cut -d: -f2 | tr -d ' ')
LAST_ACCESS=$(echo "$STATUS_OUTPUT" | grep "last_access:" | cut -d: -f2- | tr -d ' ')

echo "✓ Vault accessible"
echo "Secrets count: $SECRET_COUNT"
echo "Last access: $LAST_ACCESS"

# Check secret count
if [ "$SECRET_COUNT" -lt "$EXPECTED_SECRET_COUNT" ]; then
  echo "⚠️  WARNING: Secret count below expected ($SECRET_COUNT < $EXPECTED_SECRET_COUNT)"
  echo "EasyKey secret count warning: $SECRET_COUNT secrets (expected: $EXPECTED_SECRET_COUNT)" | \
    mail -s "EasyKey Warning" "$ALERT_EMAIL"
fi

# Test secret accessibility (sample a few secrets)
echo ""
echo "Testing secret accessibility..."

SAMPLE_SECRETS=$(easykey list --reason "Health check sampling" | head -3)
if [ -n "$SAMPLE_SECRETS" ]; then
  echo "$SAMPLE_SECRETS" | while read -r secret_name; do
    if easykey get "$secret_name" --quiet --reason "Health check test" > /dev/null; then
      echo "✓ $secret_name: accessible"
    else
      echo "❌ $secret_name: inaccessible"
      echo "EasyKey secret access failure: $secret_name" | \
        mail -s "EasyKey Critical Alert" "$ALERT_EMAIL"
    fi
  done
else
  echo "⚠️  No secrets found for testing"
fi

echo ""
echo "Health check complete - $(date)"
```

These examples demonstrate real-world usage patterns and can be adapted to specific needs and environments. Each script includes proper error handling, audit logging with reasons, and security best practices for secret management.
