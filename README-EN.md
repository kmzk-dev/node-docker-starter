# Generic JavaScript Development Environment Repository using Docker
This repository provides a versatile foundation for setting up projects using **JavaScript frameworks like React and Vue on Docker, eliminating the need for local Node.js installation.** This guide specifically focuses on setting up a `Vite & React` environment.

## Preparing the Node.js Environment and Starting the Container
Start a base Node.js environment container (node:22-alpine). The initial configuration enables interactive mode to launch a new project.

- Dockerfile
  - FROM node:22-alpine
  - Image name is node-22-install.
  - CMD ["sh"] keeps the container running persistently.
- docker-compose.yml
  - `volumes: - .:/app` synchronizes the local directory with the container directory.
  - `tty: true` and `stdin_open: true` enable interactive mode.

### Project Setup
- Start the container in detached mode (background).
```bash
docker compose up -d
```
- Check the running container's `ID` or `NAMES` and enter the container shell.
```bash
docker ps
```
```bash
docker exec -it [ID,or,NAMES] /bin/sh
```
- Inside the container shell, launch the project using the Vite interactive command. create-react-app is now deprecated, so using Vite.
```bash
/app # npm create vite
```
> 
> **Input Example:** 
> - Follow the Vite prompts to select the project name and framework.
>  - Project name: Arbitrary (e.g., vite-project).Create new directory same named in root directory
>  - Framework: Select the desired framework (This repository is based on React and Typescript).
>  - If you answer Yes to Install with npm and start now?, dependencies will be installed automatically.
>

<img src="npm vite command.png">

- Exit the shell after project creation is complete by typing shortcut-key `ctrl`+`c` to quit interactive mode, followed by exit.
```bash
/app # exit
```
### Stopping and Removing the Initial Container and Image
Project setup is now complete. Stop and remove the initial setup container and image.  
If you do not perform the removal, please update the Dockerfile and docker-compose.yml according to the new project environment.
```bash
docker compose stop
docker compose down
docker image rm node-22-install
```

## Replacing and Configuring Files for the Development Environment
Switch the newly created project (e.g., vite-project) to the optimized development and execution configuration. Move or copy the following files from the `asset` directory to the root of your newly created project. These files are optimized for a Vite & React based development environment.

|File Name|Description|
|-|-|
|asset/Dockerfile|Defines the application execution environment, including dependency installation and configuration for the hot reload port.|
|asset/docker-compose.yml|Defines the development settings, including configurations for stabilizing hot reload, port mapping, and isolating node_modules.|
|.dockerignore|Excludes unnecessary files from the image build.|

### Development Environment File Configurations
- **Dockerfile（asset/Dockerfile）:** Optimizes build caching, performs npm install, and copies the source code.
```Dockerfile
FROM node:22-alpine 

WORKDIR /app
# Cache Optimization
COPY package*.json ./ 
RUN npm install
# Copy the project source code
COPY . .
# VITE's default port
EXPOSE 5173
# Execution: Start the development server
CMD ["npm", "run", "dev"]
```
- **docker-compose.yml（asset/docker-compose.yml）:** Synchronizes files between the host (local) environment and the container, and stabilizes Vite's hot reload.
```yml
version: '3.1.0'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    # Isolate node_modules to prevent local files from overwriting container dependencies, 
    # and avoid binary errors. Dependencies are managed by package.json within the container.
    # node_modules should be excluded from copying via .dockerignore.
    volumes:
      - .:/app
      - /app/node_modules 
    # Port Mapping: Use 3000:5173 etc. if you want to map to a different local port.
    ports:
      - "5173:5173"
    # Hot Reload Stabilization (especially for Windows/Linux environments)
    environment:
      - CHOKIDAR_USEPOLLING=true
```
- **.dockerignore（asset/.dockerignore）:** Excludes local files like node_modules and dist that are automatically generated and not needed in the image.

#### Code Modifications (Only for VITE Environment)
Modify the created project's `package.json` to allow access from the host side via the dev command.##### Modifying package.json
```json
  "scripts": {
    "dev": "vite --host 0.0.0.0", // Setting "vite --host 0.0.0.0" allows access from a browser on the Docker container's host machine (local) via localhost:5173.
    "build": "tsc -b && vite build",
    "lint": "eslint .",
    "preview": "vite preview"
  },
```
##### Modifying vite.config.ts (Optional: For relative path usage)
Vite uses absolute references by default. If you want to use relative references (like create-react-app) or deploy to a shared server, add the following setting to the project root's `vite.config.ts` (or `vite.config.js`)  
>※The homepage property in package.json is not effective in Vite.
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  base: './',　// Add this line
  plugins: [react()],
})
```

## Starting the Development Server
After moving and modifying the files, start the container with the new configuration to launch the development server.

### Execution Command (Local)
1. Open new project directory (e.g, vite-project) .
2. Build the new image and start the container.
   ```bash
   docker compose up
   ```
3. Access `http://localhost:5173` in the browser

|Command|Execution|
|-|-|
|docker compose up -d|Start container in background. Running `npm run build` command in the shell|
|docker compose up --build|Force image rebuild and start container|
|docker compose up|Start container in foreground|
|`ctrl`+`c`|Stop foreground-running container (graceful shutdown)|
|docker compose stop|Stop running container.The container's state (configuration and data) is preserved.|
|docker compose down|Stop/Destroy container and network|
|docker compose run [SERVICE] [COMMAND] |Execute command in a temporary container.The container automatically terminates after the command finishes.|

