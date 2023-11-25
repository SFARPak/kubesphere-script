#!/bin/sh

# Setting hostname, hosts file, and kernel settings
os_type=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

echo "Detected OS: $os_type"

echo "Enter the new hostname: "
read new_hostname

echo "Enter the IP address (or leave empty to detect automatically): "
read ipaddress

if [ -z "$ipaddress" ]; then
    ipaddress=$(hostname -I | awk '{print $1}')
    auto_detected=true
fi

echo "Enter the Fully Qualified Domain Name (FQDN): "
read fqdn

echo "Setting hostname to $new_hostname"
sudo hostnamectl set-hostname "$new_hostname"

case "$os_type" in
    "ubuntu" | "debian" | "almalinux" | "centos" | "rhel" | "rocky" | "oracle")
        echo "Updating /etc/hosts file for supported OS"
        sudo sed -i "/\b$new_hostname\b/d" /etc/hosts
        ;;
    *)
        echo "Unsupported OS type: $os_type. Please update /etc/hosts manually."
        ;;
esac

if [ "$auto_detected" = true ]; then
    sudo sed -i "1i$ipaddress\t$fqdn\t$new_hostname" /etc/hosts
else
    sudo sed -i "1i$ipaddress\t$fqdn\t$new_hostname" /etc/hosts
fi

echo "Hostname changed to $new_hostname"
echo "Updated /etc/hosts file"

echo "FQDN:"
hostname -f

# Menu for adding iptables rules
echo "Do you want to add iptables rules manually or using the script?"
echo "1. Add rules manually"
echo "2. Add rules using the script"

read -r choice

case $choice in
    1)
        add_rules_manually
        ;;
    2)
        # Adding comprehensive iptables rules
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9098 -j ACCEPT
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9099 -j ACCEPT
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9090 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9100 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9443 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9796 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8080 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8001 -j ACCEPT
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 2376 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 2379:2380 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 6443 -j ACCEPT  
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 6783:6784 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p udp --dport 6783:6784 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9098:9100 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 179 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 30000:32767 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 10250:10258 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 53 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p udp --dport 53 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5000 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5080 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5432 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 111 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8443 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8472 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 45014 -j ACCEPT 
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 30880 -j ACCEPT
        sudo iptables -I INPUT 6 -m state --state NEW -p udp --dport 30000:32767 -j ACCEPT
        # ... Add other rules as needed

        # Save iptables rules persistently
        sudo netfilter-persistent save
        ;;
    *)
        echo "Invalid choice. No rules were added."
        ;;
esac

# Adding Docker's GPG key
echo "Adding Docker's official GPG key..."
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
# Download Docker GPG key if needed
if ! [ -f "/etc/apt/keyrings/docker.gpg" ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "Docker's GPG key added."

# Adding the Docker repository to Apt sources
echo "Adding the Docker repository to Apt sources..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "Docker repository added to Apt sources."

# Update the package lists after adding repositories
echo "Updating package lists..."
sudo apt-get update
echo "Package lists updated."

# Install Docker-related packages
echo "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "Docker packages installed."

# Dependency requirements
apt install -y socat conntrack ebtables ipset


# Function to modify resolv.conf
modify_resolv_conf() {
    echo "Modifying resolv.conf..."
    echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
    echo "resolv.conf updated."
}



# Download KubeKey
curl -sfL https://get-kk.kubesphere.io | VERSION=v3.0.13 sh -

# Make kk executable
chmod +x kk

# Function to create a Kubernetes cluster with KubeSphere
create_cluster() {
    ./kk create cluster --with-kubernetes "$1" --with-kubesphere "$2"
}

# Function to create a config file
create_config() {
    ./kk create config --with-kubernetes "$1" --with-kubesphere "$2"
    
    # Function to update values in YAML file
    update_yaml_values() {
        local new_ip="$1"
        local auth_method="$2"
    
        sed -i "s/address: 172.16.0.2/address: $new_ip/g" config-sample.yaml
        sed -i "s/internalAddress: 172.16.0.2/internalAddress: $new_ip/g" config-sample.yaml
        
        if [ "$auth_method" == "password" ]; then
            sed -i 's/privateKeyPath:.*/user: ubuntu, password: "Qcloud@123"/g' config-sample.yaml
        elif [ "$auth_method" == "SSH" ]; then
            sed -i 's/user: ubuntu, password: "Qcloud@123"/privateKeyPath: "~\/.ssh\/id_rsa"/g' config-sample.yaml
        else
            echo "Invalid authentication method: $auth_method"
        fi
    }
    
    # Get IP address for node1 from the 'ipaddress' variable
    node1_ip="$ipaddress"
    
    # Ask the user for authentication method
    echo "Choose authentication method:"
    echo "1. Password authentication"
    echo "2. SSH key authentication"
    read -r choice
    
    case $choice in
        1)
            auth_method="password"
            ;;
        2)
            auth_method="SSH"
            ;;
        *)
            echo "Invalid choice. Please choose between 1 and 2."
            exit 1
            ;;
    esac
    
    # Call the function to update values
    update_yaml_values "$node1_ip" "$auth_method"
}

echo "Choose an option:"
echo "1. Create Cluster"
echo "2. Create Config"

read -p "Enter your choice: " choice

case $choice in
    1)
        read -p "Enter Kubernetes version (default: v1.22.12): " kubernetes_version
        read -p "Enter KubeSphere version (default: v3.4.0): " kubesphere_version
        
        kubernetes_version=${kubernetes_version:-"v1.22.12"}  # Set default if empty
        kubesphere_version=${kubesphere_version:-"v3.4.0"}  # Set default if empty

        create_cluster "$kubernetes_version" "$kubesphere_version"
        ;;
    2)
        read -p "Enter Kubernetes version (default: v1.22.12): " kubernetes_version
        read -p "Enter KubeSphere version (default: v3.4.0): " kubesphere_version
        
        kubernetes_version=${kubernetes_version:-"v1.22.12"}  # Set default if empty
        kubesphere_version=${kubesphere_version:-"v3.4.0"}  # Set default if empty

        create_config "$kubernetes_version" "$kubesphere_version"
        ;;
    *)
        echo "Invalid option. Please choose 1 or 2."
        ;;
esac
