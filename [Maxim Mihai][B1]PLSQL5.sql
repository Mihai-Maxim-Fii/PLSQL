/*Dupa cum puteti observa din scriptul de creare, toti studentii au note la materia logica. Asta inseamna ca o noua nota nu ar trebui sa fie posibil sa fie inserata pentru un student si pentru aceasta materie (nu poti avea doua note la aceeasi materie). Construiti o constrangere care sa arunce o exceptie cand regula de mai sus este incalcata (poate fi unicitate pe campurile id_student+id_curs, index unique peste aceleasi doua campuri sau cheie primara peste cele doua).

Prin intermediul unui script PLSQL incercati de 1 milion de ori sa inserati o nota la materia logica. Pentru aceasta aveti doua metode:

- sa vedeti daca exista nota (cu count, cum deja ati mai facut) pentru studentul X la logica si sa inserati doar daca nu exista.
- sa incercati sa inserati si sa prindeti exceptia in caz ca aceasta este aruncata.
Implementati ambele metode si observati timpii de executie pentru fiecare dintre ele. (3pct)
Cand veti preda rezultatul, scrieti intr-un comentariu timpii obtinuti pentru fieecare metoda in parte.

Construiti o functie PLSQL care sa primeasca ca parametri numele si prenumele unui student si care sa returneze media si, in caz ca nu exista acel student (dat prin nume si prenume) sa arunce o exceptie definita de voi. Dintr-un bloc anonim care contine intr-o structura de tip colectie mai multe nume si prenume (trei studenti existenti si trei care nu sunt in baza de date), apelati functia cu diverse valori. Prindeti exceptia si afisati un mesaj corespunzator atunci cand studentul nu exista sau afisati valoarea returnata de functie daca studentul exista. (2pct) */

SET SERVEROUTPUT ON
--ADAUGARE CONSTRAINT
ALTER TABLE NOTE ADD CONSTRAINT
    uc_note unique  (ID_STUDENT,ID_CURS);

--FIRST METHOD(cea in care verific daca studentul are nota la logica,timp de rulare: 16 s 728 ms!)
declare
begin
try_insert_grade_firstmethod('50');
end;
--SECOND METHOD(cea in care incerc sa adaug fara sa verific inainte,timp de rulare: 1 m 57 s 959 ) =>prima metoda e mai rapida!
declare
  result varchar2(40);
  try_count integer;
begin
  try_count:=0;
  while(try_count<10)--ca sa imi faca de 1 mil de ori
  LOOP
  result:=try_insert_grade_secondmethod('50');
  try_count:=try_count+1;
  end LOOP;
  DBMS_OUTPUT.PUT_LINE(result);
end;
--AVG CALCULATOR(Partea a 2 a din tema)
declare
result number(4,2);
TYPE numeTabel IS TABLE OF varchar2(15);
TYPE prenumeTabel IS TABLE OF varchar2(15);--declar cele doua colectii
nume numeTabel;
prenume prenumeTabel;
indexer number;
begin
nume:=numeTabel('Simon','abc','Cernescu','mmf','Pojar','mmo'); -- le initializez cu nume si prenume,unele care nu exista
prenume:=prenumeTabel('Diana Sabina','xyz','Ciprian Darius','rpg','Eleonora','lex');
indexer:=1;
while(indexer<=6)--pentru ca sunt 6 nume si prenume
LOOP
 DBMS_OUTPUT.PUT_LINE(get_student_avg(nume(indexer),prenume(indexer)));
 indexer:=indexer+1;
 end loop;
end;
--ALL FUNCTIONS/PROCEDURES
CREATE OR REPLACE PROCEDURE try_insert_grade_firstmethod (v_id studenti.id%type)--PRIMA METODA
as
   incrementer integer; --id-ul in tabela de note este cheie primara,asa ca tre sa ma asigur ca gasesc un id unic inainte sa fac insert.
   count_note integer; --cu variabila asta vad daca are sau nu nota la logica
   try_count integer; --variabila cu care iterez prin while
BEGIN
   try_count:=1;
   while(try_count<=1000000)
   LOOP
       try_count:=try_count+1;
       select count(*) into count_note from studenti s join note n on s.ID=n.ID_STUDENT join cursuri c on n.ID_CURS=c.ID where s.ID=v_id and c.TITLU_CURS='LogicÃ£';
       if(count_note=0)then
        select max(id) into incrementer from note;--ca sa inserez cu id unic
        insert into NOTE(ID,ID_STUDENT,ID_CURS,VALOARE) VALUES (incrementer+1,V_ID,1,10);
        end if;
   end loop;

END try_insert_grade_firstmethod;

CREATE OR REPLACE FUNCTION try_insert_grade_secondmethod(v_id studenti.id%type)--A DOUA METODA
RETURN VARCHAR2
as
    incrementer integer; --la fel ca pentru prima medota,am nevoie de id unic
    done_message varchar2(60);
BEGIN

   select max(id) into incrementer from note;
   insert into NOTE(ID,ID_STUDENT,ID_CURS,VALOARE) VALUES (incrementer+1,V_ID,1,10);
   done_message:='Done';--nu se ajunge niciodata aici
   RETURN done_message;

EXCEPTION
  WHEN  DUP_VAL_ON_INDEX THEN
  RETURN 'Error,grade already assigned!';
END try_insert_grade_secondmethod;

CREATE OR REPLACE FUNCTION get_student_avg(v_nume studenti.NUME%type,v_prenume studenti.PRENUME%type)
RETURN varchar2
as
    return_value NUMBER(4,2);--variabila in care o sa bag media studentului
    listed number;--variabila cu care vad daca studentul exista sau nu
    student_inexistent EXCEPTION;--exceptia cand studentul nu exista
    student_does_not_have_grades EXCEPTION;--exceptia cand studentul nu are note
BEGIN
    listed:=0;
    select count(*) into listed from studenti where nume=v_nume and PRENUME=v_prenume;
    if listed=0 then--daca se gasesc 0 studenti cu numele si prenumele respectiv inseamna ca nu exista studentul
    raise student_inexistent;
    end if;
    --daca exista studentul se poate calcula media
    select avg(n.valoare) into return_value from studenti s join note n on s.id=n.ID_STUDENT group by s.nume,s.PRENUME having s.NUME=v_nume and s.PRENUME=v_prenume;
    --daca media e 0=>nu are note
    if listed=0 then
    raise student_does_not_have_grades;
    end if;
    return v_nume||' '||v_prenume||'are media:'||return_value;
EXCEPTION
    when student_inexistent then --=>as fi putut face cu raise raise_application_error (-20001,...)dar nu puteam sa trec prin lista
    DBMS_OUTPUT.PUT_LINE(v_nume||' '||v_prenume||' este inexistent!');
    return 0;
    when student_does_not_have_grades then
    DBMS_OUTPUT.PUT_LINE(v_nume||' '||v_prenume||' nu are note!');
    return 0;
end;

