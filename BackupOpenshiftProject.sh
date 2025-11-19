#!/bin/bash
# ============================================================
# OpenShift Comprehensive Project Backup Script
# Includes Real External Image Resolution from ImageStreams
# Author: Mahmood SeyyedAlian + ChatGPT GPT-5
# ./BackupAllProject.sh /Backup Directory   all 
# ============================================================

set -euo pipefail

# ------------- CONFIGURATION -----------------
BACKUP_ROOT=${1:-"/tmp/openshift-backup"}
TARGET_PROJECT=${2:-"all"}     # "all" or specific project name
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BASE_DIR="${BACKUP_ROOT}/backup_${TIMESTAMP}"
mkdir -p "$BASE_DIR"
# ---------------------------------------------

echo " Starting OpenShift backup..."
echo "📁 Backup directory: $BASE_DIR"

# ---------- Check dependencies ---------------
for bin in oc jq; do
  if ! command -v $bin &>/dev/null; then
    echo "❌ Error: Required tool '$bin' not found. Please install it first."
    exit 1
  fi
done

# ---------- Function: Build Image Map ----------
build_image_map() {
  local ns=$1
  declare -gA IMAGE_MAP=()
  echo "🧩 Building image map for namespace: $ns"
  local json
  json=$(oc get imagestream -n "$ns" -o json 2>/dev/null || echo "")
  [[ -z "$json" ]] && return 0

  echo "$json" | jq -r '
    .items[] |
    .metadata.name as $name |
    (.status.tags[]? | "\($name):\(.tag)=\(.items[0].dockerImageReference)")' \
  2>/dev/null | while read -r line; do
    [[ -z "$line" ]] && continue
    local key value
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2-)
    IMAGE_MAP["$key"]="$value"
  done
}

# ---------- Function: Backup Project ----------
backup_project() {
  local ns=$1
  local outdir="${BASE_DIR}/${ns}"
  mkdir -p "$outdir"
  echo " Backing up project: $ns"

  # Get all resources
  echo " Exporting resource definitions..."
  oc get all -n "$ns" -o yaml > "${outdir}/all.yaml" 2>/dev/null || true
  oc get is -n "$ns" -o yaml > "${outdir}/imagestreams.yaml" 2>/dev/null || true
  oc get cm,secret,svcroute,pvc,role,rolebinding,sa -n "$ns" -o yaml > "${outdir}/extras.yaml" 2>/dev/null || true

  # Build image map
  build_image_map "$ns"

  # Backup workloads individually with real image mapping
  local kinds=(deployment deploymentconfig statefulset daemonset cronjob job)
  for kind in "${kinds[@]}"; do
    echo "🔹 Processing ${kind}s..."
    mkdir -p "${outdir}/${kind}"
    local names
    names=$(oc get "$kind" -n "$ns" -o name 2>/dev/null || true)
    for item in $names; do
      local name yamlfile
      name=$(basename "$item")
      yamlfile="${outdir}/${kind}/${name}.yaml"
      oc get "$kind" "$name" -n "$ns" -o yaml > "$yamlfile"

      # Replace internal image references
      for key in "${!IMAGE_MAP[@]}"; do
        local real_image=${IMAGE_MAP[$key]}
        sed -i "s#image-registry\.openshift-image-registry\.svc:5000/${ns}/${key}#${real_image}#g" "$yamlfile"
      done
    done
  done

  # Backup routes and configmaps separately
  oc get route -n "$ns" -o yaml > "${outdir}/routes.yaml" 2>/dev/null || true
  oc get configmap -n "$ns" -o yaml > "${outdir}/configmaps.yaml" 2>/dev/null || true

  echo "✅ Project $ns backup complete."
}

# ---------- Main Execution ----------
if [ "$TARGET_PROJECT" == "all" ]; then
  echo " Backing up all non-system projects..."
  for proj in $(oc get projects -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -vE '^(openshift|kube|default)$'); do
    backup_project "$proj"
  done
else
  backup_project "$TARGET_PROJECT"
fi

echo " All backups completed successfully!"
echo "📂 Backup stored at: $BASE_DIR"
