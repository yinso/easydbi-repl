

create table __version_t 
( id int primary key not null
, module varchar(128) not null -- this is the module 
, version varchar(32) not null -- this is the script name
, qtype varchar(10) default 'pgsql' not null -- this is the particular flavor of the query
, query text not null -- this is the query being run
, created timestamp with time zone default now()
);

insert into __version_t (module, version, query) 
  select 'version', '1.0.0', ''