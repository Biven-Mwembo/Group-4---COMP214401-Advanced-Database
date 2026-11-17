-- COMP214 Group 4 - RESET PROJECT TABLES AND SEQUENCES
-- WARNING: Permanently removes all data in the 12 listed tables.
-- Run as the schema owner.
-- This script deliberately leaves packages, standalone routines, and unrelated objects unchanged.
-- Re-running is safe if some target tables or sequences do not exist.
SET SERVEROUTPUT ON;

DECLARE
  PROCEDURE drop_if_exists(p_name IN VARCHAR2, p_type IN VARCHAR2) IS
    v_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*) INTO v_count
    FROM USER_OBJECTS
    WHERE OBJECT_NAME = p_name AND OBJECT_TYPE = p_type;
    IF v_count > 0 THEN
      IF p_type = 'TABLE' THEN
        EXECUTE IMMEDIATE 'DROP TABLE ' || p_name || ' CASCADE CONSTRAINTS PURGE';
      ELSE
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || p_name;
      END IF;
      DBMS_OUTPUT.PUT_LINE('Dropped ' || p_type || ': ' || p_name);
    ELSE
      DBMS_OUTPUT.PUT_LINE('Absent, skipped ' || p_type || ': ' || p_name);
    END IF;
  END;
BEGIN
  -- Tables in the order used by the team's original reset file.
  drop_if_exists('BOOK_AUTHORS', 'TABLE');
  drop_if_exists('ORDER_ITEMS', 'TABLE');
  drop_if_exists('RETURNS', 'TABLE');
  drop_if_exists('REVIEWS', 'TABLE');
  drop_if_exists('PRICE_AUDIT', 'TABLE');
  drop_if_exists('EMBEDDING_LOG', 'TABLE');
  drop_if_exists('ORDERS', 'TABLE');
  drop_if_exists('BOOKS', 'TABLE');
  drop_if_exists('AUTHORS', 'TABLE');
  drop_if_exists('CUSTOMERS', 'TABLE');
  drop_if_exists('CATEGORIES', 'TABLE');
  drop_if_exists('ORDER_STATUS', 'TABLE');

  -- Remove only these 11 project sequences; they will be recreated by the master seed.
  drop_if_exists('SEQ_CATEGORY_ID', 'SEQUENCE');
  drop_if_exists('SEQ_ORDER_STATUS_ID', 'SEQUENCE');
  drop_if_exists('SEQ_AUTHOR_ID', 'SEQUENCE');
  drop_if_exists('SEQ_BOOK_ID', 'SEQUENCE');
  drop_if_exists('SEQ_CUSTOMER_ID', 'SEQUENCE');
  drop_if_exists('SEQ_ORDER_ID', 'SEQUENCE');
  drop_if_exists('SEQ_ORDER_ITEM_ID', 'SEQUENCE');
  drop_if_exists('SEQ_RETURN_ID', 'SEQUENCE');
  drop_if_exists('SEQ_REVIEW_ID', 'SEQUENCE');
  drop_if_exists('SEQ_PRICE_AUDIT_ID', 'SEQUENCE');
  drop_if_exists('SEQ_EMBEDDING_LOG_ID', 'SEQUENCE');
END;
/

-- Check that none of the target tables or sequences remain:
SELECT object_type, object_name
FROM user_objects
WHERE (object_type = 'TABLE' AND object_name IN (
  'BOOK_AUTHORS', 'ORDER_ITEMS', 'RETURNS', 'REVIEWS', 'PRICE_AUDIT', 'EMBEDDING_LOG',
  'ORDERS', 'BOOKS', 'AUTHORS', 'CUSTOMERS', 'CATEGORIES', 'ORDER_STATUS'))
   OR (object_type = 'SEQUENCE' AND object_name IN (
  'SEQ_CATEGORY_ID', 'SEQ_ORDER_STATUS_ID', 'SEQ_AUTHOR_ID', 'SEQ_BOOK_ID', 'SEQ_CUSTOMER_ID', 'SEQ_ORDER_ID',
  'SEQ_ORDER_ITEM_ID', 'SEQ_RETURN_ID', 'SEQ_REVIEW_ID', 'SEQ_PRICE_AUDIT_ID', 'SEQ_EMBEDDING_LOG_ID'))
ORDER BY object_type, object_name;

-- Expected: no rows.
-- Next: run COMP214_Create_Tables_v4.sql and then COMP214_Master_Seed_v4_No_Audit_Log_Seeds.sql.
