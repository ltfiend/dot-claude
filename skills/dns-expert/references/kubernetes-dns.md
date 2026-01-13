# DNS in Kubernetes & Containers

## Kubernetes DNS Architecture

### Pod DNS Resolution Flow
```
Pod → /etc/resolv.conf → CoreDNS (kube-dns) → Upstream
                              │
                              ├── cluster.local queries
                              │   └── kubernetes API (endpoints)
                              │
                              └── external queries
                                  └── forward to upstream
```

### Kubernetes DNS Search Domains
```bash
# Default /etc/resolv.conf in a pod (namespace: default)
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

### ndots Explained
```yaml
# ndots:5 means names with <5 dots get search domains appended first
# Query: api.example.com (2 dots, < 5)
# Order: api.example.com.default.svc.cluster.local
#        api.example.com.svc.cluster.local
#        api.example.com.cluster.local
#        api.example.com  ← finally tries absolute

# For external domains, reduce ndots or use trailing dot
spec:
  dnsConfig:
    options:
      - name: ndots
        value: "2"
```

## CoreDNS Configuration

### Basic Corefile
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
        }
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }

    internal.example.com:53 {
        forward . 10.0.0.53
    }
```

### CoreDNS Plugin Chain
```
.:53 {
    errors                    # Log errors
    health                    # Health check endpoint
    ready                     # Readiness endpoint

    kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure         # Respond to pod IP queries
        fallthrough in-addr.arpa ip6.arpa
        ttl 30                # Cache TTL for k8s records
    }

    prometheus :9153          # Metrics endpoint
    forward . /etc/resolv.conf # Upstream resolution
    cache 30                  # Cache non-k8s responses
    loop                      # Detect forwarding loops
    reload                    # Reload config on change
    loadbalance               # Round-robin A/AAAA
}
```

## Service DNS Records

### Standard Service
```yaml
# Service creates:
# my-service.default.svc.cluster.local → ClusterIP
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: default
spec:
  selector:
    app: my-app
  ports:
    - port: 80
```

### Headless Services DNS
```yaml
# Headless service (clusterIP: None)
apiVersion: v1
kind: Service
metadata:
  name: my-statefulset
spec:
  clusterIP: None
  selector:
    app: my-app

# DNS records created:
# my-statefulset.default.svc.cluster.local → A records for each pod
# pod-0.my-statefulset.default.svc.cluster.local → specific pod IP
# pod-1.my-statefulset.default.svc.cluster.local → specific pod IP
```

## Custom DNS Configuration

### Custom DNS per Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-dns-pod
spec:
  dnsPolicy: "None"  # Disable default DNS
  dnsConfig:
    nameservers:
      - 1.1.1.1
      - 8.8.8.8
    searches:
      - my-namespace.svc.cluster.local
      - svc.cluster.local
    options:
      - name: ndots
        value: "2"
      - name: edns0
```

### DNS Policies
| Policy | Description |
|--------|-------------|
| ClusterFirst | Use cluster DNS, fall back to node DNS |
| ClusterFirstWithHostNet | Like ClusterFirst but for hostNetwork pods |
| Default | Inherit from node |
| None | Custom via dnsConfig only |

## External DNS Integration

### DNSEndpoint Custom Resource
```yaml
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: my-service
spec:
  endpoints:
  - dnsName: app.example.com
    recordTTL: 300
    recordType: A
    targets:
    - 192.0.2.1
```

### External DNS Controller
```yaml
# Deploy external-dns to sync services to cloud DNS
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
spec:
  template:
    spec:
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.14.0
        args:
        - --source=service
        - --source=ingress
        - --provider=aws  # or: cloudflare, google, azure
        - --domain-filter=example.com
```

## Split-Horizon DNS

### Internal/External Resolution
```yaml
# Corefile with split-horizon
.:53 {
    errors
    health
    kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
    }
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}

# Forward internal domain to on-prem DNS
internal.example.com:53 {
    forward . 10.0.0.53
}
```

## Debugging K8s DNS

### Debug Pod
```bash
# Run debug pod with DNS tools
kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 \
    --restart=Never --rm -it -- bash

# Inside pod:
nslookup kubernetes.default
dig +search nginx-service
cat /etc/resolv.conf
```

### CoreDNS Troubleshooting
```bash
# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Check CoreDNS metrics
kubectl exec -n kube-system deploy/coredns -- curl localhost:9153/metrics

# Check CoreDNS config
kubectl get configmap coredns -n kube-system -o yaml
```

### Common Issues
| Symptom | Cause | Fix |
|---------|-------|-----|
| `NXDOMAIN` for services | Service doesn't exist or wrong namespace | Check service name and namespace |
| Slow external resolution | High ndots + many search domains | Lower ndots or use FQDN with trailing dot |
| Intermittent failures | CoreDNS pods overloaded | Scale CoreDNS, add caching |
| `connection refused` | CoreDNS not running | Check pod status, fix crashloop |

## Container DNS Patterns

### Docker DNS
```bash
# Docker built-in DNS server at 127.0.0.11
# Containers can resolve each other by name on user-defined networks

docker network create my-net
docker run -d --name db --network my-net postgres
docker run --network my-net alpine ping db  # Resolves!

# Custom DNS servers
docker run --dns 8.8.8.8 --dns-search example.com alpine
```

### Docker Compose DNS
```yaml
version: "3"
services:
  web:
    image: nginx
    networks:
      - frontend
    # Can resolve 'api' by name
  api:
    image: myapp
    networks:
      - frontend
      - backend
  db:
    image: postgres
    networks:
      - backend
    # 'web' cannot resolve 'db' (different network)
```

## DNS Monitoring & Observability

### Key Metrics
| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| Query latency (p99) | Resolution time | > 100ms |
| SERVFAIL rate | Failed resolutions | > 1% |
| NXDOMAIN rate | Non-existent domains | Baseline + 20% |
| Cache hit ratio | Caching effectiveness | < 80% |
| TCP fallback rate | Large response issues | > 5% |

### Prometheus Metrics (Unbound)
```yaml
# unbound.conf
server:
    extended-statistics: yes
    statistics-interval: 0
    statistics-cumulative: no

remote-control:
    control-enable: yes
    control-interface: /var/run/unbound.sock
```

```bash
# Collect via unbound_exporter
unbound_exporter --unbound.host="unix:///var/run/unbound.sock"
```

### dnstap for Query Logging
```yaml
# Unbound dnstap config
dnstap:
    dnstap-enable: yes
    dnstap-socket-path: "/var/run/dnstap.sock"
    dnstap-send-identity: yes
    dnstap-send-version: yes
    dnstap-log-client-query-messages: yes
    dnstap-log-client-response-messages: yes
```

## NetworkPolicy for DNS

```yaml
# Allow DNS egress to kube-system
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}  # Apply to all pods
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```
