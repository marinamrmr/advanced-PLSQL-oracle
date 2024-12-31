DECLARE

CURSOR tables_id is 

SELECT t.TABLE_NAME, c.COLUMN_NAME
FROM user_tables t
INNER JOIN USER_TAB_COLUMNS c 
ON t.table_name = c.TABLE_NAME
INNER JOIN ALL_CONS_COLUMNS acc 
ON c.table_name = acc.table_name AND c.column_name = acc.column_name
INNER JOIN ALL_CONSTRAINTS ac 
ON acc.constraint_name = ac.constraint_name
WHERE  
ac.constraint_type = 'P' 
AND (SELECT COUNT(*) 
           FROM ALL_CONS_COLUMNS 
           WHERE constraint_name = ac.constraint_name) = 1
and c.DATA_TYPE = 'NUMBER';

  CURSOR seq_drop IS
  select SEQUENCE_NAME from USER_SEQUENCES;

  max_id NUMBER(12);

  BEGIN 

    for seq_record in seq_drop LOOP
    EXECUTE IMMEDIATE 'drop Sequence '|| seq_record.SEQUENCE_NAME;
    end loop;

for table_record in tables_id LOOP
-- Sequence
EXECUTE IMMEDIATE 'select max(' || table_record.COLUMN_NAME||') '|| 
' from '|| table_record.table_name into max_id;

EXECUTE IMMEDIATE
'CREATE SEQUENCE ' ||table_record.table_name||'_SEQ ' ||
' START WITH ' ||(max_id +1)  ||
  ' MAXVALUE 999999999999999999999999999 '||
  'MINVALUE 1 '||
  'NOCYCLE '||
  'CACHE 20 '||
  'NOORDER ';
  
-- Trigger
EXECUTE IMMEDIATE
'CREATE or replace TRIGGER '|| table_record.table_name||'_trg '||
'BEFORE INSERT ON ' ||
table_record.table_name ||
' REFERENCING NEW AS New OLD AS Old '||
'FOR EACH ROW '||
'BEGIN ' ||
-- For Toad:  Highlight column EMPLOYEE_ID
  ':new.'||table_record.COLUMN_NAME ||' := ' ||table_record.table_name||'_SEQ.nextval;'||
' END;';

end loop;

END;



