# deployment.sh
#!/usr/bin/env bash

# Load configuration and utility functions
source "$(dirname "$0")/deploy.conf"
source "$(dirname "$0")/function/utils.sh"
source "$(dirname "$0")/function/docker_utils.sh"
source "$(dirname "$0")/function/ssh_utils.sh"

# Main function to execute the deployment script
main() {
  # Step 1: Check for essential dependencies
  check_dependencies

  # Step 2: Check if Docker is installed
  check_docker_installed

  # Step 3: Check internet connection
  check_internet

  # Step 4: Start Docker if not already running
  start_docker

  # Step 5: Log in to Docker Hub
  check_and_login_docker_hub

  # Deployment steps
  initial_dir=$(pwd)
  cd "$(dirname "$0")/.."

  # Step 6: Check and generate SSH key pair if necessary
  check_and_generate_ssh_key

  # Step 7: Check if public key is already on the remote server and copy if necessary
  check_and_copy_public_key

  # Step 8: Build and push Docker image to Docker Hub
  remove_build_push

  # Step 9: Remove existing Docker image on the remote server
  remove_remote_docker_image

  # Step 10: Restart Docker container on the remote server
  restart_container_remote

  # Sleep for WAIT_TIME seconds
  log "Waiting for ${WAIT_TIME} seconds before checking container status"
  sleep "${WAIT_TIME}"

  # Step 11: Check if CONTAINER_TO_RESTART is up and running on remote server
  check_remote_container_status "${CONTAINER_NAME}"

  # Step 12: Prune unused Docker images on the remote server
  prune_remote_docker_images

  # Go back to the initial directory
  cd "${initial_dir}"

  # Print successful deployment message
  print_success "Deployment successful"
}

# Load configuration file
load_config

# Set the full Docker image name with tag
IMAGE_FULL_NAME="${REGISTRY_URL:+${REGISTRY_URL}/}${DOCKER_USER}/${IMAGE_NAME}:${TAG}"

# Call the main function to start the deployment process
main
