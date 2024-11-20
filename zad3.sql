DROP TABLE RESERVATION_ATTEMPTS;
DROP TABLE CONCERT_RESERVATIONS;
/

CREATE TABLE RESERVATION_ATTEMPTS (
    attempt_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pesel VARCHAR2(11) NOT NULL,
    reservation_status NUMBER(1) NOT NULL, -- 0 = SUCCESS, 1 = ABOVE LIMIT, 2 = FAILED
    attempt_time TIMESTAMP DEFAULT SYSTIMESTAMP,
    reservation_id NUMBER, -- Ma wartość tylko jeśli rezerwacja się powiodła, inaczej NULL
    UNIQUE (pesel, attempt_time) -- Tylko jedna próba rezerwacji w danym czasie możliwa
);
/

CREATE TABLE CONCERT_RESERVATIONS (
    reservation_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pesel VARCHAR2(11) NOT NULL UNIQUE,
    reservation_time TIMESTAMP DEFAULT SYSTIMESTAMP
);
/

CREATE OR REPLACE PROCEDURE RESERVE_TICKET (
    in_pesel IN VARCHAR2,
    io_status OUT NUMBER,
    io_idr OUT NUMBER
) IS
    l_reservation_count NUMBER;
    l_reservation_id NUMBER;
    l_status NUMBER := 0;
    PRAGMA AUTONOMOUS_TRANSACTION;

    -- Logowanie próby rezerwacji w 'autonomous transaction'
    PROCEDURE log_attempt(in_pesel VARCHAR2, io_status NUMBER, p_reservation_id NUMBER) IS
    BEGIN
        INSERT INTO RESERVATION_ATTEMPTS (pesel, reservation_status, reservation_id)
        VALUES (in_pesel, io_status, p_reservation_id);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK; -- rollback w przypadku błędu
    END log_attempt;

BEGIN
    -- Sprawdzenie liczby rezerwacji
    SELECT COUNT(*) INTO l_reservation_count FROM CONCERT_RESERVATIONS;

    IF l_reservation_count >= 50000 THEN
        -- Osiągnięto limit rezerwacji
        io_idr := NULL;
        log_attempt(in_pesel, 1, NULL); --  ABOVE LIMIT
        RETURN;
    END IF;

    -- Próba rezerwacji biletu dla danego numeru PESEL
    BEGIN
        INSERT INTO CONCERT_RESERVATIONS (pesel) VALUES (in_pesel)
        RETURNING reservation_id INTO l_reservation_id;
        
        io_idr := l_reservation_id;
        log_attempt(in_pesel, 0, l_reservation_id); -- SUCCESS
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            -- Inna sesja rezerwuje już bilet dla tego numeru PESEL
            io_idr := NULL;
            log_attempt(in_pesel, 2, NULL); -- FAILED
        WHEN OTHERS THEN
            -- Inny błąd
            io_idr := NULL;
            log_attempt(in_pesel, 2, NULL); -- FAILED
            RAISE;
    END;

    COMMIT; -- Zatwierdź rezerwację jeśli rezerwacja się powiodła
END RESERVE_TICKET;
/


DECLARE
    v_pesel VARCHAR2(11);
    v_status NUMBER;
    v_idr NUMBER;
BEGIN
    FOR i IN 1..50 LOOP
        v_pesel := '980123456' || TO_CHAR(i, 'FM00');
        RESERVE_TICKET(v_pesel, v_status, v_idr);
        DBMS_OUTPUT.PUT_LINE('PESEL: ' || v_pesel || ', Status: ' || v_status || ', Reservation ID: ' || v_idr);
    END LOOP;
END;

SELECT * FROM RESERVATION_ATTEMPTS;
SELECT * FROM CONCERT_RESERVATIONS;