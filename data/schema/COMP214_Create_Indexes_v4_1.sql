-- COMP214 Online Bookstore - B-tree indexes for the v4.1 schema
-- Run AFTER COMP214_Create_Tables.sql.
-- Do not run twice unless indexes are dropped; duplicate names yield ORA-00955.
-- Oracle already indexes PK/UNIQUE constraints; avoid redundant indexes.
-- FK index on BOOK_AUTHORS.BOOK_ID is covered by PK(book_id,author_id).
-- The UNIQUE(book_id,author_order) constraint has its own supporting index.

CREATE INDEX idx_books_category ON books (category_id);
CREATE INDEX idx_book_authors_author ON book_authors (author_id);
CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_orders_status ON orders (status_id);
CREATE INDEX idx_order_items_order ON order_items (order_id);
CREATE INDEX idx_order_items_book ON order_items (book_id);
CREATE INDEX idx_returns_order_item ON returns (order_item_id);
CREATE INDEX idx_reviews_book ON reviews (book_id);
CREATE INDEX idx_reviews_customer ON reviews (customer_id);
CREATE INDEX idx_price_audit_book ON price_audit (book_id);
CREATE INDEX idx_embedding_log_book ON embedding_log (book_id);
CREATE INDEX idx_embedding_log_review ON embedding_log (review_id);

-- Verify all new indexes (indexes from PK/UNIQUE constraints are also visible in USER_INDEXES).
SELECT index_name, table_name, index_type, status
FROM user_indexes
WHERE index_name LIKE 'IDX_%'
ORDER BY table_name, index_name;
