CREATE TABLE faculty(
id SERIAL
,first_name     VARCHAR(10) NOT NULL
,last_name VARCHAR(10) NOT NULL
,gender VARCHAR(7) NOT NULL
,joining_date DATE NOT NULL
,leaving_date DATE
,PRIMARY KEY(id)
);

CREATE TABLE normal_faculty_details(
faculty_id INT NOT NULL
,department_name VARCHAR(10) NOT NULL
,login_name VARCHAR(40) NOT NULL
,password_hash VARCHAR(20) NOT NULL
,remaining_leaves INT NOT NULL
,PRIMARY KEY(faculty_id), FOREIGN KEY (faculty_id) REFERENCES faculty(id),FOREIGN KEY (department_name) REFERENCES department(department_name)
);


CREATE TABLE cross_cutting_faculty_details(
faculty_id INT NOT NULL
,designation VARCHAR(20) 
,login_name VARCHAR(40) NOT NULL
,password_hash VARCHAR(20) NOT NULL
,remaining_leaves INT NOT NULL
,PRIMARY KEY(faculty_id),FOREIGN KEY (faculty_id) REFERENCES faculty(id) 
);


CREATE TABLE department(
department_name VARCHAR(5) NOT NULL
,hod_id INT
,PRIMARY KEY(department_name)
);

CREATE TABLE hod_appointments(
department VARCHAR(5) NOT NULL
,faculty_id INT NOT NULL
,start_date DATE NOT NULL
,end_date DATE
, FOREIGN KEY (faculty_id) REFERENCES faculty(id)
);

CREATE TABLE por_appointments(
ccfaculty_id INT NOT NULL
,designation VARCHAR(10) NOT NULL
,start_date DATE NOT NULL
,end_date DATE
, FOREIGN KEY (ccfaculty_id) REFERENCES faculty(id)
);




