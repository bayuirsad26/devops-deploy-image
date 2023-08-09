# Project Deployment Script 

This script is designed for deploying Docker images to remote servers over SSH. The script checks necessary dependencies, builds Docker images, and deploys it on the server.

## Requirements

1. Docker Engine installed both on the local system and the server
2. Remote server SSH access from the local system
3. Docker images should be present on the Docker Hub

## File Structure

```
.
├── deploy.example.conf
├── deploy.sh
└── function
    ├── docker_utils.sh
    ├── ssh_utils.sh
    └── utils.sh
```
- `deploy.example.conf` : Configuration file for Docker and SSH settings
- `deploy.sh` : Deployment script that runs the deployment process
- `function/` : Contains utility bash scripts
    - `docker_utils.sh` : Contains Docker related utility functions
    - `ssh_utils.sh` : Contains SSH related utility functions
    - `utils.sh` : Contains other utility functions 

## Configurations

Before running the script, you should fill `deploy.example.conf` with proper values:

- Replace `<placeholders>` in `deploy.example.conf` with actual values.

Then, rename the file as per your environment:

- Rename `deploy.example.conf` to `deploy.conf`.

## Usage

After setup and configuration, run the script from your terminal:

```bash
$ chmod +x deploy.sh     # provides executable permissions
$ ./deploy.sh            # executes the script
```

The script will handle the following steps:

- Login to Docker Hub
- Check Docker installation
- Build and push Docker images
- Setup SSH to establish a communication between the local system and the server
- Deploy Docker images on the server

Ensure that the local system has the authorization to deploy Docker images on the remote server.

---

The command can be terminated anytime by pressing `ctrl + c`.