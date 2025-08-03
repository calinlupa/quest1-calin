# Rearc Quest Submission

This project demonstrates the deployment of Rearc's Quest web application to Google Cloud . 
It deplois the app using Cloud Run service, in two different regions for high availability, fronted by a Global Load Balancer (GLB). The infrastructure is managed using Terraform.

## Project Overview

The project structure is as follows :

*   **app:** The application code and binaries are in the `app` directory.  

*   **infra:** The infrastructure code is in the `infra` directory, and defines the following resources:

    *   **Google Cloud Run Services:** The application is deployed as two separate Cloud Run services, one in `us-central1` and another in `europe-west1`.
    *   **Google Secret Manager:** A secret is used to store a `SECRET_WORD` which is then injected into the Cloud Run containers as an environment variable.
    *   **Global Load Balancer:** A GLB is configured to distribute traffic between the two Cloud Run services, providing a single public IP address for users.

## Prerequisites

*   Google Cloud SDK (`gcloud`) installed and configured.
*   Terraform installed.
*   A Google Cloud project with the required APIs enabled (Cloud Run, Secret Manager, Compute Engine).
*   An Artifact Registry repository to store the container image.

## Building and Pushing the Container

1.  **Build the Docker image:**

    ```bash
    docker build -t rearc-quest-submission:latest app/
    ```

2.  **Tag the image for Artifact Registry:**

    ```bash
    docker tag rearc-quest-submission:latest us-central1-docker.pkg.dev/calin-rearc/rearc-quest/rearc-quest-submission:latest
    ```

3.  **Push the image to Artifact Registry:**

    ```bash
    docker push us-central1-docker.pkg.dev/calin-rearc/rearc-quest/rearc-quest-submission:latest
    ```

## Managing the Secret Word

The application expects a secret word to be available as an environment variable `SECRET_WORD`. This is managed using Google Secret Manager.

1.  **Create the secret:**

    ```bash
    gcloud secrets create SECRET_WORD --replication-policy="automatic"
    ```

2.  **Add a version to the secret:**

    ```bash
    gcloud secrets versions add SECRET_WORD --data="your-secret-word"
    ```

The Terraform configuration will automatically fetch the latest version of this secret and inject it into the Cloud Run services.

## Infrastructure Deployment with Terraform

1.  **Initialize Terraform:**

    ```bash
    cd infra
    terraform init
    ```

2.  **Review the deployment plan:**

    ```bash
    terraform plan
    ```

3.  **Apply the configuration:**

    ```bash
    terraform apply
    ```

## High Availability and Global Load Balancer

The application is deployed to two GCP regions (`us-central1` and `europe-west1`) to ensure high availability. A Global Load Balancer is configured to direct user traffic to the nearest healthy region. This setup provides resilience against regional outages and minimizes latency for users around the world.

## Terraform Output

After a successful `terraform apply`, you will see the following outputs:

*   `cloud_run_service_url`: The URLs for the individual Cloud Run services in each region.
*   `glb_ip_address`: The public IP address of the Global Load Balancer. You can access the application by navigating to this IP address in your web browser.

## Given more time, I would improve:

*   **CI/CD Pipeline:** Automate the entire process of building, testing, and deploying the application using a CI/CD pipeline (e.g., Cloud Build, GitHub Actions). This would include steps for running tests, scanning the container image for vulnerabilities, and deploying to a staging environment before promoting to production.
*   **Enhanced Monitoring and Alerting:** Implement more detailed monitoring and alerting using Cloud Monitoring. This would involve creating custom metrics, setting up dashboards to visualize application performance, and configuring alerts to notify the team of any issues.
*   **Security Hardening:**
    *   **Vulnerability Scanning:** Integrate automated vulnerability scanning of the container images into the CI/CD pipeline.
    *   **IAM Best Practices:** Create a dedicated service account for the Cloud Run service with the principle of least privilege.
    *   **WAF Protection:** Implement Google Cloud Armor to protect the application from common web-based attacks.
*   **Advanced Health Checks:** Implement a dedicated health check endpoint in the Node.js application to provide more accurate health status to the load balancer.
*   **Terraform State Management:** Use a remote backend like a Google Cloud Storage bucket for storing the Terraform state to improve security and collaboration.
