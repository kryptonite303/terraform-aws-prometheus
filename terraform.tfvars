# Auto Scaling Group variables
key_name = "prometheus"

min_size = 1

max_size = 1

domain_name = "prometheus.build.10gen.cc"

hosted_zone_id = "ZYSJTA7XCIHDB"

hosted_zone_name = "prometheus.route53.build.10gen.cc"

# Certificate manager variables
certificate_arn = "arn:aws:acm:us-east-2:557821124784:certificate/05c69961-bc89-4fcf-ae96-5850b95b4df1"

# Prometheus targets
targets = [
  "evergreenapp-1.staging.build.10gen.cc:9100",
  "evergreenapp-2.staging.build.10gen.cc:9100",
  "evergreenapp-3.staging.build.10gen.cc:9100",
]
