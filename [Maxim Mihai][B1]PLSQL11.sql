/*
Intr-un cod PLSQL sa se realizeze statistici la nivel de utilizator despre obiectele create(tabele, view, indecsi, type, package, proceduri sau functii) utilizand dictionarul de date. Se vor afisa pentru fiecare tip in parte ce obiecte a creat utilizatorul, si pentru fiecare obiect in parte se vor afisa informatii specifice. De exemplu pentru un tabel se vor afisa numele, cate inregistrari are, daca are constrangeri, indecsi si care sunt acestia, tipul de constrangere si coloanele implicate, daca este nested table, iar pentru o functie, de exemplu, numele, nr de linii de cod, daca este determinista.
*/

DECLARE
    CURSOR indexes_user IS SELECT * FROM USER_INDEXES;--cursor pentru fiecare componenta de afisat
    CURSOR objects IS SELECT * FROM USER_OBJECTS;
    CURSOR triggers IS SELECT * FROM USER_TRIGGERS;
    CURSOR procedures IS SELECT * FROM USER_PROCEDURES;
    CURSOR types IS SELECT * FROM USER_TYPES;
    CURSOR views_user IS SELECT * FROM USER_VIEWS;
    CURSOR tables IS SELECT c.constraint_name, c.constraint_type, c.TABLE_NAME, cc.COLUMN_NAME, t.num_rows, t.nested from USER_CONSTRAINTS c join USER_CONS_COLUMNS cc on c.CONSTRAINT_NAME = c.CONSTRAINT_NAME and c.TABLE_NAME = cc.TABLE_NAME-- sa vad constrangeri + detalii despre coloanele pe care le afecteaza,de aia join-ul
    join USER_TABLES t on c.TABLE_NAME = t.TABLE_NAME;
    aux number;
    BEGIN
    DBMS_OUTPUT.PUT_LINE('-------TABLES-------' );
    DBMS_OUTPUT.PUT_LINE(LPAD('Name', 10) || CHR(9) || LPAD('Rows', 10) || CHR(9) || LPAD('Nested', 10) || CHR(9) || CHR(9) || LPAD('ConstraintName', 10) || CHR(9) || CHR(9) || LPAD('ConstraintType', 15) || CHR(9) || CHR(9) || LPAD('ColumnConstrainted', 20));
    FOR row IN tables LOOP
        DBMS_OUTPUT.PUT_LINE(LPAD(row.TABLE_NAME, 10) || CHR(9) || LPAD(row.NUM_ROWS, 10) || CHR(9) || LPAD(row.NESTED,10) || CHR(9) || CHR(9) || LPAD(row.CONSTRAINT_NAME, 10) || CHR(9) || CHR(9) ||LPAD(row.CONSTRAINT_TYPE,15) || CHR(9) || CHR(9) || LPAD(row.COLUMN_NAME, 15));
    end loop;


    DBMS_OUTPUT.PUT_LINE('-------OBJECTS-------');
    DBMS_OUTPUT.PUT_LINE(LPAD('Name', 10) || CHR(9) || LPAD('Type', 10));
    FOR row IN objects LOOP
        DBMS_OUTPUT.PUT_LINE(LPAD(row.OBJECT_NAME, 15) || CHR(9) || LPAD(row.OBJECT_TYPE, 15));
        end loop;

    DBMS_OUTPUT.PUT_LINE('-------PROCEDURES-------' );
    DBMS_OUTPUT.PUT_LINE(LPAD('Name', 10) || CHR(9) || LPAD('LinesOfCode', 15) || CHR(9) || LPAD('Deterministic', 15));
    FOR row IN procedures LOOP
        select count(*) into aux from user_source where name = row.OBJECT_NAME;
        DBMS_OUTPUT.PUT_LINE(LPAD(row.OBJECT_NAME,10) || CHR(9) || LPAD(aux, 15) || CHR(9) || LPAD(row.DETERMINISTIC, 15));
        end loop;

    DBMS_OUTPUT.PUT_LINE('-------TYPES-------');
    DBMS_OUTPUT.PUT_LINE(LPAD('Name', 10) || CHR(9) || LPAD('TypeID', 15));
    FOR row IN types LOOP
        DBMS_OUTPUT.PUT_LINE(LPAD(row.TYPE_NAME, 10) || CHR(9) || LPAD(row.TYPEID, 15));
        end loop;

    DBMS_OUTPUT.PUT_LINE('-------VIEWS-------' );
    DBMS_OUTPUT.PUT_LINE(LPAD('Name', 10) || CHR(9) || LPAD('TextLength', 15) || CHR(9) || LPAD('Text', 50));
    FOR row IN views_user LOOP
        DBMS_OUTPUT.PUT_LINE(LPAD(row.VIEW_NAME, 10) || CHR(9) || LPAD(row.TEXT_LENGTH, 15) || CHR(9) || CHR(9) || LPAD(row.TEXT, 100) );
        end loop;

    DBMS_OUTPUT.PUT_LINE('-------TRIGGERS-------' );
    DBMS_OUTPUT.PUT_LINE(LPAD('Name', 10) || CHR(9) || LPAD('Type', 20));
    FOR row IN triggers LOOP
        DBMS_OUTPUT.PUT_LINE(LPAD(row.TRIGGER_NAME, 10) || CHR(9) || LPAD(row.TRIGGER_TYPE, 20));
        end loop;

    DBMS_OUTPUT.PUT_LINE('-------INDEXES-------' );
    DBMS_OUTPUT.PUT_LINE(LPAD('Name', 10) || CHR(9) || LPAD('Type', 15));
    FOR row IN indexes_user LOOP
        DBMS_OUTPUT.PUT_LINE(LPAD(row.INDEX_NAME, 10) || CHR(9) || LPAD(row.INDEX_TYPE, 15));
        end loop;

END;

