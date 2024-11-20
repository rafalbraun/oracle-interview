-- Usunięcie tabeli ORDERS
DROP TABLE ORDERS;
/

-- Utworzenie tabeli ORDERS
CREATE TABLE ORDERS (
    ORDER_ID NUMBER PRIMARY KEY,
    CUSTOMER_ID NUMBER,
    ORDER_DATE DATE,
    AMOUNT NUMBER(10, 2)
);
/

-- Wstawianie przykładowych danych do tabeli ORDERS
INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, AMOUNT) VALUES (1, 101, TO_DATE('2023-01-15', 'YYYY-MM-DD'), 150.50);
INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, AMOUNT) VALUES (2, 102, TO_DATE('2023-02-10', 'YYYY-MM-DD'), 200.00);
INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, AMOUNT) VALUES (3, 101, TO_DATE('2023-03-05', 'YYYY-MM-DD'), 75.20);
INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, AMOUNT) VALUES (4, 103, TO_DATE('2023-01-25', 'YYYY-MM-DD'), 300.75);
INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, AMOUNT) VALUES (5, 102, TO_DATE('2023-02-15', 'YYYY-MM-DD'), 400.00);
/

CREATE OR REPLACE PROCEDURE GET_CUSTOMER_ORDER_TOTALS (
    StartDate IN DATE,
    EndDate IN DATE
) 
IS
    CURSOR order_totals_cursor IS
        SELECT CUSTOMER_ID, SUM(AMOUNT) AS Total_Amount
        FROM ORDERS
        WHERE ORDER_DATE BETWEEN StartDate AND EndDate
        GROUP BY CUSTOMER_ID
        ORDER BY Total_Amount DESC;
    
    v_customer_id ORDERS.CUSTOMER_ID%TYPE;
    v_total_amount ORDERS.AMOUNT%TYPE;
BEGIN
    OPEN order_totals_cursor;
    LOOP
        FETCH order_totals_cursor INTO v_customer_id, v_total_amount;
        EXIT WHEN order_totals_cursor%NOTFOUND;

        -- Wypisz wynik
        DBMS_OUTPUT.PUT_LINE('Customer ID: ' || v_customer_id || ', Total Amount: ' || v_total_amount);
    END LOOP;
    CLOSE order_totals_cursor;
END;
/

BEGIN
    -- Wywołanie procedury z przedziałem dat od 2023-01-01 do 2023-02-28
    GET_CUSTOMER_ORDER_TOTALS(
        StartDate => TO_DATE('2023-01-01', 'YYYY-MM-DD'),
        EndDate => TO_DATE('2023-02-28', 'YYYY-MM-DD')
    );
END;
/
