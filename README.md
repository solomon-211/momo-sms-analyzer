# momo-sms-analyzer

**Team name:ThreeCode**

**Team** **members**: Darlene Ayinkamiye,Solomon Leek and Chely Kelvin Indamutsa Sheja.


# scrumboard
- https://github.com/users/Darlene250/projects/1

# Systems Architecture diagram/image
Links: https://drive.google.com/file/d/1dGZopqcA8QctI9gmXWY5yd2WziTsECas/view?usp=sharing
      OR
      https://github.com/solomon-211/momo-sms-analyzer/blob/main/docs/MoMo%20SMS%20Analyzer%20Architecture.PNG

<img width="944" height="1923" alt="MoMo SMS Analyzer Architecture" src="https://github.com/user-attachments/assets/bff44255-9588-4c6c-8921-33949cf8f30f" />

# MoMo SMS Data Processing System - Database Design

## Project Overview
This project implements a comprehensive database design for processing Mobile Money (MoMo) SMS transaction data. The system is designed to handle various types of mobile money transactions including payments, transfers, deposits, and airtime purchases.

## Database Architecture

### Core Entities
1. **Users** - Customer/account holder information
2. **Transaction Categories** - Types of mobile money operations
3. **Transactions** - Main transaction records
4. **System Logs** - Activity and error tracking
5. **Transaction Logs** - Junction table linking transactions with logs

### Entity Relationship Design

#### Primary Relationships
- **Users ↔ Transactions**: One-to-Many (sender/receiver)
- **Transaction Categories ↔ Transactions**: One-to-Many
- **Transactions ↔ System Logs**: Many-to-Many (via Transaction Logs junction table)

#### Key Design Decisions

**1. Separate User Entity**
- Extracted user information from SMS data to normalize the database
- Enables efficient user management and balance tracking
- Supports future features like user profiles and preferences

**2. Transaction Categories Table**
- Categorizes different types of mobile money operations
- Enables easy reporting and analytics by transaction type
- Supports future expansion of transaction types

**3. Many-to-Many Relationship**
- Transaction Logs junction table resolves the M:N relationship between Transactions and System Logs
- Allows multiple log entries per transaction and log entries to be associated with multiple transactions
- Essential for comprehensive audit trails and debugging

**4. Data Integrity Constraints**
- Foreign key constraints ensure referential integrity
- Check constraints validate business rules (positive amounts, non-negative fees)
- Unique constraints prevent duplicate transactions

## Database Schema

### Tables Structure

#### Users Table
```sql
- user_id (PK, INT, AUTO_INCREMENT)
- phone_number (VARCHAR(15), UNIQUE, NOT NULL)
- full_name (VARCHAR(100))
- account_number (VARCHAR(20))
- balance (DECIMAL(15,2), DEFAULT 0.00)
- status (ENUM: active, inactive, suspended)
- created_at, updated_at (TIMESTAMP)
```

#### Transaction Categories Table
```sql
- category_id (PK, INT, AUTO_INCREMENT)
- category_name (VARCHAR(50), UNIQUE, NOT NULL)
- category_code (VARCHAR(10), UNIQUE, NOT NULL)
- description (TEXT)
- created_at (TIMESTAMP)
```

#### Transactions Table
```sql
- transaction_id (PK, INT, AUTO_INCREMENT)
- tx_id (VARCHAR(50), UNIQUE, NOT NULL)
- sender_id (FK to Users)
- receiver_id (FK to Users)
- category_id (FK to Transaction Categories, NOT NULL)
- amount (DECIMAL(15,2), NOT NULL, CHECK > 0)
- fee (DECIMAL(10,2), DEFAULT 0.00, CHECK >= 0)
- balance_after (DECIMAL(15,2))
- transaction_date (DATETIME, NOT NULL)
- status (ENUM: completed, pending, failed, cancelled)
- message_body (TEXT)
- service_center (VARCHAR(20))
- created_at (TIMESTAMP)
```

#### System Logs Table
```sql
- log_id (PK, INT, AUTO_INCREMENT)
- log_level (ENUM: INFO, WARNING, ERROR, DEBUG)
- message (TEXT, NOT NULL)
- module (VARCHAR(50))
- user_id (FK to Users)
- transaction_id (FK to Transactions)
- ip_address (VARCHAR(45))
- created_at (TIMESTAMP)
```

#### Transaction Logs Table (Junction)
```sql
- log_transaction_id (PK, INT, AUTO_INCREMENT)
- transaction_id (FK to Transactions, NOT NULL)
- log_id (FK to System Logs, NOT NULL)
- log_type (ENUM: processing, validation, notification, error)
- created_at (TIMESTAMP)
- UNIQUE(transaction_id, log_id)
```

## Performance Optimizations

### Indexes
- Primary keys on all tables for fast lookups
- Foreign key indexes for join operations
- Composite indexes on frequently queried columns:
  - `idx_transaction_date_amount` on transactions
  - `idx_phone` on users phone numbers
  - `idx_category_transactions` for category-based queries

### Data Types
- Appropriate precision for monetary values (DECIMAL)
- Efficient storage with VARCHAR length limits
- ENUM types for constrained values
- Timestamp fields for audit trails

## Security Features

### Data Integrity
- Foreign key constraints prevent orphaned records
- Check constraints validate business rules
- Unique constraints prevent data duplication
- NOT NULL constraints ensure required data

### Audit Trail
- Created/updated timestamps on all tables
- System logs track all operations
- Transaction logs provide detailed audit trails
- Status tracking for transaction states

## JSON Data Modeling

The system provides JSON representations for:
- Individual entities (users, transactions, categories)
- Complex nested objects with relationships
- API response formats
- Complete transaction records with all related data

### Key JSON Features
- Proper nesting for related data
- Consistent data types and structures
- API-ready response formats
- Comprehensive transaction representations

## Sample Queries

The database supports various analytical queries:
- User transaction history
- Transaction summaries by category
- High-volume user identification
- System performance monitoring

## File Structure
```
/docs/               # ERD diagrams and documentation
/database/           # SQL setup scripts
/examples/           # JSON schemas and examples
README.md           # This documentation
```

## Future Enhancements
- Additional transaction types
- Enhanced fraud detection
- Real-time analytics
- Mobile app integration
- Advanced reporting features

## Technology Stack
- **Database**: MySQL 8.0+
- **Documentation**: Markdown
- **Version Control**: Git
- **Diagramming**: Draw.io/Lucidchart compatible

---
*This database design supports scalable mobile money transaction processing with comprehensive audit trails and performance optimization.*
