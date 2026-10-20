# Proxmox & Ubuntu Utils

A collection of utility scripts for Proxmox VE and Ubuntu homelab environments.

> **⚠️ Important:**  
> Before running any script, **review its contents** to understand exactly what it will do to your system.  
> Use at your own risk. The authors are not responsible for any data loss or system issues.

---

## 🐳 Docker + Dockhand Installer (Ubuntu)

Installs **Docker Engine**, **Docker Compose plugin**, and **[Dockhand](https://dockhand.pro)** — a modern Docker management UI — on Ubuntu 22.04 / 24.04 in a single command.

**What it does:**
- Updates the system (non-interactive, preserves existing configs)
- Installs Docker Engine via the official Docker GPG repository
- Adds your user to the `docker` group
- Deploys Dockhand as a Docker container at `http://<your-ip>:3000`
- Cleans up apt cache

To run the script, use:

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/liosmarf/proxmox-utils/main/install-docker-dockhand.sh)"
```

**Optional — change the default port (3000):**

```
DOCKHAND_PORT=8080 bash -c "$(curl -fsSL https://raw.githubusercontent.com/liosmarf/proxmox-utils/main/install-docker-dockhand.sh)"
```

After installation, open Dockhand in your browser:

```
http://<your-server-ip>:3000
```

**Manage Dockhand after install:**

```bash
# View logs
docker compose -f /opt/dockhand/docker-compose.yml logs -f

# Stop
docker compose -f /opt/dockhand/docker-compose.yml down

# Update to latest
docker compose -f /opt/dockhand/docker-compose.yml pull
docker compose -f /opt/dockhand/docker-compose.yml up -d
```

**Requirements:**
- Ubuntu 22.04 LTS or 24.04 LTS
- Root privileges (`sudo`)

---

## 🔧 Proxmox Next VMID Configuration Utility

This script allows you to set the **starting VMID range** for automatically assigned VMIDs in **Proxmox VE 8.1 or newer**, without modifying the Perl source code.

Proxmox now supports setting the VMID range via `datacenter.cfg`.

To run the script, use:

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/liosmar123/proxmox-utils/main/set-vmid-start.sh)"
```

---

### 🔧 What This Script Does

- Prompts for a **new starting VMID** (e.g. 200)
- Updates `/etc/pve/datacenter.cfg` with:

  ```
  next-id: lower=200,upper=1000000
  ```
- Automatically creates a backup of the original file
- Displays the updated config and the next available VMID

---

Example prompt:

```
👉 Enter the new starting VMID (e.g. 200): 200
```

---

### 📁 Example Output in `/etc/pve/datacenter.cfg`

```
next-id: lower=200,upper=1000000
```

---

### 🔁 To Restore Original

Each run makes a timestamped backup like:

```
/etc/pve/datacenter.cfg.bak.2025-06-18-1204
```

You can manually restore it with:

```
cp /etc/pve/datacenter.cfg.bak.<timestamp> /etc/pve/datacenter.cfg
```

---

### 🛡️ Requirements

- Proxmox VE 8.1 or later
- Root privileges

---

### 💡 Tip

To test the new behavior:

```
pvesh get /cluster/nextid
```

It will now start assigning VMIDs from the value you configured (e.g. `200`).

---

## 📜 License

MIT – free to use and modify.
