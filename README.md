# Chatwoot (Phrozen Fork)

This is a **forked version** of [Chatwoot](https://github.com/chatwoot/chatwoot), a customer engagement platform.  
For full documentation and upstream details, please refer to the original repository:  
👉 [https://github.com/chatwoot/chatwoot](https://github.com/chatwoot/chatwoot)

## 🔧 Phrozen Custom Features

- [x] **Microsoft OAuth Integration**
  - Supports login via Microsoft for both regular users and super admins.

## 🚀 How to Build & Deploy

### 🔧 Prerequisites
- Ensure `kubectl` is configured to access your target Kubernetes cluster.

---

### 📝 1. Create `values.yaml`
Create your deployment values file.  
📎 [Sample values.yaml](https://github.com/phrozen3d/chatwoot-charts/blob/main/charts/chatwoot/values.yaml)

---

### 🛠️ 2. Build Docker Images
Run the following commands to build the Chatwoot base and app images:

```
docker-compose -f docker-compose.phrozen.yaml build base
docker-compose -f docker-compose.phrozen.yaml build
```


### 📦 3. Install or Upgrade via Helm

🔄 Clone the Helm Chart Repository
```
git clone https://github.com/phrozen3d/chatwoot-charts.git
```
📁 Replace ../chatwoot-charts/charts/chatwoot with the path to your local chart directory.

🆕 Install Chatwoot
```
helm install chatwoot ../chatwoot-charts/charts/chatwoot -f values.yaml -n chatwoot
```

🔁 Upgrade Chatwoot
```
helm upgrade chatwoot ../chatwoot-charts/charts/chatwoot -f values.yaml -n chatwoot
```