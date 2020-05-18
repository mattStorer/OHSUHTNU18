-- drop database if exists bpdata2;
-- create database bpdata2;

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

load data local infile 'C:\git\OHSUHTNU18\docs\data\bp1.csv'
into table rawbpdata
fields terminated by ','
lines terminated by '\n';

load data local infile 'C:\git\OHSUHTNU18\docs\data\bp2.csv'
into table rawbpdata
fields terminated by ','
lines terminated by '\n';

load data local infile 'C:\git\OHSUHTNU18\docs\data\bp3.csv'
into table rawbpdata
fields terminated by ','
lines terminated by '\n';

load data local infile 'C:\git\OHSUHTNU18\docs\data\bp4.csv'
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


