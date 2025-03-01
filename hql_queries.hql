!echo '========================';
!echo 'Query 1: Employees who joined after 2015';
!echo '========================';
SELECT * 
FROM employees_cleaned 
WHERE CAST(SUBSTRING(join_date, 1, 4) AS INT) > 2015;

!echo '========================';
!echo 'Query 2: Average salary by department';
!echo '========================';
SELECT department, AVG(salary) AS avg_salary
FROM employees_cleaned
GROUP BY department;

!echo '========================';
!echo 'Query 3: Employees working on the Alpha project';
!echo '========================';
SELECT * 
FROM employees_cleaned
WHERE project = 'Alpha';

!echo '========================';
!echo 'Query 4: Employee count per job role';
!echo '========================';
SELECT job_role, COUNT(*) AS total_employees
FROM employees_cleaned
GROUP BY job_role;

!echo '========================';
!echo 'Query 5: Employees earning above department average salary';
!echo '========================';
SELECT e.*
FROM employees_cleaned e
JOIN (
    SELECT department, AVG(salary) AS avg_salary
    FROM employees_cleaned
    GROUP BY department
) dept_avg
ON e.department = dept_avg.department
WHERE e.salary > dept_avg.avg_salary;

!echo '========================';
!echo 'Query 6: Department with the highest number of employees';
!echo '========================';
SELECT department, COUNT(*) AS total_employees
FROM employees_cleaned
GROUP BY department
ORDER BY total_employees DESC
LIMIT 1;

!echo '========================';
!echo 'Query 7: Count of employees with NULL values';
!echo '========================';
SELECT COUNT(*) 
FROM employees_cleaned 
WHERE emp_id IS NULL 
   OR name IS NULL 
   OR age IS NULL 
   OR job_role IS NULL 
   OR salary IS NULL 
   OR project IS NULL 
   OR join_date IS NULL 
   OR department IS NULL;

!echo '========================';
!echo 'Query 8: Joining employees table with department table';
!echo '========================';
SELECT e.*, d.location
FROM employees_cleaned e
JOIN departments d
ON e.department = d.department_name;

!echo '========================';
!echo 'Query 9: Rank employees by salary within each department';
!echo '========================';
SELECT *, 
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
FROM employees_cleaned;

!echo '========================';
!echo 'Query 10: Top 3 highest-paid employees in each department';
!echo '========================';
SELECT * 
FROM (
    SELECT *, 
           DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
    FROM employees_cleaned
) ranked_employees
WHERE rank <= 3;
