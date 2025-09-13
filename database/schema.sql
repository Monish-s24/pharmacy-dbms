-- Start fresh
PROMPT Dropping old tables...
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE sale_details CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE sales CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE medicines CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE customers CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN -- ORA-00942: table or view does not exist
            RAISE;
        END IF;
END;
/

PROMPT Creating tables...

-- Table 1: Medicines
CREATE TABLE medicines (
    medicine_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(100) NOT NULL UNIQUE,
    price NUMBER(10, 2) NOT NULL CHECK (price >= 0),
    stock_quantity NUMBER NOT NULL CHECK (stock_quantity >= 0)
);

-- Table 2: Customers
CREATE TABLE customers (
    customer_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    phone VARCHAR2(15)
);

-- Table 3: Sales (Parent table for a transaction)
CREATE TABLE sales (
    sale_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    sale_date DATE DEFAULT SYSDATE,
    total_amount NUMBER(10, 2) NOT NULL CHECK (total_amount >= 0),
    CONSTRAINT fk_sale_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

-- Table 4: Sale_Details (What was in each sale)
CREATE TABLE sale_details (
    sale_id NUMBER NOT NULL,
    medicine_id NUMBER NOT NULL,
    quantity NUMBER NOT NULL CHECK (quantity > 0),
    price_sold NUMBER(10, 2) NOT NULL CHECK (price_sold >= 0),
    CONSTRAINT pk_sale_details PRIMARY KEY (sale_id, medicine_id),
    CONSTRAINT fk_detail_sale
        FOREIGN KEY (sale_id)
        REFERENCES sales(sale_id) ON DELETE CASCADE,
    CONSTRAINT fk_detail_medicine
        FOREIGN KEY (medicine_id)
        REFERENCES medicines(medicine_id)
);

PROMPT Inserting sample data...

-- Add some sample medicines
INSERT INTO medicines (name, price, stock_quantity) VALUES ('Paracetamol', 5.50, 100);
INSERT INTO medicines (name, price, stock_quantity) VALUES ('Ibuprofen', 8.25, 75);
INSERT INTO medicines (name, price, stock_quantity) VALUES ('Amoxicillin', 22.90, 30);

-- Add a sample customer
INSERT INTO customers (name, phone) VALUES ('John Doe', '555-1234');

COMMIT;
PROMPT Sample data inserted!

PROMPT Creating PL/SQL procedures...

-- Procedure 1: Add or Restock Medicine
CREATE OR REPLACE PROCEDURE add_medicine (
    p_name IN medicines.name%TYPE,
    p_price IN medicines.price%TYPE,
    p_quantity IN medicines.stock_quantity%TYPE
)
IS
BEGIN
    -- Try to update stock if medicine exists
    UPDATE medicines
    SET stock_quantity = stock_quantity + p_quantity
    WHERE name = p_name;

    -- If no row was updated, insert a new medicine
    IF SQL%NOTFOUND THEN
        INSERT INTO medicines (name, price, stock_quantity)
        VALUES (p_name, p_price, p_quantity);
        DBMS_OUTPUT.PUT_LINE('New medicine added: ' || p_name);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Stock updated for: ' || p_name);
    END IF;
    COMMIT;
END add_medicine;
/

-- Procedure 2: The Core Logic - Process a Sale
CREATE OR REPLACE PROCEDURE process_sale (
    p_customer_id IN sales.customer_id%TYPE,
    p_medicine_id IN sale_details.medicine_id%TYPE,
    p_quantity IN sale_details.quantity%TYPE
)
IS
    v_medicine_price medicines.price%TYPE;
    v_current_stock medicines.stock_quantity%TYPE;
    v_total_amount sales.total_amount%TYPE;
    v_sale_id sales.sale_id%TYPE;
BEGIN
    -- 1. Check stock and get price
    SELECT price, stock_quantity INTO v_medicine_price, v_current_stock
    FROM medicines WHERE medicine_id = p_medicine_id FOR UPDATE; -- Locks the row

    IF v_current_stock < p_quantity THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient stock for medicine ID: ' || p_medicine_id);
    END IF;

    -- 2. Calculate the total for this item
    v_total_amount := v_medicine_price * p_quantity;

    -- 3. Create the sale record
    INSERT INTO sales (customer_id, total_amount)
    VALUES (p_customer_id, v_total_amount)
    RETURNING sale_id INTO v_sale_id; -- Get the auto-generated ID

    -- 4. Create the sale detail record
    INSERT INTO sale_details (sale_id, medicine_id, quantity, price_sold)
    VALUES (v_sale_id, p_medicine_id, p_quantity, v_medicine_price);

    -- 5. Update the stock
    UPDATE medicines
    SET stock_quantity = stock_quantity - p_quantity
    WHERE medicine_id = p_medicine_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Sale ' || v_sale_id || ' processed successfully. Total: $' || v_total_amount);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Medicine not found!');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END process_sale;
/

-- Enable output to see messages from DBMS_OUTPUT
SET SERVEROUTPUT ON;

PROMPT All done! Database is ready.
PROMPT
PROMPT Try these commands:
PROMPT 1. EXEC add_medicine('Vitamin C', 12.00, 50);
PROMPT 2. EXEC process_sale(1, 1, 5); -- Sell 5 Paracetamol to customer 1
PROMPT 3. SELECT * FROM medicines;
PROMPT 4. SELECT * FROM sales;
PROMPT 5. SELECT * FROM sale_details;