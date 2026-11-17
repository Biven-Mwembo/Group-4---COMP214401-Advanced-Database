-- ============================================================================
-- COMP214 - Enterprise eCommerce Database Design (Online Bookstore)
-- CONSOLIDATED ORACLE TABLE CREATION SCRIPT - v4.2 (SHIPPED_DATE + REVIEW_ID)
-- Source: COMP214_Project_Report.docx, Section 3.5 Data Dictionary; 
--              revised per professor-approved BOOKS/AUTHORS M:N design
-- Target: Oracle Database 26ai / compatible Autonomous AI Database
-- Revised: 2026-11-17
-- ============================================================================
-- PURPOSE: Create the 12 revised tables, including PK, FK,
--          UNIQUE, NOT NULL, and CHECK constraints.
-- DOES NOT: import CSV data; create PL/SQL packages/triggers; generate embeddings;
--           create sequences or B-tree/HNSW indexes; supply a data-load script.
-- NOTE: Execute while connected as the intended schema owner, preferably on an
--       empty project schema. Running again without dropping tables will error.
--
-- ASSUMPTIONS WHERE THE DDD IS INCOMPLETE:
--  1. CUSTOMERS address, city, province = VARCHAR2(200), VARCHAR2(100),
--     VARCHAR2(100) respectively; DDD did not specify lengths.
--  2. BOOKS.created_at/updated_at are DATE, nullable, per data dictionary.
--  3. RETURNS.quantity is nullable because DDD labels CHECK > 0 but not NOT NULL.
--     Return reason is constrained to the six DDD labels.
--  4. Unit_price is constrained > 0 (DDD calls it mandatory; business rule
--     inferred). Remove CHECK if your team requires zero-priced promotional items.
--  5. EMBEDDING_LOG supports either a BOOKS or REVIEWS source using exactly
--     one populated foreign key (BOOK_ID XOR REVIEW_ID).
--  6. Sequence naming follows SEQ_<TABLE/ENTITY>_ID. The master seed script
--     creates/synchronizes sequences and configures PK defaults after loading.
--     No automatic key generation is set up here: the DDD calls for sequences
--     and a BOOKS insert trigger, to be implemented in separate scripts.
--  7. Actual dataset import may require a source-book-to-book-ID mapping and
--     revisiting ISBN NOT NULL depending on dataset completeness.
--  8. ORDER_STATUS has six named examples; source data must provide >=5 lookup
--     rows. Return status literals are case-sensitive.
--  9. Per professor confirmation, BOOKS and AUTHORS have an M:N relationship.
--     BOOKS.author_id is removed, and BOOK_AUTHORS is the junction table.
-- 10. To preserve the assignment limit of 12 tables, RETURN_REASONS has been
--     removed and RETURNS.return_reason is a required text attribute.
-- 11. Return reasons follow the DDD controlled list; update the ERD,
--     data dictionary, seed CSV, and process_return package interface.
-- 12. ORDERS.shipped_date is nullable until shipment, and must be >= order_date.
-- 13. This script is for a NEW/EMPTY schema. It does not migrate existing
--     tables; if the old schema is present, plan a safe migration separately.
-- ============================================================================

-- 01. LOOKUP: CATEGORIES
CREATE TABLE categories (
    category_id    NUMBER CONSTRAINT pk_categories PRIMARY KEY,
    category_name  VARCHAR2(60) NOT NULL,
    description    VARCHAR2(200),
    CONSTRAINT uq_categories_name UNIQUE (category_name)
);

-- 02. LOOKUP: ORDER_STATUS
CREATE TABLE order_status (
    status_id        NUMBER CONSTRAINT pk_order_status PRIMARY KEY,
    status_name      VARCHAR2(30) NOT NULL,
    status_sequence  NUMBER(2) NOT NULL,
    CONSTRAINT uq_order_status_name UNIQUE (status_name)
);

-- 03. AUTHORS
CREATE TABLE authors (
    author_id   NUMBER CONSTRAINT pk_authors PRIMARY KEY,
    first_name  VARCHAR2(50) NOT NULL,
    last_name   VARCHAR2(50) NOT NULL,
    bio         VARCHAR2(1000),
    country     VARCHAR2(50)
);

-- 04. BOOKS (text + vector)
CREATE TABLE books (
    book_id                 NUMBER CONSTRAINT pk_books PRIMARY KEY,
    isbn                    VARCHAR2(13) NOT NULL,
    title                   VARCHAR2(200) NOT NULL,
    category_id             NUMBER,
    publisher               VARCHAR2(100),
    publish_year            NUMBER(4),
    price                   NUMBER(8,2) NOT NULL,
    stock_qty               NUMBER NOT NULL,
    description             CLOB,
    description_embedding   VECTOR(384, FLOAT32),
    created_at              DATE,
    updated_at              DATE,
    CONSTRAINT uq_books_isbn UNIQUE (isbn),
    CONSTRAINT fk_books_category FOREIGN KEY (category_id) REFERENCES categories(category_id),
    CONSTRAINT ck_books_price CHECK (price > 0),
    CONSTRAINT ck_books_stock CHECK (stock_qty >= 0)
);

-- 05. BOOK_AUTHORS (many-to-many junction table)
-- Each (book_id, author_id) pair must be unique; a book may have several authors.
-- AUTHOR_ORDER = credit position for a given book, unique within that book.
CREATE TABLE book_authors (
    book_id    NUMBER NOT NULL,
    author_id     NUMBER NOT NULL,
    author_order NUMBER(2) NOT NULL,
    CONSTRAINT ck_book_authors_order CHECK (author_order > 0),
    CONSTRAINT uq_book_authors_order UNIQUE (book_id, author_order),
    CONSTRAINT pk_book_authors PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_book_authors_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT fk_book_authors_author FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

-- 06. CUSTOMERS
CREATE TABLE customers (
    customer_id   NUMBER CONSTRAINT pk_customers PRIMARY KEY,
    first_name    VARCHAR2(50) NOT NULL,
    last_name     VARCHAR2(50) NOT NULL,
    email         VARCHAR2(100) NOT NULL,
    phone         VARCHAR2(20),
    address       VARCHAR2(200),
    city          VARCHAR2(100),
    province      VARCHAR2(100),
    postal_code   VARCHAR2(10),
    created_at    DATE,
    CONSTRAINT uq_customers_email UNIQUE (email)
);

-- 07. ORDERS
CREATE TABLE orders (
    order_id           NUMBER CONSTRAINT pk_orders PRIMARY KEY,
    customer_id        NUMBER NOT NULL,
    status_id          NUMBER NOT NULL,
    order_date         DATE NOT NULL,
    shipped_date       DATE,
    total_amount       NUMBER(10,2),
    shipping_address   VARCHAR2(200),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_orders_status FOREIGN KEY (status_id) REFERENCES order_status(status_id),
    CONSTRAINT ck_orders_total CHECK (total_amount >= 0),
    CONSTRAINT ck_orders_shipped_date CHECK (shipped_date IS NULL OR shipped_date >= order_date)
);

-- 08. ORDER_ITEMS
CREATE TABLE order_items (
    order_item_id  NUMBER CONSTRAINT pk_order_items PRIMARY KEY,
    order_id       NUMBER NOT NULL,
    book_id        NUMBER NOT NULL,
    quantity       NUMBER(3) NOT NULL,
    unit_price     NUMBER(8,2) NOT NULL,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_order_items_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT ck_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT ck_order_items_unit_price CHECK (unit_price > 0)
);

-- 09. RETURNS
CREATE TABLE returns (
    return_id      NUMBER CONSTRAINT pk_returns PRIMARY KEY,
    order_item_id  NUMBER NOT NULL,
    return_reason  VARCHAR2(30) NOT NULL,
    return_date    DATE NOT NULL,
    quantity       NUMBER(3),
    refund_amount  NUMBER(8,2),
    return_status  VARCHAR2(20),
    CONSTRAINT fk_returns_item FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id),
    CONSTRAINT ck_returns_reason CHECK (return_reason IN (
        'Damaged', 'Defective', 'Wrong item', 'Changed mind',
        'Late delivery', 'Other'
    )),
    CONSTRAINT ck_returns_qty CHECK (quantity > 0),
    CONSTRAINT ck_returns_status CHECK (return_status IN ('Requested','Approved','Rejected','Refunded'))
);

-- 10. REVIEWS (text + vector)
CREATE TABLE reviews (
    review_id         NUMBER CONSTRAINT pk_reviews PRIMARY KEY,
    book_id           NUMBER NOT NULL,
    customer_id       NUMBER NOT NULL,
    rating            NUMBER(1),
    review_text       CLOB,
    review_date       DATE,
    review_embedding  VECTOR(384, FLOAT32),
    CONSTRAINT fk_reviews_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT ck_reviews_rating CHECK (rating BETWEEN 1 AND 5)
);

-- 11. PRICE_AUDIT
CREATE TABLE price_audit (
    audit_id    NUMBER CONSTRAINT pk_price_audit PRIMARY KEY,
    book_id     NUMBER NOT NULL,
    old_price   NUMBER(8,2),
    new_price   NUMBER(8,2),
    changed_by  VARCHAR2(50),
    changed_at  TIMESTAMP,
    CONSTRAINT fk_price_audit_book FOREIGN KEY (book_id) REFERENCES books(book_id)
);

-- 12. EMBEDDING_LOG: one source record per event, either BOOKS or REVIEWS
CREATE TABLE embedding_log (
    log_id        NUMBER CONSTRAINT pk_embedding_log PRIMARY KEY,
    book_id       NUMBER,
    review_id     NUMBER,
    source_table  VARCHAR2(30) NOT NULL,
    action        VARCHAR2(30),
    model_name    VARCHAR2(60),
    status        VARCHAR2(20),
    logged_at     TIMESTAMP,
    CONSTRAINT fk_embedding_log_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT fk_embedding_log_review FOREIGN KEY (review_id) REFERENCES reviews(review_id),
    CONSTRAINT ck_embedding_log_source CHECK (
       (source_table = 'BOOKS' AND book_id IS NOT NULL AND review_id IS NULL)
       OR
       (source_table = 'REVIEWS' AND review_id IS NOT NULL AND book_id IS NULL)
    )
);

-- VALIDATION: ensure all 12 tables were created in the current schema.
SELECT table_name
FROM user_tables
WHERE table_name IN (
    'CATEGORIES','ORDER_STATUS','AUTHORS','BOOKS','BOOK_AUTHORS',
    'CUSTOMERS','ORDERS','ORDER_ITEMS','RETURNS','REVIEWS',
    'PRICE_AUDIT','EMBEDDING_LOG'
)
ORDER BY table_name;

SELECT COUNT(*) AS created_table_count
FROM user_tables
WHERE table_name IN (
    'CATEGORIES','ORDER_STATUS','AUTHORS','BOOKS','BOOK_AUTHORS',
    'CUSTOMERS','ORDERS','ORDER_ITEMS','RETURNS','REVIEWS',
    'PRICE_AUDIT','EMBEDDING_LOG'
);
-- Expected: CREATED_TABLE_COUNT = 12 (when run in an empty project schema).
-- IMPORTANT: A foreign key does not, by itself, ensure every BOOKS row has
-- at least one BOOK_AUTHORS row. Validate this after loading the dataset:
SELECT COUNT(*) AS books_without_authors
FROM books b
WHERE NOT EXISTS (
    SELECT 1 FROM book_authors ba WHERE ba.book_id = b.book_id
);
-- Expected: 0 once the author mapping has been loaded.
-- END OF CONSOLIDATED TABLE CREATION SCRIPT.
