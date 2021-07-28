/*
Creati un script PLSQL care sa exporte pe calculatorul votru tabela note intr-un fisier de tip csv (Comma Separated Values) si un al doilea script care plecand de la un csv, sa recreeze tabela note. Intre cele doua operatii se va executa "delete from note".
*/

--Am 2 proceduri:prima scrie fisierul,a doua imi baga datele din fisier in tabel
CREATE OR REPLACE PROCEDURE writeGradesToFile AS --cu asta scriu in fisier,am parcurs tabelul cu un cursor
   CURSOR noteCRS IS SELECT * FROM note;
   TYPE linie_nota IS TABLE OF note%ROWTYPE;
   lista_note linie_nota;
   v_fisier UTL_FILE.FILE_TYPE;
BEGIN
   v_fisier:=UTL_FILE.FOPEN('MYDIR','myfile.csv','W');
   open noteCRS;
   SELECT * BULK COLLECT INTO lista_note FROM note;
   close noteCRS;
    for i in lista_note.first..lista_note.last loop
        if lista_note.exists(i) then
         UTL_FILE.PUT_LINE(v_fisier,lista_note(i).ID||','||lista_note(i).ID_STUDENT||','||lista_note(i).ID_CURS||','
                          ||lista_note(i).VALOARE||','||lista_note(i).DATA_NOTARE||','||lista_note(i).CREATED_AT||','
                          ||lista_note(i).UPDATED_AT);--pun elementele cu virgula intre ele,ca sa fie format csv
        end if;
    end loop;
    DBMS_OUTPUT.PUT_LINE('Numar note: '||lista_note.COUNT);
END;

CREATE OR REPLACE PROCEDURE getGradesFromFile AS
  v_fisier UTL_FILE.FILE_TYPE;
  v_sir VARCHAR2(1000);
BEGIN
  v_fisier:=UTL_FILE.FOPEN('MYDIR','myfile.csv','R');
  loop
  UTL_FILE.GET_LINE(v_fisier,v_sir);
      insert into note(ID,ID_STUDENT,ID_CURS,VALOARE,DATA_NOTARE,CREATED_AT,UPDATED_AT)
        values (regexp_substr(v_sir, '[^,]+', 1, 1),
                regexp_substr(v_sir, '[^,]+', 1, 2),
                regexp_substr(v_sir, '[^,]+', 1, 3),
                regexp_substr(v_sir, '[^,]+', 1, 4),
                regexp_substr(v_sir, '[^,]+', 1, 5),
                regexp_substr(v_sir, '[^,]+', 1, 6),
                regexp_substr(v_sir, '[^,]+', 1, 7));--de aici m-am inspirat:https://stackoverflow.com/questions/56329368/oracle-utl-file-read-csv-file-lines
  end loop;
  EXCEPTION
WHEN no_data_found THEN--nu stiu de cate ori trebuie sa fac loop asa ca fac exceptie
  UTL_FILE.FCLOSE(v_fisier);
end;

DECLARE
BEGIN
writeGradesToFile();
getGradesFromFile();
end;

delete from note;
select * from note;
select count(*) from note;
rollback ;