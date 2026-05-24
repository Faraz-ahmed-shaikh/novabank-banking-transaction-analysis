create table raw_branches (
	branch_id varchar(50) primary key,
	name varchar(50) not null,
	address varchar(50) not null,
	city varchar(20) not null,
	state varchar(20) check (state in ('Maharashtra','Karnataka'))
);

create table raw_customers (
	customer_id	varchar(50) primary key,
	customer_name varchar(100) not null,
	email varchar(100) not null,
	dob date check (dob < current_date),
	signup_date date check (signup_date < current_date),
	branch_id varchar(50) references raw_branches(branch_id),
	customer_status varchar(20) check (customer_status in ('Active', 'Declining', 'Churned', 'Dormant'))
);

create table raw_accounts (
	account_number varchar(50) primary key,
	customer_id varchar(50) references raw_customers(customer_id),
	account_type varchar(20) check (account_type in ('Savings', 'Current', 'Fixed Deposit')),
	opened_date date check (opened_date < current_date),
	current_balance numeric(20,2) check (current_balance >= 0),
	account_status varchar(20) check (account_status in ('Active', 'Closed', 'Frozen'))
);

create table raw_transactions (
	transaction_id varchar(50) primary key,
	customer_id varchar(50) references raw_customers(customer_id),
	account_number varchar(50) references raw_accounts(account_number),
	transaction_datetime timestamp,
	amount numeric(20,2) check (amount >= 0),
	transaction_type varchar(50),
	is_online varchar(10),
	debit_or_credit varchar(20) check (debit_or_credit in ('Debit', 'Credit')),
	transaction_status varchar(20),
	balance_after_transaction numeric(20,2) 
);

select count(branch_id) from raw_branches; -- 10 Rows 
select count(customer_id) from raw_customers; -- 5000 Rows
select count(account_number) from raw_accounts; -- 6356 Rows
select count(transaction_id) from raw_transactions; -- 297129 Rows

CREATE TABLE branches (LIKE raw_branches INCLUDING ALL);
INSERT INTO branches SELECT * FROM raw_branches;

create table customers (like raw_customers including all);
insert into customers select * from raw_customers;

create table accounts (like raw_accounts including all);
insert into accounts select * from raw_accounts;

create table transactions (like raw_transactions including all);
insert into transactions select * from raw_transactions;

-- Cleaning Branches 
select count(*) from branches; 

select * from branches limit 10;

select  column_name,  data_type
from information_schema.columns
where table_name = 'branches';

update branches set name = trim(initcap(name));
select distinct name from branches;

update branches set address = trim(initcap(address));
select distinct address from branches;

update branches set city = trim(initcap(city));
select distinct city from branches;

alter table branches drop constraint raw_branches_state_check;
alter table branches add constraint raw_branches_state_check check(state in ('Maharashtra', 'Karnataka','maharashtra', 'karnataka'));
update branches set state = trim(initcap(state));
select distinct state from branches;

select * from branches;

-- Cleaning customers

select count(*) from customers;

select * from customers limit 50;

select column_name, data_type from information_schema.columns where table_name = 'customers';

update customers set email = trim(lower(email));
select distinct email from customers;

update customers set customer_status = trim(initcap(customer_status));
select distinct customer_status from customers;

update customers set customer_name = trim(initcap(customer_name));
select distinct customer_name from customers;

select customer_name, email, count(*)
from customers
group by 1,2
having count(*) > 1;

-- There are 46 duplicates emails

select * from customers 
where customer_id not in (select min(customer_id)
from customers
group by email);

-- Check if any duplicate customer_ids have accounts
SELECT c.customer_id, c.email
FROM customers c
WHERE c.customer_id NOT IN (
    SELECT MIN(customer_id)
    FROM customers
    GROUP BY email
)
AND c.customer_id IN (
    SELECT DISTINCT customer_id FROM accounts
);

-- Check if any have transactions
SELECT c.customer_id, c.email
FROM customers c
WHERE c.customer_id NOT IN (
    SELECT MIN(customer_id)
    FROM customers
    GROUP BY email
)
AND c.customer_id IN (
    SELECT DISTINCT customer_id FROM transactions
);

--  These customers with duplicate emails has own separate bank accounts with transactions, thus deleting them or changing the account no can cause trouble and outbreak, thus we are flagging them 

alter table customers add column is_duplicate_email boolean default False;
update customers set is_duplicate_email = True
where customer_id not in (select min(customer_id)
from customers
group by email);

select count(*) from customers where is_duplicate_email = True; -- All 46 customers are flagged and they would be highlighted Stakeholder recommending him to add proper email validation

-- Cleaning accounts table
select count(*) from accounts;

select * from accounts limit 50;

select column_name, data_type from information_schema.columns where table_name = 'accounts';

update accounts set account_type =  trim(initcap(account_type));
update accounts set account_status =  trim(initcap(account_status));

select c.customer_id from customers as c left join accounts as a on c.customer_id = a.customer_id where a.account_number is null;
-- checking a customer who doesn't have bank account 

select min(current_balance), max(current_balance), avg(current_balance) from accounts; 
-- The minimum balance is 0 and maximum balance is 1,197,320 which is not a extreme value along with 80,000 as avg balance which might be skewed bcz of high balaance account but its okay 

-- Cleaning transactions table
select count(*) from transactions;

select * from transactions limit 10;

select column_name, data_type from information_schema.columns where table_name = 'transactions'; 

update transactions set transaction_status =  trim(initcap(transaction_status));
update transactions set transaction_type =  trim(initcap(transaction_type));

select min(amount), max(amount), avg(amount) from transactions; -- The minimum amount of transaction is 50, max is 500000 even though the account type of the highest transaction amount is saving and the max current_balance was 120K while the avg transaction is 12k, which is realistic we just need to flag it 

alter table transactions add column is_high_value_transaction boolean default False;
update transactions set is_high_value_transaction = True where amount > 200000;
select count(*) from transactions where is_high_value_transaction = True;

select min(balance_after_transaction), max(balance_after_transaction), avg(balance_after_transaction) from transactions; -- The Minimum balance after transaction is -50,000 (bcz of overdraft facilities), while maximum is 36,09,363.10 and avg is 1,02,945 

alter table transactions add column is_negative_balance boolean default False;
update transactions set is_negative_balance = True where balance_after_transaction < 0;

select count(*) from transactions where is_negative_balance = True; 
-- 35,357 balance_after_transaction are in negavtive

select count(*) from transactions as t inner join accounts as a on t.account_number = a.account_number where is_negative_balance = True and a.account_type in ('Savings', 'Fixed Deposit');
-- There are 27k negative balance even in savings and current

alter table transactions add column is_unreliable_data boolean default False;

update transactions set is_unreliable_data = True where transaction_id in
( select t.transaction_id from transactions as t inner join accounts as a on a.account_number = t.account_number
where is_negative_balance = True and a.account_type in ('Savings', 'Fixed Deposit'));
update transactions set is_unreliable_data = True where transaction_id in
( select t.transaction_id from transactions as t inner join accounts as a on a.account_number = t.account_number
where balance_after_transaction < -50000 and a.account_type in ('Current'));

-- balance_after_transaction flagged for 11-12% of rows across account types due to sequential balance tracking artifact in synthetic data generation. Flagged rows excluded from balance trend analysis. Inflow/outflow patterns used as alternative behavioral signal.

begin;
update transactions set transaction_type = 'Withdrawal or Deposit' where transaction_type ilike '' and is_online ilike 'FALSE';
update transactions set transaction_type = 'Online Transaction' where transaction_type ilike '' and is_online ilike 'TRUE';
update transactions set transaction_type = 'Unknow' where transaction_type ilike '' and is_online ilike '';
commit;

select * from transactions where transaction_type ilike ''; -- 0 Rows left
select transaction_type, count(*) from transactions group by 1;
-- Imputed 4501 nulls of transaction_type with cross column logic

select * from transactions where is_online ilike ''; -- 2425 rows  
select distinct transaction_type from transactions where is_online ilike 'FALSE';
select distinct transaction_type from transactions where is_online ilike 'TRUE';
select * from transactions where is_online ilike '' and transaction_type in ('Atm Withdrawal', 'Cash Deposit', 'Withdrawal or Deposit');
select * from transactions where is_online ilike '' and transaction_type  not in ('Unknow','Atm Withdrawal', 'Cash Deposit', 'Withdrawal or Deposit');

begin;
update transactions set is_online = 'FALSE' where is_online ilike '' and transaction_type in ('Atm Withdrawal', 'Cash Deposit', 'Withdrawal or Deposit');
update transactions set is_online = 'TRUE' where is_online ilike '' and transaction_type  not in ('Unknow','Atm Withdrawal', 'Cash Deposit', 'Withdrawal or Deposit');
update transactions set is_online = 'FALSE' where is_online ilike '';
commit; -- Imputing Nulls of is_online by cross column logic and then imputing 46 rows with force False

select * from transactions where is_online ilike '';
select distinct is_online from transactions;

begin;
alter table transactions alter column is_online type boolean using is_online::boolean;
select distinct is_online from transactions;
select column_name, data_type from information_schema.columns where table_name = 'transactions';
commit; -- Changing Data type

select * from transactions where is_online is null or transaction_type ilike ''; -- Final check

-- Now Fixing the final customer with no transactions 
select count(c.customer_id) 
from customers as c left join transactions as t on c.customer_id = t.customer_id
where t.transaction_id is null
limit 20; -- This number was cross check by: Total No. of customers (5000) - Total No. of unique customers in transactions table (2279) = 2721 No transactioning customers

begin;
alter table customers add column is_non_transacting_customer boolean default False;
update customers set is_non_transacting_customer = True 
where customer_id in (
	select distinct c.customer_id 
	from customers as c left join transactions as t on c.customer_id = t.customer_id
	where t.transaction_id is null
);
select count(*) from customers where is_non_transacting_customer = True; -- should be 2721
commit;
select is_non_transacting_customer, count(*) from customers group by is_non_transacting_customer; -- correct

update transactions set transaction_type = 'Unknown' where transaction_type = 'Unknow'; -- Fixed spelling issue

-- Extracting Date Features
alter table transactions add column transaction_year int;
update transactions set transaction_year = extract (year from transaction_datetime);
alter table transactions add column transaction_month int;
update transactions set transaction_month = extract (month from transaction_datetime);
alter table transactions add column transaction_quarter int;
update transactions set transaction_quarter = extract (quarter from transaction_datetime

-- Now Flagging Accounts with no transactions 

select count(distinct account_number) from transactions; -- There are only 2942 accounts from 6356 total accounts who have made transactions thus there are 3414 accounts with no transactions
-- Now we have to flag those accounts as non_transacting_account
select count(distinct a.account_number) 
from accounts as a left join transactions as t on a.account_number = t.account_number
where t.transaction_id is null; -- the 3414 number matches

begin;
alter table accounts add column is_non_transacting_account boolean default False;
update accounts set is_non_transacting_account = True
where account_number in (
	select distinct a.account_number) 
	from accounts as a left join transactions as t on a.account_number = t.account_number
	where t.transaction_id is null
);
select count(*) from accounts where is_non_transacting_account = True;
select count(*) from accounts where is_non_transacting_account = False;
commit;

select * from accounts limit 100;
select account_status, (
	sum(case when is_non_transacting_account = True then 1 else 0 end) * 100.0 / count(account_number)
) as per_of_nta
from accounts group by 1; -- 50% of Active, 100% Closed & 64.5% Frozen Accounts is non transacting (Its a insight)

-- =========================================
-- Data Validation : Branches
-- =========================================

SELECT COUNT(*) FROM branches; -- branches table has 10 rows i.e correct

SELECT  * FROM branches; -- Table looks fine

SELECT  column_name,  data_type
FROM information_schema.columns
WHERE table_name = 'branches'; -- All have correct data types

SELECT
    SUM(CASE WHEN branch_id IS NULL THEN 1 ELSE 0 END) AS branch_nulls,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS name_nulls,
	SUM(CASE WHEN address IS NULL THEN 1 ELSE 0 END) AS address_nulls,
	SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
	SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END) AS state_nulls
FROM branches; -- There are no nulls perfect!

SELECT COUNT(DISTINCT branch_id) FROM branches; -- There are 10 unique id means id don't have null
SELECT COUNT(DISTINCT name) FROM branches;
SELECT COUNT(DISTINCT address) FROM branches; -- The names and address are also unique 
SELECT DISTINCT city FROM branches; -- No Typos or fuzz words 
SELECT DISTINCT state FROM branches; -- Again correct

-- There are no numeric columns for statistical profiling

-- =========================================
-- Data Validation : Customers Table
-- =========================================

SELECT COUNT(*) FROM customers; -- customers table has 5000 rows i.e correct

SELECT * FROM customers limit 100; -- Table preview looks fine

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'customers';
-- All columns have correct data types

SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS customer_name_nulls,
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS email_nulls,
    SUM(CASE WHEN dob IS NULL THEN 1 ELSE 0 END) AS dob_nulls,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS signup_date_nulls,
    SUM(CASE WHEN branch_id IS NULL THEN 1 ELSE 0 END) AS branch_id_nulls,
    SUM(CASE WHEN customer_status IS NULL THEN 1 ELSE 0 END) AS customer_status_nulls
FROM customers;
-- There are no null values in existing columns

SELECT COUNT(DISTINCT customer_id) FROM customers; -- All customer IDs are unique

SELECT COUNT(DISTINCT email) FROM customers; -- 46 emails where duplicates we already new it

SELECT COUNT(DISTINCT customer_name) FROM customers; -- Checking customer name uniqueness (1593 unique names)

SELECT DISTINCT customer_status FROM customers;-- No typo or fuzz values in customer_status

SELECT DISTINCT branch_id FROM customers; -- All branch IDs appear valid

SELECT *
FROM customers
WHERE email NOT LIKE '%@%.%'; -- No invalid email patterns found

SELECT *
FROM customers
WHERE dob >= CURRENT_DATE; -- No future DOB values found

SELECT *
FROM customers
WHERE signup_date >= CURRENT_DATE; -- No future signup dates found

SELECT
    MIN(dob) AS oldest_dob,
    MAX(dob) AS youngest_dob
FROM customers; -- DOB range looks realistic

SELECT
    MIN(signup_date) AS earliest_signup,
    MAX(signup_date) AS latest_signup
FROM customers; -- Signup dates look realistic

SELECT c.customer_id
FROM customers c
LEFT JOIN branches b
ON c.branch_id = b.branch_id
WHERE b.branch_id IS NULL; -- No customers with out branch 

SELECT b.branch_id 
FROM branches b 
LEFT JOIN customers c
ON c.branch_id = b.branch_id
WHERE c.customer_id IS NULL; -- No branch with out customers

SELECT
    customer_status,
    COUNT(*) AS total_customers
FROM customers
GROUP BY customer_status
ORDER BY total_customers DESC;
-- Customer status distribution looks reasonable

SELECT is_duplicate_email , COUNT(*) FROM customers
GROUP BY 1; -- the is_duplicate_email is correct as we know

SELECT is_non_transacting_customer , COUNT(*) FROM customers
GROUP BY 1; -- the is_non_transacting_customer is correct as we know, but a concrn as 2721 customers are non transacting 

SELECT
    branch_id,
    COUNT(*) AS total_customers
FROM customers
GROUP BY branch_id
ORDER BY total_customers DESC;
-- Customer distribution across branches verified

select min(age), max(age), avg(age) from customers; -- The age is also reasonable

-- =========================================
-- Data Validation : Accounts Table
-- =========================================

SELECT COUNT(*) FROM accounts; -- accounts table has 6356 rows i.e correct

SELECT * FROM accounts; -- Table preview looks fine

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'accounts'; -- All columns have correct data types

SELECT
    SUM(CASE WHEN account_number IS NULL THEN 1 ELSE 0 END) AS account_number_nulls,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN account_type IS NULL THEN 1 ELSE 0 END) AS account_type_nulls,
    SUM(CASE WHEN opened_date IS NULL THEN 1 ELSE 0 END) AS opened_date_nulls,
    SUM(CASE WHEN current_balance IS NULL THEN 1 ELSE 0 END) AS current_balance_nulls,
    SUM(CASE WHEN account_status IS NULL THEN 1 ELSE 0 END) AS account_status_nulls,
    SUM(CASE WHEN is_non_transacting_account IS NULL THEN 1 ELSE 0 END) AS non_transacting_flag_nulls
FROM accounts; -- There are no null values

SELECT COUNT(DISTINCT account_number) FROM accounts; -- All account numbers are unique

SELECT COUNT(DISTINCT customer_id) FROM accounts; -- the unique customer count is 5000 which means all customers have account

SELECT DISTINCT account_type FROM accounts; -- No typo or fuzz values in account_type

SELECT DISTINCT account_status FROM accounts; -- No typo or fuzz values in account_status

SELECT DISTINCT is_non_transacting_account FROM accounts; -- Non-transacting account flag values look correct

SELECT *
FROM accounts
WHERE opened_date >= CURRENT_DATE; -- No future account opening dates found

SELECT *
FROM accounts
WHERE current_balance < 0; -- No negative balances found

SELECT
    MIN(current_balance) AS minimum_balance,
    MAX(current_balance) AS maximum_balance,
    AVG(current_balance) AS average_balance
FROM accounts; -- Statistical profiling for account balances completed, all numbers looks same i.e reasonable 

SELECT
    account_type,
    COUNT(*) AS total_accounts
FROM accounts
GROUP BY account_type
ORDER BY total_accounts DESC;
-- Account type distribution verified 4119 savings, 1277 current and 960 FDs

SELECT
    account_status,
    COUNT(*) AS total_accounts
FROM accounts
GROUP BY account_status
ORDER BY total_accounts DESC; -- Account status distribution verified 5723 Active, 365 closed and 268 Frozen

SELECT
    is_non_transacting_account,
    COUNT(*) AS total_accounts
FROM accounts
GROUP BY is_non_transacting_account
ORDER BY total_accounts DESC; -- Non-transacting account distribution verified 3414 in 6356 accounts are non transacting 

SELECT sum(current_balance)
FROM accounts
WHERE account_status = 'Closed'
AND current_balance > 0; -- Checking for closed accounts having remaining balance there is 7,40,067 total current balance in Closed Accounts, we have to remind each account owners about there money and try to re-active them

SELECT sum(current_balance)
FROM accounts
WHERE account_status = 'Frozen'
AND current_balance > 0; -- Checking for closed accounts having remaining balance there is 22,89,545 total current balance in Frozen Accounts, what to do with this ?

SELECT
    MIN(opened_date) AS earliest_opened_date,
    MAX(opened_date) AS latest_opened_date
FROM accounts;
-- Account opening date range looks realistic


SELECT a.account_number
FROM accounts a
LEFT JOIN customers c
ON a.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- No orphan Accounts

SELECT
    customer_id,
    COUNT(*) AS total_accounts
FROM accounts
GROUP BY customer_id
ORDER BY total_accounts DESC;
-- Multiple account ownership pattern verified there are customers with 3 accounts too thats normal

SELECT
    customer_id,
    COUNT(*) AS fixed_deposit_accounts
FROM accounts
WHERE account_type = 'Fixed Deposit'
GROUP BY customer_id
HAVING COUNT(*) > 2;
-- Checking unusually high number of fixed deposit accounts


SELECT *
FROM accounts
WHERE is_non_transacting_account = True
AND account_number IN (
    SELECT DISTINCT account_number
    FROM transactions
);
-- Validating that non-transacting accounts truly have no transactions


SELECT *
FROM accounts
WHERE is_non_transacting_account = False
AND account_number NOT IN (
    SELECT DISTINCT account_number
    FROM transactions
);
-- Validating that active transactional accounts exist in transactions table


SELECT
    AVG(current_balance) AS avg_balance_non_transacting_accounts
FROM accounts
WHERE is_non_transacting_account = True;
-- Understanding average balance i.e 72,697 of dormant/non-transacting accounts

SELECT
    AVG(current_balance) AS avg_balance_transacting_accounts
FROM accounts
WHERE is_non_transacting_account = False;
-- Comparing balance behavior i.e 89,160 against active accounts

-- =========================================
-- Data Validation : Transactions Table
-- =========================================

SELECT COUNT(*) FROM transactions;-- transactions table has 297129 rows i.e correct

SELECT * FROM transactions limit 100; -- Table preview looks fine

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'transactions'; -- All columns have correct data types

SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS transaction_id_nulls,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN account_number IS NULL THEN 1 ELSE 0 END) AS account_number_nulls,
    SUM(CASE WHEN transaction_datetime IS NULL THEN 1 ELSE 0 END) AS transaction_datetime_nulls,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS amount_nulls,
    SUM(CASE WHEN transaction_type IS NULL THEN 1 ELSE 0 END) AS transaction_type_nulls,
    SUM(CASE WHEN is_online IS NULL THEN 1 ELSE 0 END) AS is_online_nulls,
    SUM(CASE WHEN debit_or_credit IS NULL THEN 1 ELSE 0 END) AS debit_credit_nulls,
    SUM(CASE WHEN transaction_status IS NULL THEN 1 ELSE 0 END) AS transaction_status_nulls,
    SUM(CASE WHEN balance_after_transaction IS NULL THEN 1 ELSE 0 END) AS balance_after_transaction_nulls,
    SUM(CASE WHEN is_high_value_transaction IS NULL THEN 1 ELSE 0 END) AS high_value_flag_nulls,
    SUM(CASE WHEN is_negative_balance IS NULL THEN 1 ELSE 0 END) AS negative_balance_flag_nulls,
    SUM(CASE WHEN is_unreliable_data IS NULL THEN 1 ELSE 0 END) AS unreliable_data_flag_nulls,
    SUM(CASE WHEN transaction_year IS NULL THEN 1 ELSE 0 END) AS transaction_year_nulls,
    SUM(CASE WHEN transaction_month IS NULL THEN 1 ELSE 0 END) AS transaction_month_nulls,
    SUM(CASE WHEN transaction_quarter IS NULL THEN 1 ELSE 0 END) AS transaction_quarter_nulls
FROM transactions; -- There are no null values Yyayyyyyy


SELECT COUNT(DISTINCT transaction_id) FROM transactions; -- All transaction IDs are unique

SELECT COUNT(DISTINCT customer_id) FROM transactions; -- There are 2279 unique customers as we know 2721 customers didn't transcited

SELECT COUNT(DISTINCT account_number) FROM transactions; -- There are 2942 unique accounts as we know 3414 accounts are there without transactions

SELECT DISTINCT transaction_type
FROM transactions
ORDER BY transaction_type; -- No typo or fuzz values in transaction_type

SELECT DISTINCT transaction_status
FROM transactions
ORDER BY transaction_status; -- No typo or fuzz values in transaction_status

SELECT DISTINCT debit_or_credit
FROM transactions
ORDER BY debit_or_credit; -- Debit/Credit values verified

SELECT DISTINCT is_online
FROM transactions; -- Boolean online transaction values verified

SELECT DISTINCT is_high_value_transaction
FROM transactions; -- High value transaction flag values verified

SELECT DISTINCT is_negative_balance
FROM transactions; -- Negative balance flag values verified

SELECT DISTINCT is_unreliable_data
FROM transactions; -- Unreliable data flag values verified

SELECT *
FROM transactions
WHERE transaction_datetime > CURRENT_TIMESTAMP; -- No future transactions found

SELECT *
FROM transactions
WHERE amount < 0; -- No negative transaction amounts found

SELECT *
FROM transactions
WHERE balance_after_transaction < 0
AND is_negative_balance = FALSE; -- No incorrect negative balance flag found

SELECT *
FROM transactions
WHERE balance_after_transaction >= 0
AND is_negative_balance = TRUE; -- No incorrect negative balance flag found

SELECT *
FROM transactions
WHERE amount > 200000
AND is_high_value_transaction = FALSE; -- Checking missed high value transactions, No errors found

SELECT *
FROM transactions
WHERE amount < 200000
AND is_high_value_transaction = TRUE; -- Checking incorrectly flagged high value transactions, No errors found

SELECT
    MIN(amount) AS minimum_transaction_amount,
    MAX(amount) AS maximum_transaction_amount,
    AVG(amount) AS average_transaction_amount,
    STDDEV(amount) AS transaction_amount_stddev
FROM transactions; -- Statistical profiling for transaction amounts completed
-- Again the min amt is 50.00, max amt is 500000.00, avg amt is	8411.83, and std is	14323

SELECT
    MIN(balance_after_transaction) AS minimum_balance_after_transaction,
    MAX(balance_after_transaction) AS maximum_balance_after_transaction,
    AVG(balance_after_transaction) AS average_balance_after_transaction
FROM transactions;
-- Statistical profiling for balances completed
-- Again the min balance after trans is -50000, max balance after trans is 36,09,363.10, avg balance after trans is	1,02,945.37

SELECT
    MIN(transaction_datetime) AS earliest_transaction,
    MAX(transaction_datetime) AS latest_transaction
FROM transactions; -- Transaction date range looks realistic

SELECT
    transaction_status,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY transaction_status
ORDER BY total_transactions DESC;
-- Transaction status distribution verified, where 245661 successful transaction, 48947 Failed Transaction (we have to point this to stakeholder) and 2521 pending 

SELECT
    transaction_type,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY transaction_type
ORDER BY total_transactions DESC;
-- Transaction type distribution verified
-- "Interest Credit"	61817
-- "Upi Payment"	37577
-- "Online Transfer"	37026
-- "Salary Credit"	34546
-- "Debit Card"	34126
-- "Atm Withdrawal"	30369
-- "Bill Payment"	20662
-- "Cash Deposit"	14273
-- "Shopping"	13614
-- "Subscription"	8618
-- "Online Transaction"	3752
-- "Withdrawal or Deposit"	703
-- "Unknown"	46
SELECT
    debit_or_credit,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY debit_or_credit
ORDER BY total_transactions DESC; -- Debit vs Credit distribution verified, there are 173196 debit and 123933 credit transactions

SELECT
    is_online,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY is_online
ORDER BY total_transactions DESC; -- Online vs offline transaction distribution verified, there are 251738 online transactions and 45391 offline

SELECT
    is_high_value_transaction,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY is_high_value_transaction
ORDER BY total_transactions DESC; -- High value transaction distribution verified, there are 44 high value transactions 

SELECT
    is_negative_balance,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY is_negative_balance
ORDER BY total_transactions DESC;
-- Negative balance transaction distribution verified, total 35357 with negative after balance

SELECT
    is_unreliable_data,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY is_unreliable_data
ORDER BY total_transactions DESC;
-- Unreliable transaction distribution verified, total 27037 unreliable data

SELECT
    transaction_year,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY transaction_year
ORDER BY transaction_year;
-- Transaction year distribution verified, in 2022 there was 63131 transactions, which growed to 233998 transactions in 2023

SELECT
    transaction_year,
    sum (case when is_online = True then 1 else 0 end) as online_trans,
	COUNT(*) AS total_transactions, 
	(sum (case when is_online = True then 1 else 0 end)*100.0 / COUNT(transaction_id))
FROM transactions
GROUP BY transaction_year
ORDER BY transaction_year;

select extract(year from signup_date), count(customer_id)
from customers 
group by 1
order by 1;

select b.state, extract(year from c.signup_date), count(c.customer_id)
from customers as c inner join branches as b on c.branch_id = b.branch_id
group by 1, 2
order by 1, 2;

SELECT
    transaction_month,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY transaction_month
ORDER BY transaction_month;
-- Transaction month distribution verified
-- [
-- 1	15649
-- 2	14961
-- 3	15341
-- 4	17619
-- 5	19092
-- 6	20408
-- 7	24583
-- 8	26426
-- 9	28002
-- 10	35429
-- 11	41947
-- 12	37672
-- ]

SELECT
    transaction_quarter,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY transaction_quarter
ORDER BY transaction_quarter;
-- Transaction quarter distribution verified
-- 1	45951
-- 2	57119
-- 3	79011
-- 4	115048

SELECT t.transaction_id
FROM transactions t
LEFT JOIN customers c
ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- No transactions without customer

SELECT t.transaction_id
FROM transactions t
LEFT JOIN accounts a
ON t.account_number = a.account_number
WHERE a.account_number IS NULL;
-- No transactions without customer

SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;
-- No duplicate transaction IDs found

SELECT *
FROM transactions
WHERE is_unreliable_data = TRUE;
-- Reviewing intentionally injected unreliable/anomalous records


SELECT *
FROM transactions
WHERE amount = 0;
-- Checking suspicious zero amount transactions

SELECT *
FROM transactions
WHERE transaction_status = 'Failed'
AND debit_or_credit = 'Credit';
-- Reviewing failed credit transaction behavior


SELECT
    customer_id,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY customer_id
ORDER BY total_transactions DESC
LIMIT 10;
-- Top highly active customers verified

SELECT
    account_number,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY account_number
ORDER BY total_transactions DESC
LIMIT 10;
-- Most active accounts verified

select * from cleaned_customers;