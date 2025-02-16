## Craftech 2025 Prueba 2 - Despliegue de una aplicación Django y React.js 
Elaborar el deployment dockerizado de una aplicación en django (backend) con frontend en React.js contenida en el repositorio. Es necesario desplegar todos los servicios en un solo docker-compose.

Se deben entregar los Dockerfiles pertinentes para elaborar el despliegue y justificar la forma en la que elabora el deployment (supervisor, scripts, docker-compose, kubernetes, etc)

Subir todo lo elaborado a un repositorio (github, gitlab, bitbucket, etc). En el repositorio se debe incluir el código de la aplicación y un archivo README.md con instrucciones detalladas para compilar y desplegar la aplicación, tanto en una PC local como en la nube (AWS o GCP).

## Dockerfiles
### backend
```bash
FROM python:3.10.12

WORKDIR /usr/src/app

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt # instalacion de dependencias

COPY . .

CMD ["python3", "manage.py", "runserver"]
```

Se intento utilizar una imagen mas pequeña como slim ó alpine pero saltaron errores de dependencias.

```bash
REPOSITORY                        TAG                  IMAGE ID       CREATED          SIZE
prueba-2-backend                  latest               91c62ecb29dc   16 minutes ago   1.05GB
```

### frontend

```bash
FROM node:18.20.4-alpine 

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

CMD ["npm", "start"]
```
Se utiliza la version alpine de node para disminuir el tamaño de la imagen final

```bash
REPOSITORY                        TAG                  IMAGE ID       CREATED          SIZE
prueba-2-frontend                 latest               64c394deba20   28 minutes ago   1.05GB
```

## Docker Compose
```bash
version: '3.8'
services:
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - 8000:8000
    environment:
      - SQL_HOST=db
      - DJANGO_ALLOWED_HOSTS=*
      - DEBUG=0
    depends_on:
      - db
    command: ./backend-launcher.sh
    volumes:
      - ./backend:/usr/src/app
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - 3000:3000
    depends_on:
      - backend
    volumes:
      - ./frontend:/usr/src/app
  db:
    container_name: database
    image: postgres:12.0-alpine
    environment:
      - POSTGRES_USER=${SQL_USER}
      - POSTGRES_PASSWORD=${SQL_PASSWORD}
      - POSTGRES_DB=${SQL_DATABASE}
    volumes:
      - postgres_data:/var/lib/postgresql/data
volumes:
  postgres_data:
  static:
  media:
```

Backend:
- Construye desde ./backend con su Dockerfile.
- Expone el puerto 8000:8000 (LOCAL:CONTAINER).
- Usa variables de entorno (SQL_HOST=db, DJANGO_ALLOWED_HOSTS=*, DEBUG=0).
- Depende del servicio db.
- Ejecuta backend-launcher.sh.
    ```
    #!/bin/sh
    echo "Starting migrations..."
    python manage.py migrate
    echo "Starting server..."
    python manage.py runserver 0.0.0.0:8000
    ```
- Volumen: backend.

Frontend:
- Construye desde ./frontend con su Dockerfile.
- Expone el puerto 3000:3000.
- Depende del servicio backend.
- Volumen: frontend.

Base de datos:
- Usa la imagen postgres:12.0-alpine.
- Define usuario, contraseña y base de datos con variables de entorno.
- Asigna el nombre database al contenedor.
Volumenes: postgres_data, static, media.

## Como ejecutar
### En local
- Descarga e instala [Docker Engine](https://docs.docker.com/engine/install/) y [Docker Compose](https://docs.docker.com/compose/install/)
- Ejecutar **docker compose up** al ejecutar por primera vez este comando lo que hara sera construir/descargar las imagenes definidas en el yml, en las posteriores ejecuciones solo levantará las intancias, puedes ejecutarlo en modo dettached de la siguiente forma **docker compose up -d** para liberar la terminal.
- Finalmente si todo esta correcto, ejecuta tu navegador de preferencia y accede a [localhost:3000](https://localhost:3000)

Puedes ejecutar el siguiente comando para detener los contenedores
```bash
docker compose down
```
Puedes ejecutar el siguiente comando para eliminar los contenedores inactivos
```bash
docker container prune
```
Y puedes ejecutar lo siguiente para eliminar las imagenes que no estan siendo utilizadas 
```bash
docker images
docker rmi <image-id>
```

### En AWS
#### Pre-requisitos:
Tener una cuenta de AWS.

#### Pasos para el Despliegue:
- 1. Crear una instancia EC2
- 2. Crear el security group habilitando el acceso a internet.
- 3. Crear un RSA key pair para posteriormente utilizarlo para conectarnos a la VM. file name: agustin-msi-ssh.
- 4. Conectarse a la maquina mediante ssh.
    - para esto debemos instalar el cliente de aws:
```bash
brew install awscli
```
    - En la web, vamos a instances -> instancia Generada  -> connect -> SSH Client, ejecuta los pasos que te recomienda. Ej:
```bash
    Instance ID

    i-076784c5af8707670 (craftech-machine-t1)
    Open an SSH client.

    Locate your private key file. The key used to launch this instance is agustin-msi-ssh.pem

    Run this command, if necessary, to ensure your key is not publicly viewable.
    chmod 400 "agustin-msi-ssh.pem"

    Connect to your instance using its Public DNS:
    ec2-54-174-102-162.compute-1.amazonaws.com

    Example:

    ssh -i "agustin-msi-ssh.pem" ubuntu@ec2-54-174-102-162.compute-1.amazonaws.com
```

    - Ejecutar los siguiente comandos ó utilizar un userData:
```bash
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update


    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    git clone --single-branch --branch activity-2 https://github.com/agustinhernando2/devops-interview-ultimate-resolution.git
    cd devops-interview-ultimate-resolution/prueba-2
    # Add your user to the docker group:
    sudo usermod -aG docker $USER
    # Log in to the new docker group (to avoid having to log out and log in again; but if not enough, try to reboot):
    newgrp docker
    cp backend/.env_example backend/.env
    export NODE_OPTIONS="--max-old-space-size=8192"
    docker compose build
    docker compose up -d
```
- 5. Luego buscar el security group donde se encuentra nuestra VM y abrir el puerto 3000.