MySQL Recovery Kit
==================

Recovers InnoDB in case of when MySQL won't start even with forced recovery.
Just copy your database structure dump into `./database-dumps` and your `ibdata1` into `./mysql-bin-data`, then do `make start` and verify output of docker-compose, and monitor `./recovered` directory.

On `localhost:9005` you have a PhpMyAdmin instance for testing.
Use `make` tasks to `get_into_recovery_container` and more.
