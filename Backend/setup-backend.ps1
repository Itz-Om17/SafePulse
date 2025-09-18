# Create root folder
New-Item -ItemType Directory -Force -Path "server"
Set-Location "server"

# Create src subfolders
New-Item -ItemType Directory -Force -Path "src/config"
New-Item -ItemType Directory -Force -Path "src/controllers"
New-Item -ItemType Directory -Force -Path "src/models"
New-Item -ItemType Directory -Force -Path "src/routes"
New-Item -ItemType Directory -Force -Path "src/middlewares"
New-Item -ItemType Directory -Force -Path "src/utils"

# Create main files
New-Item -ItemType File -Force -Path "src/app.js"
New-Item -ItemType File -Force -Path "src/server.js"
New-Item -ItemType File -Force -Path "src/routes/index.js"

# Example files in each folder
New-Item -ItemType File -Force -Path "src/config/db.js"
New-Item -ItemType File -Force -Path "src/controllers/dc.controller.js"
New-Item -ItemType File -Force -Path "src/models/dc.model.js"
New-Item -ItemType File -Force -Path "src/routes/dc.routes.js"
New-Item -ItemType File -Force -Path "src/middlewares/auth.middleware.js"
New-Item -ItemType File -Force -Path "src/utils/validators.js"

# Root level files
New-Item -ItemType File -Force -Path ".env"
New-Item -ItemType File -Force -Path "package.json"
New-Item -ItemType File -Force -Path "README.md"

Write-Host "✅ Backend folder structure created successfully!"
