use bpdata2;


-- patients
drop table if exists patient;
create table patient (
  id int not null auto_increment primary key,
  pat_id varchar(15) unique not null,
  sex varchar(6),
  race varchar(30),
  ethnic_group varchar(15),
  age int,
  given_name varchar(20),
  family_name varchar(20),
  birth_date date
);

insert into patient(pat_id, sex, race, ethnic_group, age)
  select p.pat_id, h.sex, h.race, h.ethnic_group, h.age
  from (
    select distinct pat_id from (
      select pat_id from ae_pt2
      union
      select pat_id from hodx2
      union
      select pat_id from htn_meds_samp
      union
      select pat_id from htn_out2
      union
      select pat_id from np_pt2
    ) t
  ) p
  left join hodx2 h on h.pat_id=p.pat_id;

call deidentify('patient', 'pat_id', 'pat_study_id', true);
-- call deidentify('bpdata', 'pat_enc_csn_id', 'pat_enc_csn_study_id', true);

-- now create an encounter table and populate it with associated study data
drop table if exists encounter;
create table encounter (
  pat_enc_csn_id varchar(16),
  pat_id varchar(16),
  start_date datetime,
  end_date datetime
);

-- ideally replace these with actual PCP encounters
insert into encounter (pat_enc_csn_id, pat_id, start_date, end_date)
select pat_enc_csn_id,
  pat_id,
--  min(recorded_time) as startDate,
--  max(recorded_time) as endDate
  concat(date(min(recorded_time)), ' 00:00:00') as start_date,
  concat(date(max(recorded_time)), ' 23:59:59') as end_date
from bpdata
group by pat_enc_csn_id, pat_id
order by pat_id, pat_enc_csn_id;


call deidentify('encounter', 'pat_enc_csn_id', 'pat_enc_csn_study_id', true);
select * from encounter;

-- now create a patient table and populate it with associated study and dummy data


drop procedure if exists fillInPatients;

delimiter //
create procedure fillInPatients()
begin
  declare _id int;
  declare _sex varchar(6);
  declare _age int;
  declare given_name varchar(20);
  declare family_name varchar(20);
  declare day_shift int;
  declare birth_date date;
  declare done int default false;
  declare c cursor for select id, sex, age from patient where sex is not null and age is not null;
  declare continue handler for not found set done = true;

  open c;

  processFields: loop
    fetch c into _id, _sex, _age;

    if done = true then
      leave processFields;
    end if;

    if lower(_sex) = 'male' then
      select male into given_name from givenNames gn join (select ceil(rand() * max(id)) as randId from givenNames) x on gn.id=x.randId;
    else
      select female into given_name from givenNames gn join (select ceil(rand() * max(id)) as randId from givenNames) x on gn.id=x.randId;
    end if;

    select name into family_name from familyNames fn join (select ceil(rand() * max(id)) as randId from familyNames) x on fn.id=x.randId;

    set day_shift = ceil(rand() * 180); -- +/- 6 months 
	if (floor(rand() * 2) = 0) then
      set day_shift = day_shift * -1;
	end if;
    
    select date_add(now(), interval (_age * 365 * -1) + day_shift day) into birth_date;

	set @update_sql = concat('update patient set given_name="', given_name, '", family_name="', family_name, '", birth_date="', 
      birth_date, '" where id=', _id);
    prepare update_stmt from @update_sql;
    execute update_stmt;
    deallocate prepare update_stmt;
  end loop processFields;

  close c;
end;
//
delimiter ;

call fillInPatients();


select * from patient;