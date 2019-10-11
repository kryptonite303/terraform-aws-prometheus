#cloud-config

runcmd:
  - apt-get install -y nfs-common
  - mkdir /efs
  - mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${dns_name}:/ /efs
  - chown -R prometheus:prometheus /efs
  - ln -s /var/lib/prometheus /efs
  - systemctl restart prometheus

write_files:
  - content: ${content}
    encoding: b64
    owner: prometheus:prometheus
    path: /etc/prometheus/file_sd/node.yml
    permissions: '0644'
