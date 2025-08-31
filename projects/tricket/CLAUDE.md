# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a monorepo for the Tricket digital ecosystem project with the following structure:

```
/tricket/
├── tricket-backend/           # Backend components
│   ├── supabase/             # Database migrations and configuration
│   │   ├── config.toml       # Supabase configuration
│   │   └── migrations/       # SQL migration files
│   ├── volumes/functions/    # Edge Functions (Deno/TypeScript)
│   └── scripts/              # Database and storage scripts
├── tricket-tests/            # Python integration test suite
│   ├── operations/           # Test operations and utilities
│   ├── testing/              # Specific test scenarios
│   ├── main.py              # Interactive test runner
│   └── Makefile             # Test automation commands
└── tricket-vault/           # Documentation and knowledge base
    ├── docs/                # Technical documentation
    ├── plans/               # Project planning documents
    ├── changelogs/          # Detailed project changelogs
    ├── tasks/               # Task definitions and epics
    └── rules/               # Development guidelines
```

## Technology Stack

- **Database**: PostgreSQL with Supabase (self-hosted)
- **Backend Functions**: Deno Edge Functions (TypeScript)
- **Integration Tests**: Python with pytest
- **Frontend**: WeWeb (low-code platform) - separate repository
- **External APIs**: Asaas (payments), Cappta (POS), GS1 Brasil (product data)

## Essential Development Commands

### Database Operations
Apply migrations to development database:
```bash
cd ~/workspaces/projects/tricket/tricket-backend
supabase db push --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
```

Reset database (WARNING: destroys all data):
```bash
cd ~/workspaces/projects/tricket/tricket-backend
supabase db reset --yes --db-url "postgresql://postgres.dev_tricket_tenant:yMepPcxVCBDa3NB1yx0Q8Fxh5DpweaYvXVP7W5AH@localhost:5408/postgres"
```

### Testing
Run integration test suite:
```bash
cd ~/workspaces/projects/tricket/tricket-tests
pytest
```

Run interactive test system:
```bash
cd ~/workspaces/projects/tricket/tricket-tests
python main.py
```

Install test dependencies:
```bash
cd ~/workspaces/projects/tricket/tricket-tests
pip install -r requirements.txt
```

### Using the Test System Makefile
```bash
cd ~/workspaces/projects/tricket/tricket-tests
make install    # Install dependencies
make run        # Run interactive test system
make list-profiles  # List profiles awaiting approval
make approve id=<UUID>  # Approve specific profile
```

## Architecture Overview

### Core Business Logic
- **IAM (Identity & Access Management)**: User registration, profile management, RBAC
- **Marketplace**: Product catalog, supplier offers, cart/checkout system
- **Financial Integration**: Asaas payment processing, account management
- **POS Integration**: Cappta integration for merchant terminals

### Database Structure
- **RBAC Tables**: Role-based access control system
- **IAM Tables**: User profiles (Individual/Organization), addresses, contacts
- **Marketplace Tables**: Products, categories, brands, supplier offers
- **Integration Tables**: Asaas accounts, Cappta POS configurations
- **RPC Functions**: Database-level business logic and validation

### Edge Functions
Located in `tricket-backend/volumes/functions/`, these handle:
- External API integrations (Asaas, Cappta, GS1)
- Webhook processing
- Authentication workflows
- Business logic orchestration

## Development Workflow

### Mandatory Development Process
1. **Create feature branch** from `main`
2. **Create plan document** in `tricket-vault/plans/YYYY-MM-DD-HHMM-task-name.md`
3. **Implement changes** (SQL migrations, Edge Functions)
4. **Apply migrations** using the supabase db push command
5. **Run test suite** to validate changes
6. **Create changelog** in `tricket-vault/changelogs/YYYY-MM-DD-HHMM-task-name.md`
7. **Commit and push** changes

### Migration Naming Convention
Migration files follow numerical prefixes:
- `1xx`: Global settings and infrastructure
- `2xx`: Core tables (IAM, marketplace, integrations)
- `3xx`: Views
- `5xx`: Functions
- `6xx`: RPC functions
- `8xx`: Seed data
- `9xx`: Data imports

### Test Users
The test system includes predefined user profiles:
- `admin@tricket.com.br` - System administrator
- `fornecedor@tricket.com.br` - Supplier (José Fornecedor/Coca-Cola)
- `comerciante@tricket.com.br` - Merchant (Maria Comerciante/Padaria)
- `consumidor@tricket.com.br` - Consumer (João Henrique/Individual)

## Key Configuration Files

- `tricket-backend/supabase/config.toml` - Supabase configuration
- `tricket-tests/config/tricket.json` - Test user configurations
- `tricket-tests/pytest.ini` - Test discovery configuration
- `tricket-vault/rules/tricket-rules.md` - Complete development guidelines

## Business Context

Tricket is a B2B2C digital ecosystem that connects:
- **Individual Profiles (PF)**: Personal consumers
- **Organization Profiles (PJ)**: Businesses (suppliers, merchants)

The platform provides:
- Digital payment accounts via Asaas
- Marketplace for B2B commerce
- POS terminals for merchants via Captta
- Integrated financial and supply chain management

## Security and Data Flow

- All users go through KYC (Know Your Customer) verification
- Financial operations use Asaas payment infrastructure
- POS transactions flow through Cappta integration
- Product data can be enhanced via GS1 Brasil API
- Role-based permissions control system access

## Important Notes

- Always test changes with the integration test suite before committing
- Database changes must be applied via migrations, never direct SQL
- External API configurations are environment-specific
- Token management system stores authentication tokens for testing
- The system supports multi-tenant architecture with organization-based access control