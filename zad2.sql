DROP TABLE TMP_FACT_HISTORY_COMPARE_DIFF;
/
DROP TABLE TMP_FACT_HISTORY_COMPARE_STATUS;
/
DROP TABLE FACT_HISTORY;
/

CREATE TABLE TMP_FACT_HISTORY_COMPARE_DIFF (
    ID_FACT NUMBER,
    COL_NAME VARCHAR2(255),
    COL_TYPE VARCHAR2(50),
    COL_OLD_VALUE VARCHAR2(4000),
    COL_NEW_VALUE VARCHAR2(4000)
);
/
CREATE TABLE TMP_FACT_HISTORY_COMPARE_STATUS (
    ID_FACT NUMBER,
    STATUS NUMBER
);
/
CREATE TABLE FACT_HISTORY (
    ID_PACK INTEGER,
    ID_FACT NUMBER,
    COLUMN1 VARCHAR2(100),
    COLUMN2 DATE,
    COLUMN3 NUMBER,
    PRIMARY KEY (ID_PACK, ID_FACT)
);
/

-- Paczka 1
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (1, 101, 'ABC', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 100);
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (1, 102, 'DEF', TO_DATE('2023-01-02', 'YYYY-MM-DD'), 200);
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (1, 103, 'GHI', TO_DATE('2023-01-03', 'YYYY-MM-DD'), 300);
/

-- Paczka 2 (z modyfikacjami i nowymi rekordami)
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (2, 101, 'ABC', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 100);
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (2, 102, 'XYZ', TO_DATE('2023-01-02', 'YYYY-MM-DD'), 200);
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (2, 104, 'JKL', TO_DATE('2023-01-04', 'YYYY-MM-DD'), 400);
/

CREATE OR REPLACE PACKAGE FACT_HISTORY_PKG AS
    PROCEDURE COMPARE_FACT(ID_PACK_OLD IN INTEGER, ID_PACK_NEW IN INTEGER, BUILD_DIFF IN BOOLEAN DEFAULT FALSE);
END FACT_HISTORY_PKG;
/

CREATE OR REPLACE PACKAGE BODY FACT_HISTORY_PKG AS

    PROCEDURE COMPARE_FACT(ID_PACK_OLD IN INTEGER, ID_PACK_NEW IN INTEGER, BUILD_DIFF IN BOOLEAN DEFAULT FALSE) IS
        CURSOR old_version IS
            SELECT ID_FACT, COLUMN1, COLUMN2, COLUMN3
            FROM FACT_HISTORY
            WHERE ID_PACK = ID_PACK_OLD;

        CURSOR new_version IS
            SELECT ID_FACT, COLUMN1, COLUMN2, COLUMN3
            FROM FACT_HISTORY
            WHERE ID_PACK = ID_PACK_NEW;

        TYPE record_type IS RECORD (
            ID_FACT NUMBER,
            COLUMN1 VARCHAR2(100),
            COLUMN2 DATE,
            COLUMN3 NUMBER
        );

        old_row record_type;
        new_row record_type;

        -- Zmienne do przechowywania statusów
        v_status NUMBER;

        -- Formatowanie wartości na VARCHAR2
        FUNCTION Format_Value(val IN VARCHAR2) RETURN VARCHAR2 IS
        BEGIN
            RETURN val;
        END;

    BEGIN
        -- Opróżniamy tabele tymczasowe przed porównaniem
        DELETE FROM TMP_FACT_HISTORY_COMPARE_STATUS;
        DELETE FROM TMP_FACT_HISTORY_COMPARE_DIFF;

        -- Porównanie danych w starej paczce
        FOR old_row IN old_version LOOP
            BEGIN
                -- Sprawdzamy, czy rekord istnieje w nowej paczce
                SELECT COLUMN1, COLUMN2, COLUMN3
                INTO new_row.COLUMN1, new_row.COLUMN2, new_row.COLUMN3
                FROM FACT_HISTORY
                WHERE ID_FACT = old_row.ID_FACT AND ID_PACK = ID_PACK_NEW;
                
                -- Sprawdzamy, czy rekord został zmodyfikowany
                IF old_row.COLUMN1 != new_row.COLUMN1
                   OR old_row.COLUMN2 != new_row.COLUMN2
                   OR old_row.COLUMN3 != new_row.COLUMN3 THEN
                    -- Rekord zmodyfikowany, zapisujemy status
                    INSERT INTO TMP_FACT_HISTORY_COMPARE_STATUS (ID_FACT, STATUS)
                    VALUES (old_row.ID_FACT, 1); -- MODIFIED

                    -- Zapisujemy różnice kolumn (jeśli BUILD_DIFF = TRUE)
                    IF BUILD_DIFF THEN
                        IF old_row.COLUMN1 != new_row.COLUMN1 THEN
                            INSERT INTO TMP_FACT_HISTORY_COMPARE_DIFF (ID_FACT, COL_NAME, COL_TYPE, COL_OLD_VALUE, COL_NEW_VALUE)
                            VALUES (old_row.ID_FACT, 'COLUMN1', 'VARCHAR2', old_row.COLUMN1, new_row.COLUMN1);
                        END IF;

                        IF old_row.COLUMN2 != new_row.COLUMN2 THEN
                            INSERT INTO TMP_FACT_HISTORY_COMPARE_DIFF (ID_FACT, COL_NAME, COL_TYPE, COL_OLD_VALUE, COL_NEW_VALUE)
                            VALUES (old_row.ID_FACT, 'COLUMN2', 'DATE', TO_CHAR(old_row.COLUMN2, 'yyyy/mm/dd'), TO_CHAR(new_row.COLUMN2, 'yyyy/mm/dd'));
                        END IF;

                        IF old_row.COLUMN3 != new_row.COLUMN3 THEN
                            INSERT INTO TMP_FACT_HISTORY_COMPARE_DIFF (ID_FACT, COL_NAME, COL_TYPE, COL_OLD_VALUE, COL_NEW_VALUE)
                            VALUES (old_row.ID_FACT, 'COLUMN3', 'NUMBER', TO_CHAR(old_row.COLUMN3), TO_CHAR(new_row.COLUMN3));
                        END IF;
                    END IF;

                END IF;

            EXCEPTION
                -- Jeśli rekord nie istnieje w nowej paczce, oznacza to, że został usunięty
                WHEN NO_DATA_FOUND THEN
                    INSERT INTO TMP_FACT_HISTORY_COMPARE_STATUS (ID_FACT, STATUS)
                    VALUES (old_row.ID_FACT, 3); -- DELETED
            END;
        END LOOP;

        -- Sprawdzanie nowych rekordów w nowej paczce
        FOR new_row IN new_version LOOP
            SELECT COUNT(*)
            INTO v_status
            FROM FACT_HISTORY
            WHERE ID_FACT = new_row.ID_FACT AND ID_PACK = ID_PACK_OLD;

            -- Jeśli rekord nie istnieje w starej paczce, jest nowy
            IF v_status = 0 THEN
                INSERT INTO TMP_FACT_HISTORY_COMPARE_STATUS (ID_FACT, STATUS)
                VALUES (new_row.ID_FACT, 2); -- NEW
            END IF;
        END LOOP;
    END COMPARE_FACT;

END FACT_HISTORY_PKG;
/


BEGIN
    FACT_HISTORY_PKG.COMPARE_FACT(ID_PACK_OLD => 1, ID_PACK_NEW => 2, BUILD_DIFF => TRUE);
END;
/

SELECT * FROM FACT_HISTORY;
/
SELECT * FROM TMP_FACT_HISTORY_COMPARE_DIFF;
/
