# OpenShift Utility Scripts

This repository contains two helper scripts for managing an **isolated private OpenShift cluster**:

1. **Project Backup Script**  
   Enhanced backup script using [`kubectl-neat`](https://github.com/itaysk/kubectl-neat) for clean and reusable YAMLs.  

2. **Node Cleanup Script**  
   Safe cleanup tool for reclaiming storage on OpenShift nodes when disk usage grows unexpectedly.  

---

## 📌 Scripts

### 1. Project Backup Script
- Runs on a server where the `oc` CLI is available and logged in.  
- Backs up **all resources** in your OpenShift cluster projects.  
- Uses `kubectl-neat` to strip out runtime metadata and produce **clean YAMLs** for restore or version control.  

**Usage:**
```bash
./ocp-backup.sh
