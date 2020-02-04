use bpdata2;

drop table if exists rawbpdata;
create table rawbpdata (
  pat_id varchar(20) not null,
  pat_enc_csn_id int unsigned not null,
  recorded_time datetime not null,
  lnc_code varchar(10) not null,
  mapped_value_name varchar(50) not null,
  flo_meas_id varchar(50) not null,
  meas_value varchar(10) not null
);

load data local infile 'C:/Users/storer/tmp/2019 01-06.csv'
into table rawbpdata
fields terminated by ','
lines terminated by '\n';

drop table if exists bpdata;
create table bpdata (
  pat_id varchar(20) not null,
  pat_enc_csn_id int unsigned not null,
  recorded_time datetime not null,
  lnc_code varchar(10) not null,
  mapped_value_name varchar(50) not null,
  flo_meas_id varchar(50) not null,
  meas_value varchar(10) not null
);

insert into bpdata (pat_id, pat_enc_csn_id, recorded_time, lnc_code, mapped_value_name, flo_meas_id, meas_value)
select pat_id, pat_enc_csn_id, recorded_time, lnc_code, mapped_value_name, flo_meas_id, meas_value
from rawbpdata
where pat_id in (
  select pat_id
  from (
    select pat_id, count(*) as ct
    from rawbpdata
    group by pat_id
  ) t
  where ct >= 10 and ct <= 80
);

-- select pat_id, count(*) as ct from bpdata group by pat_id order by ct desc;

create view vwTop200Pts as select distinct pat_id from bpdata order by rand() limit 200;
delete from bpdata where pat_id not in (select pat_id from vwTop200Pts);
drop view vwTop200Pts;

drop table rawbpdata;

alter table bpdata add id int unsigned not null auto_increment primary key first;

drop procedure if exists deidentify;

delimiter //
create procedure deidentify(in tbl varchar(50), in field varchar(50), in deidentified_field varchar(50), in create_field tinyint(1))
begin
  declare field_val varchar(255);
  declare deidentified_val varchar(16);
  declare done int default false;
  declare c cursor for select distinct f from vw_deidentify_proc;
  declare continue handler for not found set done = true;

  if create_field then
    set @alter_sql = concat('alter table ', tbl, ' add ', deidentified_field, ' varchar(16) after ', field);
    prepare alter_stmt from @alter_sql;
    execute alter_stmt;
    deallocate prepare alter_stmt;
  end if;

  -- selecting fields where the deidentified version is null acts as a guard against timeouts when
  -- processing very large tables.  in such a case, *some* records will get updated, but not all of them,
  -- and any that haven't yet been *fully* processed will have at least one deidentified field with a
  -- null value.  so if the function times out, just rerun it.  that partial record will get reprocessed,
  -- as well as some number of other records, and eventually, with sufficent reruns, all records will
  -- be processed.
  set @create_view_sql = concat('create view vw_deidentify_proc as select ', field, ' as f from ', tbl, ' where ', deidentified_field, ' is null');
  prepare create_view_stmt from @create_view_sql;
  execute create_view_stmt;
  deallocate prepare create_view_stmt;

  open c;

  processFields: loop
    fetch c into field_val;
    if done = true then
      leave processFields;
	end if;

    set deidentified_val = left(sha2(concat(field_val, rand()), 256), 16);

    set @update_sql = concat('update ', tbl, ' set ', deidentified_field, ' = "', deidentified_val, '" where ', field, ' = "', field_val, '"');
    prepare update_stmt from @update_sql;
    execute update_stmt;
    deallocate prepare update_stmt;
  end loop processFields;

  close c;

  drop view vw_deidentify_proc;
end;
//
delimiter ;

call deidentify('bpdata', 'pat_id', 'pat_study_id', true);
call deidentify('bpdata', 'pat_enc_csn_id', 'pat_enc_csn_study_id', true);

-- now create an encounter table and populate it with associated study data
drop table if exists encounter;
create table encounter (
  pat_enc_csn_study_id varchar(16),
  pat_study_id varchar(16),
  start_date datetime,
  end_date datetime
);

insert into encounter (pat_enc_csn_study_id, pat_study_id, start_date, end_date)
select pat_enc_csn_study_id,
  pat_study_id,
--  min(recorded_time) as startDate,
--  max(recorded_time) as endDate
  concat(date(min(recorded_time)), ' 00:00:00') as start_date,
  concat(date(max(recorded_time)), ' 23:59:59') as end_date
from bpdata
group by pat_enc_csn_study_id, pat_study_id
order by pat_study_id, pat_enc_csn_study_id;


-- now create some lookup tables that will be used to populate the dummy data in the patient table
drop table if exists givenNames;
create table givenNames(
  id int not null auto_increment primary key,
  male varchar(20) not null,
  female varchar(20) not null
);

insert into givenNames (male, female) values("James", "Mary");
insert into givenNames (male, female) values("John", "Patricia");
insert into givenNames (male, female) values("Robert", "Jennifer");
insert into givenNames (male, female) values("Michael", "Linda");
insert into givenNames (male, female) values("William", "Elizabeth");
insert into givenNames (male, female) values("David", "Barbara");
insert into givenNames (male, female) values("Richard", "Susan");
insert into givenNames (male, female) values("Joseph", "Jessica");
insert into givenNames (male, female) values("Thomas", "Sarah");
insert into givenNames (male, female) values("Charles", "Karen");
insert into givenNames (male, female) values("Christopher", "Nancy");
insert into givenNames (male, female) values("Daniel", "Margaret");
insert into givenNames (male, female) values("Matthew", "Lisa");
insert into givenNames (male, female) values("Anthony", "Betty");
insert into givenNames (male, female) values("Donald", "Dorothy");
insert into givenNames (male, female) values("Mark", "Sandra");
insert into givenNames (male, female) values("Paul", "Ashley");
insert into givenNames (male, female) values("Steven", "Kimberly");
insert into givenNames (male, female) values("Andrew", "Donna");
insert into givenNames (male, female) values("Kenneth", "Emily");
insert into givenNames (male, female) values("Joshua", "Michelle");
insert into givenNames (male, female) values("George", "Carol");
insert into givenNames (male, female) values("Kevin", "Amanda");
insert into givenNames (male, female) values("Brian", "Melissa");
insert into givenNames (male, female) values("Edward", "Deborah");
insert into givenNames (male, female) values("Ronald", "Stephanie");
insert into givenNames (male, female) values("Timothy", "Rebecca");
insert into givenNames (male, female) values("Jason", "Laura");
insert into givenNames (male, female) values("Jeffrey", "Sharon");
insert into givenNames (male, female) values("Ryan", "Cynthia");
insert into givenNames (male, female) values("Jacob", "Kathleen");
insert into givenNames (male, female) values("Gary", "Helen");
insert into givenNames (male, female) values("Nicholas", "Amy");
insert into givenNames (male, female) values("Eric", "Shirley");
insert into givenNames (male, female) values("Stephen", "Angela");
insert into givenNames (male, female) values("Jonathan", "Anna");
insert into givenNames (male, female) values("Larry", "Brenda");
insert into givenNames (male, female) values("Justin", "Pamela");
insert into givenNames (male, female) values("Scott", "Nicole");
insert into givenNames (male, female) values("Brandon", "Ruth");
insert into givenNames (male, female) values("Frank", "Katherine");
insert into givenNames (male, female) values("Benjamin", "Samantha");
insert into givenNames (male, female) values("Gregory", "Christine");
insert into givenNames (male, female) values("Samuel", "Emma");
insert into givenNames (male, female) values("Raymond", "Catherine");
insert into givenNames (male, female) values("Patrick", "Debra");
insert into givenNames (male, female) values("Alexander", "Virginia");
insert into givenNames (male, female) values("Jack", "Rachel");
insert into givenNames (male, female) values("Dennis", "Carolyn");
insert into givenNames (male, female) values("Jerry", "Janet");
insert into givenNames (male, female) values("Tyler", "Maria");
insert into givenNames (male, female) values("Aaron", "Heather");
insert into givenNames (male, female) values("Jose", "Diane");
insert into givenNames (male, female) values("Henry", "Julie");
insert into givenNames (male, female) values("Douglas", "Joyce");
insert into givenNames (male, female) values("Adam", "Victoria");
insert into givenNames (male, female) values("Peter", "Kelly");
insert into givenNames (male, female) values("Nathan", "Christina");
insert into givenNames (male, female) values("Zachary", "Joan");
insert into givenNames (male, female) values("Walter", "Evelyn");
insert into givenNames (male, female) values("Kyle", "Lauren");
insert into givenNames (male, female) values("Harold", "Judith");
insert into givenNames (male, female) values("Carl", "Olivia");
insert into givenNames (male, female) values("Jeremy", "Frances");
insert into givenNames (male, female) values("Keith", "Martha");
insert into givenNames (male, female) values("Roger", "Cheryl");
insert into givenNames (male, female) values("Gerald", "Megan");
insert into givenNames (male, female) values("Ethan", "Andrea");
insert into givenNames (male, female) values("Arthur", "Hannah");
insert into givenNames (male, female) values("Terry", "Jacqueline");
insert into givenNames (male, female) values("Christian", "Ann");
insert into givenNames (male, female) values("Sean", "Jean");
insert into givenNames (male, female) values("Lawrence", "Alice");
insert into givenNames (male, female) values("Austin", "Kathryn");
insert into givenNames (male, female) values("Joe", "Gloria");
insert into givenNames (male, female) values("Noah", "Teresa");
insert into givenNames (male, female) values("Jesse", "Doris");
insert into givenNames (male, female) values("Albert", "Sara");
insert into givenNames (male, female) values("Bryan", "Janice");
insert into givenNames (male, female) values("Billy", "Julia");
insert into givenNames (male, female) values("Bruce", "Marie");
insert into givenNames (male, female) values("Willie", "Madison");
insert into givenNames (male, female) values("Jordan", "Grace");
insert into givenNames (male, female) values("Dylan", "Judy");
insert into givenNames (male, female) values("Alan", "Theresa");
insert into givenNames (male, female) values("Ralph", "Beverly");
insert into givenNames (male, female) values("Gabriel", "Denise");
insert into givenNames (male, female) values("Roy", "Marilyn");
insert into givenNames (male, female) values("Juan", "Amber");
insert into givenNames (male, female) values("Wayne", "Danielle");
insert into givenNames (male, female) values("Eugene", "Abigail");
insert into givenNames (male, female) values("Logan", "Brittany");
insert into givenNames (male, female) values("Randy", "Rose");
insert into givenNames (male, female) values("Louis", "Diana");
insert into givenNames (male, female) values("Russell", "Natalie");
insert into givenNames (male, female) values("Vincent", "Sophia");
insert into givenNames (male, female) values("Philip", "Alexis");
insert into givenNames (male, female) values("Bobby", "Lori");
insert into givenNames (male, female) values("Johnny", "Kayla");
insert into givenNames (male, female) values("Bradley", "Jane");


create table familyNames(
  id int not null auto_increment primary key,
  name varchar(20) not null
);

insert into familyNames (name) values("Smith");
insert into familyNames (name) values("Johnson");
insert into familyNames (name) values("Williams");
insert into familyNames (name) values("Brown");
insert into familyNames (name) values("Jones");
insert into familyNames (name) values("Miller");
insert into familyNames (name) values("Davis");
insert into familyNames (name) values("Garcia");
insert into familyNames (name) values("Rodriguez");
insert into familyNames (name) values("Wilson");
insert into familyNames (name) values("Martinez");
insert into familyNames (name) values("Anderson");
insert into familyNames (name) values("Taylor");
insert into familyNames (name) values("Thomas");
insert into familyNames (name) values("Hernandez");
insert into familyNames (name) values("Moore");
insert into familyNames (name) values("Martin");
insert into familyNames (name) values("Jackson");
insert into familyNames (name) values("Thompson");
insert into familyNames (name) values("White");
insert into familyNames (name) values("Lopez");
insert into familyNames (name) values("Lee");
insert into familyNames (name) values("Gonzalez");
insert into familyNames (name) values("Harris");
insert into familyNames (name) values("Clark");
insert into familyNames (name) values("Lewis");
insert into familyNames (name) values("Robinson");
insert into familyNames (name) values("Walker");
insert into familyNames (name) values("Perez");
insert into familyNames (name) values("Hall");
insert into familyNames (name) values("Young");
insert into familyNames (name) values("Allen");
insert into familyNames (name) values("Sanchez");
insert into familyNames (name) values("Wright");
insert into familyNames (name) values("King");
insert into familyNames (name) values("Scott");
insert into familyNames (name) values("Green");
insert into familyNames (name) values("Baker");
insert into familyNames (name) values("Adams");
insert into familyNames (name) values("Nelson");
insert into familyNames (name) values("Hill");
insert into familyNames (name) values("Ramirez");
insert into familyNames (name) values("Campbell");
insert into familyNames (name) values("Mitchell");
insert into familyNames (name) values("Roberts");
insert into familyNames (name) values("Carter");
insert into familyNames (name) values("Phillips");
insert into familyNames (name) values("Evans");
insert into familyNames (name) values("Turner");
insert into familyNames (name) values("Torres");
insert into familyNames (name) values("Parker");
insert into familyNames (name) values("Collins");
insert into familyNames (name) values("Edwards");
insert into familyNames (name) values("Stewart");
insert into familyNames (name) values("Flores");
insert into familyNames (name) values("Morris");
insert into familyNames (name) values("Nguyen");
insert into familyNames (name) values("Murphy");
insert into familyNames (name) values("Rivera");
insert into familyNames (name) values("Cook");
insert into familyNames (name) values("Rogers");
insert into familyNames (name) values("Morgan");
insert into familyNames (name) values("Peterson");
insert into familyNames (name) values("Cooper");
insert into familyNames (name) values("Reed");
insert into familyNames (name) values("Bailey");
insert into familyNames (name) values("Bell");
insert into familyNames (name) values("Gomez");
insert into familyNames (name) values("Kelly");
insert into familyNames (name) values("Howard");
insert into familyNames (name) values("Ward");
insert into familyNames (name) values("Cox");
insert into familyNames (name) values("Diaz");
insert into familyNames (name) values("Richardson");
insert into familyNames (name) values("Wood");
insert into familyNames (name) values("Watson");
insert into familyNames (name) values("Brooks");
insert into familyNames (name) values("Bennett");
insert into familyNames (name) values("Gray");
insert into familyNames (name) values("James");
insert into familyNames (name) values("Reyes");
insert into familyNames (name) values("Cruz");
insert into familyNames (name) values("Hughes");
insert into familyNames (name) values("Price");
insert into familyNames (name) values("Myers");
insert into familyNames (name) values("Long");
insert into familyNames (name) values("Foster");
insert into familyNames (name) values("Sanders");
insert into familyNames (name) values("Ross");
insert into familyNames (name) values("Morales");
insert into familyNames (name) values("Powell");
insert into familyNames (name) values("Sullivan");
insert into familyNames (name) values("Russell");
insert into familyNames (name) values("Ortiz");
insert into familyNames (name) values("Jenkins");
insert into familyNames (name) values("Gutierrez");
insert into familyNames (name) values("Perry");
insert into familyNames (name) values("Butler");
insert into familyNames (name) values("Barnes");
insert into familyNames (name) values("Fisher");

-- now create a patient table and populate it with associated study and dummy data

create table patient (
  id int not null auto_increment primary key,
  pat_study_id varchar(16) not null,
  given_name varchar(20) not null,
  family_name varchar(20) not null,
  birth_date date not null,
  gender varchar(6)
);

drop procedure if exists createPatients;

delimiter //
create procedure createPatients()
begin
  declare psid varchar(16);
  declare msd date;
  declare given_name varchar(20);
  declare family_name varchar(20);
  declare birth_date date;
  declare gender varchar(6);
  declare done int default false;
  declare c cursor for select pat_study_id, date(min(start_date)) as min_start_date from encounter group by pat_study_id;
  declare continue handler for not found set done = true;

  open c;

  processFields: loop
    fetch c into psid, msd;
    if done = true then
      leave processFields;
    end if;

    if floor(rand() * 2) = 0 then
      set gender = "male";
      select male into given_name from givenNames gn join (select ceil(rand() * max(id)) as randId from givenNames) x on gn.id=x.randId;
    else
      set gender = "female";
      select female into given_name from givenNames gn join (select ceil(rand() * max(id)) as randId from givenNames) x on gn.id=x.randId;
    end if;

    select name into family_name from familyNames fn join (select ceil(rand() * max(id)) as randId from familyNames) x on fn.id=x.randId;

    select date_add(msd, interval (rand() * 365 * 60 * -1) day) into birth_date;

    set @insert_sql = concat('insert into patient(pat_study_id, given_name, family_name, birth_date, gender) values("', psid, '", "',
      given_name, '", "', family_name, '", "', birth_date, '", "', gender, '")');

    prepare insert_stmt from @insert_sql;
    execute insert_stmt;
    deallocate prepare insert_stmt;
  end loop processFields;

  close c;
end;
//
delimiter ;

call createPatients();
