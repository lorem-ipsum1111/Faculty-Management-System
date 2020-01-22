



-------------------------START A NEW PROJECT-------------------------------------	

CREATE OR REPLACE FUNCTION start_project(pi_id INT, projectName TEXT)
RETURNS INTEGER AS $$
BEGIN
	IF EXISTS(SELECT * FROM project WHERE project_name = $2) THEN
		RAISE EXCEPTION 'PROJECT WITH THAT NAME ALREADY EXISTS';
	END IF;
	IF EXISTS(SELECT * FROM faculty WHERE id = $1) THEN
	INSERT INTO project(main_pi_id,project_name,starting_date) VALUES($1,$2,CURRENT_DATE);
	ELSE
	RAISE EXCEPTION 'NO FACULTY WITH THAT ID EXISTS IN DATABASE';
	END IF;
  RETURN 0;
END;
$$ LANGUAGE plpgsql;



--------------------------------------APPOINT A CO-PI---------------------------------


CREATE OR REPLACE FUNCTION make_normal_pi(piID INT, projectID INT)
RETURNS INTEGER AS $$
BEGIN
	IF EXISTS(SELECT * FROM normal_pi WHERE project_id = $2 AND pi_id = $1) THEN
		RAISE EXCEPTION 'THE PI HAS ALREADY BEEN ASSIGNED TO THAT PROJECT';
	END IF;
	IF EXISTS(SELECT * FROM faculty WHERE id = $1) THEN
		INSERT INTO normal_pi VALUES($2,$1);
	ELSE
		RAISE EXCEPTION 'NO FACULTY WITH THAT ID EXISTS IN DATABASE' ;
	END IF;
	RETURN 0;
END;
$$ LANGUAGE plpgsql;



---------------------------APPOINT BUDGET HEAD----------------------




CREATE OR REPLACE FUNCTION make_budget_head(projectID INT, budgetType TEXT, budgetHeadID INT)
RETURNS INTEGER AS $$
BEGIN
	IF EXISTS(SELECT * FROM budget WHERE project_id = $1 AND budget_type = $2) THEN
		UPDATE budget
		SET budget_head_id = $3
		WHERE project_id = $1 AND budget_type = $2;
	ELSE
	INSERT INTO budget VALUES($1,$2,$3,0);
	END IF;
	RETURN 0;
END;
$$ LANGUAGE plpgsql;


---------------------------ALLOT BUDGET-------------------------------------

CREATE OR REPLACE FUNCTION allot_budget(projectID INT, budgetType TEXT, amount INT)
RETURNS INTEGER AS $$
BEGIN

	UPDATE budget
	SET budget_amount = budget_amount + $3 
	WHERE project_id = $1 AND budget_type = $2;
	RETURN 0;
END;
$$ LANGUAGE plpgsql;




---------------------------CLOSE A PROJECT------------------------------------


CREATE OR REPLACE FUNCTION close_project(projectID INT)
RETURNS INTEGER AS $$
BEGIN
	IF EXISTS(SELECT * FROM project WHERE project_id = $1 AND ending_date IS NOT NULL) THEN
  	RAISE EXCEPTION 'THIS PROJECT HAS ALREADY BEEN CLOSED';
  END IF;
	DELETE FROM current_request
	WHERE project_id = $1;
	
	UPDATE project
	SET ending_date = CURRENT_DATE
	WHERE project_id = $1;
RETURN 0;
END;
$$ LANGUAGE plpgsql;





CREATE OR REPLACE FUNCTION request_expenditure( proj_id INTEGER , pi_idd INTEGER , exp_type TEXT , cperunit INTEGER , nunits INTEGER , comm TEXT)
RETURNS INTEGER AS $$
DECLARE 
	pi_desig TEXT ;
    curr_id INTEGER;
    curr_desig TEXT;
    flag INTEGER := 0;
    path TEXT[];
    expamt INTEGER ;
    availexp INTEGER ;


    req_id INTEGER ;

BEGIN
	IF NOT EXISTS(SELECET * FROM project WHERE project_id = $1 AND ending_date is null) THEN
	RAISE EXCEPTION 'THE PROJECT IS CLOSED';
	END IF;
	IF NOT EXISTS(SELECT * FROM BUDGET WHERE project_id = $1 AND budget_type = $3) THEN
	RAISE EXCEPTION 'THIS TYPE OF BUDGET CATEGORY DOES NOT EXISTS FOR THIS PROJECT';
	END IF;
	
	
    select count(*) from cross_cutting_faculty_details where faculty_id = pi_idd into flag;


    flag := 0 ;

    select count(*) from project where main_pi_id = pi_idd into flag ;

    IF flag = 1 THEN 
        -- he is main_pi
        pi_desig := 'MAIN_PI';
    ELSE
        pi_desig := 'NORMAL_PI';
    END IF;

  

    SELECT request_path.path FROM request_path WHERE request_path.designation = pi_desig  INTO path;

    curr_desig := path[2]; -- next person in list 

    IF curr_desig = 'DEAN_SP' THEN
        select faculty_id from cross_cutting_faculty_details where designation = curr_desig into curr_id;
    ELSE
        -- he is main_pi
        select main_pi_id from project where project_id = proj_id into curr_id ;
    END IF;


    expamt := cperunit * nunits ;

      

    select budget_amount from budget where budget_type = exp_type into availexp;

    IF availexp < expamt THEN
        raise exception 'Not enough Budget to accomodate this expenditure ! ';
        RETURN NULL;
    END IF;

    
    

    insert into current_request(
    project_id 
    ,pi_id  
    ,pi_designation 
    ,current_holder_id 
    ,current_holder_designation 
    ,cost_per_unit 
    ,num_of_units 
    ,expenditure_type
    ,comments 
    ) values(
    proj_id
    ,pi_idd
    ,pi_desig
    ,curr_id
    ,curr_desig
    ,cperunit
    ,nunits
    ,exp_type
    ,comm
    );


    -- add paper_trail

    

    select request_id from current_request where current_request.project_id = $1 and  current_request.pi_id = $2 and current_request.cost_per_unit = cperunit  and current_request.num_of_units = nunits and  current_request.expenditure_type = exp_type into req_id;

    insert into decisions_trail ( request_id ,  project_id , pi_id , decision_maker_id , date_of_decision , comments) values (  req_id , proj_id , pi_idd , curr_id , CURRENT_DATE , comm);
    
    RETURN 0;
    
END
$$ LANGUAGE PLPGSQL;

---------------- forward_expenditure ----------------------

CREATE OR REPLACE FUNCTION forward_expenditure ( req_id INTEGER , comm TEXT)
RETURNS INTEGER AS $$
DECLARE
    curr_desig TEXT ;
    curr_id INTEGER;
   
    next_id INTEGER ;
    next_desig TEXT ;

    proj_id INTEGER ;
    pi_idd INTEGER ;
    
    iterator INTEGER := 1 ;
    arrlength INTEGER ;
    position INTEGER ;
    path TEXT [] ;

BEGIN
    
    select current_holder_designation from current_request where request_id = req_id into curr_desig;
    select current_holder_id from current_request where request_id = req_id into curr_id ;
   

    SELECT request_path.path FROM request_path WHERE request_path.designation = curr_desig INTO path;


    arrlength := array_length(path , 1);

    LOOP
        IF iterator > arrlength THEN
            EXIT;
        END IF;
        IF path[iterator] = curr_desig THEN
            position := iterator;
            EXIT;
        END IF;
        iterator = iterator + 1;
    END LOOP;

    position := position + 1;

    comm := CONCAT ( curr_desig , ' : ' , comm);

   

    IF position > arrlength THEN
        raise exception 'The path has Ended , cannot forward anymore ' ;
        RETURN -1;
    END IF;

    next_desig := path[position];
    
    select faculty_id from cross_cutting_faculty_details where designation = next_desig into next_id ;

    

    UPDATE current_request SET current_holder_id = next_id , current_holder_designation = next_desig , comments = CONCAT (comments , chr(10) , comm)  where request_id = req_id ;

    -- add paper trail 

    select project_id from current_request where request_id = req_id into proj_id ;
    select pi_id from current_request where request_id = req_id into pi_idd;


    insert into decisions_trail values ( req_id , proj_id , pi_idd , curr_id , CURRENT_DATE , comm);

    RETURN 0;
END $$
LANGUAGE PLPGSQL ;


------------ Approve function -----------------

CREATE OR REPLACE FUNCTION approve_expenditure (req_id INTEGER , comm TEXT)
RETURNS INTEGER AS $$
DECLARE
    proj_id INTEGER ;
    exp_type TEXT ;
    cperunit INTEGER ;
    nunits INTEGER;
    pi_idd INTEGER ;
    curr_desig TEXT ;
    curr_id INTEGER ;
    expamt INTEGER ;
    availexp INTEGER ;
    
BEGIN

    -- 1. add to expenditure table 
    -- 2. add to decision_trail
    -- 3. remove from current_request


    select project_id from current_request where request_id = req_id into proj_id ;
    select pi_id from current_request where request_id = req_id into pi_idd;
    
    select cost_per_unit  from current_request where request_id = req_id into cperunit ;
    select num_of_units from current_request where request_id = req_id into nunits ;
    select current_holder_designation from current_request where request_id = req_id into curr_desig;
    select current_holder_id from current_request where request_id = req_id into curr_id ;

    

    select expenditure_type from current_request where request_id = req_id into exp_type;

    select budget_amount from budget where budget_type = exp_type and project_id = proj_id into availexp;

    expamt := cperunit * nunits ;

    IF availexp < expamt THEN
        raise exception 'Not enough Budget to accomodate this expenditure ! ';
        RETURN -1;
    END IF;


   
    comm := CONCAT ( curr_desig , ' : ' , comm);




    insert into expenditure values (req_id , proj_id , exp_type , cperunit , nunits) ;

    insert into decisions_trail values ( req_id , proj_id , pi_idd , curr_id , CURRENT_DATE , comm);

    delete from current_request where request_id = req_id ;

    -- update the budget remaining now

    update budget set budget_amount = budget_amount - expamt where project_id = proj_id and budget_type = exp_type ;

    RETURN 0;

END
$$ LANGUAGE PLPGSQL ;

-------------------- REJECT FUNCTION --------------------------------

CREATE OR REPLACE FUNCTION reject_expenditure ( req_id INTEGER , comm TEXT )
RETURNS INTEGER AS $$
DECLARE 
    proj_id INTEGER ;
    exp_type TEXT ;
    cperunit INTEGER ;
    nunits INTEGER;
    pi_idd INTEGER ;
    curr_desig TEXT ;
    curr_id INTEGER ;
    expamt INTEGER ;
    availexp INTEGER ;
BEGIN

    select project_id from current_request where request_id = req_id into proj_id ;
    select pi_id from current_request where request_id = req_id into pi_idd;
    
    select cost_per_unit  from current_request where request_id = req_id into cperunit ;
    select num_of_units from current_request where request_id = req_id into nunits ;
    select current_holder_designation from current_request where request_id = req_id into curr_desig;
    select current_holder_id from current_request where request_id = req_id into curr_id ;

    select expenditure_type from current_request where request_id = req_id into exp_type;


    insert into rejected_requests values ( req_id , exp_type , cperunit , nunits , curr_id );

    insert into decisions_trail values ( req_id , proj_id , pi_idd , curr_id , CURRENT_DATE , comm);

    delete from current_request where request_id = req_id ;

    RETURN 0;

END
$$ LANGUAGE PLPGSQL ;









