# Calu Project Deployment on Oracle Cloud VM

This document outlines the steps to deploy the "Calu" multi-service Docker application onto your Oracle Cloud Infrastructure (OCI) Virtual Machine (VM), assuming the VM is created, has a public IP, DNS is configured via No-IP, and Oracle Cloud firewall rules (Security Lists) are correctly set up.

## 1. Prerequisites (Should be already completed)

* Oracle Cloud VM instance created and running.
* VM has a Public IP address.
* No-IP hostname (e.g., `calu-showcase.ddns.net`) configured to point to your VM's Public IP.
* Oracle Cloud Security List Ingress Rules configured to allow traffic on necessary ports (e.g., 3000, 3001, 3003, 4000, 5050, 15672, 22).
* You have the SSH private key file (`.key` or `.pem`) downloaded from Oracle Cloud, stored securely on your local machine.
* Your local "Calu" project directory has all the latest changes.

## 2. Connect to Your Oracle Cloud VM via SSH

You need to access your VM's command line remotely.

1.  **Open your terminal** (Linux/macOS) or use an SSH client like Git Bash / WSL (Windows).
2.  **Locate your private SSH key file.** Ensure its permissions are strict (read-only for your user).
    * If your key file is named `ssh-key-2025-06-22.key` and is in a folder like `calu-project oracle ssh keys` within your `~/Documents/Projects` directory, the command is:
        ```bash
        chmod 400 'calu-project oracle ssh keys/ssh-key-2025-06-22.key'
        ```
    * **Explanation of `chmod 400`:** This command sets permissions so only the owner can read the file, preventing the "UNPROTECTED PRIVATE KEY FILE!" error.

3.  **Execute the SSH command:**
    * The default user for Ubuntu VMs on Oracle Cloud is `ubuntu`.
    * Replace `YOUR_VM_PUBLIC_IP_ADDRESS` with the actual Public IP of your Oracle Cloud VM.
    * Example:
        ```bash
        ssh -i 'calu-project oracle ssh keys/ssh-key-2025-06-22.key' ubuntu@YOUR_VM_PUBLIC_IP_ADDRESS
        ```
    * **First-time connection:** You might see a message about the host's authenticity. Type `yes` and press Enter to proceed and add the host to your known hosts list.

## 3. Install Docker and Docker Compose on the VM

Once you are successfully logged into your VM via SSH, run these commands:

1.  **Update package lists:**
    ```bash
    sudo apt update
    ```

2.  **Install Docker Engine (`docker.io`):**
    ```bash
    sudo apt install docker.io -y
    ```

3.  **Install Docker Compose:**
    ```bash
    sudo apt install docker-compose -y
    ```
    *(Note: If `docker-compose` isn't found by `apt`, you might need to install it via `pip` or download the binary, but `apt` is usually the simplest for Ubuntu.)*

4.  **Add your `ubuntu` user to the `docker` group:**
    This allows you to run `docker` commands without needing `sudo` every time.
    ```bash
    sudo usermod -aG docker ubuntu
    ```

5.  **Re-login to apply group changes:**
    * After the `usermod` command, you **must log out** of your SSH session and then **log back in** for the group membership to take effect.
    * Type `exit` in the VM's terminal to log out.
    * Then, execute the `ssh` command from Step 2 again to log back in.

## 4. Transfer Calu Project Files to the VM

Now that Docker is installed and your user can run Docker commands, you need to get your project files onto the VM.

1.  **On your LOCAL machine's terminal** (not the SSH session):
    * Navigate to the directory that contains your `docker-compose.yml` file, along with your `Code-Base` and `Docker-Environment-Orchestration` folders. This is the root of your "Calu" project.

2.  **Use `scp` (Secure Copy) to transfer the entire directory:**
    ```bash
    scp -r -i /path/to/your/private_key.key ./ ubuntu@YOUR_VM_PUBLIC_IP_ADDRESS:/home/ubuntu/calu-project
    ```
    * Replace `/path/to/your/private_key.key` with the path to your actual key file.
    * Replace `YOUR_VM_PUBLIC_IP_ADDRESS` with your VM's Public IP.
    * `./` means "copy the current directory and its contents recursively."
    * `/home/ubuntu/calu-project` is the destination path on your VM. The `calu-project` directory will be created there.

## 5. Run Your Docker Compose Application

Finally, deploy your application on the VM.

1.  **Connect to your VM via SSH** again (if you logged out).
2.  **Navigate to your project directory** on the VM:
    ```bash
    cd /home/ubuntu/calu-project
    ```
3.  **Start your Docker Compose services:**
    ```bash
    docker-compose up -d --build
    ```
    * `-d` runs containers in detached mode (in the background).
    * `--build` rebuilds your service images. This is important for your custom UIs and backend services.

## 6. Access Your Application

Once all services are up and running (this might take a few minutes, you can check `docker-compose ps`), you should be able to access your application through your No-IP domain!

* **UI Admin:** `http://calu-showcase.ddns.net:3000`
* **UI Consumer:** `http://calu-showcase.ddns.net:3001`
* **UI Business:** `http://calu-showcase.ddns.net:3003`
* **API Gateway:** `http://calu-showcase.ddns.net:4000`

---