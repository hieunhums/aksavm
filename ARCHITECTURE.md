# AKS Architecture Diagram

## High-Level Architecture

```mermaid
graph TB
    subgraph Internet["Internet"]
        User[User/Developer]
        CI[CI/CD Pipeline]
    end
    
    subgraph AzureSubscription["Azure Subscription: 1ba93e37-9d55-40ca-b240-0435b633fc72"]
        
        subgraph StateStorage["Terraform State Storage"]
            RGState[Resource Group<br/>rg-terraform-state]
            SA[Storage Account<br/>sttfstatedevXXXXXX<br/>🔐 Azure AD Auth Only]
            Container[Container: tfstate]
            
            RGState --> SA --> Container
            
            subgraph StateFiles["State Files"]
                S1[network.tfstate]
                S2[aks.tfstate]
                S3[postgresql.tfstate]
            end
            Container --> StateFiles
        end
        
        subgraph NetworkRG["Resource Group: rg-aks-network-dev<br/>Location: Australia East"]
            VNet[Virtual Network<br/>vnet-aks-dev<br/>10.0.0.0/16]
            
            subgraph Subnets["Subnets"]
                SubnetAKS[AKS System Nodes<br/>snet-aks-system<br/>10.0.0.0/22<br/>1024 IPs]
                SubnetPE[Private Endpoints<br/>snet-private-endpoints<br/>10.0.4.0/24<br/>256 IPs]
            end
            
            subgraph DNS["Private DNS Zones"]
                DNSAKS[privatelink.australiaeast<br/>.azmk8s.io]
                DNSACR[privatelink.azurecr.io]
            end
            
            subgraph Identity["Managed Identities"]
                IDAKS[User Assigned Identity<br/>id-aks-dev]
            end
            
            NSG[Network Security Group<br/>aks-nsg]
            
            VNet --> Subnets
            VNet -.->|linked| DNS
            NSG -.->|attached| SubnetAKS
        end
        
        subgraph AKSRG["Resource Group: rg-aks-dev<br/>Location: Australia East"]
            
            subgraph AKSCluster["AKS Cluster: aks-aks-dev-australiaeast"]
                ControlPlane[Control Plane<br/>🔒 Private<br/>Kubernetes v1.31]
                
                subgraph SystemPool["System Node Pool: agentpool"]
                    SysNode1[Node 1<br/>Standard_D4d_v5<br/>Zone 2]
                    SysNode2[Node 2<br/>Standard_D4d_v5<br/>Zone 2]
                    SysNode3[Node 3<br/>Standard_D4d_v5<br/>Zone 2]
                end
                
                subgraph UserPool["User Node Pool: user2"]
                    UserNode1[Node 1<br/>Standard_D4d_v5<br/>Zone 2]
                end
                
                subgraph PodNetwork["Pod Network - CNI Overlay"]
                    PodCIDR[Pod CIDR<br/>10.244.0.0/16]
                    ServiceCIDR[Service CIDR<br/>10.245.0.0/16]
                    DNS[DNS: 10.245.0.10]
                end
                
                subgraph Security["Security & Identity"]
                    RBAC[Azure AD RBAC<br/>🔐 Enabled]
                    Policy[Azure Policy<br/>✅ Enabled]
                    WLIdentity[Workload Identity<br/>OIDC Issuer]
                    KV[Key Vault Secrets<br/>Provider]
                end
                
                ControlPlane --> SystemPool
                ControlPlane --> UserPool
            end
            
            subgraph Monitoring["Monitoring & Logging"]
                LAW[Log Analytics Workspace<br/>log-aks-dev-australiaeast-aks]
                Diag[Diagnostic Settings<br/>AllMetrics + Logs]
                
                subgraph Tables["Log Tables - Basic Plan"]
                    T1[AKSAudit - 30 days]
                    T2[AKSAuditAdmin - 30 days]
                    T3[AKSControlPlane - 30 days]
                    T4[ContainerLogV2 - 30 days]
                end
                
                LAW --> Tables
            end
            
            Identity2[User Assigned Identity<br/>uami-aks]
            
            AKSCluster --> LAW
            Identity2 -.->|assigned to| ControlPlane
        end
        
        subgraph NodeRG["Node Resource Group<br/>(Auto-created by AKS)"]
            VMSS1[VM Scale Set<br/>System Pool]
            VMSS2[VM Scale Set<br/>User Pool]
            Disks[Managed Disks<br/>OS + Data]
            LB[Load Balancer<br/>Standard]
            PIP[Public IP<br/>(if not private)]
        end
    end
    
    %% Connections
    User -.->|kubectl via<br/>Private Link| ControlPlane
    CI -.->|Azure DevOps Agent| ControlPlane
    
    SubnetAKS -.->|hosts| SystemPool
    SubnetAKS -.->|hosts| UserPool
    
    ControlPlane -.->|uses| DNSAKS
    
    AKSCluster -.->|network| SubnetAKS
    
    Identity2 -.->|Network Contributor| NetworkRG
    Identity2 -.->|DNS Zone Contributor| DNSAKS
    
    SystemPool --> VMSS1
    UserPool --> VMSS2
    
    %% Styling
    classDef azure fill:#0078d4,stroke:#005a9e,color:#fff
    classDef network fill:#7fba00,stroke:#5c8700,color:#fff
    classDef compute fill:#ff8c00,stroke:#cc7000,color:#fff
    classDef security fill:#e81123,stroke:#b00a1a,color:#fff
    classDef storage fill:#50e6ff,stroke:#00b7c3,color:#000
    classDef monitor fill:#ffb900,stroke:#cc9400,color:#000
    
    class AzureSubscription azure
    class NetworkRG,VNet,Subnets,DNS network
    class AKSRG,AKSCluster,SystemPool,UserPool,NodeRG compute
    class RBAC,Policy,WLIdentity,KV security
    class StateStorage,SA,Container storage
    class Monitoring,LAW,Tables monitor
```

---

## Network Architecture Detail

```mermaid
graph TB
    subgraph Azure["Azure Region: Australia East"]
        subgraph VNet["Virtual Network: 10.0.0.0/16"]
            subgraph AKSSubnet["snet-aks-system: 10.0.0.0/22"]
                direction LR
                Node1[AKS Node<br/>10.0.0.4]
                Node2[AKS Node<br/>10.0.0.5]
                Node3[AKS Node<br/>10.0.0.6]
                
                subgraph Pods1["Pods on Node1"]
                    Pod1[Pod<br/>10.244.1.x]
                    Pod2[Pod<br/>10.244.1.y]
                end
                
                Node1 --> Pods1
            end
            
            subgraph PESubnet["snet-private-endpoints: 10.0.4.0/24"]
                PE_ACR[Private Endpoint<br/>ACR<br/>10.0.4.x]
                PE_KV[Private Endpoint<br/>Key Vault<br/>10.0.4.y]
            end
        end
        
        subgraph PrivateDNS["Private DNS Resolution"]
            Zone1[privatelink.australiaeast.azmk8s.io<br/>→ Control Plane IP]
            Zone2[privatelink.azurecr.io<br/>→ ACR Private IP]
        end
        
        LB[Azure Load Balancer<br/>Frontend: Service IPs<br/>Backend: Nodes]
        
        AKSSubnet -.->|pods pull images| PE_ACR
        AKSSubnet -.->|pods get secrets| PE_KV
        
        Node1 -.->|resolves via| Zone1
        Node1 -.->|resolves via| Zone2
        
        LB -.->|distributes to| AKSSubnet
    end
    
    Internet[Internet Traffic] -.->|ingress| LB
    
    classDef subnet fill:#d4edda,stroke:#28a745
    classDef dns fill:#cce5ff,stroke:#004085
    classDef pod fill:#fff3cd,stroke:#856404
    
    class AKSSubnet,PESubnet subnet
    class PrivateDNS,Zone1,Zone2 dns
    class Pods1,Pod1,Pod2 pod
```

---

## Pod Networking - CNI Overlay

```mermaid
graph LR
    subgraph Node["AKS Node - VNet IP: 10.0.0.4"]
        direction TB
        
        subgraph PodNetwork["Overlay Network"]
            Pod1[Pod 1<br/>10.244.1.10<br/>App Container]
            Pod2[Pod 2<br/>10.244.1.11<br/>App Container]
            Pod3[Pod 3<br/>10.244.1.12<br/>App Container]
        end
        
        CNI[Azure CNI Overlay<br/>Network Plugin]
        
        Pod1 --> CNI
        Pod2 --> CNI
        Pod3 --> CNI
    end
    
    subgraph Services["Kubernetes Services"]
        Svc1[Service A<br/>10.245.0.100<br/>ClusterIP]
        Svc2[Service B<br/>10.245.0.101<br/>ClusterIP]
    end
    
    CNI -.->|NAT to Node IP| VNet[VNet: 10.0.0.0/16]
    Svc1 -.->|load balance| Pod1
    Svc1 -.->|load balance| Pod2
    Svc2 -.->|load balance| Pod3
    
    VNet -.->|route traffic| Internet[Internet/Azure Services]
    
    classDef pod fill:#e3f2fd,stroke:#1976d2
    classDef service fill:#f3e5f5,stroke:#7b1fa2
    classDef network fill:#e8f5e9,stroke:#388e3c
    
    class Pod1,Pod2,Pod3,PodNetwork pod
    class Svc1,Svc2,Services service
    class VNet,CNI network
```

---

## Security Architecture

```mermaid
graph TB
    subgraph UserAccess["User Access"]
        Dev[Developer]
        Admin[Cluster Admin]
        App[Application]
    end
    
    subgraph AzureAD["Azure Active Directory"]
        AADUser[AAD User/Group]
        SvcPrincipal[Service Principal]
        ManagedID[Managed Identity]
    end
    
    subgraph AKS["AKS Cluster"]
        OIDC[OIDC Issuer<br/>Workload Identity]
        
        subgraph RBAC["Azure RBAC"]
            Role1[Azure Kubernetes Service<br/>Cluster Admin Role]
            Role2[Azure Kubernetes Service<br/>RBAC Reader]
        end
        
        subgraph K8sRBAC["Kubernetes RBAC"]
            K8sAdmin[cluster-admin]
            K8sView[view]
        end
        
        subgraph Policies["Azure Policy"]
            Pol1[✓ Enforce HTTPS ingress]
            Pol2[✓ Require resource limits]
            Pol3[✓ Block privileged pods]
            Pol4[✓ Enforce image registry]
        end
        
        subgraph NetworkPolicy["Cilium Network Policy"]
            NP1[Pod → Pod rules]
            NP2[Pod → External rules]
            NP3[Namespace isolation]
        end
        
        subgraph Secrets["Secrets Management"]
            KVProvider[Key Vault Provider<br/>CSI Driver]
            K8sSecrets[Kubernetes Secrets]
        end
    end
    
    subgraph KeyVault["Azure Key Vault"]
        Secret1[Database Password]
        Secret2[API Keys]
        Cert1[TLS Certificates]
    end
    
    Dev -.->|authenticate| AADUser
    Admin -.->|authenticate| AADUser
    App -.->|uses| ManagedID
    
    AADUser -.->|assigned| Role1
    AADUser -.->|assigned| Role2
    
    Role1 -.->|grants| K8sAdmin
    Role2 -.->|grants| K8sView
    
    ManagedID -.->|federated with| OIDC
    OIDC -.->|token exchange| App
    
    App -.->|accesses via<br/>workload identity| KeyVault
    
    KVProvider -.->|mounts as volume| K8sSecrets
    KeyVault -.->|provides| KVProvider
    
    classDef user fill:#fff3cd,stroke:#856404
    classDef aad fill:#e3f2fd,stroke:#1976d2
    classDef rbac fill:#f3e5f5,stroke:#7b1fa2
    classDef policy fill:#ffebee,stroke:#c62828
    classDef secret fill:#e8f5e9,stroke:#2e7d32
    
    class Dev,Admin,App user
    class AADUser,SvcPrincipal,ManagedID,AzureAD aad
    class RBAC,K8sRBAC,Role1,Role2,K8sAdmin,K8sView rbac
    class Policies,Pol1,Pol2,Pol3,Pol4,NetworkPolicy,NP1,NP2,NP3 policy
    class Secrets,KeyVault,KVProvider,K8sSecrets,Secret1,Secret2,Cert1 secret
```

---

## Monitoring & Observability Architecture

```mermaid
graph TB
    subgraph AKS["AKS Cluster"]
        ControlPlane[Control Plane<br/>API Server, Scheduler, etc.]
        
        subgraph Nodes["Nodes"]
            Node1[Node 1]
            Node2[Node 2]
            
            subgraph Pods["Pods"]
                App1[Application Pod]
                App2[Application Pod]
            end
        end
        
        subgraph Agents["Monitoring Agents"]
            OMS[Container Insights<br/>OMS Agent]
            MetricsAgent[Azure Monitor<br/>Metrics Agent]
        end
    end
    
    subgraph Monitoring["Azure Monitor"]
        LAW[Log Analytics Workspace<br/>log-aks-dev-australiaeast-aks]
        
        subgraph Logs["Container Insights Logs"]
            ContainerLog[ContainerLogV2<br/>30 day retention<br/>Basic plan]
            PerfLog[Perf<br/>Performance metrics]
            InvLog[KubeNodeInventory<br/>Node inventory]
        end
        
        subgraph DiagLogs["AKS Diagnostic Logs"]
            APIServer[kube-apiserver<br/>API requests]
            Audit[kube-audit<br/>Audit events]
            AuditAdmin[kube-audit-admin<br/>Admin actions]
            ControlPlaneLog[AKSControlPlane<br/>Control plane logs]
            Autoscaler[cluster-autoscaler<br/>Scaling events]
            CloudController[cloud-controller-manager]
            CSIDisk[csi-azuredisk-controller]
            CSIFile[csi-azurefile-controller]
            Guard[guard<br/>Admission webhook]
            Scheduler[kube-scheduler]
        end
        
        subgraph Metrics["Azure Monitor Metrics"]
            NodeCPU[Node CPU %]
            NodeMem[Node Memory %]
            PodCount[Pod Count]
            DiskUsage[Disk Usage]
        end
    end
    
    subgraph Visualization["Visualization & Alerts"]
        Portal[Azure Portal<br/>Container Insights]
        Workbooks[Azure Workbooks<br/>Custom Dashboards]
        Alerts[Alert Rules<br/>Email/SMS/Webhook]
        Grafana[Grafana<br/>(Optional)]
    end
    
    %% Data Flow
    ControlPlane -->|diagnostic logs| DiagLogs
    Nodes -->|via OMS agent| Logs
    Pods -->|stdout/stderr| ContainerLog
    Nodes -->|metrics| Metrics
    
    Logs --> LAW
    DiagLogs --> LAW
    Metrics --> LAW
    
    LAW --> Portal
    LAW --> Workbooks
    LAW --> Alerts
    LAW -.->|export| Grafana
    
    %% Queries
    subgraph Queries["Sample Queries"]
        Q1["Failed Pods:<br/>ContainerLogV2<br/>| where ContainerStatus == 'Failed'"]
        Q2["High CPU Nodes:<br/>Perf<br/>| where CounterName == 'cpuUsagePercentage'<br/>| where CounterValue > 80"]
        Q3["API Server Errors:<br/>AKSControlPlane<br/>| where Category == 'kube-apiserver'<br/>| where Level == 'Error'"]
    end
    
    Portal -.->|run| Queries
    
    classDef aks fill:#0078d4,stroke:#005a9e,color:#fff
    classDef monitor fill:#ffb900,stroke:#cc9400,color:#000
    classDef logs fill:#e8f5e9,stroke:#388e3c
    classDef viz fill:#f3e5f5,stroke:#7b1fa2
    
    class AKS,ControlPlane,Nodes,Pods aks
    class Monitoring,LAW,Metrics monitor
    class Logs,DiagLogs,ContainerLog,APIServer,Audit logs
    class Visualization,Portal,Workbooks,Alerts,Grafana viz
```

---

## Auto-scaling Architecture

```mermaid
graph TB
    subgraph Triggers["Scaling Triggers"]
        CPUTrigger[CPU Utilization > 80%]
        MemTrigger[Memory Utilization > 80%]
        CustomMetric[Custom Metrics<br/>Queue Length, etc.]
        Schedule[Scheduled Scaling]
    end
    
    subgraph HPA["Horizontal Pod Autoscaler"]
        HPAController[HPA Controller]
        MinPods[Min Replicas: 2]
        MaxPods[Max Replicas: 10]
        
        HPAController --> MinPods
        HPAController --> MaxPods
    end
    
    subgraph ClusterAutoscaler["Cluster Autoscaler"]
        CAController[Cluster Autoscaler]
        
        subgraph SystemPool["System Node Pool"]
            SysMin[Min: 3 nodes]
            SysMax[Max: 9 nodes]
        end
        
        subgraph UserPool["User Node Pool"]
            UserMin[Min: 1 node]
            UserMax[Max: 3 nodes]
        end
        
        CAController --> SystemPool
        CAController --> UserPool
    end
    
    subgraph Decisions["Scaling Decisions"]
        ScaleOutPods[Scale Out Pods<br/>Add more replicas]
        ScaleInPods[Scale In Pods<br/>Remove replicas]
        ScaleOutNodes[Scale Out Nodes<br/>Add new nodes]
        ScaleInNodes[Scale In Nodes<br/>Remove nodes]
    end
    
    CPUTrigger -->|triggers| HPAController
    MemTrigger -->|triggers| HPAController
    CustomMetric -->|triggers| HPAController
    
    HPAController -.->|needs more capacity| ScaleOutPods
    ScaleOutPods -.->|pending pods| CAController
    
    CAController -.->|insufficient capacity| ScaleOutNodes
    CAController -.->|nodes underutilized<br/>15min threshold| ScaleInNodes
    
    HPAController -.->|low utilization| ScaleInPods
    
    subgraph Config["Autoscaler Configuration"]
        Expander[Expander: random]
        ScaleDown[Scale Down Delay: 10m]
        MaxUnready[Max Unready: 3 nodes]
        MaxPercent[Max Unready: 45%]
        ScanInterval[Scan Interval: 10s]
        MaxTime[Max Provision Time: 15m]
    end
    
    CAController -.->|uses| Config
    
    classDef trigger fill:#fff3cd,stroke:#856404
    classDef scaler fill:#e3f2fd,stroke:#1976d2
    classDef decision fill:#e8f5e9,stroke:#388e3c
    classDef config fill:#f3e5f5,stroke:#7b1fa2
    
    class Triggers,CPUTrigger,MemTrigger,CustomMetric,Schedule trigger
    class HPA,ClusterAutoscaler,HPAController,CAController scaler
    class Decisions,ScaleOutPods,ScaleInPods,ScaleOutNodes,ScaleInNodes decision
    class Config config
```

---

## Deployment Pipeline Architecture

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as Git Repository
    participant TF as Terraform
    participant Azure as Azure APIs
    participant Storage as State Storage
    participant AKS as AKS Cluster
    
    Note over Dev,AKS: Phase 1: Bootstrap
    Dev->>TF: terraform apply (0-bootstrap)
    TF->>Azure: Create storage account
    Azure-->>TF: Storage account created
    TF->>Storage: Create container
    TF-->>Dev: Output: storage_account_name
    
    Note over Dev,AKS: Phase 2: Network Foundation
    Dev->>Azure: Assign Storage Blob Data Contributor
    Azure-->>Dev: Role assigned
    Dev->>TF: terraform init -backend-config
    TF->>Storage: Initialize remote state (Azure AD auth)
    Storage-->>TF: Backend configured
    Dev->>TF: terraform apply (1-network)
    TF->>Azure: Create VNet, subnets, DNS zones
    TF->>Azure: Create managed identity
    Azure-->>TF: Resources created
    TF->>Storage: Write network.tfstate
    TF-->>Dev: Output: network_config
    
    Note over Dev,AKS: Phase 3: AKS Deployment
    Dev->>Azure: Enable EncryptionAtHost feature
    Azure-->>Dev: Feature enabled
    Dev->>TF: terraform init (2-aks)
    TF->>Storage: Read network.tfstate
    Storage-->>TF: Network configuration
    Dev->>TF: terraform apply (2-aks)
    TF->>Azure: Create AKS cluster
    TF->>Azure: Create node pools
    TF->>Azure: Create Log Analytics
    TF->>Azure: Configure RBAC roles
    Azure-->>TF: AKS cluster created
    TF->>Storage: Write aks.tfstate
    TF-->>Dev: Output: kubeconfig, OIDC URL
    
    Note over Dev,AKS: Access Cluster
    Dev->>Azure: az aks get-credentials
    Azure-->>Dev: kubeconfig downloaded
    Dev->>AKS: kubectl get nodes
    AKS-->>Dev: Node list
```

---

## Resource Dependencies

```mermaid
graph TB
    subgraph Bootstrap["0-bootstrap"]
        RG1[Resource Group<br/>rg-terraform-state]
        ST[Storage Account<br/>sttfstatedevXXXXXX]
        CN[Container<br/>tfstate]
        
        RG1 --> ST --> CN
    end
    
    subgraph Network["1-network"]
        RG2[Resource Group<br/>rg-aks-network-dev]
        VN[Virtual Network<br/>vnet-aks-dev]
        SN1[Subnet<br/>snet-aks-system]
        SN2[Subnet<br/>snet-private-endpoints]
        DNS1[Private DNS Zone<br/>AKS]
        DNS2[Private DNS Zone<br/>ACR]
        ID1[Managed Identity<br/>id-aks-dev]
        NSG1[Network Security Group]
        
        RG2 --> VN
        VN --> SN1
        VN --> SN2
        RG2 --> DNS1
        RG2 --> DNS2
        RG2 --> ID1
        RG2 --> NSG1
        NSG1 -.->|attached| SN1
        DNS1 -.->|linked| VN
        DNS2 -.->|linked| VN
    end
    
    subgraph AKS["2-aks"]
        RG3[Resource Group<br/>rg-aks-dev]
        ID2[Managed Identity<br/>uami-aks]
        Cluster[AKS Cluster<br/>aks-aks-dev-australiaeast]
        NP1[System Node Pool<br/>agentpool]
        NP2[User Node Pool<br/>user2]
        LAW1[Log Analytics Workspace]
        Tables[Log Tables x4]
        Diag[Diagnostic Settings]
        RA1[Role Assignment<br/>Network Contributor]
        RA2[Role Assignment<br/>DNS Zone Contributor]
        
        RG3 --> ID2
        RG3 --> Cluster
        RG3 --> LAW1
        Cluster --> NP1
        Cluster --> NP2
        LAW1 --> Tables
        Cluster --> Diag
        Diag --> LAW1
        ID2 --> RA1
        ID2 --> RA2
        
        Cluster -.->|uses| SN1
        Cluster -.->|uses| DNS1
        RA1 -.->|scope| RG2
        RA2 -.->|scope| DNS1
    end
    
    subgraph NodeRG["MC_* (Auto-created)"]
        VMSS1[VM Scale Set<br/>System]
        VMSS2[VM Scale Set<br/>User]
        Disks[Managed Disks]
        LB1[Load Balancer]
        
        NP1 -.->|provisions| VMSS1
        NP2 -.->|provisions| VMSS2
        VMSS1 --> Disks
        VMSS2 --> Disks
        VMSS1 --> LB1
        VMSS2 --> LB1
    end
    
    ST -.->|stores state| Network
    ST -.->|stores state| AKS
    Network -.->|remote state| AKS
    
    classDef bootstrap fill:#bbdefb,stroke:#1976d2
    classDef network fill:#c8e6c9,stroke:#388e3c
    classDef aks fill:#ffe0b2,stroke:#e65100
    classDef noderg fill:#f8bbd0,stroke:#c2185b
    
    class Bootstrap,RG1,ST,CN bootstrap
    class Network,RG2,VN,SN1,SN2,DNS1,DNS2,ID1,NSG1 network
    class AKS,RG3,ID2,Cluster,NP1,NP2,LAW1,Tables,Diag,RA1,RA2 aks
    class NodeRG,VMSS1,VMSS2,Disks,LB1 noderg
```

---

## Summary

This architecture provides:

- **🔒 Security**: Private cluster, Azure AD RBAC, Azure Policy, Network Policy
- **📊 Observability**: Comprehensive logging to Log Analytics, Container Insights
- **⚡ Scalability**: Pod and node autoscaling with configurable thresholds
- **🛡️ Reliability**: Zone redundancy, HA configuration, health monitoring
- **🔐 Identity**: Workload Identity for pod-to-Azure authentication
- **📦 State Management**: Centralized Terraform state with Azure AD authentication
- **🌐 Networking**: CNI Overlay for efficient IP utilization, private DNS resolution
