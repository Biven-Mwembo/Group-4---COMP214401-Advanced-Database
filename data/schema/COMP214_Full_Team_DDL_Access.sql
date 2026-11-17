-- COMP214: Broad development access for two teammates
-- RUN AS: ADMIN in the SAME Autonomous AI Database where jdanie48 owns the project.
-- REPLACE MEMBER2 and MEMBER3 with the ACTUAL existing database usernames.
-- IMPORTANT: ANY system privileges below apply to OTHER NON-SYSTEM SCHEMAS,
-- not just jdanie48. Grant ONLY to trusted teammates in a class-only database.
-- This is NOT a grant of SYSDBA, database ownership, or OCI console access.
-- Back up the jdanie48 schema before running this script.

SET DEFINE OFF
SET SERVEROUTPUT ON

-- 1. Logon and ability to create objects in each user's own schema.
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE
TO nmwembo1, ljacks47;

-- 2. Database-wide cross-schema DDL privileges.
-- These permit qualified operations such as DROP TABLE jdanie48.BOOKS.
GRANT CREATE ANY TABLE, ALTER ANY TABLE, DROP ANY TABLE,
      CREATE ANY INDEX, ALTER ANY INDEX, DROP ANY INDEX,
      CREATE ANY VIEW, DROP ANY VIEW,
      CREATE ANY SEQUENCE, ALTER ANY SEQUENCE, DROP ANY SEQUENCE,
      CREATE ANY PROCEDURE, ALTER ANY PROCEDURE, DROP ANY PROCEDURE,
      CREATE ANY TRIGGER, ALTER ANY TRIGGER, DROP ANY TRIGGER,
      CREATE ANY TYPE, ALTER ANY TYPE, DROP ANY TYPE
TO nmwembo1, ljacks47;

-- 3. Give full DML access to the *existing and currently present* jdanie48 tables,
-- and read/execute rights for existing views, sequences, PL/SQL, types.
-- New objects created later need additional grants (or suitable system privileges).
-- ADMIN requires GRANT ANY OBJECT PRIVILEGE (normally available in Autonomous).
BEGIN
  FOR obj IN (
    SELECT object_name, object_type
    FROM dba_objects
    WHERE owner = 'JDANIE48'
      AND object_type IN ('TABLE','VIEW','SEQUENCE','PROCEDURE','FUNCTION','PACKAGE','TYPE')
      AND object_name NOT LIKE 'BIN$%'
    ORDER BY object_type, object_name
  ) LOOP
    FOR teammate IN (SELECT 'nmwembo1' AS username FROM dual
                    UNION ALL SELECT 'ljacks47' FROM dual) LOOP
      DECLARE
        l_priv VARCHAR2(100);
        l_stmt VARCHAR2(1000);
      BEGIN
        l_priv := CASE
          WHEN obj.object_type = 'TABLE' THEN 'SELECT, INSERT, UPDATE, DELETE, ALTER, REFERENCES'
          WHEN obj.object_type IN ('VIEW','SEQUENCE') THEN 'SELECT'
          ELSE 'EXECUTE'
        END;
        l_stmt := 'GRANT ' || l_priv || ' ON JDANIE48."' || obj.object_name || '" TO ' || teammate.username;
        EXECUTE IMMEDIATE l_stmt;
        DBMS_OUTPUT.PUT_LINE('OK: ' || l_stmt);
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('FAILED: ' || l_stmt || ' -> ' || SQLERRM);
          RAISE;
      END;
    END LOOP;
  END LOOP;
END;
/

-- 4. Verify system privileges (run as ADMIN):
SELECT grantee, privilege
FROM dba_sys_privs
WHERE grantee IN ('nmwembo1','ljacks47')
  AND (privilege LIKE '%ANY TABLE%'
    OR privilege LIKE '%ANY SEQUENCE%'
    OR privilege LIKE '%ANY PROCEDURE%'
    OR privilege LIKE '%ANY TRIGGER%'
    OR privilege LIKE '%ANY INDEX%')
ORDER BY grantee, privilege;


