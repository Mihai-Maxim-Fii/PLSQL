
/*Construiti o functie ce va genera catalogul unei materii: parametrul de intrare va fi un ID de materie si functia va genera o tabela avand acelasi nume cu materia (daca sunt mai multe cuvinte se vor concatena). Catalogul va contine nota, data notarii, numele, prenumele si numarul matricol al studentului ce a luat nota respectiva. Scriptul trebuie sa ruleze corect chiar dupa adaugarea unei noi materii sau eliminarea uneia deja existenta. Tipul si dimensiunea coloanelor vor fi identice cu cele din baza de date despre studenti/note/cursuri si le veti afla interogand baza de date (nu folosind valori concrete/hardcodate). Daca tabelul exista deja (creat dinainte), functia il va sterge inainte de generare.

Utilizati doar pachetul DBMS_SQL. Pentru utilizarea comenzii execute immediate aveti o penalizare de 3 puncte.
*/

--Functia de pe pastebin...
create or replace function getType(v_rec_tab DBMS_SQL.DESC_TAB, v_nr_col int) return varchar2 as
  v_tip_coloana varchar2(200);
  v_precizie VARCHAR2(40);
begin
     CASE (v_rec_tab(v_nr_col).col_type)
        WHEN 1 THEN v_tip_coloana := 'VARCHAR2'; v_precizie := '(' || v_rec_tab(v_nr_col).col_max_len || ')';
        WHEN 2 THEN v_tip_coloana := 'NUMBER'; v_precizie := '(' || v_rec_tab(v_nr_col).col_precision || ',' || v_rec_tab(v_nr_col).col_scale || ')';
        WHEN 12 THEN v_tip_coloana := 'DATE'; v_precizie := '';
        WHEN 96 THEN v_tip_coloana := 'CHAR'; v_precizie := '(' || v_rec_tab(v_nr_col).col_max_len || ')';
        WHEN 112 THEN v_tip_coloana := 'CLOB'; v_precizie := '';
        WHEN 113 THEN v_tip_coloana := 'BLOB'; v_precizie := '';
        WHEN 109 THEN v_tip_coloana := 'XMLTYPE'; v_precizie := '';
        WHEN 101 THEN v_tip_coloana := 'BINARY_DOUBLE'; v_precizie := '';
        WHEN 100 THEN v_tip_coloana := 'BINARY_FLOAT'; v_precizie := '';
        WHEN 8 THEN v_tip_coloana := 'LONG'; v_precizie := '';
        WHEN 180 THEN v_tip_coloana := 'TIMESTAMP'; v_precizie :='(' || v_rec_tab(v_nr_col).col_scale || ')';
        WHEN 181 THEN v_tip_coloana := 'TIMESTAMP' || '(' || v_rec_tab(v_nr_col).col_scale || ') ' || 'WITH TIME ZONE'; v_precizie := '';
        WHEN 231 THEN v_tip_coloana := 'TIMESTAMP' || '(' || v_rec_tab(v_nr_col).col_scale || ') ' || 'WITH LOCAL TIME ZONE'; v_precizie := '';
        WHEN 114 THEN v_tip_coloana := 'BFILE'; v_precizie := '';
        WHEN 23 THEN v_tip_coloana := 'RAW'; v_precizie := '(' || v_rec_tab(v_nr_col).col_max_len || ')';
        WHEN 11 THEN v_tip_coloana := 'ROWID'; v_precizie := '';
        WHEN 109 THEN v_tip_coloana := 'URITYPE'; v_precizie := '';
      END CASE;
      return v_tip_coloana||v_precizie;
end;
--Procedura cu care generez nou tabel
create or replace procedure genereaza_catalog_materie(ID_MATERIE IN NUMBER)
as
  v_cursor_id NUMBER;
  v_ok        NUMBER;
  v_rec_tab     DBMS_SQL.DESC_TAB;
  v_nr_col     NUMBER;
  v_total_coloane     NUMBER;
  TYPE col_array IS varray(5)  OF varchar2(30);
  col_type col_array;
  temp_table_name varchar2(30);
  table_name varchar2(30);--in aceasta structura o sa retin tipul de date al coloanelor din tabel.
   CURSOR curs IS select VALOARE ,DATA_NOTARE,NUME,PRENUME,NR_MATRICOL from STUDENTI s join note n on s.ID=n.ID_STUDENT join CURSURI c on n.ID_CURS=c.ID WHERE n.ID_CURS=ID_MATERIE;
   TYPE linie_student IS TABLE OF curs%ROWTYPE; --Cu acest cursor o sa inserez datele in noul tabel,la final.
   lista_studenti linie_student;
BEGIN
  select TITLU_CURS into temp_table_name from CURSURI where id=ID_MATERIE;--aflu numele materiei in functie de id
  select REPLACE (temp_table_name, ' ', '' ) into table_name from dual;--scot spatiile libere din numele materiei
  col_type:=col_array('test','test','test','test','test');--ca sa nu mai dau extend,am ales sa initializez direct cu niste date temporare
  v_cursor_id  := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(v_cursor_id , 'select VALOARE ,DATA_NOTARE,NUME,PRENUME,NR_MATRICOL from STUDENTI s join note n' ||
  ' on s.ID=n.ID_STUDENT join CURSURI c on n.ID_CURS=c.ID where n.ID_CURS='||ID_MATERIE||'',DBMS_SQL.NATIVE);--join in care am toate coloanele necesare
  v_ok := DBMS_SQL.EXECUTE(v_cursor_id );
  DBMS_SQL.DESCRIBE_COLUMNS(v_cursor_id, v_total_coloane, v_rec_tab);

  v_nr_col := v_rec_tab.first;
  IF (v_nr_col IS NOT NULL) THEN
    LOOP
      col_type(v_nr_col):=gettype(v_rec_tab,v_nr_col);--retin tipul de date al coloanelor
      v_nr_col := v_rec_tab.next(v_nr_col);
      EXIT WHEN (v_nr_col IS NULL);
    END LOOP;
  END IF;
  DBMS_SQL.CLOSE_CURSOR(v_cursor_id);

  BEGIN --daca tabela este deja facuta,o scot
    v_cursor_id  := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(v_cursor_id, 'DROP TABLE '||table_name,DBMS_SQL.native);
    v_ok := DBMS_SQL.EXECUTE(table_name);
    DBMS_SQL.CLOSE_CURSOR(table_name);
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Catalogul nu exista,il creez...');
  END;

  v_cursor_id  := DBMS_SQL.OPEN_CURSOR; --imi construiesc tabela cu tipurile de date retinute in array(col_type)
  DBMS_SQL.PARSE(v_cursor_id,'CREATE TABLE '||table_name||'(VALOARE '||col_type(1)||
                             ',DATA_NOTARE '||col_type(2)||',NUME '||col_type(3)||',PRENUME '||col_type(4)||
                             ',NR_MATRICOL '||col_type(5)||')',DBMS_SQL.NATIVE);
  v_ok := DBMS_SQL.EXECUTE(v_cursor_id );
  DBMS_SQL.CLOSE_CURSOR(v_cursor_id);


   open curs;
   SELECT VALOARE ,DATA_NOTARE,NUME,PRENUME,NR_MATRICOL BULK COLLECT INTO lista_studenti FROM STUDENTI s join note n on s.ID=n.ID_STUDENT join CURSURI c on n.ID_CURS=c.ID;
   close curs;
  v_cursor_id  := DBMS_SQL.OPEN_CURSOR;--deschid alt cursor cu care parcurg datele din join si le bag in tabela nou creata
   for i in lista_studenti.first..lista_studenti.last loop
        if lista_studenti.exists(i) then
              DBMS_SQL.PARSE(v_cursor_id,'INSERT INTO '||table_name||' values('||lista_studenti(i).VALOARE||','''||lista_studenti(i).DATA_NOTARE||''','''||lista_studenti(i).NUME||
                                             ''','''||lista_studenti(i).PRENUME||''','''||lista_studenti(i).NR_MATRICOL||''')',DBMS_SQL.NATIVE);
              v_ok := DBMS_SQL.EXECUTE(v_cursor_id );

        end if;
    end loop;
  DBMS_SQL.CLOSE_CURSOR(v_cursor_id);
END;

BEGIN
    GENEREAZA_CATALOG_MATERIE(3);
end;
