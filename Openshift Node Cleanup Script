#!/bin/bash
# OpenShift Node Cleanup Script BY Mahmood Seyyedalian
# Usage Method:
#   ./ocp-node-cleanup.sh dry     ### Step 1: Show what can be deleted Safe
#   ./ocp-node-cleanup.sh clean   ### Step 2: Delete unused data

ACTION=$1

echo "=========================================="
echo "OpenShift Node Storage Cleanup - $ACTION"
echo "=========================================="

# Function: show unused images
check_images() {
  echo "Checking unused container images..."
  crictl images | grep "<none>" || echo "✅ No dangling images"
}

# Function: show unused pods
check_pods() {
  echo "Checking old/completed pods..."
  oc get pod -A --field-selector=status.phase=Succeeded,status.phase=Failed || echo "No completed/failed pods"
}

# Function: show logs size
check_logs() {
  echo "Checking log directory sizes..."
  du -sh /var/log/containers /var/log/pods 2>/dev/null
}

# Function: show ephemeral volumes - (Pod storage without PVC)
check_emptydir() {
  echo "Checking ephemeral pod volumes..."
  du -sh /var/lib/kubelet/pods/*/volumes/*/* 2>/dev/null | sort -h | tail -20
}

# -------------------
# Dry Run Mode
# -------------------
if [[ "$ACTION" == "dry" ]]; then
  check_images
  check_pods
  check_logs
  check_emptydir
  echo "=========================================="
  echo "Dry run complete. Nothing deleted."
  echo "Run './ocp-node-cleanup.sh clean' to cleanup."
  exit 0
fi

# -------------------
# Cleanup Mode
# -------------------
if [[ "$ACTION" == "clean" ]]; then
  echo "Cleaning unused resources..."

  echo "Removing unused/dangling images..."
  crictl rmi --prune || echo "⚠️ Failed image prune"

  echo "Deleting completed/failed pods..."
  oc delete pod -A --field-selector=status.phase=Succeeded,status.phase=Failed || true

  echo "Forcing logrotate..."
  logrotate -f /etc/logrotate.conf || echo "⚠️ Logrotate not configured"

  echo "Cleaning up ephemeral volumes..."
  find /var/lib/kubelet/pods/ -type d -name "volumes" -exec du -sh {} \; | sort -h | tail -20

  echo "=========================================="
  echo "Cleanup finished."
  exit 0
fi

# Help
echo "Usage: $0 [dry|clean]"
exit 1
