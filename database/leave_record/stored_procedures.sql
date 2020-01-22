
CREATE OR REPLACE FUNCTION replenish_leaves()
RETURNS integer AS $$
DECLARE
	num_of_leaves INT NOT NULL;
BEGIN
	SELECT INTO leaves_allowed leave FROM leave_per_year;
	UPDATE normal_faculty_details
	SET remaining_leaves = remaining_leaves + num_of_leaves;
	
	RETURN 0;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION forward_leave (sender_idd INTEGER , reciever_title VARCHAR(20) , comment TEXT )
RETURNS INTEGER AS $$
DECLARE
    path    TEXT[] ;
    arrlength INTEGER;
    position INTEGER;
    newholderdesig VARCHAR(20);
    newholder_id INTEGER;
    sender_title VARCHAR(20);
    iterator INTEGER := 1;
    sender_dept VARCHAR(20);
    appid INTEGER ;
    reciever_id INTEGER;
    request_date1 DATE;
    request_date2 DATE;
   
BEGIN

    
    SELECT sender_designation from leave_pending where sender_id = sender_idd  INTO sender_title ; 

    SELECT date_of_leave1 from leave_pending where sender_id = sender_idd INTO request_date1 ;
    SELECT date_of_leave2 from leave_pending where sender_id = sender_idd INTO request_date2 ;

    SELECT path_table.path FROM path_table WHERE path_table.designation = sender_title  INTO path;


    arrlength := array_length(path , 1);

    LOOP
        IF iterator > arrlength THEN
            EXIT;
        END IF;
        IF path[iterator] = reciever_title THEN
            position := iterator;
            EXIT;
        END IF;
        iterator = iterator + 1;
    END LOOP;

    position := position + 1;

   

    IF position > arrlength THEN
        raise notice 'The path has Ended , cannot forward anymore ' ;
        RETURN -1;
    END IF;

    newholderdesig := path[position];

    -- any one who presses the forward button can be  a :
    -- 1. faculty 
    -- 2. HOD
    -- 3. other cross cutting faculty 

    -- If the next person in line is HOD , we need to search the HOD table and get the HOD info 
    IF newholderdesig = 'HOD' THEN
        -- find the department of sender
        select department_name from normal_faculty_details where faculty_id = sender_idd into sender_dept;
        select hod_id from department where department_name = sender_dept into newholder_id ;
    ELSE
    -- If the guy next in line is not HOD , then he MUST be cross cutting
        SELECT faculty_id FROM cross_cutting_faculty_details WHERE designation = newholderdesig INTO newholder_id;
    END IF ;

    comment := CONCAT (reciever_title , ' : ' , comment);
    UPDATE leave_pending SET current_holder_id = newholder_id , current_holder_designation = newholderdesig , comments = CONCAT(comments,chr(10),comment) WHERE sender_id = sender_idd ; 
    
    --add paper trail
    select application_id from leave_pending where sender_id = sender_idd into appid;

    -- extract the current holder id (reciever_id)

    

    IF reciever_title <> 'HOD' THEN
        select faculty_id from cross_cutting_faculty_details where designation = reciever_title into reciever_id;
    ELSE -- he is HOD
        select department_name from normal_faculty_details where faculty_id = sender_idd into sender_dept;
        select hod_id from department where department_name = sender_dept into reciever_id ;
    END IF; 

    -- after send_back() , call forward using the designation as 'faculty' else it wont work

    IF reciever_title = 'faculty' THEN
        -- if this happens that means that it has been sent back
        reciever_id := sender_idd ;
    END IF;

    insert into paper_trail values(
        appid,
        reciever_id,
        reciever_title,
        'Leave application forwarded',
        comment,
        CURRENT_DATE,
        request_date1,
        request_date2
    );

    RETURN 0;


END;
$$ LANGUAGE PLPGSQL;



CREATE OR REPLACE FUNCTION request_leave(fac_id INTEGER , request_date1 DATE ,request_date2 DATE, comment TEXT ) 
RETURNS INTEGER AS $$
DECLARE
    fac_desig VARCHAR(20) ;
    next_desig VARCHAR(20);
    next_id INTEGER;
    flag INTEGER := 0; -- 1 if the requested party is normal ( fac , HOD ) else 0 if cross cutitng (Dean , Director , Asso. Dean)
    path text[];
    num_requested_leaves INTEGER; 
    hod_flag INTEGER := 0;
    fac_dept VARCHAR(20);
    appid INTEGER;
    
    
    num_of_days INTEGER NOT NULL;
    num_remaining_leaves INTEGER DEFAULT 0;
    temporary_scanning_variable INTEGER DEFAULT 0;
    
    

BEGIN
	SELECT INTO num_of_days request_date2-request_date1;
	
	IF request_date1 < CURRENT_DATE
		RAISE EXCEPTION 'Date has already passed ! ';
	END IF;
	
	IF num_of_days < 0 THEN
		RAISE EXCEPTION 'RETURNING DATE IS BEFORE LEAVING DATE';
	END IF;
	num_of_days = num_of_days + 1;
	
	
	
	SELECT INTO temporary_scanning_variable remaining_leaves FROM normal_faculty_details WHERE faculty_id = fac_id;
	 
	
	
	IF temporary_scanning_variable IS NULL THEN
		SELECT INTO temporary_scanning_variable remaining_leaves FROM cross_cutting_faculty_details WHERE faculty_id = fac_id;
	 
	 	
	 END IF;
	 
	 num_remaining_leaves = num_remaining_leaves + temporary_scanning_variable;
	 
	 SELECT INTO temporary_scanning_variable leave FROM leave_per_year;
	 num_remaining_leaves = num_remaining_leaves + temporary_scanning_variable;
	 
	 IF num_of_days > num_remaining_leaves THEN
	 	RAISE EXCEPTION 'NOT ENOUGH LEAVES REMAINING';
	 END IF;
	 
    
    
    select count(*) from leave_pending where sender_id = fac_id into num_requested_leaves;
	
    IF num_requested_leaves > 0 THEN
        raise exception 'The Faculty has already requested a leave ! ';
        RETURN -1;
    END IF;

    -- find faculty designation to get path
    
    select count(*) from normal_faculty_details where faculty_id = fac_id into flag;

    IF flag = 1 THEN -- if flag is 1 he is normal ( 1 tuple found that is)
        fac_desig := 'faculty';

        -- it may happen that he is an HOD
        select count(*) from department where hod_id = fac_id into hod_flag;

        IF hod_flag = 1 THEN
            fac_desig := 'HOD';
        END IF;

    ELSE -- he is cross - cutting
        -- designation can be Dean , As.Dean or Director
        select designation from cross_cutting_faculty_details where faculty_id = fac_id into fac_desig;
    END IF;

    
    
    -- find path for this designation first of all
    SELECT path_table.path FROM path_table WHERE path_table.designation = fac_desig  INTO path;

    -- find next guy to forward to 

    IF path = NULL THEN
        raise notice 'There is no path specified for %' , fac_desig ;
        RETURN -1;
    END IF;
    
    next_desig = path[2]; -- next person in path 

    IF next_desig = 'HOD' THEN
        select department_name from normal_faculty_details where faculty_id = fac_id into fac_dept;
        select hod_id from department where department_name = fac_dept into next_id;
    ELSE
        select faculty_id from cross_cutting_faculty_details where designation = next_desig into next_id;
    END IF;


    -- add entry     
    insert into leave_pending ( 
    sender_id 
    ,sender_designation 
    ,current_holder_id 
    ,current_holder_designation 
    ,comments , date_of_leave1,date_of_leave2)  values (fac_id, fac_desig , next_id , next_desig , comment , request_date1,request_date2);

    --add paper trail
    select application_id from leave_pending where sender_id = fac_id into appid;
    insert into paper_trail values(
        appid,
        fac_id,
        fac_desig,
        'Leave Requested',
        comment,
        CURRENT_DATE,
        request_date1,
        request_date2
    );
   

    RETURN 0;
END $$
LANGUAGE PLPGSQL ;


CREATE OR REPLACE FUNCTION send_back(original_sender_id INTEGER , current_holder_designation TEXT , comment TEXT)
RETURNS INTEGER AS $$
DECLARE
    sender_title VARCHAR(20);
    appid INTEGER ;
    flag INTEGER := 0;
    reciever_id INTEGER;
    sender_dept VARCHAR(20);
    request_date1 DATE;
    request_date2 DATE;
BEGIN


    SELECT date_of_leave1 from leave_pending where sender_id = original_sender_id INTO request_date1 ;
    SELECT date_of_leave2 from leave_pending where sender_id = original_sender_id INTO request_date2 ;

    -- THIS FUNCTION SENDS BACK THE LEAVE APPLICATION TO ORIGINAL SENDER
    -- That is now in the table the original sender and current holder of the leave application are same .
    select sender_designation from leave_pending where sender_id = original_sender_id into sender_title;
    comment = CONCAT ( current_holder_designation , ' : ' , comment);
    
    -- update the leave table
    UPDATE leave_pending SET current_holder_id = original_sender_id , current_holder_designation = sender_title , comments = CONCAT(comments,chr(10),comment) WHERE sender_id = original_sender_id ; 

    --add paper trail
    select application_id from leave_pending where sender_id = original_sender_id into appid;

    select count(*) from cross_cutting_faculty_details where designation = current_holder_designation into flag;

    IF flag = 1 THEN
        select faculty_id from cross_cutting_faculty_details where designation = current_holder_designation into reciever_id;
    ELSE -- he is HOD
        select department_name from normal_faculty_details where faculty_id = original_sender_id into sender_dept;
        select hod_id from department where department_name = sender_dept into reciever_id ;
    END IF; 


    insert into paper_trail values(
        appid,
        reciever_id,
        current_holder_designation,
        'Leave application reverted back to sender ',
        comment,
        CURRENT_DATE,
        request_date1,
        request_date2
    );

    RETURN 0;

END $$
LANGUAGE PLPGSQL ;



CREATE OR REPLACE FUNCTION approve_leave(original_sender_id INTEGER , current_holder_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    curr_desig TEXT ;
    appid INTEGER ; 
    comment TEXT ;
    request_date1 DATE ;
    request_date2 DATE;
    flag INTEGER := 0;
    num_of_days INT DEFAULT 1;
BEGIN
    -- 1. remove from leave table 
    -- 2. add paper trail 
    -- 3. add to finalised leaves
    
    SELECT INTO num_of_days request_date2-request_date1;
    num_of_days = num_of_days +1;

    select current_holder_designation from leave_pending where sender_id = original_sender_id into curr_desig;

    select application_id from leave_pending where sender_id = original_sender_id into appid;

    select comments from leave_pending where sender_id = original_sender_id into comment ;

    select date_of_leave1 from leave_pending where sender_id = original_sender_id into request_date1 ;
    
    select date_of_leave2 from leave_pending where sender_id = original_sender_id into request_date2 ;
    


    insert into finalised_leaves values(
        appid,
        original_sender_id,
        current_holder_id,
        curr_desig,
        'APPROVED',
        request_date1,
        request_date2,
        ' '
    );

    insert into  paper_trail values (
        appid ,
        current_holder_id,
        curr_desig,
        'LEAVE APPROVED',
        comment,
        CURRENT_DATE,
        request_date1,
        request_date2
    );

    delete from leave_pending where sender_id = original_sender_id ;

    -- update the number of remaining leaves 
    -- they are either cross cutting or normal

    select count(*) from normal_faculty_details where faculty_id = original_sender_id into flag;

    IF flag = 0 THEN -- cross cutting
        UPDATE cross_cutting_faculty_details SET remaining_leaves = remaining_leaves - num_of_days where faculty_id = original_sender_id;
    ELSE
        UPDATE normal_faculty_details SET remaining_leaves = remaining_leaves - num_of_days where faculty_id = original_sender_id ;
    END IF;

    

    RETURN 0;
END

$$ LANGUAGE PLPGSQL ;

CREATE OR REPLACE FUNCTION reject_leave (original_sender_id INTEGER , current_holder_id INTEGER , reject_reason TEXT)
RETURNS INT AS $$

DECLARE
    appid INTEGER ;
    comment TEXT ;
    request_date1 DATE ;
    request_date2 DATE;
    curr_desig TEXT ;

BEGIN

    select current_holder_designation from leave_pending where sender_id = original_sender_id into curr_desig;

    select application_id from leave_pending where sender_id = original_sender_id into appid;

    select comments from leave_pending where sender_id = original_sender_id into comment ;

    select date_of_leave1 from leave_pending where sender_id = original_sender_id into request_date1 ;
     select date_of_leave2 from leave_pending where sender_id = original_sender_id into request_date2;


    insert into finalised_leaves values(
        appid,
        original_sender_id,
        current_holder_id,
        curr_desig,
        'REJECTED',
        request_date1,
        request_date2,
        reject_reason
    );

    insert into  paper_trail values (
        appid ,
        current_holder_id,
        curr_desig,
        'LEAVE REJECTED',
        comment,
        CURRENT_DATE,
        request_date1,
        request_date2
    );

    delete from leave_pending where sender_id = original_sender_id ;

    RETURN 0;
END 
$$ LANGUAGE PLPGSQL ;



CREATE OR REPLACE FUNCTION change_leave_per_year(newLeave INT)
RETURNS INTEGERS AS $$
BEGIN
	UPDATE leave_per_year
	SET leave = $1;
END;
$$ LANGUAGE plpgsql;


