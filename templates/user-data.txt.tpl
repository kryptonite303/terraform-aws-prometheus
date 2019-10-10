#cloud-config

write_files:
  - content: ${content}
    encoding: b64
    owner: prometheus:prometheus
    path: /etc/prometheus/file_sd/node.yml
    permissions: '0644'
