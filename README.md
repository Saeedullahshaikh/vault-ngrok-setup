# Vault and Ngrok Setup

This project demonstrates the deployment of **HashiCorp Vault** and **Ngrok** to securely expose local services to the internet.

---

## 🚀 Project Overview

The goal of this project is to automate the setup of:

* **HashiCorp Vault**: A tool for secrets management and data protection.
* **Ngrok**: A service that creates secure tunnels to localhost, allowing you to expose local servers to the internet.

---

## 🛠️ Project Structure

```
vault-ngrok-setup/
├── vault-ngrok-setup.sh  # Shell script to automate the setup
```

---

## 👞 Prerequisites

Before you begin, ensure you have the following:

* [HashiCorp Vault](https://www.vaultproject.io/downloads) installed.
* [Ngrok](https://ngrok.com/download) installed.
* An active [Ngrok account](https://ngrok.com/).
* Basic knowledge of Vault and Ngrok.

---

## ⚙️ Usage

1. **Clone the repository**:

```bash
git clone https://github.com/Saeedullahshaikh/vault-ngrok-setup.git
cd vault-ngrok-setup
```

2. **Run the setup script**:

```bash
chmod +x vault-ngrok-setup.sh
./vault-ngrok-setup.sh
```

This script will:

* Initialize and unseal Vault.
* Start Ngrok to expose Vault's API to the internet.

3. **Access Vault**:

After the script completes, Ngrok will provide a public URL. Open this URL in your browser to access the Vault UI.

4. **Authenticate with Vault**:

Use the root token provided by the script to authenticate.

---

## 🛠️ Features

* **Automated Setup**: Initialize and unseal Vault with a single script.
* **Secure Exposure**: Use Ngrok to securely expose Vault's API to the internet.
* **Easy Access**: Access Vault's UI from anywhere using the Ngrok URL.

---

## Author

**Saeedullah Shaikh**
- GitHub: [@Saeedullahshaikh](https://github.com/Saeedullahshaikh)

---

## 📜 License

This project is licensed under the MIT License.
