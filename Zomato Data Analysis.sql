drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select* from goldusers_signup
select * from sales;
select * from product;
select* from users


-- 1.What is the total amount each customer spent on zomato
select s.userid,sum(p.price) as total_amount from sales s
inner join product p on s.product_id=p.product_id
group by s.userid

-- 2.How days has each customer visited zomato
select userid,count(distinct created_date) as days_visited from sales
group by userid

-- 3.What was the first product purchased by each customer
select*from(
select*,rank() over(partition by userid order by created_date) as rank from sales) as a where rank=1

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customer
SELECT s.userid,s.product_id, p.product_name,COUNT(s.product_id) AS product_count
FROM sales s
JOIN product p ON s.product_id = p.product_id
GROUP BY s.userid,s.product_id,p.product_name
ORDER BY product_count desc

-- 5.What is the most popular product for each customer
select * from(
select *,rank() over(partition by userid order by product_count desc) as rank from(
select userid,product_id,count(product_id) as product_count from sales
group by userid,product_id)as a) as b where rank=1

-- 6.Which Item was purchased first by the customer after becoming the member
select * from(
select*,rank() over(partition by userid order by created_date) as rank from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a
inner join goldusers_signup b on a.userid=b.userid
and created_date>= gold_signup_date)a) b where rank =1

-- 7.Which Item was purchased first by the customer before becoming the member
select * from(
select*,rank() over(partition by userid order by created_date desc) as rank from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a
inner join goldusers_signup b on a.userid=b.userid
and created_date< gold_signup_date)a) b where rank =1

--8.What is the total orders and amount spent for each member before they became a member
select userid,count(created_date) as total_orders,sum(price) as total_amount_spent from(
select a.*,p.price from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s
inner join goldusers_signup g on s.userid=g.userid
and created_date< gold_signup_date)a inner join product p on a.product_id=p.product_id)b
group by userid

/*9. If buying each product generates points for eg; 5rs =2 zomato point and each product has different purchasing points
	 for eg; for p1 5rs=1 zomato point,p2 10rs=5 zomato points and p3 5rs=1 zomato point,calculate points collected by each
	 customer and for which products most points have been till now*/ 

select f.userid,sum(total_points) as total_points_user_earned,sum(total_points)*2.5 as total_cashback_user_earned from
(select c.*,amount/points as total_points from
(select b.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select a.userid,a.product_id,sum(price) as amount from
(select s.*,p.price from sales s inner join product p on s.product_id=p.product_id)a
group by a.userid,a.product_id)b)c)f group by f.userid

select f.product_id,sum(total_points) as total_points_earned_on_product from
(select c.*,amount/points as total_points from
(select b.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select a.userid,a.product_id,sum(price) as amount from
(select s.*,p.price from sales s inner join product p on s.product_id=p.product_id)a
group by a.userid,a.product_id)b)c)f group by f.product_id order by total_points_earned_on_product desc

/*10. In the first one year after the customer joins gold program(including their join date) irrespective of what the customer
	  has purchased they earn 5 zomato points for every 10rs spent who earned more user 1 or user 3 and what was their points earning in their first year*/

select a.*,p.price*0.5 as total_earned_points from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s
inner join goldusers_signup g on s.userid=g.userid
and created_date<=dateadd(year,1,gold_signup_date) and created_date>=gold_signup_date)a
inner join product p on a.product_id=p.product_id

-- 11.Rank all the transactions of the customers

select *,rank() over(partition by userid order by created_date) as rank from sales

--12.Rank all the transactions for each member whenever they are a zomato gold signup member for every non gold transaction mark as NA
select c.*,case when gold_signup_date is NULL then 'NA' else cast(rank as varchar)  end as rank from
(select a.userid,a.created_date,b.gold_signup_date,rank() over (partition by a.userid order by b.gold_signup_date desc) as rank from sales a
left join goldusers_signup b on a.userid=b.userid
and created_date>= gold_signup_date)c