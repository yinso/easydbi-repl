create table __version_t 
( id serial primary key
 , module varchar(32) not null
 , version varchar(64) not null
 , query text not null 
 , created timestamp with time zone default now()
 );

