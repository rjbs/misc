CREATE TABLE uris (
	id INTEGER PRIMARY KEY,
	uri varchar UNIQUE NOT NULL
);
*
CREATE TABLE users (
	username PRIMARY KEY
);
*
CREATE TABLE useruris (
	id INTEGER PRIMARY KEY,
	uri varchar NOT NULL,
	username varchar NOT NULL,
	title varchar NOT NULL,
	description varchar,
	UNIQUE (uri, username)
);
*
CREATE TABLE useruritags (
	useruri NOT NULL,
	tag NOT NULL,
	PRIMARY KEY (useruri, tag)
);
