Asset Audit System

## Overview
Comprehensive audit management system for physical asset tokenization with auditor authorization, compliance tracking, and risk assessment capabilities.

## Technical Implementation
### Key Functions Added:
- **authorize-auditor**: Register certified auditors with specialization and reputation scores
- **revoke-auditor**: Deauthorize auditors when needed
- **conduct-asset-audit**: Complete audit process with findings and compliance scoring
- **request-audit**: Asset owners can request audits with budget allocation
- **update-auditor-reputation**: Admin function to manage auditor reputation scores

### Key Data Structures:
- **auditors**: Map storing auditor credentials and reputation
- **asset-audits**: Individual audit records with findings and compliance scores
- **asset-audit-history**: Historical audit data per asset with risk calculations

### Read-Only Functions:
- **get-asset-compliance-score**: Current compliance rating
- **calculate-audit-risk-score**: Dynamic risk assessment based on audit history
- **is-audit-valid**: Check if audit is still within validity period

## Testing & Validation
- ✅ Contract passes clarinet check
- ✅ All npm tests successful
- ✅ CI/CD pipeline configured
- ✅ Clarity v3 compliant with proper error handling
