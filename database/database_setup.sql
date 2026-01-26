-- ============================================================================
-- MoMo SMS Data Processing System - Database Setup Script
-- ============================================================================

-- Drop existing database if it exists (for clean setup)
DROP DATABASE IF EXISTS momo_sms_db;

-- Create new database
CREATE DATABASE momo_sms_db;
USE momo_sms_db;

-- ============================================================================
-- TABLE: TRANSACTION_CATEGORIES
-- Description: Stores different types of mobile money transaction categories
-- ============================================================================
CREATE TABLE transaction_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for transaction category',
    category_name VARCHAR(50) NOT NULL UNIQUE COMMENT 'Name of the transaction category',
    category_code VARCHAR(10) NOT NULL UNIQUE COMMENT 'Short code for the category',
    description TEXT COMMENT 'Detailed description of the category',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    
    -- Constraints
    CONSTRAINT chk_category_name_not_empty CHECK (LENGTH(TRIM(category_name)) > 0),
    CONSTRAINT chk_category_code_not_empty CHECK (LENGTH(TRIM(category_code)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Transaction category lookup table';

-- Index for performance
CREATE INDEX idx_category_code ON transaction_categories(category_code);

-- ============================================================================
-- TABLE: USERS
-- Description: Stores customer/user information for mobile money accounts
-- ============================================================================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for user',
    phone_number VARCHAR(15) NOT NULL UNIQUE COMMENT 'User phone number (unique identifier)',
    full_name VARCHAR(100) NOT NULL COMMENT 'Full name of the user',
    account_number VARCHAR(20) UNIQUE COMMENT 'Mobile money account number',
    balance DECIMAL(15, 2) DEFAULT 0.00 COMMENT 'Current account balance',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active' COMMENT 'Account status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Account creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    
    -- Constraints
    CONSTRAINT chk_balance_non_negative CHECK (balance >= 0),
    CONSTRAINT chk_phone_format CHECK (phone_number REGEXP '^[0-9]{10,15}$'),
    CONSTRAINT chk_full_name_not_empty CHECK (LENGTH(TRIM(full_name)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User/Customer account information';

-- Indexes for performance
CREATE INDEX idx_phone_number ON users(phone_number);
CREATE INDEX idx_account_number ON users(account_number);
CREATE INDEX idx_status ON users(status);

-- ============================================================================
-- TABLE: TRANSACTIONS
-- Description: Main transaction records for all mobile money operations
-- ============================================================================
CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for transaction',
    tx_id VARCHAR(50) NOT NULL UNIQUE COMMENT 'External transaction ID from SMS',
    sender_id INT COMMENT 'Foreign key to users table (sender)',
    receiver_id INT COMMENT 'Foreign key to users table (receiver)',
    category_id INT NOT NULL COMMENT 'Foreign key to transaction_categories',
    amount DECIMAL(15, 2) NOT NULL COMMENT 'Transaction amount',
    fee DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Transaction fee charged',
    balance_after DECIMAL(15, 2) COMMENT 'Balance after transaction',
    transaction_date DATETIME NOT NULL COMMENT 'Date and time of transaction',
    status ENUM('completed', 'pending', 'failed', 'cancelled') DEFAULT 'pending' COMMENT 'Transaction status',
    message_body TEXT COMMENT 'Original SMS message body',
    service_center VARCHAR(20) COMMENT 'SMS service center number',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    
    -- Foreign Keys
    CONSTRAINT fk_sender FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_receiver FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES transaction_categories(category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_fee_non_negative CHECK (fee >= 0),
    CONSTRAINT chk_tx_id_not_empty CHECK (LENGTH(TRIM(tx_id)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Main transaction records';

-- Indexes for performance
CREATE INDEX idx_tx_id ON transactions(tx_id);
CREATE INDEX idx_sender_id ON transactions(sender_id);
CREATE INDEX idx_receiver_id ON transactions(receiver_id);
CREATE INDEX idx_category_id ON transactions(category_id);
CREATE INDEX idx_transaction_date ON transactions(transaction_date);
CREATE INDEX idx_status ON transactions(status);
CREATE INDEX idx_created_at ON transactions(created_at);
-- Composite index for common queries
CREATE INDEX idx_sender_date ON transactions(sender_id, transaction_date);
CREATE INDEX idx_receiver_date ON transactions(receiver_id, transaction_date);

-- ============================================================================
-- TABLE: SYSTEM_LOGS
-- Description: System logs for tracking events and debugging
-- ============================================================================
CREATE TABLE system_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for log entry',
    log_level ENUM('INFO', 'WARNING', 'ERROR', 'DEBUG') NOT NULL COMMENT 'Log severity level',
    message TEXT NOT NULL COMMENT 'Log message content',
    module VARCHAR(50) NOT NULL COMMENT 'Module/component that generated the log',
    user_id INT COMMENT 'Related user ID (if applicable)',
    transaction_id INT COMMENT 'Related transaction ID (if applicable)',
    ip_address VARCHAR(45) COMMENT 'IP address (supports IPv4 and IPv6)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Log creation timestamp',
    
    -- Foreign Keys
    CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_log_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_message_not_empty CHECK (LENGTH(TRIM(message)) > 0),
    CONSTRAINT chk_module_not_empty CHECK (LENGTH(TRIM(module)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='System event logs';

-- Indexes for performance
CREATE INDEX idx_log_level ON system_logs(log_level);
CREATE INDEX idx_module ON system_logs(module);
CREATE INDEX idx_user_id ON system_logs(user_id);
CREATE INDEX idx_transaction_id ON system_logs(transaction_id);
CREATE INDEX idx_created_at ON system_logs(created_at);
-- Composite index for common queries
CREATE INDEX idx_level_created ON system_logs(log_level, created_at);

-- ============================================================================
-- TABLE: TRANSACTION_LOGS (Junction Table)
-- Description: Many-to-many relationship between transactions and logs
-- ============================================================================
CREATE TABLE transaction_logs (
    log_transaction_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for junction record',
    transaction_id INT NOT NULL COMMENT 'Foreign key to transactions',
    log_id INT NOT NULL COMMENT 'Foreign key to system_logs',
    log_type ENUM('PROCESSING', 'VALIDATION', 'NOTIFICATION', 'ERROR', 'AUDIT') NOT NULL COMMENT 'Type of log entry',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    
    -- Foreign Keys
    CONSTRAINT fk_tl_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_tl_log FOREIGN KEY (log_id) REFERENCES system_logs(log_id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Unique constraint to prevent duplicate entries
    CONSTRAINT uk_transaction_log UNIQUE (transaction_id, log_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Junction table linking transactions to logs';

-- Indexes for performance
CREATE INDEX idx_tl_transaction_id ON transaction_logs(transaction_id);
CREATE INDEX idx_tl_log_id ON transaction_logs(log_id);
CREATE INDEX idx_log_type ON transaction_logs(log_type);

-- ============================================================================
-- SAMPLE DATA INSERTION
-- ============================================================================

-- Insert Transaction Categories
INSERT INTO transaction_categories (category_name, category_code, description) VALUES
('Payment', 'PAY', 'General payments to merchants or individuals'),
('Bank Deposit', 'DEP', 'Deposits from bank accounts to mobile money'),
('Money Transfer', 'TRF', 'Person-to-person money transfers'),
('Airtime Purchase', 'AIR', 'Mobile airtime top-up purchases'),
('Merchant Payment', 'MER', 'Payments to registered merchants'),
('Bill Payment', 'BILL', 'Utility and service bill payments'),
('Cash Withdrawal', 'WITH', 'Cash withdrawal at agents');

-- Insert Users
INSERT INTO users (phone_number, full_name, account_number, balance, status) VALUES
('250791666666', 'Samuel Carter', '36521838', 25000.00, 'active'),
('250790777777', 'Jane Smith', '95464', 15000.00, 'active'),
('250788555555', 'John Doe', '12345', 50000.00, 'active'),
('250789444444', 'Alice Johnson', '67890', 30000.00, 'active'),
('250787333333', 'Bob Wilson', '11111', 20000.00, 'active'),
('250786222222', 'Carol Brown', '22222', 45000.00, 'active');

-- Insert Transactions
INSERT INTO transactions (tx_id, sender_id, receiver_id, category_id, amount, fee, balance_after, transaction_date, status, message_body, service_center) VALUES
('51732411227', 1, 2, 1, 600.00, 0.00, 24400.00, '2024-05-10 21:32:32', 'completed', 'Your payment of 600 RWF to Jane Smith 95464 has been completed', '+250788110381'),
('BANK_DEP_001', NULL, 1, 2, 40000.00, 0.00, 64400.00, '2024-05-11 18:43:49', 'completed', 'A bank deposit of 40000 RWF has been added to your mobile money account', '+250788110381'),
('13913173274', 1, NULL, 4, 2000.00, 0.00, 62400.00, '2024-05-12 11:41:28', 'completed', 'Your payment of 2000 RWF to Airtime with token has been completed', '+250788110381'),
('TRF_165_001', 1, 2, 3, 10000.00, 100.00, 52300.00, '2024-05-11 20:34:47', 'completed', '10000 RWF transferred to Jane Smith from 36521838', '+250788110381'),
('45434420466', 1, 2, 5, 10900.00, 0.00, 41400.00, '2024-05-12 13:26:13', 'completed', 'Your payment of 10,900 RWF to Jane Smith 59543 has been completed', '+250788110381'),
('TRF_002', 3, 4, 3, 5000.00, 50.00, 44950.00, '2024-05-13 09:15:22', 'completed', 'Transfer of 5000 RWF to Alice Johnson completed', '+250788110381'),
('BILL_001', 5, NULL, 6, 15000.00, 0.00, 5000.00, '2024-05-13 14:22:11', 'completed', 'Bill payment of 15000 RWF completed', '+250788110381');

-- Insert System Logs
INSERT INTO system_logs (log_level, message, module, user_id, transaction_id) VALUES
('INFO', 'Transaction processed successfully', 'TRANSACTION_PROCESSOR', 1, 1),
('INFO', 'SMS notification sent', 'NOTIFICATION_SERVICE', 1, 1),
('INFO', 'Bank deposit validated', 'VALIDATION_SERVICE', 1, 2),
('INFO', 'Transaction completed', 'TRANSACTION_PROCESSOR', 1, 2),
('WARNING', 'Low balance warning triggered', 'BALANCE_MONITOR', 5, 7),
('INFO', 'Airtime purchase processed', 'AIRTIME_SERVICE', 1, 3),
('ERROR', 'Network timeout during notification', 'NOTIFICATION_SERVICE', 3, 6),
('INFO', 'Transfer authorized', 'AUTHORIZATION_SERVICE', 1, 4),
('DEBUG', 'Database connection established', 'DATABASE_SERVICE', NULL, NULL),
('INFO', 'User login successful', 'AUTH_SERVICE', 2, NULL);

-- Insert Transaction Logs (Junction Table)
INSERT INTO transaction_logs (transaction_id, log_id, log_type) VALUES
(1, 1, 'PROCESSING'),
(1, 2, 'NOTIFICATION'),
(2, 3, 'VALIDATION'),
(2, 4, 'PROCESSING'),
(7, 5, 'AUDIT'),
(3, 6, 'PROCESSING'),
(6, 7, 'ERROR'),
(4, 8, 'VALIDATION');

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify table creation
SELECT 'Database Tables Created Successfully' AS Status;
SHOW TABLES;

-- Verify data insertion
SELECT 'Transaction Categories Count:' AS Info, COUNT(*) AS Total FROM transaction_categories;
SELECT 'Users Count:' AS Info, COUNT(*) AS Total FROM users;
SELECT 'Transactions Count:' AS Info, COUNT(*) AS Total FROM transactions;
SELECT 'System Logs Count:' AS Info, COUNT(*) AS Total FROM system_logs;
SELECT 'Transaction Logs Count:' AS Info, COUNT(*) AS Total FROM transaction_logs;

