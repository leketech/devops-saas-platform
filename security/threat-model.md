# Threat Model for Multi-Tenant SaaS API

## System Overview

The Multi-Tenant SaaS API is a cloud-native application built with Go, PostgreSQL, and Redis, deployed on AWS EKS. It serves multiple tenants with isolated data and resources.

## Architecture Components

- **API Service**: Go-based HTTP service with JWT authentication
- **Database**: PostgreSQL RDS instance with tenant isolation
- **Cache**: Redis instance for rate limiting and caching
- **Kubernetes**: EKS cluster with multiple namespaces
- **Load Balancer**: AWS Application Load Balancer with ACM certificates
- **Authentication**: JWT-based with tenant ID in claims

## Assets to Protect

- **Tenant Data**: Isolated data for each tenant in the database
- **Authentication Tokens**: JWT tokens containing tenant information
- **API Endpoints**: Protected from unauthorized access
- **Infrastructure**: EKS cluster, RDS, and Redis instances
- **Network Traffic**: Encrypted in-transit communication

## Threat Agents

- **Malicious Tenants**: Attempting to access other tenants' data
- **Insider Threats**: Unauthorized access by internal personnel
- **External Attackers**: Attempting to exploit vulnerabilities
- **Compromised Applications**: Applications with stolen credentials

## Threat Scenarios

### 1. Tenant Data Isolation Bypass
- **Threat**: Tenant A accessing Tenant B's data
- **Attack Vector**: Manipulating tenant_id in requests or exploiting query vulnerabilities
- **Impact**: High - Data breach of sensitive tenant information
- **Mitigation**: 
  - Always filter queries by tenant_id
  - Use row-level security in PostgreSQL
  - Implement tenant ID validation middleware

### 2. JWT Token Tampering
- **Threat**: Modifying JWT tokens to impersonate other tenants
- **Attack Vector**: Intercepting and modifying JWT claims
- **Impact**: High - Unauthorized access to tenant resources
- **Mitigation**:
  - Use strong signing algorithms (HS256/RS256)
  - Short token expiration times
  - Validate all token claims server-side

### 3. API Rate Limit Bypass
- **Threat**: Overwhelming the API with requests
- **Attack Vector**: Circumventing rate limiting mechanisms
- **Impact**: Medium - Potential DoS on the service
- **Mitigation**:
  - Per-tenant rate limiting
  - Proper Redis implementation
  - Monitoring and alerting on unusual traffic patterns

### 4. IAM Permission Escalation
- **Threat**: Applications gaining excessive AWS permissions
- **Attack Vector**: Overly permissive IAM roles
- **Impact**: High - Potential access to all AWS resources
- **Mitigation**:
  - Use IRSA with minimal required permissions
  - Regular permission audits
  - Principle of least privilege

### 5. Network Traffic Interception
- **Threat**: Intercepting communication between services
- **Attack Vector**: Unencrypted internal communication
- **Impact**: Medium - Potential data exposure
- **Mitigation**:
  - TLS encryption for all service communication
  - Network policies to restrict traffic
  - VPC private subnets

### 6. SQL Injection
- **Threat**: Injecting malicious SQL through API inputs
- **Attack Vector**: Unvalidated user inputs in database queries
- **Impact**: High - Data breach and potential system compromise
- **Mitigation**:
  - Parameterized queries
  - Input validation and sanitization
  - Regular security testing

### 7. Secrets Exposure
- **Threat**: Exposure of database passwords, JWT secrets, etc.
- **Attack Vector**: Hardcoded secrets, unencrypted storage
- **Impact**: High - Full system compromise
- **Mitigation**:
  - Use AWS Secrets Manager
  - Never hardcode secrets
  - Proper RBAC for secret access

## Security Controls

### Authentication & Authorization
- JWT-based authentication with tenant isolation
- Role-based access control
- Multi-factor authentication for admin access

### Data Protection
- Encryption at rest (RDS and EBS volumes)
- Encryption in transit (TLS 1.2+)
- Data anonymization for non-production environments

### Infrastructure Security
- IRSA for Kubernetes service accounts
- Network policies restricting traffic
- Pod security standards enforcement
- Regular image scanning and patching

### Monitoring & Logging
- Centralized logging with tenant isolation
- Real-time threat detection
- Anomaly detection for unusual access patterns
- Audit logging for all data access

## Risk Assessment

| Threat | Likelihood | Impact | Risk Level | Status |
|--------|------------|--------|------------|---------|
| Tenant Data Isolation Bypass | Medium | High | High | Mitigated |
| JWT Token Tampering | Low | High | Medium | Mitigated |
| API Rate Limit Bypass | Medium | Medium | Medium | Mitigated |
| IAM Permission Escalation | Low | High | Medium | Mitigated |
| Network Traffic Interception | Low | Medium | Low | Mitigated |
| SQL Injection | Low | High | Medium | Mitigated |
| Secrets Exposure | Low | High | Medium | Mitigated |

## Security Testing

- Regular penetration testing
- Static code analysis
- Dynamic application security testing
- Infrastructure as code security scanning
- Container image vulnerability scanning

## Compliance Considerations

- GDPR compliance for data handling
- SOC 2 Type II compliance
- Data residency requirements
- Audit logging requirements
- Data retention policies