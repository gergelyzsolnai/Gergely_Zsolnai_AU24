begin;
create database political_campaign;


create schema  if not exists political_schema;
commit;

begin;

create table if not exists political_schema.address (
	address_id serial primary key,
	country text not null,
	city text not null,
	zip_code text not null,
	address text not null
	);


create table if not exists political_schema.voter (
	voter_id SERIAL primary KEY,
	address_id INT not NULL,
	first_name VARCHAR(50) not null,
	last_name VARCHAR(50) not null,
	gender CHAR(1) not null, check(gender in ('M', 'F')), --checks if its filled with "M" or "F", otherwise it gets error.
	email VARCHAR(250) unique not null,
	phone VARCHAR(15) unique not null,
	registration_date DATE not null default current_date check (registration_date >= '2000-01-01'),  --checks if the reg.date is higher than 2000.01.01.
	CONSTRAINT address_Fkey FOREIGN KEY (address_id) REFERENCES political_schema.address (address_id),
	constraint check_email_format check (email like '%@%')  --Checking wether the email is proper email address
	);


create table if not exists political_schema.contributor (
	contributor_id SERIAL primary KEY,
	first_name VARCHAR(50) not null,
	last_name VARCHAR(50) not null,
	email VARCHAR(250) unique not null,
	phone VARCHAR(15) unique not null,
	donation_amount DECIMAL(10,2) NOT NULL CHECK(donation_amount > 0), --checks if the donation amount is higher than 0.
	donation_date DATE not null default current_date check (donation_date >= '2000-01-01'), --checks if the donation date is higher than 2000.01.01.
	constraint check_email_format check (email like '%@%')  --Checking wether the email is proper email address
);


create table if not exists political_schema.campaign (
	campaign_id SERIAL primary KEY,
	name VARCHAR(100) not null,
	start_date DATE not null,
	end_date DATE CHECK (end_date >= start_date), --checks, because end_date must be equal or higher than the start_date is higher than 2000.01.01.
	is_active BOOLEAN default (TRUE) 
);


create table if not exists political_schema.campaign_contribution (
	campaign_contribution_id SERIAL primary KEY,
	campaign_id INT not null,
	contributor_id INT not null,
	contribution_amount DECIMAL(10,2) NOT NULL CHECK(contribution_amount > 0), --checks if the contribution amount is positive mumber
	contribution_date DATE not null default current_date check (contribution_date >= '2000-01-01'), --checks if the contribution date is higher than 2000.01.01.
	CONSTRAINT campaign_Fkey FOREIGN KEY (campaign_id) REFERENCES political_schema.campaign (campaign_id),
	CONSTRAINT contributor_Fkey FOREIGN KEY (contributor_id) REFERENCES political_schema.contributor (contributor_id)
);

create table if not exists political_schema.finance (
	finance_id SERIAL primary KEY,
	campaign_id INT not null,
	expense_description text not NULL,
	expense_amount DECIMAL(10,2) not null check (expense_amount > 0), --checks if the contribution amount is positive mumber
	transactional_date TIMESTAMP not null default CURRENT_TIMESTAMP,  --donation_date must be filled, default is the current date and time, when the financial transaction happened
	CONSTRAINT campaign_Fkey FOREIGN KEY (campaign_id) REFERENCES political_schema.campaign (campaign_id)
);


create table if not exists political_schema.contribution_finance (
	contributor_id INT not null,
	finance_id INT not null,
	CONSTRAINT contributor_Fkey FOREIGN KEY (contributor_id) REFERENCES political_schema.contributor (contributor_id),
	CONSTRAINT finance_Fkey FOREIGN KEY (finance_id) REFERENCES political_schema.finance (finance_id),
	CONSTRAINT contribution_finance_Pkey PRIMARY KEY (contributor_id, finance_id)  --The primary key is the congtributor_id and the finance_id together. We don't need a contribution_finance_id to get the primary key.
);


CREATE TABLE if not exists political_schema.event (
	event_id Serial PRIMARY KEY,
	campaign_id INT not null,
	event_type TEXT NOT NULL CHECK (event_type IN ('rally', 'town_hall', 'debate', 'social_media')), --event_type must be one of the listed events, there is no default
	event_date TIMESTAMP not null,
	location VARCHAR(250),
	description text,
	CONSTRAINT campaign_Fkey FOREIGN KEY (campaign_id) REFERENCES political_schema.campaign (campaign_id)
);


create table if not exists political_schema.volunteer (
	volunteer_id Serial PRIMARY KEY,
	address_id INT not null,
	first_name VARCHAR(50) not null,
	last_name VARCHAR(50) not null,
	gender CHAR(1) not null, check(gender in ('M', 'F')), --checks if its filled with "M" or "F", otherwise it gets error.
	email VARCHAR(250) unique not null,
	phone VARCHAR(15) unique not null,
	availability BOOLEAN not null default true,
	role VARCHAR(50),
	CONSTRAINT address_Fkey FOREIGN KEY (address_id) references political_schema.address (address_id),
	constraint check_email_format check (email like '%@%')  --Checking wether the email is proper email address
);


create table if not exists political_schema.survey (
	survey_id Serial PRIMARY KEY,
	campaign_id INT not null,
	survey_name VARCHAR(150) not null,
	survey_date DATE not null default current_date,
	CONSTRAINT campaign_Fkey FOREIGN KEY (campaign_id) REFERENCES political_schema.campaign (campaign_id)
);


create table if not exists political_schema.survey_question (
	question_id Serial PRIMARY KEY,
	survey_id INT not null,
	question VARCHAR(250) not null,
	type TEXT NOT NULL CHECK (type IN ('yes_no', 'scale', 'multiple_choice', 'rating', 'text')), --type must be one of the listed questionnaire types, there is not default
	CONSTRAINT survey_Fkey FOREIGN KEY (survey_id) REFERENCES political_schema.survey (survey_id)
);


create table if not exists political_schema.survey_response (
	response_id serial primary key,
	question_id INT not null,
	voter_id INT not null,
	response VARCHAR(250) not null,
	CONSTRAINT question_Fkey FOREIGN KEY (question_id) REFERENCES political_schema.survey_question (question_id),
	CONSTRAINT voter_Fkey FOREIGN KEY (voter_id) REFERENCES political_schema.voter (voter_id)
);


create table if not exists political_schema.measure_event (
	measure_event_id serial primary key,
	event_type TEXT NOT NULL CHECK (event_type IN ('rally', 'town_hall', 'debate', 'survey', 'other')), --event_type must be one of the listed measure events, there is not default
	event_date TIMESTAMP not NULL,
	description TEXT
);


create table if not exists political_schema.opponent_measure (
	measure_id serial primary key,
	measure_event_id INT not null,
	voter_id INT not null,
	opponent_strength INT NOT NULL CHECK (opponent_strength >= 0 AND opponent_strength <= 10), --checking if the number is between 0 and 10.
	public_opinion_score INT not null check(public_opinion_score >= 0 AND public_opinion_score <= 10), --checking if the number is between 0 and 10.
	feedback text,
	result INT GENERATED ALWAYS AS (opponent_strength * public_opinion_score) stored,
	CONSTRAINT measure_event_Fkey FOREIGN KEY (measure_event_id) REFERENCES political_schema.measure_event (measure_event_id),
	CONSTRAINT voter_Fkey FOREIGN KEY (voter_id) REFERENCES political_schema.voter (voter_id)
);


create table if not exists political_schema.event_participant (
	event_participant_id serial primary key,
	event_id INT not null,
	volunteer_id INT not null,
	unique (event_id, volunteer_id), --unique, because the volunteer paricipates on an event and it is unique key combination
	CONSTRAINT volunteer_Fkey FOREIGN KEY (volunteer_id) REFERENCES political_schema.volunteer (volunteer_id),
	CONSTRAINT event_Fkey FOREIGN KEY (event_id) REFERENCES political_schema.event (event_id)
);

commit;

begin;


alter table political_schema.address add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.voter add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.contributor add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.campaign add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.campaign_contribution add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.finance add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.contribution_finance add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.event add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.volunteer add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.survey add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.survey_question add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.survey_response add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.measure_event add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.opponent_measure add column record_ts DATE DEFAULT CURRENT_DATE;
alter table political_schema.event_participant add column record_ts DATE DEFAULT CURRENT_DATE;

commit;

begin;

insert into political_schema.address (country, city, zip_code, address)
	select 'Hungary', 'Szeged', '6723', 'Malom street 13/A'
		where not exists (
			select 1 from political_schema.address
			where country = 'Hungary' and city =  'Szeged' and zip_code =  '6723' and address = 'Malom street 13/A'
			)
	union all 
	select 'Hungary', 'Budapest', '1173', 'Erzsebet street 42'
		where not exists (
			select 1 from political_schema.address
			where country = 'Hungary' and city =  'Budapest' and zip_code =  '1173' and address = 'Erzsebet street 42'
			)
	union all 
	select 'Hungary', 'Budapest', '1121', 'Jozsef roundway 12'
		where not exists (
			select 1 from political_schema.address
			where country = 'Hungary' and city =  'Budapest' and zip_code =  '1121' and address = 'Jozsef roundway 12'
			)
	union all 
	select 'Hungary', 'Békéscsaba', '6854', 'Gyula highway 32'
		where not exists (
			select 1 from political_schema.address
			where country = 'Hungary' and city =  'Békéscsaba' and zip_code =  '6854' and address = 'Gyula highway 32'
			)
	union all 
	select 'Austria', 'Wien', 'A73_8844', 'Maria-hilfer strasse 77'
		where not exists (
			select 1 from political_schema.address
			where country = 'Austria' and city =  'Wien' and zip_code =  'A73_8844' and address = 'Maria-hilfer strasse 77'
			)
	returning address_id;
	
		
INSERT INTO political_schema.voter (address_id, first_name, last_name, gender, email, phone)
	SELECT 
    	address_id, 'James', 'Jordan', 'M', 'james.jordan@example.com', '06309875641'
	FROM political_schema.address 
	WHERE UPPER(country) = 'HUNGARY' 
 	 AND UPPER(city) = 'SZEGED' 
  	AND zip_code = '6723' 
 	 AND UPPER(address) = 'MALOM STREET 13/A'
  	AND NOT EXISTS (SELECT 1 FROM political_schema.voter WHERE email = 'james.jordan@example.com')
	UNION ALL
	SELECT 
    	address_id, 'Chuck', 'Jones', 'M', 'chuck.jones@example.com', '06201547865'
	FROM political_schema.address 
	WHERE UPPER(country) = 'HUNGARY' 
  	AND UPPER(city) = 'BUDAPEST' 
  	AND zip_code = '1173' 
  	AND UPPER(address) = 'ERZSEBET STREET 42'
  	AND NOT EXISTS (SELECT 1 FROM political_schema.voter WHERE email = 'chuck.jones@example.com')
	UNION ALL
	SELECT 
    	address_id, 'Adeliene', 'Francis', 'F', 'adeliene.francis@example.com', '06709951167'
	FROM political_schema.address 
	WHERE UPPER(country) = 'HUNGARY' 
  	AND UPPER(city) = 'BUDAPEST' 
  	AND zip_code = '1121' 
  	AND UPPER(address) = 'JOZSEF ROUNDWAY 12'
 	 AND NOT EXISTS (SELECT 1 FROM political_schema.voter WHERE email = 'adeliene.francis@example.com')
 	returning voter_id;

insert into political_schema.contributor (first_name, last_name, email, phone, donation_amount)
	select 'Frank', 'Hymenes', 'frank.hymenes@example.com', '36705847335', 500
		where not exists (
			select 1 from political_schema.contributor
				where first_name = 'Frank'
				and last_name = 'Hymenes'
				and email = 'frank.hymenes@example.com')
	union 
	select 'Tina', 'Smith', 'tina.smith@example.com', '06305125321', 2500
		where not exists (
			select 1 from political_schema.contributor
				where first_name = 'Tina'
				and last_name = 'Smith'
				and email = 'tina.smith@example.com')
	union  
	select 'Hhyman', 'Roth', 'hhyman.roth@example.com', '06308547211', 1000
		where not exists (
			select 1 from political_schema.contributor
				where first_name = 'Hhyman'
				and last_name = 'Roth'
				and email = 'hhyman.roth@example.com')
	returning contributor_id;

insert into political_schema.campaign (name, start_date, end_date, is_active)
	select 'Fundraising october', cast('2024-10-01' AS DATE), cast ('2024-10-31' as DATE), false
		where not exists (
			select 1 from political_schema.campaign
				where name = 'Fundraising october')
	union 
	select 'Fundraising november', cast('2024-11-01' as DATE), null, true
		where not exists (
			select 1 from political_schema.campaign
				where name = 'Fundraising november')
	union  
	select 'District-Level', cast('2024-01-01' as DATE), null, true
		where not exists (
			select 1 from political_schema.campaign
				where name = 'District-Level')
	returning campaign_id;

insert into political_schema.campaign_contribution (campaign_id, contributor_id, contribution_amount, contribution_date)
	select
		(SELECT campaign_id FROM political_schema.campaign WHERE name = 'Fundraising october'),
		(SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'FRANK' AND UPPER(last_name) = 'HYMENES' and email = 'frank.hymenes@example.com'),
		500, cast('2024-10-10' as DATE)
		where not exists (
			select 1 from political_schema.campaign_contribution
				where campaign_id = (SELECT campaign_id FROM political_schema.campaign WHERE name = 'Fundraising october')
				and contributor_id = (SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'FRANK' AND UPPER(last_name) = 'HYMENES' and email = 'frank.hymenes@example.com')
				and contribution_date = cast('2024-10-10' as DATE))
	union
	SELECT	
		(SELECT campaign_id FROM political_schema.campaign WHERE name = 'Fundraising november'),
		(SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'TINA' AND UPPER(last_name) = 'SMITH' and email = 'tina.smith@example.com'),
		2500, '2024-11-10'
		where not exists (
			select 1 from political_schema.campaign_contribution
				where campaign_id = (SELECT campaign_id FROM political_schema.campaign WHERE name = 'Fundraising november')
				and contributor_id = (SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'TINA' AND UPPER(last_name) = 'SMITH' and email = 'tina.smith@example.com')
				and contribution_date = cast('2024-11-10' as DATE))
	union
	SELECT
		(SELECT campaign_id FROM political_schema.campaign WHERE name = 'Fundraising november'),
		(SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'HHYMAN' AND UPPER(last_name) = 'ROTH' and email = 'hhyman.roth@example.com'),
		2500, '2024-11-12'
		where not exists (
			select 1 from political_schema.campaign_contribution
				where campaign_id = (SELECT campaign_id FROM political_schema.campaign WHERE name = 'Fundraising november')
				and contributor_id = (SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'HHYMAN' AND UPPER(last_name) = 'ROTH' and email = 'hhyman.roth@example.com')
				and contribution_date = cast('2024-11-12' as DATE))
	returning campaign_contribution_id;

--Why can not be duplicates? A contributor can give donation for campaign several times. So i put the contribution_date to the where not exists, because
--i lock the donation for 1 person can only donate for each campaign only once a day. 

insert into political_schema.finance (campaign_id, expense_description, expense_amount, transactional_date)
	SELECT
		(SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising october'), 'Advertising', 500, cast('2024-10-01' as DATE)
	where not exists (
		select 1 from political_schema.finance
			where campaign_id = (SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising october')
			and expense_description = 'Advertising'
			and transactional_date = cast('2024-10-01' as date))
	union 
	SELECT
		(SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising november'), 'Contributors event', 5000, cast('2024-11-15' as date)
	where not exists (
		select 1 from political_schema.finance
			where campaign_id = (SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising november')
			and expense_description = 'Contributors event'
			and transactional_date = cast('2024-11-15' as date))
	returning finance_id;


insert into political_schema.contribution_finance (contributor_id, finance_id)
	SELECT 
		(SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'FRANK' AND UPPER(last_name) = 'HYMENES' and email = 'frank.hymenes@example.com'), 
		(SELECT finance_id FROM political_schema.finance WHERE expense_description = 'Advertising' and campaign_id = (SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising october'))
		where not exists (
			select 1 from political_schema.contribution_finance
				where contributor_id = (SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'FRANK' AND UPPER(last_name) = 'HYMENES' and email = 'frank.hymenes@example.com')
				and finance_id = (SELECT finance_id FROM political_schema.finance WHERE expense_description = 'Advertising' and campaign_id = (SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising october')))
		union
	select
		(SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'TINA' AND UPPER(last_name) = 'SMITH' and email = 'tina.smith@example.com'), 
		(SELECT finance_id FROM political_schema.finance WHERE expense_description = 'Contributors event' and campaign_id = (SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising november'))
		where not exists (
			select 1 from political_schema.contribution_finance
				where contributor_id = (SELECT contributor_id FROM political_schema.contributor WHERE upper(first_name) = 'TINA' AND UPPER(last_name) = 'SMITH' and email = 'tina.smith@example.com')
				and finance_id = (SELECT finance_id FROM political_schema.finance WHERE expense_description = 'Contributors event' and campaign_id = (SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising november')))
	returning *;

insert into political_schema.event (campaign_id, event_type, event_date, location, description)
	SELECT
		(SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising october'), 'rally', cast('2024-10-01 10:00:00' as timestamp), 'Budapest', 'Fundraising rally in the Hősök square'
		where not exists (
			select 1 from political_schema.event
				where campaign_id = (SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising october')
				and event_type = 'rally' and event_date = cast('2024-10-01 10:00:00' as timestamp))
		union
	select
		(SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising november'), 'town_hall', cast('2024-11-20 18:00:00' as timestamp), 'Budapest', 'Fundraising for the contriubutors event'
		where not exists (
			select 1 from political_schema.event
				where campaign_id = (SELECT campaign_id from political_schema.campaign WHERE name = 'Fundraising november')
				and event_type = 'town_hall' and event_date = cast('2024-11-20 18:00:00' as timestamp))
	returning event_id;



insert into political_schema.volunteer (address_id, first_name, last_name, gender, email, phone, availability, role)
	select 
		address_id, 'Michael', 'Jordan', 'M', 'michael.jordan@example.com', '06309875640', true, 'data collector'
	from political_schema.address 
		WHERE UPPER(country) = 'AUSTRIA' 
 	 	AND UPPER(city) = 'WIEN' 
  		AND zip_code = 'A73_8844' 
 	 	AND UPPER(address) = 'MARIA-HILFER STRASSE 77'
  		AND NOT EXISTS (SELECT 1 FROM political_schema.volunteer WHERE email = 'michael.jordan@example.com')
	UNION ALL
	select 
		address_id, 'Hugh', 'Coleman', 'M', 'hugh.coleman@example.com', '06208857412', true, 'bar staff'
	from political_schema.address 
		WHERE UPPER(country) = 'HUNGARY' 
 	 	AND UPPER(city) = 'BÉKÉSCSABA' 
  		AND zip_code = '6854' 
 	 	AND UPPER(address) = 'GYULA HIGHWAY 32'
  		AND NOT EXISTS (SELECT 1 FROM political_schema.volunteer WHERE email = 'hugh.coleman@example.com')
  	returning volunteer_id;

commit;

insert into political_schema.survey (campaign_id, survey_name, survey_date)
	select
		(select campaign_id from political_schema.campaign WHERE name = 'Fundraising october'), 'October Campaign Feedback', cast('2024-11-02' as date)
		where not exists (
			select 1 from political_schema.survey
				where campaign_id = (select campaign_id from political_schema.campaign WHERE name = 'Fundraising october')
				and survey_name = 'October Campaign Feedback')	
	union
	select
		(select campaign_id from political_schema.campaign WHERE name = 'Fundraising november'), 'Contributors Event Feedback', cast('2024-11-22' as date)
		where not exists (
			select 1 from political_schema.survey
				where campaign_id = (select campaign_id from political_schema.campaign WHERE name = 'Fundraising november')
				and survey_name = 'Contributors Event Feedback')
	returning survey_id;
			
--Should i include survey_date as well? Because i lock out all the same named surveys for the same campaign. 
--But what if they start the same campaign (so the ID will be the same), and use the same name for the survey, 
--but with a different date, so they can start a new one, which they can measure later. So they won't use the old surveys, 
--and there won't be any conflicts
	commit;
			
insert into political_schema.survey_question (survey_id, question, type)
	select
		(SELECT survey_id from political_schema.survey WHERE survey_name = 'October Campaign Feedback'),
		'Do you support our campaign goals?', 'yes_no'
		where not exists (
			select 1 from political_schema.survey_question
				where survey_id = (SELECT survey_id from political_schema.survey WHERE survey_name = 'October Campaign Feedback')
				and question = 'Do you support our campaign goals?' and type = 'yes_no')
	union
	select
		(SELECT survey_id from political_schema.survey WHERE survey_name = 'Contributors Event Feedback'),
		'How do you like our candidate', 'rating'
		where not exists (
			select 1 from political_schema.survey_question
				where survey_id = (SELECT survey_id from political_schema.survey WHERE survey_name = 'Contributors Event Feedback')
				and question = 'How do you like our candidate' and type = 'rating')
	returning question_id;

insert into political_schema.survey_response (question_id, voter_id, response)
	SELECT
		(SELECT question_id FROM political_schema.survey_question WHERE question = 'Do you support our campaign goals?'),
		(SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com'),
		'Yes'
		WHERE NOT EXISTS (
			SELECT 1 FROM political_schema.survey_response 
				WHERE question_id = (SELECT question_id FROM political_schema.survey_question WHERE question = 'Do you support our campaign goals?') 
				AND voter_id = (SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com'))
	returning response_id;

insert into political_schema.survey_response (question_id, voter_id, response)
	SELECT		
		(SELECT question_id FROM political_schema.survey_question WHERE question = 'Do you support our campaign goals?'),
		(SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com'),
		'No'
		WHERE NOT EXISTS (
			SELECT 1 FROM political_schema.survey_response 
				WHERE question_id = (SELECT question_id FROM political_schema.survey_question WHERE question = 'do you support our campaign goals?') 
				AND voter_id = (SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com'))
	returning response_id;


INSERT INTO political_schema.measure_event (event_type, event_date, description)
	select
		'rally', cast('2024-10-08 16:00:00' as timestamp), 'Fidesz party rally held next to the Parlaiment'
		where not exists (
			select 1 from political_schema.measure_event
				where event_type = 'rally' and event_date = cast('2024-10-08 16:00:00' as timestamp))
	union
	select
		'debate', cast('2024-11-15 18:00:00' as timestamp), 'Fidesz and Momentum parties debate for city election'
		where not exists (
			select 1 from political_schema.measure_event
				where event_type = 'debate' and event_date = cast('2024-11-15 18:00:00' as timestamp))
	returning measure_event_id;


INSERT INTO political_schema.opponent_measure (measure_event_id, voter_id, opponent_strength, public_opinion_score, feedback)
	select
		(SELECT measure_event_id FROM political_schema.measure_event WHERE event_type = 'rally' AND event_date = cast('2024-10-08 16:00:00' as timestamp)),
		(SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com'), 2, 4, 'Very aggressive and hostile.'
		where not exists (
			select 1 from political_schema.opponent_measure
				where measure_event_id = (SELECT measure_event_id FROM political_schema.measure_event WHERE event_type = 'rally' AND event_date = cast('2024-10-08 16:00:00' as timestamp))
				and voter_id = (SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com'))	
	union
	select
		(SELECT measure_event_id FROM political_schema.measure_event WHERE event_type = 'rally' AND event_date = cast('2024-10-08 16:00:00' as timestamp)),
		(SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com'), 10, 4, 'I like his aggressiveness.'
		where not exists (
			select 1 from political_schema.opponent_measure
				where measure_event_id = (SELECT measure_event_id FROM political_schema.measure_event WHERE event_type = 'rally' AND event_date = cast('2024-10-08 16:00:00' as timestamp))
				and voter_id = (SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com'))
	union
	select
		(SELECT measure_event_id FROM political_schema.measure_event WHERE event_type = 'debate' AND event_date = cast('2024-11-15 18:00:00' as timestamp)),
		(SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com'), 4, 8, 'It was a fair debate'
		where not exists (
			select 1 from political_schema.opponent_measure
				where measure_event_id = (SELECT measure_event_id FROM political_schema.measure_event WHERE event_type = 'debate' AND event_date = cast('2024-11-15 18:00:00' as timestamp))
				and voter_id = (SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com'))	
	union
	select
		(SELECT measure_event_id FROM political_schema.measure_event WHERE event_type = 'debate' AND event_date = cast('2024-11-15 18:00:00' as timestamp)),
		(SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com'), 6, 8, 'Our party did not win the whole debate, but we were better than the other one'
		where not exists (
			select 1 from political_schema.opponent_measure
				where measure_event_id = (SELECT measure_event_id FROM political_schema.measure_event WHERE event_type = 'debate' AND event_date = cast('2024-11-15 18:00:00' as timestamp))
				and voter_id = (SELECT voter_id FROM political_schema.voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com'))
	returning measure_id;


insert into political_schema.event_participant (event_id, volunteer_id)
	select
		(SELECT event_id FROM political_schema.event WHERE event_type = 'rally' AND event_date = cast('2024-10-01 10:00:00' as timestamp)),
		(SELECT volunteer_id FROM political_schema.volunteer WHERE upper(first_name) = 'MICHAEL' AND UPPER(last_name) = 'JORDAN')
		where not exists (
			select 1 from political_schema.event_participant
				where event_id = (SELECT event_id FROM political_schema.event WHERE event_type = 'rally' AND event_date = cast('2024-10-01 10:00:00' as timestamp))
				and volunteer_id = (SELECT volunteer_id FROM political_schema.volunteer WHERE upper(first_name) = 'MICHAEL' AND UPPER(last_name) = 'JORDAN'))
	union
	select
		(SELECT event_id FROM political_schema.event WHERE event_type = 'town_hall' AND event_date = cast('2024-11-20 18:00:00' as timestamp)),
		(SELECT volunteer_id FROM political_schema.volunteer WHERE upper(first_name) = 'HUGH' AND UPPER(last_name) = 'COLEMAN')
		where not exists (
			select 1 from political_schema.event_participant
				where event_id = (SELECT event_id FROM political_schema.event WHERE event_type = 'town_hall' AND event_date = cast('2024-11-20 18:00:00' as timestamp))
				and volunteer_id = (SELECT volunteer_id FROM political_schema.volunteer WHERE upper(first_name) = 'HUGH' AND UPPER(last_name) = 'COLEMAN'))
	returning event_participant_id;

commit;
	
--I do not know why it doesn't want to accept the dates and timestamps... I had to cast them manually. 
--I hope you accept it, but if not, i will have more time to find out. Now i have to start working on the current homework 