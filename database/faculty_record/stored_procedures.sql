CREATE OR REPLACE FUNCTION add_faculty_normal(fname TEXT, lname TEXT,gndr TEXT, dept TEXT,login TEXT, passwd TEXT)
RETURNS integer AS $$
DECLARE
	assigned_id INT;
	present_date DATE DEFAULT CURRENT_DATE;
	leaves_allowed INT DEFAULT 40;
	
BEGIN
	SELECT INTO leaves_allowed leave FROM leave_per_year;
	IF NOT EXIST(SELECT * FROM department WHERE department_name = $4) THEN
		INSERT INTO department(department_name) VALUES($4);
	END IF;
	INSERT INTO faculty(first_name,last_name,gender,joining_date)
	VALUES($1,$2,$3,present_date);
	SELECT INTO assigned_id id from faculty WHERE first_name = fname AND last_name = lname AND gender = gndr AND joining_date = present_date;
	INSERT INTO normal_faculty_details(faculty_id,department_name,login_name,password_hash,remaining_leaves) VALUES(assigned_id,$4,$5,$6,leaves_allowed); 
	RETURN 0;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION add_faculty_cross_cutting(fname TEXT, lname TEXT, gndr TEXT,desgn TEXT,login TEXT,passwd TEXT)
RETURNS integer AS $$
DECLARE
	assigned_id INT;
	old_id INT;
	present_date DATE DEFAULT CURRENT_DATE;
	leaves_allowed INT DEFAULT 40;
	
BEGIN
	SELECT INTO leaves_allowed leave FROM leave_per_year;
	IF EXISTS(SELECT * FROM cross_cutting_faculty_details WHERE designation=$4) THEN
		RAISE NOTICE 'A faculty on that designation already exists. Putting new faculty in its place';
		SELECT INTO old_id faculty_id FROM cross_cutting_faculty_details WHERE designation=$4;
		
		UPDATE cross_cutting_faculty_details
		SET designation = NULL
		WHERE faculty_id = old_id;
		
		UPDATE por_appointments
		SET end_date = present_date
		WHERE ccfaculty_id=old_id;
		
	END IF;
	INSERT INTO faculty(first_name,last_name,gender,joining_date) VALUES($1,$2,$3,present_date);
	SELECT INTO assigned_id id from faculty WHERE first_name = $1 AND last_name = $2 AND gender = $3 AND joining_date = present_date;
	INSERT INTO cross_cutting_faculty_details(faculty_id,designation,login_name,password_hash,remaining_leaves) VALUES(assigned_id,$4,$5,$6,leaves_allowed); 
	INSERT INTO por_appointments(ccfaculty_id,designation,start_date) VALUES(assigned_id,$4,present_date);
	
	RETURN 0;
END;
$$ LANGUAGE plpgsql;





CREATE OR REPLACE FUNCTION change_hod(id INT)
RETURNS integer AS $$
DECLARE
	name_dept VARCHAR(5);
	id_old_hod INT;
BEGIN
	IF EXISTS(SELECT * FROM normal_faculty_details where faculty_id=$1) THEN					
		SELECT INTO name_dept department_name FROM normal_faculty_details WHERE faculty_id=$1;
		IF EXISTS(SELECT * FROM department WHERE department_name = name_dept) THEN
		SELECT INTO id_old_hod hod_id FROM department WHERE department_name = name_dept;
		UPDATE department
		SET hod_id = $1
		WHERE department_name = name_dept;
		INSERT INTO hod_appointments(department,faculty_id,start_date) VALUES (name_dept,$1,CURRENT_DATE);
		IF (NOT id_oLd_hod Is null) THEN
			UPDATE hod_appointments
			SET end_date = CURRENT_DATE
			WHERE faculty_id = id_old_hod;
		END IF;
		ELSE
		INSERT INTO department(department_name,hod_id) VALUES(name_dept,$1);
		INSERT INTO hod_appointments(department,faculty_id,start_date) VALUES (name_dept,$1,CURRENT_DATE);
		END IF;	
		
	ELSE
		RAISE EXCEPTION 'NO FACUTLY WITH THAT DESCRIPTION EXISTS';
	END IF;
	
	RETURN 0;
END;
$$ LANGUAGE plpgsql;












CREATE OR REPLACE FUNCTION change_por(id INT, dsgn TEXT)
RETURNS integer AS $$
DECLARE
	old_id INT;
	present_date DATE DEFAULT CURRENT_DATE;
	designtn TEXT;
	
BEGIN
	
	IF EXISTS(SELECT * FROM cross_cutting_faculty_details WHERE faculty_id = $1 ) THEN
		INSERT INTO por_appointments(ccfaculty_id,designation,start_date) VALUES($1,$2,present_date);
		IF EXISTS(SELECT * FROM cross_cutting_faculty_details WHERE designation=$2) THEN
			SELECT INTO old_id faculty_id FROM cross_cutting_faculty_details WHERE designation=$2;
		
			UPDATE cross_cutting_faculty_details
			SET designation = NULL
			WHERE faculty_id = old_id;
			
			UPDATE por_appointments
			SET end_date = present_date
			WHERE ccfaculty_id=old_id;
			
					
		END IF;	
		SELECT INTO designtn designation FROM cross_cutting_faculty_details WHERE faculty_id = $1;
		IF (NOT designtn Is null) THEN
		UPDATE por_appointments
		SET end_date = present_date
		WHERE ccfaculty_id = old_id;
		END IF;
		
			UPDATE cross_cutting_faculty_details
			SET designation = $2
			WHERE faculty_id = $1;
			
	ELSE
		RAISE EXCEPTION 'NO CROSS CUTTING FACULTY WITH THAT ID IS PRESENT IN DATABASE';
	END IF;
	
	RETURN 0;
END;
$$ LANGUAGE plpgsql;







		
CREATE OR REPLACE FUNCTION remove_faculty(fac_id INT)
RETURNS INTEGER AS $$
DECLARE 
	present_date DATE DEFAULT CURRENT_DATE;
BEGIN
	UPDATE faculty
	SET leaving_date=present_date
	WHERE id = fac_id;
	
	DELETE FROM cross_cutting_faculty_details
	WHERE faculty_id = fac_id;
	
	DELETE FROM normal_faculty_details
	WHERE faculty_id = fac_id;
	
	UPDATE departments
	SET hod_id = NULL
	WHERE hod_id = fac_id;
	
	UPDATE hod_appointments
	SET end_date = present_date
	WHERE faculty_id = fac_id;
	
	UPDATE por_appointments
	SET end_date = present_date
	WHERE ccfaculty_id=fac_id;
	return 0;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION normal_to_cross_cutting(fac_id INT, desgn TEXT)
RETURNS integer AS $$
DECLARE
	lognam VARCHAR(40);
	pass VARCHAR(20);
	remainleaves INT;
	old_id INT;
	present_date DATE DEFAULT CURRENT_DATE;
	
BEGIN

	
	SELECT INTO lognam login_name FROM normal_faculty_details WHERE faculty_id = fac_id;
	SELECT INTO pass password_hash FROM normal_faculty_details WHERE faculty_id = fac_id;
	SELECT INTO remainleaves remaining_leaves FROM normal_faculty_details WHERE faculty_id = fac_id;
	
	
	
	UPDATE department
	SET hod_id = NULL
	WHERE hod_id = fac_id;
	
	UPDATE hod_appointments
	SET end_date = present_date
	WHERE faculty_id = fac_id;
	
	
	
	IF EXISTS(SELECT * FROM cross_cutting_faculty_details WHERE designation=$2) THEN
		RAISE NOTICE 'A faculty on that designation already exists. Putting new faculty in its place';
		SELECT INTO old_id faculty_id FROM cross_cutting_faculty_details WHERE designation=$2;
		
		UPDATE cross_cutting_faculty_details
		SET designation = NULL
		WHERE faculty_id = old_id;
		
		UPDATE por_appointments
		SET end_date = present_date
		WHERE ccfaculty_id=old_id;
		
	END IF;
	
	INSERT INTO cross_cutting_faculty_details(faculty_id,designation,login_name,password_hash,remaining_leaves) VALUES($1,$2,lognam,pass,remainleaves); 
	INSERT INTO por_appointments(ccfaculty_id,designation,start_date) VALUES(fac_id,$2,present_date);
	DELETE FROM normal_faculty_details WHERE faculty_id = fac_id;
RETURN 0;
END;
$$ LANGUAGE plpgsql;









CREATE OR REPLACE FUNCTION cross_cutting_to_normal(fac_id  INT, dept TEXT)
RETURNS INTEGER AS $$
DECLARE
	lognam VARCHAR(40);
	pass VARCHAR(20);
	remainleaves INT;
	
BEGIN

	SELECT INTO lognam login_name FROM cross_cutting_faculty_details WHERE faculty_id = fac_id;
	SELECT INTO pass password_hash FROM cross_cutting_faculty_details WHERE faculty_id = fac_id;
	SELECT INTO remainleaves remaining_leaves FROM cross_cutting_faculty_details WHERE faculty_id = fac_id;
	
	
	UPDATE por_appointments
	SET end_date = present_date
	WHERE ccfaculty_id=fac_id;
	return 0;
	
	
	DELETE FROM cross_cutting_faculty_details
	WHERE faculty_id = fac_id;
	
	INSERT INTO normal_faculty_details(faculty_id , department_name , login_name , password_hash , remaining_leaves) VALUES($1,$2,lognam,pass,remainleaves);
	
	RETURN 0;
	
END;
$$ LANGUAGE plpgsql;











