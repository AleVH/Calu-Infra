# Hosting Options for the "Calu" Project (Multi-Service Docker Application)

## 1. Project Overview

The "Calu" project is identified as a complex, multi-service application requiring a Dockerized environment for deployment. Based on the provided `docker-compose.yml`, the system comprises:

* **Frontend UI Services (3):** `ui-admin`, `ui-consumer`, `ui-business`
* **API Gateway (1):** `api-gateway`
* **Backend Microservices (7):** `auth-service`, `user-service`, `card-service`, `payment-service`, `fx-service`, `kyc-service`, `dummy-service`
* **Database/Messaging Services (3):** `postgres`, `redis`, `rabbitmq`
* **Worker Services (2):** `redis-worker`, `rabbitmq-worker`
* **Database Management Tool (1):** `pgadmin`

In total, the project consists of 17 distinct Docker services, including custom builds and pre-built infrastructure images. This setup necessitates an environment capable of running Docker and Docker Compose, managing multiple services, and handling persistent data volumes.

## 2. Unsuitable Hosting Options

**Traditional "Free Web Hosting" (e.g., InfinityFree, AwardSpace, Freehostia)**

* **Reason for Unsuitability:** These services are designed for basic web applications (like WordPress, static HTML/PHP) and **do not provide the necessary environment for Docker or Docker Compose**. They lack SSH access, the ability to run custom executables, or support for persistent background processes.
* **Conclusion:** Not a viable option for the "Calu" project.

## 3. Recommended Hosting Options (Free/Low-Cost Cloud VMs)

Given the complexity and Docker-centric nature of the "Calu" project, the most suitable (and likely only) free options are **Virtual Machines (VMs) provided by major cloud platforms' free tiers.** These provide a dedicated environment with root access, allowing full control over the software stack.

### 3.1. Oracle Cloud Free Tier (Strongest Recommendation for "Always Free")

* **URL:** [https://www.oracle.com/cloud/free/](https://www.oracle.com/cloud/free/)
* **Pros:**
    * **Generous "Always Free" Resources:** Offers two AMD-based VMs (1 OCPU, 1 GB RAM each) or more powerful ARM-based "Ampere A1" VMs (up to 4 OCPUs, 24 GB RAM, shareable across VMs). This is significantly more resource-rich than other "always free" VM tiers and often sufficient for personal projects.
    * **Full Root Access (SSH):** Allows complete control to install Docker, Docker Compose, and all necessary dependencies for your services.
    * **Ample Free Storage:** Includes generous block storage for Docker images, containers, and data volumes, crucial for PostgreSQL, Redis, and RabbitMQ persistence.
    * **Persistent Free Tier:** Resources are "always free," meaning they do not expire after a limited period (e.g., 12 months), as long as usage stays within the specified free limits.
* **Cons:**
    * **Learning Curve:** Requires familiarity with Linux command line (SSH) for VM setup, Docker installation, and project deployment.
    * **Network Configuration:** Demands manual configuration of Security Lists (firewall rules) to expose only necessary public-facing ports (e.g., your UI ports 3000, 3001, 3003, and API Gateway port 4000).
    * **Resource Management:** While generous, careful monitoring of VM resources (CPU, RAM) is still necessary to avoid exceeding free tier limits and incurring charges, especially during peak loads or initial startup of all services.
    * **Region Availability:** Specific resource allocations (like the ARM VMs) might have varying availability across different data center regions.

### 3.2. AWS Free Tier (12 Months Free)

* **URL:** [https://aws.amazon.com/free/](https://aws.amazon.com/free/)
* **Pros:**
    * **Industry Standard:** Widely used and well-documented cloud platform.
    * **Full Root Access (SSH):** Provides control over the VM environment for Docker installation.
    * **12 Months Free:** Offers a `t2.micro` or `t3.micro` EC2 instance for 12 months.
* **Cons:**
    * **Limited Time:** The free tier is only for the first 12 months. After this period, standard charges will apply for continued use.
    * **Limited Resources:** A `t2.micro` (1 CPU, 1GB RAM) may struggle to comfortably run all 17 services of the "Calu" project concurrently, especially during build processes, startup, or under any significant load. Performance issues or service restarts due to resource exhaustion are possible.
    * **Higher Learning Curve:** The broader AWS ecosystem can be complex to navigate for newcomers.

### 3.3. Google Cloud Platform (GCP) Free Tier / $300 Credit

* **URL:** [https://cloud.google.com/free/](https://cloud.google.com/free/)
* **Pros:**
    * **"Always Free" VM Option:** Offers an `e2-micro` instance in select regions as an "always free" option.
    * **Initial Credit:** Provides $300 in free credits for the first 90 days, which can be used for more powerful VMs or other GCP services.
    * **User-Friendly Console:** Generally considered to have a more intuitive user interface than AWS by some users.
* **Cons:**
    * **Limited "Always Free" VM:** The `e2-micro` instance (2 vCPUs, 1GB RAM) is often comparable in terms of effective resources to AWS's `t2.micro` and may face similar performance challenges with the "Calu" stack.
    * **Credit Expiration:** The $300 credit is time-limited (90 days), after which usage will incur charges if exceeding the "always free" resources.
    * **Learning Curve:** Similar to other major cloud providers, requires familiarity with VM management and command-line operations.

## 4. General Deployment Steps (for Cloud VM Options)

1.  **Account Creation:** Sign up for an account with your chosen cloud provider (e.g., Oracle Cloud).
2.  **VM Provisioning:** Create a new Virtual Machine instance within their free tier limits.
3.  **SSH Access:** Obtain the necessary credentials (e.g., SSH key) and connect to your VM using an SSH client.
4.  **Install Docker & Docker Compose:** Once connected, install Docker Engine and Docker Compose on the VM's operating system (e.g., Ubuntu, CentOS).
5.  **Project Transfer:** Copy your entire "Calu" project directory (including `docker-compose.yml`, `Code-Base`, and `Docker-Environment-Orchestration`) to the VM.
6.  **Build & Run:** Navigate to the directory containing your `docker-compose.yml` on the VM and execute `docker-compose up -d --build`.
7.  **Firewall Configuration:** Configure the cloud provider's network security rules (e.g., Oracle's Security List, AWS Security Groups, GCP Firewall Rules) to allow inbound traffic only on the necessary public-facing ports (e.g., 3000, 3001, 3003, 4000 for your UIs and API Gateway).
8.  **Monitoring:** Regularly monitor your VM's resource usage (CPU, RAM, disk I/O, network) to ensure you stay within the free tier limits and to identify any performance bottlenecks.

## 5. Next Steps

* Evaluate your comfort level with Linux command line and cloud environments.
* Prioritize Oracle Cloud's "Always Free" tier for its resource generosity and persistence.
* Begin the setup process, starting with account creation and VM provisioning.
* Be prepared to troubleshoot Docker and network configurations.

---
