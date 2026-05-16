SET SERVEROUTPUT ON;

-- Zadanie 1.
DECLARE
  v_liczba_kursantow   NUMBER;
  v_liczba_kursow      NUMBER;
  v_liczba_wykladowcow NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_liczba_kursantow FROM kursanci;
  SELECT COUNT(*) INTO v_liczba_kursow FROM kursy;
  SELECT COUNT(*) INTO v_liczba_wykladowcow FROM wykladowcy;

  DBMS_OUTPUT.PUT_LINE('Liczba kursantów: ' || v_liczba_kursantow);
  DBMS_OUTPUT.PUT_LINE('Liczba kursów: ' || v_liczba_kursow);
  DBMS_OUTPUT.PUT_LINE('Liczba wykładowców: ' || v_liczba_wykladowcow);
END;
/

-- Zadanie 2.
DECLARE
  v_laczna_wartosc NUMBER;
BEGIN
  SELECT SUM(r.cena)
  INTO v_laczna_wartosc
  FROM umowy u
  JOIN kursy k   ON u.kurs_id = k.kurs_id
  JOIN rodzaje r ON k.rodzaj_id = r.rodzaj_id
  WHERE u.miasto = 'BYDGOSZCZ';

  DBMS_OUTPUT.PUT_LINE('Łączna wartość umów dla BYDGOSZCZY: ' || v_laczna_wartosc || ' zł');
END;
/

-- Zadanie 3.
DECLARE
  v_miasto       VARCHAR2(30) := 'BYDGOSZCZ';
  v_liczba_umow  NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_liczba_umow FROM umowy WHERE miasto = v_miasto;
 
  IF v_liczba_umow = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Brak umów dla miasta ' || v_miasto);
  ELSIF v_liczba_umow < 50 THEN
    DBMS_OUTPUT.PUT_LINE('Mała liczba umów (' || v_liczba_umow || ')');
  ELSIF v_liczba_umow <= 100 THEN
    DBMS_OUTPUT.PUT_LINE('Średnia liczba umów (' || v_liczba_umow || ')');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Duża liczba umów (' || v_liczba_umow || ')');
  END IF;
END;
/

-- Zadanie 4.
BEGIN
  FOR r IN (
    SELECT k.kurs_id, r.nazwa, r.godz, r.cena, w.imie, w.nazwisko
    FROM kursy k
    JOIN rodzaje r    ON k.rodzaj_id = r.rodzaj_id
    JOIN wykladowcy w ON k.wykladowca_id = w.wykladowca_id
    ORDER BY k.kurs_id
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Kurs ' || r.kurs_id || ': ' || r.nazwa || ', ' || r.godz || 'h, ' || r.cena || ' zł, prowadzący: ' || r.imie || ' ' || r.nazwisko);
  END LOOP;
END;
/

-- Zadanie 5.
CREATE OR REPLACE PROCEDURE raport_umow_miasto(p_miasto IN VARCHAR2)
AS
  v_liczba_umow     NUMBER;
  v_laczna_wartosc  NUMBER;
  v_srednia_wartosc NUMBER;
BEGIN
  SELECT COUNT(*), NVL(SUM(r.cena), 0), NVL(ROUND(AVG(r.cena), 2), 0)
  INTO v_liczba_umow, v_laczna_wartosc, v_srednia_wartosc
  FROM umowy u
  JOIN kursy k   ON u.kurs_id = k.kurs_id
  JOIN rodzaje r ON k.rodzaj_id = r.rodzaj_id
  WHERE u.miasto = p_miasto;

  DBMS_OUTPUT.PUT_LINE('Raport dla miasta: ' || p_miasto);
  DBMS_OUTPUT.PUT_LINE('Liczba umów: ' || v_liczba_umow);
  DBMS_OUTPUT.PUT_LINE('Łączna wartość umów: ' || v_laczna_wartosc || ' zł');
  DBMS_OUTPUT.PUT_LINE('Średnia wartość umowy: ' || v_srednia_wartosc || ' zł');
END;
/

-- Zadanie 6.
CREATE OR REPLACE FUNCTION wartosc_kursu(p_kurs_id IN NUMBER)
RETURN NUMBER
AS
  v_cena NUMBER;
BEGIN
  SELECT r.cena INTO v_cena FROM kursy k JOIN rodzaje r ON k.rodzaj_id = r.rodzaj_id WHERE k.kurs_id = p_kurs_id;
  RETURN v_cena;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
END;
/

-- Zadanie 7.
CREATE OR REPLACE PROCEDURE pokaz_kursanta(p_kursant_id IN NUMBER)
AS
  v_imie     kursanci.imie%TYPE;
  v_nazwisko kursanci.nazwisko%TYPE;
BEGIN
  SELECT imie, nazwisko INTO v_imie, v_nazwisko FROM kursanci WHERE kursant_id = p_kursant_id;
  DBMS_OUTPUT.PUT_LINE(v_imie || ' ' || v_nazwisko);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Nie znaleziono kursanta o ID: ' || p_kursant_id);
END;
/

CREATE OR REPLACE PROCEDURE pokaz_kursanta_po_nazwisku(p_nazwisko IN VARCHAR2)
AS
  v_imie     kursanci.imie%TYPE;
  v_nazwisko kursanci.nazwisko%TYPE;
BEGIN
  SELECT imie, nazwisko INTO v_imie, v_nazwisko FROM kursanci WHERE nazwisko = UPPER(p_nazwisko);
  DBMS_OUTPUT.PUT_LINE(v_imie || ' ' || v_nazwisko);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Nie znaleziono kursanta o nazwisku: ' || p_nazwisko);
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('Zbyt wiele wyników dla nazwiska: ' || p_nazwisko);
END;
/

-- Zadanie 8.
DECLARE
  CURSOR c_szczegoly_umow IS
    SELECT u.umowa_id, kr.imie, kr.nazwisko, r.nazwa, r.cena
    FROM umowy u
    JOIN kursanci kr ON u.kursant_id = kr.kursant_id
    JOIN kursy k     ON u.kurs_id = k.kurs_id
    JOIN rodzaje r   ON k.rodzaj_id = r.rodzaj_id
    WHERE u.miasto = 'BYDGOSZCZ';
  v_rekord c_szczegoly_umow%ROWTYPE;
BEGIN
  OPEN c_szczegoly_umow;
  LOOP
    FETCH c_szczegoly_umow INTO v_rekord;
    EXIT WHEN c_szczegoly_umow%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Umowa ' || v_rekord.umowa_id || ' | ' || v_rekord.imie || ' ' || v_rekord.nazwisko || ' | ' || v_rekord.nazwa || ' | ' || v_rekord.cena || ' zł');
  END LOOP;
  CLOSE c_szczegoly_umow;
END;
/

-- Zadanie 9.
CREATE OR REPLACE PROCEDURE raport_umow_szczecin
AS
BEGIN
  FOR r IN (
    SELECT u.umowa_id, kf.imie, kf.nazwisko, rf.nazwa, rf.cena, u.miasto
    FROM umowy u
    JOIN mv_kursanci_filia kf ON u.kursant_id = kf.kursant_id
    JOIN mv_kursy_filia kf_   ON u.kurs_id = kf_.kurs_id
    JOIN mv_rodzaje_filia rf  ON kf_.rodzaj_id = rf.rodzaj_id
    WHERE u.miasto = 'SZCZECIN'
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Umowa ' || r.umowa_id || ' | ' || r.imie || ' ' || r.nazwisko || ' | ' || r.nazwa || ' | ' || r.cena || ' zł | ' || r.miasto);
  END LOOP;
END;
/

-- Zadanie 10.
CREATE TABLE raporty_uczelni (
  data_generowania DATE,
  miasto VARCHAR2(20),
  liczba_umow NUMBER,
  laczna_wartosc NUMBER,
  najdrozszy_kurs VARCHAR2(100),
  najpopularniejszy_kurs VARCHAR2(100)
);

CREATE OR REPLACE PROCEDURE raport_uczelni
AS
  v_byd_ile NUMBER; v_byd_suma NUMBER; v_byd_najdrozszy VARCHAR2(100); v_byd_popularny VARCHAR2(100);
  v_szc_ile NUMBER; v_szc_suma NUMBER; v_szc_najdrozszy VARCHAR2(100); v_szc_popularny VARCHAR2(100);
BEGIN
  SELECT COUNT(*), NVL(SUM(r.cena), 0) INTO v_byd_ile, v_byd_suma FROM umowy u JOIN kursy k ON u.kurs_id = k.kurs_id JOIN rodzaje r ON k.rodzaj_id = r.rodzaj_id WHERE u.miasto = 'BYDGOSZCZ';
  SELECT nazwa INTO v_byd_najdrozszy FROM (SELECT r.nazwa FROM umowy u JOIN kursy k ON u.kurs_id = k.kurs_id JOIN rodzaje r ON k.rodzaj_id = r.rodzaj_id WHERE u.miasto = 'BYDGOSZCZ' ORDER BY r.cena DESC) WHERE ROWNUM = 1;
  SELECT nazwa INTO v_byd_popularny FROM (SELECT r.nazwa FROM umowy u JOIN kursy k ON u.kurs_id = k.kurs_id JOIN rodzaje r ON k.rodzaj_id = r.rodzaj_id WHERE u.miasto = 'BYDGOSZCZ' GROUP BY r.nazwa ORDER BY COUNT(*) DESC) WHERE ROWNUM = 1;

  SELECT COUNT(*), NVL(SUM(rf.cena), 0) INTO v_szc_ile, v_szc_suma FROM umowy u JOIN mv_kursy_filia kf ON u.kurs_id = kf.kurs_id JOIN mv_rodzaje_filia rf ON kf.rodzaj_id = rf.rodzaj_id WHERE u.miasto = 'SZCZECIN';
  SELECT nazwa INTO v_szc_najdrozszy FROM (SELECT rf.nazwa FROM umowy u JOIN mv_kursy_filia kf ON u.kurs_id = kf.kurs_id JOIN mv_rodzaje_filia rf ON kf.rodzaj_id = rf.rodzaj_id WHERE u.miasto = 'SZCZECIN' ORDER BY rf.cena DESC) WHERE ROWNUM = 1;
  SELECT nazwa INTO v_szc_popularny FROM (SELECT rf.nazwa FROM umowy u JOIN mv_kursy_filia kf ON u.kurs_id = kf.kurs_id JOIN mv_rodzaje_filia rf ON kf.rodzaj_id = rf.rodzaj_id WHERE u.miasto = 'SZCZECIN' GROUP BY rf.nazwa ORDER BY COUNT(*) DESC) WHERE ROWNUM = 1;

  DBMS_OUTPUT.PUT_LINE('RAPORT UCZELNI');
  DBMS_OUTPUT.PUT_LINE('Miasto: BYDGOSZCZ');
  DBMS_OUTPUT.PUT_LINE('Liczba umów: ' || v_byd_ile || ' | Wartość: ' || v_byd_suma || ' zł | Najdroższy: ' || v_byd_najdrozszy || ' | Popularny: ' || v_byd_popularny);
  DBMS_OUTPUT.PUT_LINE('Miasto: SZCZECIN');
  DBMS_OUTPUT.PUT_LINE('Liczba umów: ' || v_szc_ile || ' | Wartość: ' || v_szc_suma || ' zł | Najdroższy: ' || v_szc_najdrozszy || ' | Popularny: ' || v_szc_popularny);
  DBMS_OUTPUT.PUT_LINE('PODSUMOWANIE | Umowy: ' || (v_byd_ile + v_szc_ile) || ' | Wartość łączna: ' || (v_byd_suma + v_szc_suma) || ' zł');

  INSERT INTO raporty_uczelni VALUES (SYSDATE, 'BYDGOSZCZ', v_byd_ile, v_byd_suma, v_byd_najdrozszy, v_byd_popularny);
  INSERT INTO raporty_uczelni VALUES (SYSDATE, 'SZCZECIN', v_szc_ile, v_szc_suma, v_szc_najdrozszy, v_szc_popularny);
  COMMIT;
END;
/