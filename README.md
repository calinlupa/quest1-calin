# Project Overview

This project demonstrates a simple application deployed to Google Cloud Run using Docker and Terraform.

## Prerequisites

Before you begin, ensure you have the following tools installed and configured:

*   **Docker:** For building and managing container images.
*   **Google Cloud SDK (gcloud CLI):** For interacting with Google Cloud services, including Artifact Registry. Ensure you are authenticated (`gcloud auth login`) and have set your project (`gcloud config set project <PROJECT_ID>`).
*   **Terraform:** For deploying infrastructure as code.

## 1. Building and Pushing the Docker Image to Artifact Registry

Follow these steps to build your application's Docker image and push it to Google Cloud Artifact Registry.

1.  **Navigate to the application directory:**

    ```bash
    cd app
    ```

2.  **Build the Docker image:**
    This command builds the Docker image and tags it as `app:latest`.

    ```bash
    docker build -t app .
    ```

3.  **Configure Docker to authenticate with Artifact Registry:**
    Replace `<REGION>` with your desired Google Cloud region (e.g., `us-central1`).

    ```bash
    gcloud auth configure-docker <REGION>-docker.pkg.dev
    ```

4.  **Create an Artifact Registry repository (if you don't have one):**
    Replace `<REGION>` with your desired Google Cloud region and `<REPOSITORY_NAME>` with a name for your Docker repository (e.g., `cloud-run-repo`).

    ```bash
    gcloud artifacts repositories create <REPOSITORY_NAME> \
      --repository-format=docker \
      --location=<REGION> \
      --description="Docker repository for Cloud Run application images"
    ```

5.  **Tag the Docker image for Artifact Registry:**
    Replace `<REGION>`, `<PROJECT_ID>`, and `<REPOSITORY_NAME>` with your specific values.

    ```bash
    docker tag app <REGION>-docker.pkg.dev/<PROJECT_ID>/<REPOSITORY_NAME>/app:latest
    ```

6.  **Push the Docker image to Artifact Registry:**
    This will upload your tagged image to the specified Artifact Registry repository.

    ```bash
    docker push <REGION>-docker.pkg.dev/<PROJECT_ID>/<REPOSITORY_NAME>/app:latest
    ```

## 2. Terraform Deployment

This section explains the Terraform configuration and how to deploy the application to Google Cloud Run.

### Terraform Files Explained

The `infra` directory contains the Terraform configuration for deploying the application.

*   **`infra/main.tf`**: This is the main Terraform configuration file. It orchestrates the deployment by calling the `cloud_run` module and passing necessary variables. It defines the Google Cloud project and region where resources will be deployed.
*   **`infra/variables.tf`**: This file defines input variables for the Terraform configuration, such as `project_id`, `region`, and `image_name`. These variables allow you to customize the deployment without modifying the core configuration.
*   **`infra/modules/cloud_run/`**: This directory contains a reusable Terraform module specifically for deploying a Google Cloud Run service.
    *   **`infra/modules/cloud_run/main.tf`**: Defines the Google Cloud Run service resource, including its name, image, and other configurations.
    *   **`infra/modules/cloud_run/variables.tf`**: Defines the input variables required by the `cloud_run` module (e.g., `service_name`, `image_url`).

### Deploying with Terraform

1.  **Navigate to the Terraform infrastructure directory:**

    ```bash
    cd infra
    ```

2.  **Initialize Terraform:**
    This command initializes the Terraform working directory, downloading necessary providers and modules.

    ```bash
    terraform init
    ```

3.  **Review the deployment plan:**
    This command generates an execution plan, showing what actions Terraform will take without actually performing them. Replace `<PROJECT_ID>`, `<REGION>`, and `<REPOSITORY_NAME>` with your specific values. The `image_name` should be the full path to the Docker image you pushed to Artifact Registry.

    ```bash
    terraform plan \
      -var="project_id=<PROJECT_ID>" \
      -var="region=<REGION>" \
      -var="image_name=<REGION>-docker.pkg.dev/<PROJECT_ID>/<REPOSITORY_NAME>/app:latest"
    ```

4.  **Apply the deployment:**
    This command executes the actions outlined in the plan, deploying your Cloud Run service. Confirm the prompt by typing `yes`.

    ```bash
    terraform apply \
      -var="project_id=<PROJECT_ID>" \
      -var="region=<REGION>" \
      -var="image_name=<REGION>-docker.pkg.dev/<PROJECT_ID>/<REPOSITORY_NAME>/app:latest"
    ```

After successful application, Terraform will output the URL of your deployed Cloud Run service.
