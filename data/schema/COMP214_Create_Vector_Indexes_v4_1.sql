-- COMP214 Online Bookstore - HNSW vector indexes, Oracle Database 23ai+
-- Execute separately AFTER actual 384-dimensional FLOAT32 embeddings are populated.
-- Requires Oracle AI Vector Search HNSW availability and sufficient vector-memory capacity.
-- Keep metric COSINE consistent with semantic search queries.
-- Do not run twice unless existing indexes are dropped.

CREATE VECTOR INDEX idx_books_description_hnsw
ON books (description_embedding)
ORGANIZATION INMEMORY NEIGHBOR GRAPH
DISTANCE COSINE
WITH TARGET ACCURACY 90;

CREATE VECTOR INDEX idx_reviews_review_hnsw
ON reviews (review_embedding)
ORGANIZATION INMEMORY NEIGHBOR GRAPH
DISTANCE COSINE
WITH TARGET ACCURACY 90;

SELECT index_name, table_name, index_type, status
FROM user_indexes
WHERE index_name IN ('IDX_BOOKS_DESCRIPTION_HNSW', 'IDX_REVIEWS_REVIEW_HNSW')
ORDER BY table_name;
