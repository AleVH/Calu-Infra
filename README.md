## ⚙️ First-Time Setup

Run this before anything else:
```bash
./clone-services.sh
```
Then run:

```bash
./run-me-before-running-docker.sh
```

## Note
To make the files executable, run the following commands
```
chmod +x clone-services.sh
chmod +x run-me-before-running-docker.sh
```

## Run Docker
Once those 2 script were excecuted, go to the folder `Docker-Environment-Orchestration` and run docker
```
docker-compose up -d --build
```

## Database
Once docker is up and running, import the database schema. This will prepare all basic tables for the syste to run.
Some tables like country and currency have special seeders that will regenerate on request. This will be allocated in `Code-Base/SYSTEM-SCRIPTS/PYTHON`