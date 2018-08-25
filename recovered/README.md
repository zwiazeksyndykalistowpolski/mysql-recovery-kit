Data recovered goes there and can be later imported into MySQL
with a command that will be outputted at the end of every table recovery.

Example:
```sql
LOAD DATA INFILE '/opt/percona-data-recovery-tool-for-innodb-0.5/dumps/default/anarchist_organizations_contacts' 
REPLACE INTO TABLE `anarchist_organizations_contacts` 
FIELDS TERMINATED BY '\t' 
OPTIONALLY ENCLOSED BY '"' 
LINES STARTING BY 'anarchist_organizations_contacts\t' (NAME, ID, ADDRESS, PHONE);
```
