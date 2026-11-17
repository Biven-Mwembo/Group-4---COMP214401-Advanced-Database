-- ============================================================================
-- COMP214 Online Bookstore - Private Synonyms for Team Members
-- Owner of shared objects: jdanie48
-- Run as: EACH TEAM MEMBER'S OWN USER (e.g., jdanie48)
-- Do not run as ADMIN
-- Oracle SQL Developer: use F5 (Run Script).
--
-- Creates private synonyms in the currently logged-in user's schema.
-- Synonyms do not grant access; the owner/ADMIN must grant underlying privileges.
-- They normally appear under the Synonyms node, not the user's Tables node.
--
-- Safe to rerun: CREATE OR REPLACE SYNONYM refreshes existing synonyms.
-- This script never creates/drops tables or sequences.
-- ============================================================================

SET SERVEROUTPUT ON

DECLARE
    v_user VARCHAR2(128) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_existing NUMBER;
    PROCEDURE add_synonym(p_name IN VARCHAR2) IS
    BEGIN
        -- Avoid replacing a non-synonym schema object that might use the name.
        SELECT COUNT(*) INTO v_existing
          FROM user_objects
         WHERE object_name = p_name
           AND object_type <> 'SYNONYM';

        IF v_existing > 0 THEN
            DBMS_OUTPUT.PUT_LINE('SKIP: ' || p_name || ' (another object already uses this name)');
        ELSE
            EXECUTE IMMEDIATE
                'CREATE OR REPLACE SYNONYM ' || p_name || ' FOR JUNXD11.' || p_name;
            DBMS_OUTPUT.PUT_LINE('OK: ' || p_name || ' -> JUNXD11.' || p_name);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: ' || p_name || ': ' || SQLERRM);
            RAISE;
    END;
BEGIN
    IF v_user IN ('ADMIN', 'JUNXD11') THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Connect as your own TEAM MEMBER account, not ' || v_user || '.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Creating private synonyms for ' || v_user);

    -- 12 tables
    add_synonym('CATEGORIES');
    add_synonym('ORDER_STATUS');
    add_synonym('AUTHORS');
    add_synonym('BOOKS');
    add_synonym('BOOK_AUTHORS');
    add_synonym('CUSTOMERS');
    add_synonym('ORDERS');
    add_synonym('ORDER_ITEMS');
    add_synonym('RETURNS');
    add_synonym('REVIEWS');
    add_synonym('PRICE_AUDIT');
    add_synonym('EMBEDDING_LOG');

    -- 11 sequences: enables SEQ_BOOK_ID.NEXTVAL etc., if SELECT is granted.
    add_synonym('SEQ_CATEGORY_ID');
    add_synonym('SEQ_ORDER_STATUS_ID');
    add_synonym('SEQ_AUTHOR_ID');
    add_synonym('SEQ_BOOK_ID');
    add_synonym('SEQ_CUSTOMER_ID');
    add_synonym('SEQ_ORDER_ID');
    add_synonym('SEQ_ORDER_ITEM_ID');
    add_synonym('SEQ_RETURN_ID');
    add_synonym('SEQ_REVIEW_ID');
    add_synonym('SEQ_PRICE_AUDIT_ID');
    add_synonym('SEQ_EMBEDDING_LOG_ID');

    DBMS_OUTPUT.PUT_LINE('Completed. Review output and verification query below.');
END;
/

PROMPT === Current user and current schema ===
SELECT USER AS connected_user,
       SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema
FROM dual;

PROMPT === Synonyms in your own schema pointing to JUNXD11 ===
SELECT synonym_name, table_owner, table_name
FROM user_synonyms
WHERE table_owner = 'JUNXD11'
ORDER BY synonym_name;

PROMPT === Quick access test (works if SELECT was granted) ===
SELECT COUNT(*) AS book_count FROM books;

-- To remove one synonym if necessary:
-- DROP SYNONYM BOOKS;
-- Note: a synonym does NOT give you ownership of the shared table.
