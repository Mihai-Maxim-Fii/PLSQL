/*
Sa se construiasca un view ca fiind joinul dintre tabelul studenti, note si cursuri, cu rolul de catalog: va contine numele si prenumele studentului, materia si nota pe care studentul a luat-o la acea materie.

Dupa cum va puteti da seama, operatii de genul INSERT nu sunt permise pe acest view din cauza ca ar trebui sa inserati datele in toate tabelele. Totusi, cu ajutorul unui trigger, puteti sa verificati existenta studentului (si sa il creati daca nu exista), existenta materiei (si sa o creati daca nu exista) sau a notei.


Construiti triggere pentru realizarea de operatii de tipul INSERT, UPDATE si DELETE pe viewul creat, care sa genereze date random atunci cand sunt adaugate informatii inexistente (de exemplu daca faceti insert cu un student inexistent, va genera un nr matricol, o bursa, grupa, an etc pentru acel student sau un numar de credite si un an, semestru pentru un curs, etc.)

Cazuri posibile:

Stergerea unui student si totodata a notelor sale (fara a folosi cascade constraints);
Inserarea unei note la un curs pentru un student inexistent cu adaugarea studentului;
Inserarea unei note la un curs pentru un curs inexistent - cu adaugarea cursului;
Inserarea unei note cand nu exista nici studentul si nici cursul.
Update la valoarea notei pentru un student - se va modifica valoarea campului updated_at. De asemenea, valoarea nu poate fi modificata cu una mai mica (la mariri se considera nota mai mare).
ex: INSERT INTO CATALOG VALUES ('Popescu', 'Mircea', 10, 'Yoga');
*/
--View-ul pe care l-am facut:
create or replace view catalog as
select nume as nume, prenume as prenume, VALOARE, TITLU_CURS
from studenti
         join note on STUDENTI.id = note.ID_STUDENT
         join CURSURI on CURSURI.id = NOTE.ID_CURS;
--Trigger-ul cu care sterg un student.
CREATE OR REPLACE TRIGGER delete_student
    INSTEAD OF delete
    ON catalog
declare
    --idd number;
BEGIN
    --select STUDENTI.id into idd from STUDENTI where nume=:OLD.NUME and prenume=:OLD.PRENUME;
    -- dbms_output.put_line('Stergem pe:' ||:OLD.nume||' '||:OLD.prenume||' '||idd); --DE CE NU MERGE? :))
    dbms_output.put_line('Stergem pe:' || :OLD.nume || ' ' || :OLD.prenume);
    delete from note where id_student in (select id from studenti where nume = :OLD.nume and prenume = :OLD.prenume);
    delete
    from prieteni
    where id_student1 in (select id from studenti where nume = :OLD.nume and prenume = :OLD.prenume);
    delete
    from prieteni
    where id_student2 in (select id from studenti where nume = :OLD.nume and prenume = :OLD.prenume);
    delete from studenti where id in (select id from studenti where nume = :OLD.nume and prenume = :OLD.prenume);
END ;
--Trigger-ul in care fac update:
create or replace trigger update_student
instead of update on catalog
begin
    if(:OLD.VALOARE>:NEW.VALOARE)THEN
        DBMS_OUTPUT.PUT_LINE('Nu se poate face update cu o nota mai mica!');
    elsif(:OLD.VALOARE<:NEW.VALOARE)THEN
        UPDATE NOTE --Update la valoarea notei
        set VALOARE=:NEW.VALOARE WHERE ID_STUDENT in(select id from studenti where nume=:OLD.nume and prenume=:OLD.prenume)
        and ID_CURS in(select id from CURSURI where titlu_curs=:OLD.titlu_curs);
        update NOTE --Update la data notarii
        set UPDATED_AT=sysdate where id_student in (select id from studenti where nume=:OLD.nume and prenume=:OLD.prenume)
        and ID_CURS in (select id from CURSURI where titlu_curs=:OLD.titlu_curs);
    end if;

end;

CREATE OR REPLACE TRIGGER insert_student
    INSTEAD OF insert
    ON catalog
DECLARE
    existsStudent number; --Variabila cu care vad daca exista studentul
    existsCourse  number; --Variabila cu care vad daca exista cursul
    idStud        number; --Variabila in care retin id-ul studentului ,daca exista sau  urmatorul id al studentului pe care trebuie sa il inserez
    idCurs        number; --La fel ca idStud,doar ca pentru curs
    idMax         number; --Variabila cu care determin care ar fi urmatorul id de student sau curs ce ar putea fi inserat.
    randomDate    date; --Variabila in care tin minte o data de nastere generata random
BEGIN
    select count(*) into existsStudent from studenti where nume = :NEW.nume and prenume = :NEW.prenume; --Vad daca exista studentul
    select count(*) into existsCourse from CURSURI where TITLU_CURS = :NEW.TITLU_CURS;--Vad daca exista cursul

    if (existsStudent > 0 and existsCourse > 0) then --Exista si studentul si cursul

        DBMS_OUTPUT.PUT_LINE('Exista si studentul si cursul');
        select studenti.id into idStud from STUDENTI where nume = :NEW.nume and prenume = :NEW.prenume;
        select cursuri.id into idCurs from CURSURI where TITLU_CURS = :NEW.titlu_curs;
        select max(id) into idMax from NOTE;
        idMax := idMax + 1;

        insert into NOTE(ID, ID_STUDENT, ID_CURS, VALOARE) VALUES (idMax, idStud, idCurs, :NEW.valoare);
    end if;

    if (existsStudent > 0 and existsCourse < 1) then--Exista studentul,dar nu exista cursul
        DBMS_OUTPUT.PUT_LINE('Exista studentul,dar nu exista cursul');
        select studenti.id into idStud from STUDENTI where nume = :NEW.nume and prenume = :NEW.prenume;
        select max(id) into idCurs from CURSURI;
        idCurs := idCurs + 1;
        insert into CURSURI(ID, TITLU_CURS, AN, SEMESTRU, CREDITE, CREATED_AT, UPDATED_AT)
        values (idCurs, :NEW.TITLU_CURS, DBMS_RANDOM.VALUE(1, 3), DBMS_RANDOM.VALUE(1, 2), DBMS_RANDOM.VALUE(4, 6),
                sysdate, sysdate);
        select max(id) into idMax from note;
        idMax := idMax + 1;

        insert into NOTE(ID, ID_STUDENT, ID_CURS, VALOARE) VALUES (idMax, idStud, idCurs, :NEW.valoare);
        end if;

        if(existsCourse>0 and existsStudent < 1) then--Exista cursul,dar nu exista studentul
        DBMS_OUTPUT.PUT_LINE('Exista cursul,dar nu exista studentul');
        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2454467,2454467+364)),'J') into randomDate FROM DUAL;
        select max(id) into idStud from STUDENTI;
        idStud := idStud + 1;
        insert into STUDENTI(ID,NR_MATRICOL,NUME,PRENUME,AN,GRUPA,BURSA,DATA_NASTERE,EMAIL,CREATED_AT,UPDATED_AT)
        VALUES (idStud,DBMS_RANDOM.STRING('A',6),:NEW.NUME,:NEW.PRENUME,DBMS_RANDOM.VALUE(1,3)
        ,Concat(DBMS_RANDOM.STRING('U',1),round(DBMS_RANDOM.VALUE(1,7))),DBMS_RANDOM.VALUE(300,600),
        randomDate,DBMS_RANDOM.STRING('A',15),sysdate,sysdate);
        select max(id) into idMax from NOTE;
        idMax:=idMax+1;
        select ID into idCurs from CURSURI where TITLU_CURS=:NEW.TITLU_CURS;

        insert into NOTE(ID, ID_STUDENT, ID_CURS, VALOARE) VALUES (idMax, idStud, idCurs, :NEW.valoare);
        end if;

        if(existsCourse<1 and existsStudent<1) then --Nu exista nici cursul si nici studentul
        --Partea in care adaug cursul
        DBMS_OUTPUT.PUT_LINE('Nu exista nici cursul si nici studentul');
        SELECT TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2454467,2454467+364)),'J') into randomDate FROM DUAL;
        select max(id) into idStud from STUDENTI;
        idStud := idStud + 1;
        insert into STUDENTI(ID,NR_MATRICOL,NUME,PRENUME,AN,GRUPA,BURSA,DATA_NASTERE,EMAIL,CREATED_AT,UPDATED_AT)
        VALUES (idStud,DBMS_RANDOM.STRING('A',6),:NEW.NUME,:NEW.PRENUME,DBMS_RANDOM.VALUE(1,3)
        ,Concat(DBMS_RANDOM.STRING('U',1),round(DBMS_RANDOM.VALUE(1,7))),DBMS_RANDOM.VALUE(300,600),
        randomDate,DBMS_RANDOM.STRING('A',15),sysdate,sysdate);

        --Partea in care adaug studentul
        select studenti.id into idStud from STUDENTI where nume = :NEW.nume and prenume = :NEW.prenume;
        select max(id) into idCurs from CURSURI;
        idCurs := idCurs + 1;
        insert into CURSURI(ID, TITLU_CURS, AN, SEMESTRU, CREDITE, CREATED_AT, UPDATED_AT)
        values (idCurs, :NEW.TITLU_CURS, DBMS_RANDOM.VALUE(1, 3), DBMS_RANDOM.VALUE(1, 2), DBMS_RANDOM.VALUE(4, 6),
                sysdate, sysdate);
        select max(id) into idMax from note;
        idMax := idMax + 1;

        insert into NOTE(ID, ID_STUDENT, ID_CURS, VALOARE) VALUES (idMax, idStud, idCurs, :NEW.valoare);

    end if;

END;

--Chestii de testat:
--Nu exista nici studentul si nici cursul:
INSERT INTO CATALOG VALUES ('NumeRandom', 'PrenumeRandom', 6, 'Sport');
select nume as nume, prenume as prenume, VALOARE, TITLU_CURS
from studenti
         join note on STUDENTI.id = note.ID_STUDENT
         join CURSURI on CURSURI.id = NOTE.ID_CURS
where nume='NumeRandom' and prenume='PrenumeRandom';

--Exista studentul,dar nu exista cursul:
INSERT INTO CATALOG VALUES ('NumeRandom','PrenumeRandom',7,'Geografie');
select nume as nume, prenume as prenume, VALOARE, TITLU_CURS
from studenti
         join note on STUDENTI.id = note.ID_STUDENT
         join CURSURI on CURSURI.id = NOTE.ID_CURS
where nume='NumeRandom' and prenume='PrenumeRandom';

--Nu exista studentul,dar exista cursul:
INSERT INTO CATALOG VALUES('NumeRandom1','PrenumeRandom1',8,'Geografie');
select nume as nume, prenume as prenume, VALOARE, TITLU_CURS
from studenti
         join note on STUDENTI.id = note.ID_STUDENT
         join CURSURI on CURSURI.id = NOTE.ID_CURS
where nume='NumeRandom1' and prenume='PrenumeRandom1';

--Update la nota,nereusit:
UPDATE catalog set valoare = 5 where titlu_curs='Sport' and nume='NumeRandom' and prenume='PrenumeRandom';
select nume as nume, prenume as prenume, VALOARE, TITLU_CURS
from studenti
         join note on STUDENTI.id = note.ID_STUDENT
         join CURSURI on CURSURI.id = NOTE.ID_CURS
where nume='NumeRandom' and prenume='PrenumeRandom';

--Update la note,reusit:
UPDATE catalog set valoare = 7 where titlu_curs='Sport' and nume='NumeRandom' and prenume='PrenumeRandom';
select nume as nume, prenume as prenume, VALOARE, TITLU_CURS
from studenti
         join note on STUDENTI.id = note.ID_STUDENT
         join CURSURI on CURSURI.id = NOTE.ID_CURS
where nume='NumeRandom' and prenume='PrenumeRandom';

--Stergere student;
delete from catalog where nume='NumeRandom' and prenume='PrenumeRandom';
delete from catalog where nume='NumeRandom1' and prenume='PrenumeRandom1';
select nume as nume, prenume as prenume, VALOARE, TITLU_CURS
from studenti
         join note on STUDENTI.id = note.ID_STUDENT
         join CURSURI on CURSURI.id = NOTE.ID_CURS
where nume='NumeRandom' and prenume='PrenumeRandom';


rollback;



