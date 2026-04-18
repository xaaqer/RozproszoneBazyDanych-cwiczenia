-- ZADANIE 1
CREATE DATABASE LINK dblinkFilia
    CONNECT TO RBDN2_ST7
    IDENTIFIED BY start123
    USING 'baza11b';


-- ZADANIE 2
SELECT kursant_id, imie, nazwisko
FROM   kursanci@dblinkFilia;


-- ZADANIE 3
CREATE SYNONYM wykladowcySiedziba FOR wykladowcy;
CREATE SYNONYM kursanciSiedziba    FOR kursanci;
CREATE SYNONYM rodzajeSiedziba     FOR rodzaje;
CREATE SYNONYM kursySiedziba       FOR kursy;

CREATE SYNONYM wykladowcyFilia FOR wykladowcy@dblinkFilia;
CREATE SYNONYM kursanciFilia    FOR kursanci@dblinkFilia;
CREATE SYNONYM rodzajeFilia     FOR rodzaje@dblinkFilia;
CREATE SYNONYM kursyFilia       FOR kursy@dblinkFilia;


-- ZADANIE 4
CREATE OR REPLACE VIEW kursanciAll AS
    SELECT imie, nazwisko FROM kursanciSiedziba
    UNION
    SELECT imie, nazwisko FROM kursanciFilia;

CREATE OR REPLACE VIEW wykladowcyAll AS
    SELECT imie, nazwisko FROM wykladowcySiedziba
    UNION
    SELECT imie, nazwisko FROM wykladowcyFilia;


-- ZADANIE 5
CREATE OR REPLACE VIEW kursyAll AS
    SELECT
        r.nazwa                  AS nazwa_kursu,
        w.imie,
        w.nazwisko,
        COUNT(u.kursant_id)      AS liczba_uczestnikow
    FROM   kursySiedziba      k
    JOIN   rodzajeSiedziba    r ON k.rodzaj_id     = r.rodzaj_id
    JOIN   wykladowcySiedziba w ON k.wykladowca_id = w.wykladowca_id
    JOIN   umowy              u ON k.kurs_id       = u.kurs_id
    GROUP BY r.nazwa, w.imie, w.nazwisko

    UNION ALL

    SELECT
        r.nazwa                  AS nazwa_kursu,
        w.imie,
        w.nazwisko,
        COUNT(u.kursant_id)      AS liczba_uczestnikow
    FROM   kursyFilia         k
    JOIN   rodzajeFilia       r ON k.rodzaj_id     = r.rodzaj_id
    JOIN   wykladowcyFilia    w ON k.wykladowca_id = w.wykladowca_id
    JOIN   umowy              u ON k.kurs_id       = u.kurs_id
    GROUP BY r.nazwa, w.imie, w.nazwisko;


-- ZADANIE 6
SELECT SUM(przychod) AS laczny_przychod
FROM (
    SELECT COUNT(u.kursant_id) * r.cena AS przychod
    FROM   kursySiedziba      k
    JOIN   rodzajeSiedziba    r ON k.rodzaj_id = r.rodzaj_id
    JOIN   umowy              u ON k.kurs_id   = u.kurs_id
    GROUP BY k.kurs_id, r.cena

    UNION ALL

    SELECT COUNT(u.kursant_id) * r.cena AS przychod
    FROM   kursyFilia         k
    JOIN   rodzajeFilia       r ON k.rodzaj_id = r.rodzaj_id
    JOIN   umowy              u ON k.kurs_id   = u.kurs_id
    GROUP BY k.kurs_id, r.cena
);


-- ZADANIE 7
SELECT SUM(koszt) AS laczne_koszty
FROM (
    SELECT w.stawka * r.godz AS koszt
    FROM   kursySiedziba      k
    JOIN   rodzajeSiedziba    r ON k.rodzaj_id     = r.rodzaj_id
    JOIN   wykladowcySiedziba w ON k.wykladowca_id = w.wykladowca_id

    UNION ALL

    SELECT w.stawka * r.godz AS koszt
    FROM   kursyFilia         k
    JOIN   rodzajeFilia       r ON k.rodzaj_id     = r.rodzaj_id
    JOIN   wykladowcyFilia    w ON k.wykladowca_id = w.wykladowca_id
);


-- ZADANIE 8
SELECT
    nazwa_kursu,
    przychod,
    koszt,
    przychod - koszt AS zysk
FROM (
    SELECT
        r.nazwa                         AS nazwa_kursu,
        COUNT(u.kursant_id) * r.cena    AS przychod,
        w.stawka * r.godz               AS koszt
    FROM   kursySiedziba      k
    JOIN   rodzajeSiedziba    r ON k.rodzaj_id     = r.rodzaj_id
    JOIN   wykladowcySiedziba w ON k.wykladowca_id = w.wykladowca_id
    JOIN   umowy              u ON k.kurs_id       = u.kurs_id
    GROUP BY r.nazwa, r.cena, w.stawka, r.godz

    UNION ALL

    SELECT
        r.nazwa                         AS nazwa_kursu,
        COUNT(u.kursant_id) * r.cena    AS przychod,
        w.stawka * r.godz               AS koszt
    FROM   kursyFilia         k
    JOIN   rodzajeFilia       r ON k.rodzaj_id     = r.rodzaj_id
    JOIN   wykladowcyFilia    w ON k.wykladowca_id = w.wykladowca_id
    JOIN   umowy              u ON k.kurs_id       = u.kurs_id
    GROUP BY r.nazwa, r.cena, w.stawka, r.godz
);


-- ZADANIE 9
SELECT SUM(przychod - koszt) AS laczny_zysk
FROM (
    SELECT
        COUNT(u.kursant_id) * r.cena    AS przychod,
        w.stawka * r.godz               AS koszt
    FROM   kursySiedziba      k
    JOIN   rodzajeSiedziba    r ON k.rodzaj_id     = r.rodzaj_id
    JOIN   wykladowcySiedziba w ON k.wykladowca_id = w.wykladowca_id
    JOIN   umowy              u ON k.kurs_id       = u.kurs_id
    GROUP BY r.cena, w.stawka, r.godz

    UNION ALL

    SELECT
        COUNT(u.kursant_id) * r.cena    AS przychod,
        w.stawka * r.godz               AS koszt
    FROM   kursyFilia         k
    JOIN   rodzajeFilia       r ON k.rodzaj_id     = r.rodzaj_id
    JOIN   wykladowcyFilia    w ON k.wykladowca_id = w.wykladowca_id
    JOIN   umowy              u ON k.kurs_id       = u.kurs_id
    GROUP BY r.cena, w.stawka, r.godz
);
