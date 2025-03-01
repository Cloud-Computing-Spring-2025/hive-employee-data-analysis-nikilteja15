# HadoopHiveHue
# Hive Employee Data Analysis
### Author
Sai Nikil Teja Swarna

## Project Overview
This project involves analyzing employee data using Apache Hive. The dataset consists of two files:

- **employees.csv**: Contains employee details such as ID, name, age, job role, salary, project assignment, and department.
- **departments.csv**: Contains department details including department ID, name, and location.

The analysis involves partitioning, filtering, aggregation, ranking, and joining tables using Hive queries.

## Prerequisites
- Docker installed
- Hive and HDFS running inside Docker containers
- Employees and Departments dataset in CSV format

---

## Steps to Execute the Assignment

### Step 1: Access Namenode Container
```sh
# Open an interactive bash shell inside the namenode container
docker exec -it namenode /bin/bash
```

### Step 2: Create Directories in HDFS and Locally
```sh
# List directories in HDFS root to check existing structure
hdfs dfs -ls /

# Create a directory in HDFS for storing employee data
hdfs dfs -mkdir -p /data/employee_data

# Create a local directory for CSV files
mkdir -p /data/employee_data

# List files in the local directory
ls -l /data/employee_data
```

### Step 3: Exit Namenode Container
```sh
exit  # Exit the namenode container shell
```

### Step 4: Copy CSV Files to Namenode Container
```sh
# Copy employees CSV file to namenode container
docker cp /workspaces/hive-employee-data-analysis-nikilteja15/input_dataset/employees.csv namenode:/data/employee_data/employees.csv

# Copy departments CSV file to namenode container
docker cp /workspaces/hive-employee-data-analysis-nikilteja15/input_dataset/departments.csv namenode:/data/employee_data/departments.csv
```

### Step 5: Verify File Upload inside Namenode
```sh
# Open a shell inside namenode container
docker exec -it namenode /bin/bash

# List copied files in the container
ls -l /data/employee_data/
```

### Step 6: Upload Files to HDFS
```sh
# Ensure HDFS directory exists
hdfs dfs -mkdir -p /data/employee_data

# Upload employees CSV to HDFS
hdfs dfs -put /data/employee_data/employees.csv /data/employee_data/

# Upload departments CSV to HDFS
hdfs dfs -put /data/employee_data/departments.csv /data/employee_data/

# Verify files in HDFS
hdfs dfs -ls /data/employee_data/
```

### Step 7: Exit Namenode Container
```sh
exit
```

### Step 8: Access Hive Server Container
```sh
# Open a shell inside the hive-server container
docker exec -it hive-server /bin/bash
```

### Step 9: Start Hive CLI
```sh
hive  # Start the Hive CLI
```

### Step 10: Create Hive Tables
#### Create Partitioned Employees Table
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS employees (
    emp_id INT,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING
)
PARTITIONED BY (department STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/employee_data';
```
#### Create Departments Table
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS departments (
    dept_id INT,
    department_name STRING,
    location STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/employee_data';
```

### Step 11: Enable Dynamic Partitioning
```sql
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
```

### Step 12: Create Staging Table and Load Data
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS employees_staging (
    emp_id INT,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING,
    department STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/employee_data';
```
```sql
LOAD DATA INPATH '/data/employee_data/employees.csv' INTO TABLE employees_staging;
```
```sql
INSERT OVERWRITE TABLE employees PARTITION (department)
SELECT emp_id, name, age, job_role, salary, project, join_date, department
FROM employees_staging;
```

### Step 13: Verify Partitions
```sql
SHOW PARTITIONS employees;
```

### Step 14: Load Data into Departments Table
```sql
LOAD DATA INPATH '/data/employee_data/departments.csv' INTO TABLE departments;
```

### Step 15: Clean Up Null Values
```sql
CREATE TABLE employees_cleaned LIKE employees;
INSERT OVERWRITE TABLE employees_cleaned PARTITION (department)
SELECT emp_id, name, age, job_role, salary, project, join_date, department
FROM employees
WHERE department IS NOT NULL;
```
```sql
ALTER TABLE employees DROP PARTITION (department='_HIVE_DEFAULT_PARTITION_');
```
```sql
ALTER TABLE employees DROP PARTITION (department='department');  
```

## Challenges Faced
### 1. Error while Running a DELETE command
When attempting to delete:
```sql
DELETE FROM employees WHERE department IS NULL;;
```
I encountered the following error:
```sh
FAILED: SemanticException [Error 10294]: Attempt to do update or delete using transaction manager that does not support these operations.
```
This was resolved by creating a new cleaned table and filtering out null partitions before inserting the data.

### 2. Removing Duplicate Partitions
There were cases where duplicate or incorrect partitions were created. This required using `SHOW PARTITIONS employees;` and ensuring only valid partitions remained in the final dataset.
This was resolved using the following commands;
```sql
ALTER TABLE employees DROP PARTITION (department='_HIVE_DEFAULT_PARTITION_');
```
```sql
ALTER TABLE employees DROP PARTITION (department='department');  
```

### Step 16: Execute Hive Queries
```sql
-- Retrieve employees who joined after 2015
SELECT * FROM employees_cleaned WHERE CAST(SUBSTRING(join_date, 1, 4) AS INT) > 2015;

-- Find the average salary of employees in each department
SELECT department, AVG(salary) AS avg_salary FROM employees_cleaned GROUP BY department;

-- Identify employees working on the 'Alpha' project
SELECT * FROM employees_cleaned WHERE project = 'Alpha';

-- Count employees by job role
SELECT job_role, COUNT(*) AS total_employees FROM employees_cleaned GROUP BY job_role;

-- Retrieve employees earning above the department’s average salary
SELECT e.* FROM employees_cleaned e
JOIN (SELECT department, AVG(salary) AS avg_salary FROM employees_cleaned GROUP BY department) dept_avg
ON e.department = dept_avg.department WHERE e.salary > dept_avg.avg_salary;

-- Find department with highest number of employees
SELECT department, COUNT(*) AS total_employees FROM employees_cleaned GROUP BY department ORDER BY total_employees DESC LIMIT 1;

-- Identify employees with missing values
SELECT COUNT(*) FROM employees_cleaned WHERE emp_id IS NULL OR name IS NULL OR age IS NULL OR job_role IS NULL OR salary IS NULL OR project IS NULL OR join_date IS NULL OR department IS NULL;

-- Join Employees and Departments Tables
SELECT e.*, d.location FROM employees_cleaned e JOIN departments d ON e.department = d.department_name;

-- Rank employees by salary in each department
SELECT *, RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank FROM employees_cleaned;

-- Find top 3 highest-paid employees in each department
SELECT * FROM (SELECT *, DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank FROM employees_cleaned) ranked_employees WHERE rank <= 3;
```
### Step 16: Execute Hive Queries
```sh
# Create an empty file to store Hive queries
touch hql_queries.hql  

# Open the file in an editor (use nano, vim, or VS Code)
nano hql_queries.hql

# Copy the HQL file to the Hive server container
docker cp hql_queries.hql hive-server:/opt/hql_queries.hql  

# Verify that the file exists inside the container
docker exec -it hive-server ls -l /opt/hql_queries.hql  

# Open a shell inside the Hive server container
docker exec -it hive-server /bin/bash  

# Execute queries from the HQL file and save the output
hive -f /opt/hql_queries.hql | tee /opt/hql_output.txt  

# Exit the Hive server container
exit

# Copy the Hive query output from the container to the local machine
docker cp hive-server:/opt/hql_output.txt hql_output.txt  

# Confirm that the output file is present on the local machine
ls -l
```

## Output Files
- The queries were created in hql_queries.hql file.
- The output for the executed queries was stored in hql_output.txt file.





