## Zadania Rekrutacyjne - Firma Datafuze

### Zadanie 1

Mamy tabelę FACT_HISTORY która przechowuje wersje danych tabeli FACT taką, że klucz główny PK_FACT_HISTORY (ID_PACK INTEGER, ID_FACT NUMBER) składa się z numeru paczki wersji tj. ID_PACK oraz klucza głównego tabeli źródłowej tj. ID_FACT zaś tabela zawiera oprócz kolumn klucza PK_FACT_HISTORY, kolumny danych (np. po 10 VARCHAR2, DATE, NUMBER). Napisz pakiet z procedurą COMPARE_FACT (ID_PACK_OLD, ID_PACK_NEW), która pozwala podać dwa różne ID_PACK by porównać dane z obu wersji. Wynik porównania powinien być dostępny w tabeli tymczasowej TMP_FACT_HISTORY_COMPARE_STATUS (1 - MODIFIED, 2 - NEW, 3 - DELETED)

### Test
```
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (1, 101, 'ABC', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 100);	
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (1, 102, 'DEF', TO_DATE('2023-01-02', 'YYYY-MM-DD'), 200);	
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (1, 103, 'GHI', TO_DATE('2023-01-03', 'YYYY-MM-DD'), 300);	-- fakt który zostaje usunięty
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (2, 101, 'ABC', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 100);	-- fakt bez zmian
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (2, 102, 'XYZ', TO_DATE('2023-01-02', 'YYYY-MM-DD'), 200);	-- zmiana wartości faktu z DEF na XYZ w COLUMN1
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (2, 104, 'JKL', TO_DATE('2023-01-04', 'YYYY-MM-DD'), 400);	-- wprowadzenie nowego faktu o id 104

// wywołanie procedury FACT_HISTORY_PKG.COMPARE_FACT(ID_PACK_OLD => 1, ID_PACK_NEW => 2)

SELECT * FROM FACT_HISTORY;

ID_PACK		ID_FACT		COLUMN1		COLUMN2		COLUMN3
1			101			ABC			01-JAN-23	100
1			102			DEF			02-JAN-23	200
1			103			GHI			03-JAN-23	300
2			101			ABC			01-JAN-23	100
2			102			XYZ			02-JAN-23	200
2			104			JKL			04-JAN-23	400

SELECT * FROM TMP_FACT_HISTORY_COMPARE_STATUS;

ID_FACT	STATUS
102		1
103		3
104		2
```

### Zadanie 2
Procedura COMPARE_FACT (ID_PACK_OLD, ID_PACK_NEW, BUILD_DIFF default false) pozwala opcjonalnie wymusić uzupełnienie tabeli tymczasowej TMP_FACT_HISTORY_COMPARE_DIFF. Wartości COL_OLD_VALUE oraz COL_NEW_VALUE reprezentują oryginalne wartości kolumn które się różnią w postaci sformatowanej VARCHAR2 (format stały zdefiniowany w pakiecie). W tabeli tej znajdują się tylko wiersze STATUS = 1 (MODIFIED)

### Test
```
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (1, 101, 'ABC', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 100);	
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (1, 102, 'DEF', TO_DATE('2023-01-02', 'YYYY-MM-DD'), 200);	
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (1, 103, 'GHI', TO_DATE('2023-01-03', 'YYYY-MM-DD'), 300);	-- fakt który zostaje usunięty
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (2, 101, 'ABC', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 100);	-- fakt bez zmian
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (2, 102, 'XYZ', TO_DATE('2023-01-02', 'YYYY-MM-DD'), 200);	-- zmiana wartości faktu z DEF na XYZ w COLUMN1
INSERT INTO FACT_HISTORY (ID_PACK, ID_FACT, COLUMN1, COLUMN2, COLUMN3) VALUES (2, 104, 'JKL', TO_DATE('2023-01-04', 'YYYY-MM-DD'), 400);	-- wprowadzenie nowego faktu o id 104

// wywołanie procedury FACT_HISTORY_PKG.COMPARE_FACT(ID_PACK_OLD => 1, ID_PACK_NEW => 2, BUILD_DIFF => TRUE);

SELECT * FROM TMP_FACT_HISTORY_COMPARE_DIFF;

ID_FACT	COL_NAME	COL_TYPE	COL_OLD_VALUE	COL_NEW_VALUE
102		COLUMN1		VARCHAR2	DEF				XYZ
```

### Zadanie 3
Napisz procedurę, która umożliwia rezerwację biletu na koncert, przyjmij że:
● procedurę mogą wywoływać równoległe niezależne sesje np. 50
● limit rezerwacji np. 50k
● każda próba rejestracji powinna zostać odłożona w dedykowanej tabeli (zaproponuj jej strukturę)

Zaproponuj sposób testowania rozwiązania
1) próba rezerwacji ponad ustalony limit 50k
2) próba jednoczesnej rezerwacji z poziomu różnych sesji (sprawdzenie czy odkładanie logu działa poprawnie)

Potencjalne nadużycia w przypadku procedury anulowania rezerwacji:
- koniecznosć sprawdzania czy dana rezerwacja (bilet) został już użyty
- w przypadku dostępnej możliwości wielokrotnej zmiany statusu rezerwacji (zarezerwowany/anulowany/zużyty) różne sesje mogą widzieć różny (nieaktualny) stan danej rezerwacji, stąd jednym z rozwiązań jest narzucenie limitu anulowań w określonym przedziale czasu, tzw timeoutu (np. za pomocą dodatkowego pola w tabeli reservation_logs, które rejestruje częstotliwość anulowań dla danego PESEL i biletów)

### Test
```
// wywołanie procedury RESERVE_TICKET z przykładowymi danymi

PESEL: 98012345601, Status: 0, Reservation ID: 1
PESEL: 98012345602, Status: 0, Reservation ID: 2
PESEL: 98012345603, Status: 0, Reservation ID: 3
PESEL: 98012345604, Status: 0, Reservation ID: 4
PESEL: 98012345605, Status: 0, Reservation ID: 5
PESEL: 98012345606, Status: 0, Reservation ID: 6
PESEL: 98012345607, Status: 0, Reservation ID: 7
PESEL: 98012345608, Status: 0, Reservation ID: 8
PESEL: 98012345609, Status: 0, Reservation ID: 9
PESEL: 98012345610, Status: 0, Reservation ID: 10
PESEL: 98012345611, Status: 0, Reservation ID: 11
PESEL: 98012345612, Status: 0, Reservation ID: 12
PESEL: 98012345613, Status: 0, Reservation ID: 13
PESEL: 98012345614, Status: 0, Reservation ID: 14
PESEL: 98012345615, Status: 0, Reservation ID: 15
PESEL: 98012345616, Status: 0, Reservation ID: 16
PESEL: 98012345617, Status: 0, Reservation ID: 17
PESEL: 98012345618, Status: 0, Reservation ID: 18
PESEL: 98012345619, Status: 0, Reservation ID: 19
PESEL: 98012345620, Status: 0, Reservation ID: 20
PESEL: 98012345621, Status: 0, Reservation ID: 21
PESEL: 98012345622, Status: 0, Reservation ID: 22
PESEL: 98012345623, Status: 0, Reservation ID: 23
PESEL: 98012345624, Status: 0, Reservation ID: 24
PESEL: 98012345625, Status: 0, Reservation ID: 25
PESEL: 98012345626, Status: 0, Reservation ID: 26
PESEL: 98012345627, Status: 0, Reservation ID: 27
PESEL: 98012345628, Status: 0, Reservation ID: 28
PESEL: 98012345629, Status: 0, Reservation ID: 29
PESEL: 98012345630, Status: 0, Reservation ID: 30
PESEL: 98012345631, Status: 0, Reservation ID: 31
PESEL: 98012345632, Status: 0, Reservation ID: 32
PESEL: 98012345633, Status: 0, Reservation ID: 33
PESEL: 98012345634, Status: 0, Reservation ID: 34
PESEL: 98012345635, Status: 0, Reservation ID: 35
PESEL: 98012345636, Status: 0, Reservation ID: 36
PESEL: 98012345637, Status: 0, Reservation ID: 37
PESEL: 98012345638, Status: 0, Reservation ID: 38
PESEL: 98012345639, Status: 0, Reservation ID: 39
PESEL: 98012345640, Status: 0, Reservation ID: 40
PESEL: 98012345641, Status: 0, Reservation ID: 41
PESEL: 98012345642, Status: 0, Reservation ID: 42
PESEL: 98012345643, Status: 0, Reservation ID: 43
PESEL: 98012345644, Status: 0, Reservation ID: 44
PESEL: 98012345645, Status: 0, Reservation ID: 45
PESEL: 98012345646, Status: 0, Reservation ID: 46
PESEL: 98012345647, Status: 0, Reservation ID: 47
PESEL: 98012345648, Status: 0, Reservation ID: 48
PESEL: 98012345649, Status: 0, Reservation ID: 49
PESEL: 98012345650, Status: 0, Reservation ID: 50
```

### Zadanie 4
Tabela ORDERS zawiera dane o zamówieniach. Napisz metodę PL/SQL, która przyjmuje dwa argumenty typu DATE (StartDate i EndDate) oraz zwraca sumaryczną kwotę zamówień złożonych pomiędzy tymi datami dla każdego klienta. Wynik powinien być posortowany malejąco według sumarycznej kwoty.

### Test
```
// wywołanie procedury GET_CUSTOMER_ORDER_TOTALS(StartDate => TO_DATE('2023-01-01', 'YYYY-MM-DD'), EndDate => TO_DATE('2023-02-28', 'YYYY-MM-DD')

Customer ID: 102, Total Amount: 600
Customer ID: 103, Total Amount: 300.75
Customer ID: 101, Total Amount: 150.5
```

### Zadanie 5
Napisz metodę, która za parametr przyjmuje json klient:zamówienia i rozkłada go na poszczególne tabele.

### Test
```
// wywołanie procedury INSERT_ORDERS_FROM_JSON

SELECT * FROM customers;

CUSTOMER_ID		NAME	SURNAME		ADDRESS
1				Jan		Kowalski	ul. Testowa 123, 00-000 Warszawa

SELECT * FROM orders;

ORDER_ID	PRODUCT					CNT			PRICE		CUSTOMER_ID
1			Laptop					1			3500		1
2			Smartphone				2			1500		1
3			Słuchawki bezprzewodowe	1			200			1
```


