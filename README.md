# Decentralized Regulatory Compliance Training Management

A comprehensive blockchain-based system for managing regulatory compliance training using Stacks smart contracts written in Clarity.

## Overview

This system provides a complete solution for organizations to manage compliance training requirements, validate training providers, deliver courses, track completion, and manage certifications in a decentralized manner.

## System Architecture

The system consists of five interconnected smart contracts:

### 1. Training Provider Verification Contract (`training-provider-verification.clar`)
- Validates and manages compliance training providers
- Handles provider registration and verification status
- Maintains provider credentials and ratings

### 2. Requirement Mapping Contract (`requirement-mapping.clar`)
- Maps compliance training requirements to specific roles/departments
- Defines mandatory training courses for different positions
- Manages requirement updates and versioning

### 3. Course Delivery Contract (`course-delivery.clar`)
- Delivers compliance training courses
- Manages course content and scheduling
- Handles course enrollment and prerequisites

### 4. Completion Tracking Contract (`completion-tracking.clar`)
- Tracks training completion status
- Records completion dates and scores
- Maintains audit trails for compliance reporting

### 5. Certification Management Contract (`certification-management.clar`)
- Manages compliance certifications
- Issues and renews certificates
- Validates certification status and expiration

## Features

- **Decentralized Provider Network**: Verified training providers can offer courses
- **Automated Compliance Mapping**: Automatic assignment of required training based on roles
- **Immutable Records**: Blockchain-based completion and certification records
- **Real-time Tracking**: Live status updates for training progress
- **Audit Trail**: Complete history of all training activities
- **Certificate Lifecycle**: Automated issuance, renewal, and expiration management

## Contract Functions

### Provider Verification
- `register-provider`: Register a new training provider
- `verify-provider`: Verify a provider's credentials
- `update-provider-status`: Update provider verification status
- `get-provider-info`: Retrieve provider information

### Requirement Mapping
- `set-requirement`: Define training requirements for roles
- `update-requirement`: Modify existing requirements
- `get-requirements`: Get requirements for specific roles
- `check-compliance`: Verify if user meets requirements

### Course Delivery
- `create-course`: Create a new training course
- `enroll-user`: Enroll user in a course
- `start-course`: Begin course for enrolled user
- `get-course-info`: Retrieve course details

### Completion Tracking
- `record-completion`: Record training completion
- `update-progress`: Update user's course progress
- `get-completion-status`: Check completion status
- `get-user-progress`: Retrieve user's training history

### Certification Management
- `issue-certificate`: Issue compliance certificate
- `renew-certificate`: Renew existing certificate
- `revoke-certificate`: Revoke certificate if needed
- `check-certificate-validity`: Verify certificate status

## Data Structures

### Provider
```clarity
{
  name: (string-ascii 100),
  verified: bool,
  rating: uint,
  registration-date: uint,
  courses-offered: (list 50 uint)
}
```

### Training Requirement
```clarity
{
  role: (string-ascii 50),
  required-courses: (list 20 uint),
  renewal-period: uint,
  mandatory: bool
}
```

### Course
```clarity
{
  provider-id: uint,
  title: (string-ascii 100),
  duration: uint,
  prerequisites: (list 10 uint),
  active: bool
}
```

### Completion Record
```clarity
{
  user: principal,
  course-id: uint,
  completion-date: uint,
  score: uint,
  certified: bool
}
```

### Certificate
```clarity
{
  user: principal,
  course-id: uint,
  issue-date: uint,
  expiry-date: uint,
  status: (string-ascii 20)
}
```

## Installation

1. Clone the repository
2. Install Clarinet CLI
3. Deploy contracts to Stacks blockchain or local testnet

```bash
clarinet console
clarinet test
clarinet deploy
```

## Usage Example

```clarity
;; Register a training provider
(contract-call? .training-provider-verification register-provider "ACME Training Corp" "Cybersecurity specialist")

;; Set training requirement for a role
(contract-call? .requirement-mapping set-requirement "Security Analyst" (list u1 u2 u3) u365 true)

;; Create a course
(contract-call? .course-delivery create-course u1 "Data Privacy Fundamentals" u30 (list))

;; Enroll and complete training
(contract-call? .course-delivery enroll-user u1)
(contract-call? .completion-tracking record-completion u1 u95)

;; Issue certificate
(contract-call? .certification-management issue-certificate u1)
```

## Testing

The system includes comprehensive tests using Vitest:

```bash
npm test
```

Tests cover:
- Provider registration and verification
- Requirement mapping and updates
- Course creation and enrollment
- Completion tracking and progress
- Certificate issuance and management
- Error handling and edge cases

## Security Considerations

- All contracts include proper access controls
- Only verified providers can create courses
- Completion records are immutable once created
- Certificate revocation requires proper authorization
- Input validation prevents malicious data

## Compliance Features

- **SOX Compliance**: Immutable audit trails
- **GDPR Compliance**: User data protection measures
- **ISO 27001**: Security training tracking
- **HIPAA**: Healthcare compliance training
- **PCI DSS**: Payment security training

## Future Enhancements

- Integration with external learning management systems
- Mobile app for training delivery
- AI-powered personalized learning paths
- Advanced analytics and reporting
- Multi-language support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For technical support or questions, please open an issue in the repository.
