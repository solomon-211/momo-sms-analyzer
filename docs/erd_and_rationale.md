# ERD Diagram - MoMo SMS Database System

## Entity Relationship Diagram

```
                         TRANSACTION_CATEGORIES
                    ┌─────────────────────────────┐
                    │ PK: category_id (INT)       │
                    │     category_name (VARCHAR) │
                    │     category_code (VARCHAR) │
                    │     description (TEXT)      │
                    │     created_at (TIMESTAMP)  │
                    └─────────────────────────────┘
                                   │
                                   │ 1:M
                                   ▼
        USERS                    TRANSACTIONS                    SYSTEM_LOGS
┌─────────────────────┐    ┌─────────────────────────┐    ┌─────────────────────┐
│ PK: user_id (INT)   │◄──►│ PK: transaction_id (INT)│    │ PK: log_id (INT)    │
│     phone_number    │1:M │     tx_id (VARCHAR)     │    │     log_level (ENUM)│
│     full_name       │    │ FK: sender_id (INT)     │    │     message (TEXT)  │
│     account_number  │    │ FK: receiver_id (INT)   │    │     module (VARCHAR)│
│     balance (DEC)   │    │ FK: category_id (INT)   │    │ FK: user_id (INT)   │
│     status (ENUM)   │    │     amount (DECIMAL)    │    │ FK: transaction_id  │
│     created_at      │    │     fee (DECIMAL)       │    │     ip_address      │
│     updated_at      │    │     balance_after (DEC) │    │     created_at      │
└─────────────────────┘    │     transaction_date    │    └─────────────────────┘
                           │     status (ENUM)       │              ▲
                           │     message_body (TEXT) │              │
                           │     service_center      │              │ M:N
                           │     created_at          │              │
                           └─────────────────────────┘              │
                                      │                             │
                                      │ M:N                         │
                                      ▼                             │
                            ┌─────────────────────────┐             │
                            │    TRANSACTION_LOGS     │─────────────┘
                            │   (Junction Table)      │
                            ├─────────────────────────┤
                            │ PK: log_transaction_id  │
                            │ FK: transaction_id (INT)│
                            │ FK: log_id (INT)        │
                            │     log_type (ENUM)     │
                            │     created_at          │
                            │ UK: (transaction_id,    │
                            │      log_id)            │
                            └─────────────────────────┘
```

## Design Rationale (300+ words)

The MoMo SMS Data Processing System database design addresses the complex requirements of mobile money transaction processing through a carefully architected relational database structure. The design decisions were driven by the need to handle high-volume transaction processing while maintaining data integrity, supporting comprehensive audit trails, and ensuring scalability for future growth.

**Normalization Strategy**: The database follows Third Normal Form (3NF) principles to eliminate data redundancy and ensure consistency. User information is centralized in the USERS table, preventing duplicate customer data across transactions. Transaction categories are maintained in a separate lookup table, enabling easy addition of new transaction types without schema modifications. This normalization approach reduces storage requirements and eliminates update anomalies.

**Many-to-Many Resolution**: The most critical design decision was resolving the complex relationship between transactions and system logs. A single transaction can generate multiple log entries (processing, validation, notification), and system logs may relate to multiple transactions during batch processing. The TRANSACTION_LOGS junction table elegantly resolves this many-to-many relationship, enabling comprehensive audit trails essential for regulatory compliance and debugging.

**Data Integrity Framework**: The design implements multiple layers of data integrity through primary keys, foreign keys, check constraints, and unique constraints. Business rules are enforced at the database level, ensuring transaction amounts are positive, fees are non-negative, and user balances remain consistent. This constraint system prevents data corruption and maintains business rule compliance regardless of the application layer.

**Performance Optimization**: Strategic indexing on frequently queried columns (phone numbers, transaction IDs, dates) ensures optimal query performance. Composite indexes support complex analytical queries while maintaining fast transaction processing. The design balances query performance with storage efficiency.

**Audit and Compliance**: The comprehensive logging system through the junction table design supports regulatory requirements for financial transaction tracking. Every transaction can be traced through its complete lifecycle with detailed audit trails, essential for mobile money operations in regulated financial environments.

This design provides a robust foundation for mobile money transaction processing with professional-grade data integrity, performance, and audit capabilities.