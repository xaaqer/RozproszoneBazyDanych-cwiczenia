-- ============================================================
-- ZADANIA – MIGAWKI COMPLETE
-- ============================================================

-- ZADANIE COMPLETE 1
CREATE MATERIALIZED VIEW REP_wykladowcy
    BUILD IMMEDIATE
    REFRESH COMPLETE
    ON DEMAND
AS
    SELECT wykladowca_id, imie, nazwisko, stawka
    FROM   wykladowcy@baza11b;


-- ZADANIE COMPLETE 2
INSERT INTO wykladowcy (wykladowca_id, imie, nazwisko, stawka)
VALUES (115, 'NOWY', 'WYKLADOWCA', 110);
COMMIT;


-- ZADANIE COMPLETE 3
SELECT * FROM REP_wykladowcy;


-- ZADANIE COMPLETE 4
EXECUTE DBMS_MVIEW.REFRESH('REP_wykladowcy', 'C');


-- ZADANIE COMPLETE 5
SELECT * FROM REP_wykladowcy;


-- ZADANIE COMPLETE 6
CREATE MATERIALIZED VIEW REP_godz_wykladowcy_godziny
    BUILD DEFERRED
    REFRESH COMPLETE
    ON DEMAND
    START WITH LAST_DAY(SYSDATE)
    NEXT  LAST_DAY(SYSDATE) + 1/24
AS
    SELECT
        w.wykladowca_id,
        w.imie,
        w.nazwisko,
        SUM(r.godz) AS laczna_liczba_godzin
    FROM   wykladowcy@baza11b w
    JOIN   kursy@baza11b      k ON w.wykladowca_id = k.wykladowca_id
    JOIN   rodzaje@baza11b    r ON k.rodzaj_id      = r.rodzaj_id
    GROUP BY w.wykladowca_id, w.imie, w.nazwisko;


-- ZADANIE COMPLETE 7
CREATE MATERIALIZED VIEW REP_kursy
    BUILD IMMEDIATE
    REFRESH COMPLETE
    ON DEMAND
    START WITH SYSDATE
    NEXT  SYSDATE + 7
AS
    SELECT
        k.kurs_id,
        r.nazwa         AS nazwa_kursu,
        w.imie,
        w.nazwisko,
        r.godz          AS liczba_godzin,
        r.cena          AS oplata
    FROM   kursy@baza11b      k
    JOIN   rodzaje@baza11b    r ON k.rodzaj_id      = r.rodzaj_id
    JOIN   wykladowcy@baza11b w ON k.wykladowca_id  = w.wykladowca_id;


-- ZADANIE COMPLETE 8
CREATE OR REPLACE VIEW V_KURSY_WSZYSTKIE AS
    SELECT
        'FILIA'    AS zrodlo,
        kurs_id,
        nazwa_kursu,
        imie,
        nazwisko,
        liczba_godzin,
        oplata
    FROM REP_kursy

    UNION ALL

    SELECT
        'SIEDZIBA' AS zrodlo,
        k.kurs_id,
        r.nazwa    AS nazwa_kursu,
        w.imie,
        w.nazwisko,
        r.godz     AS liczba_godzin,
        r.cena     AS oplata
    FROM   kursy      k
    JOIN   rodzaje    r ON k.rodzaj_id     = r.rodzaj_id
    JOIN   wykladowcy w ON k.wykladowca_id = w.wykladowca_id;


-- ZADANIE COMPLETE 9
SELECT name,
       refresh_method,
       refresh_mode,
       start_with,
       next,
       last_refresh
FROM   USER_SNAPSHOTS;

SELECT mview_name,
       refresh_method,
       refresh_mode,
       start_with,
       next,
       last_refresh_date,
       compile_state
FROM   USER_MVIEWS;


-- ============================================================
-- ZADANIA – MIGAWKI FAST
-- ============================================================

-- ZADANIE FAST 1
-- Wykonaj najpierw w siedzibie (baza11a) – dziennik dla tabeli zdalnej
CREATE MATERIALIZED VIEW LOG ON kursanci
    WITH PRIMARY KEY, ROWID
    INCLUDING NEW VALUES;

-- Następnie w filii (baza11b) – migawka przyrostowa
CREATE MATERIALIZED VIEW REP_kursanci_filia
    BUILD IMMEDIATE
    REFRESH FAST
    ON DEMAND
AS
    SELECT kursant_id, imie, nazwisko
    FROM   kursanci@baza11a;


-- ZADANIE FAST 2
-- Dziennik dla lokalnej tabeli kursanci w siedzibie (baza11a)
CREATE MATERIALIZED VIEW LOG ON kursanci
    WITH PRIMARY KEY, ROWID
    INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW REP_kursanci_on_commit
    BUILD IMMEDIATE
    REFRESH FAST
    ON COMMIT
AS
    SELECT kursant_id, imie, nazwisko
    FROM   kursanci;


-- ZADANIE FAST 3
CREATE MATERIALIZED VIEW REP_przychod_kursow
    BUILD IMMEDIATE
    REFRESH COMPLETE
    ON DEMAND
AS
    SELECT
        k.kurs_id,
        r.nazwa                                          AS nazwa_kursu,
        r.cena                                           AS cena_jednostkowa,
        COUNT(u.kursant_id)                              AS liczba_kursantow,
        COUNT(u.kursant_id) * r.cena                     AS laczny_przychod,
        ROUND(COUNT(u.kursant_id) * r.cena * 0.19, 2)   AS podatek_19proc
    FROM   kursy    k
    JOIN   rodzaje  r ON k.rodzaj_id  = r.rodzaj_id
    JOIN   umowy    u ON k.kurs_id    = u.kurs_id
    GROUP BY k.kurs_id, r.nazwa, r.cena;


-- ZADANIE FAST 4
-- Próba przepisania migawki REP_przychod_kursow w trybie FAST ON COMMIT.
-- Nie jest możliwa w tej formie – patrz niżej.
-- Warunki które muszą być spełnione dla FAST z agregacją:
--   a) SELECT musi zawierać COUNT(*) obok COUNT(kolumny)
--   b) Dzienniki migawek muszą istnieć dla KAŻDEJ tabeli w FROM (kursy, rodzaje, umowy)
--   c) ON COMMIT wymaga, żeby wszystkie tabele były lokalne
-- Poniżej poprawna wersja spełniająca wymogi FAST (ON DEMAND, bo umowy jest lokalna):

CREATE MATERIALIZED VIEW LOG ON umowy
    WITH PRIMARY KEY, ROWID
    INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON kursy
    WITH PRIMARY KEY, ROWID
    INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON rodzaje
    WITH PRIMARY KEY, ROWID
    INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW REP_przychod_kursow_fast
    BUILD IMMEDIATE
    REFRESH FAST
    ON COMMIT
AS
    SELECT
        k.kurs_id,
        r.nazwa                                        AS nazwa_kursu,
        r.cena                                         AS cena_jednostkowa,
        COUNT(*)                                       AS cnt,
        COUNT(u.kursant_id)                            AS liczba_kursantow,
        SUM(r.cena)                                    AS laczny_przychod,
        SUM(r.cena * 0.19)                             AS podatek_19proc
    FROM   kursy    k
    JOIN   rodzaje  r ON k.rodzaj_id  = r.rodzaj_id
    JOIN   umowy    u ON k.kurs_id    = u.kurs_id
    GROUP BY k.kurs_id, r.nazwa, r.cena;
