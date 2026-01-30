#!/bin/bash

set -e  # exit on error

echo "========================================="
echo "K3s Cluster Setup"
echo "========================================="

CONFIG="config.yaml"
KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
SERVICE="k3s"

if [ "$EUID" -ne 0 ]; then # if not running as root
    echo "❌ Please run as root or with sudo"
    exit 1
fi

is_k3s_available() {
    command -v k3s &> /dev/null
}

is_k3s_running() {
    systemctl is-active --quiet $SERVICE
}

get_current_version() {
    k3s --version 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' | head -n1 | cut -d'+' -f1 # strip everything after the + character
}

get_latest_version() {
    curl -s https://api.github.com/repos/k3s-io/k3s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | cut -d'+' -f1
}

extract_credentials() {
    echo ""
    echo "========================================="
    echo "📋 Kubernetes Credentials"
    echo "========================================="
    
    if [ ! -f "$KUBECONFIG" ]; then
        echo "❌ Kubeconfig not found at $KUBECONFIG"
        return 1
    fi
    
    echo ""
    echo "🔗 Kubernetes Host:"
    grep "server:" $KUBECONFIG | awk '{print $2}'
    
    echo ""
    echo "🔐 Kubernetes Certificate (base64):"
    grep "certificate-authority-data:" $KUBECONFIG | awk '{print $2}'
        
    sleep 5 # wait for k3s to be fully ready
    
    # Create service account if it doesn't exist
    if ! k3s kubectl get sa terraform -n kube-system &>/dev/null; then
        echo ""
        echo "Creating service account 'terraform'..."
        k3s kubectl create serviceaccount terraform -n kube-system
        k3s kubectl create clusterrolebinding terraform --clusterrole=cluster-admin --serviceaccount=kube-system:terraform
    else
        echo "✓ Service account 'terraform' already exists"
    fi
    
    # Create token (works for K3s 1.24+)
    echo ""
    echo "🎫 Bearer Token (for Terraform):"
    k3s kubectl create token terraform -n kube-system --duration=87600h 2>/dev/null
}

echo "" # main script logic

echo "🔍 Checking for latest K3s version..."
LATEST_VERSION=$(get_latest_version)
echo "   Latest version available: $LATEST_VERSION"
echo ""

if is_k3s_available; then
    CURRENT_VERSION=$(get_current_version)
    echo "✓ K3s is installed: $CURRENT_VERSION"
    
    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo ""
        echo "⚠️  New version available!"
        read -p "   Do you want to upgrade? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "📦 Upgrading K3s to $LATEST_VERSION..."
            curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$LATEST_VERSION sh -s - server --config $CONFIG
            echo "✅ K3s upgraded successfully!"
        else
            echo "⏩ Skipping upgrade"
        fi
    else
        echo "✅ K3s is already at the latest version."
    fi
    
    if is_k3s_running; then
        echo "✓ K3s service is running"
    else
        echo "⚠️  K3s service is not running. Starting..."
        systemctl start $SERVICE
        echo "✅ K3s service started"
    fi
else
    echo "📦 K3s is not installed. Installing latest version..."
    
    if [ ! -f "$CONFIG" ]; then
        echo "❌ Configuration file not found: $CONFIG"
        exit 1
    fi
    
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$LATEST_VERSION sh -s - server --config $CONFIG
    echo "✅ K3s installed successfully!"
fi

echo "🔍 Verifying K3s installation..."
if is_k3s_running; then
    echo "✅ K3s is running properly"
    k3s kubectl get nodes
else
    echo "❌ K3s failed to start"
    echo "   Check logs with: journalctl -xeu k3s"
    exit 1
fi


# Extract Credentials Once Install/Upgrade is Complete
extract_credentials

echo ""
echo "✅ K3s Cluster Setup Complete!"
