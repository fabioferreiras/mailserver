#!/bin/bash

# update and upgrade packages
sudo -i
apt-get update -y && apt-get upgrade -y

# Add hostname
echo "127.0.0.1 mail.$HOSTNAME" >>/etc/hosts

# Disable systemd-resolve in order to avoid conflict between dnsmasq and systemd-resolve
systemctl disable systemd-resolved
systemctl stop systemd-resolved

rm -f /etc/resolv.conf
# Now create your own resolv.conf
sh -c 'echo nameserver 8.8.8.8 >> /etc/resolv.conf'

#Now install Dnsmasq
apt install dnsmasq -y


# Take the backup of the existing Dnsmasq config file and edit the file
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak


# install docker
#apt-get install -y docker.io apt-transport-https

mkdir -p /etc/kubernetes /etc/kubernetes/pki /etc/systemd/system/kubelet.service.d

cat <<EOF >/etc/kubernetes/cloud-config
{
  "cloud": "AzurePublicCloud",
  "tenantId": "${TENANT_ID}",
  "subscriptionId": "${SUBSCRIPTION_ID}",
  "aadClientId": "${CLIENT_ID}",
  "aadClientSecret": "${CLIENT_SECRET}",
  "location": "${LOCATION}",
  "resourceGroup": "${RESOURCE_GROUP}",
  "vmType": "vmss",
  "subnetName": "subnet",
  "securityGroupName": "nsg",
  "vnetName": "vnet",
  "vnetResourceGroup": "",
  "routeTableName": "routetable",
  "primaryScaleSetName": "node0",
  "cloudProviderBackoff": false,
  "cloudProviderBackoffRetries": 0,
  "cloudProviderBackoffExponent": 0,
  "cloudProviderBackoffDuration": 0,
  "cloudProviderBackoffJitter": 0,
  "cloudProviderRatelimit": false,
  "cloudProviderRateLimitQPS": 0,
  "cloudProviderRateLimitBucket": 0,
  "useManagedIdentityExtension": false,
  "useInstanceMetadata": true
}
EOF


curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y --option=Dpkg::Options::=--force-confold kubelet kubeadm kubectl


