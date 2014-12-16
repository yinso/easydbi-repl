-- the drop tables are done in reverse order.
drop table if exists forget_password_t;

drop table if exists resource_role_t;

drop table if exists resource_t;

drop table if exists user_account_permission_t;

drop table if exists user_role_t;

drop table if exists role_permission_t;

drop table if exists account_module_t;

drop table if exists permission_t;

drop table if exists module_t;

drop table if exists role_t;

drop table if exists role_type_t;

drop table if exists account_t;

drop table if exists account_type_t;

drop table if exists password_t;

drop table if exists password_type_t;

drop table if exists user_t;

create table if not exists user_t (
    id serial primary key
    , uuid uuid unique
    , login varchar(64) unique
    , email varchar(255) unique
    , firstName varchar(255) null
    , lastName varchar(255) null
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists password_type_t (
    type varchar(32) primary key
    , description text null
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

insert into password_type_t (type) values ('sha256'), ('sha512'), ('bcrypt');

create table if not exists password_t (
    id serial primary key
    , userUUID uuid references user_t ( uuid )
    , type varchar(32) default 'sha256' references password_type_t ( type )
    , salt varchar(128) unique
    , hash varchar(128)
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists account_type_t (
    type varchar(32) primary key
    , description text null
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

insert into account_type_t (type) values ('super'), ('individual'), ('organization');

create table if not exists account_t (
    id serial primary key
    , uuid uuid unique
    , name varchar(64) unique
    , type varchar(32) references account_type_t ( type )
    , parentUUID uuid default null references account_t (uuid)
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

-- ought there be role type? probably...
create table if not exists role_type_t (
    type varchar(32) primary key
    , description text null
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

insert into role_type_t (type) values ('super'), ('owner'), ('user'), ('guest'), ('anonymous');

create table if not exists role_t (
    id serial primary key
    , uuid uuid unique
    , name varchar(64)
    , accountUUID uuid references account_t ( uuid )
    , unique ( name, accountUUID )
    , type varchar(32) references role_type_t ( type )
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists module_t (
    id serial primary key
    , uuid uuid unique
    , name varchar(32) unique
    , description text null
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists permission_t (
    id serial primary key
    , uuid uuid unique
    , name varchar(32)
    , moduleUUID uuid references module_t ( uuid )
    , unique ( name, moduleUUID )
    , description text null
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists account_module_t (
    id serial primary key
    , accountUUID uuid references account_t ( uuid )
    , moduleUUID uuid references module_t ( uuid )
    , unique ( accountUUID , moduleUUID )
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists role_permission_t (
    id serial primary key
    , roleUUID uuid references role_t ( uuid )
    , permissionUUID uuid references permission_t ( uuid )
    , unique ( roleUUID, permissionUUID )
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists user_role_t (
    id serial primary key
    , userUUID uuid references user_t ( uuid )
    , roleUUID uuid references role_t ( uuid )
    , unique ( userUUID, roleUUID  )
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists user_account_permission_t (
    id serial primary key
    , userUUID uuid references user_t ( uuid )
    , accountUUID uuid references account_t ( uuid )
    , permissionUUID uuid references permission_t ( uuid )
    , unique ( userUUID, accountUUID, permissionUUID )
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists resource_t (
    id serial primary key
    , uuid uuid unique
    , accountUUID uuid references account_t ( uuid )
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists resource_role_t (
    id serial primary key
    , resourceUUID uuid references resource_t ( uuid )
    , roleUUID uuid references role_t ( uuid )
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

create table if not exists forget_password_t (
    id serial primary key
    , uuid uuid unique
    , userUUID uuid references user_t ( uuid )
    , created timestamp with time zone default now()
    , createdBy uuid null references user_t ( uuid )
    , modified timestamp with time zone default now()
    , modifiedBy uuid null references user_t ( uuid )
    , version int default 1
);

