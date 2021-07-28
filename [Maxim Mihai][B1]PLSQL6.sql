set serveroutput on;



/*Creati o clasa la alegere care sa contina macar doua metode si un constructor explicit ( in afara celuil implicit). Tot in cadrul acestei clase scrieti si o metoda de comparare a doua obiecte (MAP sau ORDER), inserati o serie de obiecte intr-o tabela si incercati sa le ordonati dupa coloana in care este introdus obiectul pentru a demonstra ca obiectele pot fi intr-adevar comparate unul cu celalalt.

Construiti o subclasa pentru clasa de mai sus. Suprascrieti macar o metoda din cele existente in clasa de baza.

Construiti un bloc anonim in care sa demonstrati functionalitatea claselor construite.*/

--Am facut o clasa lista_cursuri ce are ca atribute titlul,anul,semestrul si nr de credite al unui curs.
--Clasa are 2 metode(proceduri) afiseaza_titlu si afiseaza_titlu_credite:Prima afiseaza doar numele cursului si cealalta imi afiseaza si creditele
--Clasa are 2 constructori:cel implicit si unul care imi ia doar titlul cursului si numarul de credite
--Mai am o clasa:lista_cursuri_extins care are ca parinte lista_cursuri si adauga un nou atribut:rata de promovabilitate
--Ca sa pot compara obiectele am folosit MAP pe nr de credite.
--Ca sa sortez obiectele de tip lisa_curs am facut un tabel care retine obiecte de acest tip,le-am adaugat si am facut un select statement pe care il ordonez dupa tipul obiectului.
create table curs_credite(curs lista_cursuri);--tabelul in care retin obiectele de tip lista_cursuri
DECLARE
   v_curs_full lista_cursuri;
   v_curs_extins lista_cursuri_extins;
   v_curs1 lista_cursuri;
   v_curs2 lista_cursuri;
   v_curs3 lista_cursuri;
   v_curs4 lista_cursuri;
BEGIN
   v_curs_full:=lista_cursuri('Baze de date',2,1,5);--aici intra constructor-ul implicit
   v_curs_extins:=lista_cursuri_extins('Baze de date',2,1,5,30);--obiect derivat din lista_cursuri,se adauga un nou atribut:promovabilitate
   v_curs1 := lista_cursuri('LogicÃ£',3);
   v_curs2 := lista_cursuri('Sisteme de operare',1);
   v_curs3:=lista_cursuri('MatematicÃ£',6);
   v_curs4:=lista_cursuri('Tehnologii WEB',0);
   v_curs_extins.AFISEAZA_TITLU();--metoda 
   insert into curs_credite(curs) values (v_curs1);
   insert into curs_credite(curs) values (v_curs2);
   insert into curs_credite(curs) values (v_curs3);
   insert into curs_credite(curs) values (v_curs4);
END;
select * from curs_credite order by curs;
CREATE OR REPLACE TYPE lista_cursuri AS OBJECT
(titlu varchar2(52),
 an number(1),
 semestru number(1),
 credite number(2),
 map member FUNCTION nr_de_credite RETURN NUMBER,
 NOT FINAL member procedure afiseaza_titlu,
 NOT FINAL member procedure afiseaza_titlu_credite,
 CONSTRUCTOR FUNCTION lista_cursuri(titlu varchar2, credite number)
    RETURN SELF AS RESULT
) NOT FINAL;

CREATE OR REPLACE TYPE BODY lista_cursuri AS
    CONSTRUCTOR FUNCTION lista_cursuri(titlu varchar2, credite number)
    RETURN SELF AS RESULT
  AS
  BEGIN
    SELF.titlu := titlu;
    SELF.credite := credite;
    RETURN;
  END;
 map member FUNCTION nr_de_credite RETURN NUMBER
  AS
    BEGIN
    RETURN SELF.CREDITE;
  END;


   MEMBER PROCEDURE afiseaza_titlu IS
   BEGIN
       DBMS_OUTPUT.PUT_LINE('Cursul se numeste:'||titlu);
   END afiseaza_titlu;

   MEMBER PROCEDURE afiseaza_titlu_credite IS
   BEGIN
       DBMS_OUTPUT.PUT_LINE('Cursul se numeste:'||titlu||' si are:'||credite||' credite');
   END afiseaza_titlu_credite;

END;

  CREATE OR REPLACE TYPE lista_cursuri_extins UNDER lista_cursuri
(
   promovabilitate number,
   OVERRIDING member procedure afiseaza_titlu
);

CREATE OR REPLACE TYPE BODY lista_cursuri_extins AS
    OVERRIDING MEMBER PROCEDURE afiseaza_titlu IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Cursul se numeste:'||titlu||' si are rata de promovabilitate:'||promovabilitate||'%');
    END afiseaza_titlu;
END;