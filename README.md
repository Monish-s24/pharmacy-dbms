# 💊 Pharmacy Database Management System (DBMS)

A standalone Oracle SQL & PL/SQL based database system for managing pharmacy inventory, customers, and sales transactions. This project demonstrates core database principles without a front-end, focusing on robust backend logic.

## 🗃️ Database Schema

The system consists of four main tables:
- **Medicines** (`medicine_id`, name, price, stock_quantity)
- **Customers** (`customer_id`, name, phone)
- **Sales** (`sale_id`, customer_id, sale_date, total_amount)
- **Sale_Details** (`sale_id`, `medicine_id`, quantity, price_sold) - Junction table.

## ⚙️ Features

- **CRUD Operations:** Manage medicines and customers.
- **Process Sales:** Execute complex sales transactions while checking stock levels.
- **Inventory Management:** Automatic stock updates upon sale.
- **Data Integrity:** Enforced through primary keys, foreign keys, and `CHECK` constraints.

## 🚀 Getting Started

### Prerequisites
- Oracle Database 11g/12c/19c/21c or Oracle XE
- SQL*Plus or any SQL client (SQL Developer, TOAD)

### Installation & Setup
1.  Clone this repository:
    ```bash
    git clone https://github.com/your-username/pharmacy-dbms.git
    ```
2.  Connect to your Oracle database using SQL*Plus:
    ```bash
    sqlplus username/password@service_name
    ```
3.  Run the main schema script to create tables, sequences, and procedures:
    ```sql
    @database/schema.sql
    ```

## 📖 Usage

### Adding a New Medicine
```sql
EXEC add_medicine('Vitamin C', 12.00, 50);
```

### Processing a Sale
Sell 5 units of medicine ID 1 to customer ID 1:
```sql
EXEC process_sale(1, 1, 5);
```

### Checking Inventory
```sql
SELECT * FROM medicines;
```

## 🔧 Key Procedures

- `add_medicine(p_name, p_price, p_quantity)`: Adds a new medicine or restocks an existing one.
- `process_sale(p_customer_id, p_medicine_id, p_quantity)`: **The core function.** Processes a sale, updates inventory, and maintains transactional integrity.

## 🧠 Technical Highlights

- **PL/SQL Programming:** Business logic is encapsulated within stored procedures.
- **Transaction Management:** Uses `COMMIT` and `ROLLBACK` to ensure data consistency (e.g., prevents sales if stock is insufficient).
- **Constraint Enforcement:** Uses `PRIMARY KEY`, `FOREIGN KEY`, and `CHECK` constraints to validate data at the database level.

## 📄 License

This project is licensed under the MIT License.
