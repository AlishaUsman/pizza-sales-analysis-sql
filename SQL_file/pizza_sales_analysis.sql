create database pizza_hut;
use pizza_hut;

select * from pizza_hut.pizzas;
select * from pizza_types;

create table orders (
order_id int not null,
order_date date not null,
order_time time not null ,
primary key (order_id)
);
select * from pizza_hut.orders;

create table order_details (
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
primary key (order_details_id)
);
select * from order_details;

-- Retrieve the total number of orders placed.
select count(order_id) as total_orders_placed from orders ;

-- Calculate the total revenue generated from pizza sales.
select round(sum(( order_details.quantity )*( pizzas.price)),2) as Total_revenue
from order_details
left join pizzas on order_details.pizza_id=pizzas.pizza_id;

-- Identify the highest-priced pizza.
select pizza_types.name,pizzas.price
from pizza_types
inner join pizzas on pizza_types.pizza_type_id=pizzas.pizza_type_id
order by pizzas.price desc limit 1;

-- Identify the most common pizza size ordered.
select count(*) as Total_orders, pizzas.size
from order_details
inner join pizzas on order_details.pizza_id=pizzas.pizza_id
group by pizzas.size
order by Total_orders desc limit 1;

-- List the top 5 most ordered pizza types along with their quantities.
select pizza_types.name as Pizza_Name , sum(order_details.quantity) as Most_Ordered_Quantity
from pizza_types inner join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on order_details.pizza_id=pizzas.pizza_id
group by Pizza_Name
order by Most_Ordered_Quantity desc limit 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered.
select pizza_types.category as Category, sum(order_details.quantity) as Total_Quantity_Ordered 
from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on order_details.pizza_id=pizzas.pizza_id
group by Category;

-- Determine the distribution of orders by hour of the day.
select hour(order_time) as Hour,count(order_id) as Total_Orders from orders
group by Hour;

-- Join relevant tables to find the category-wise distribution of pizzas.
select pizza_types.category as Category , count(pizzas.pizza_id) as Distribution
from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
group by pizza_types.category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
select round(avg(Total_no_pizza),0) as Average_no_pizza
from(
select orders.order_date, sum(order_details.quantity) as Total_no_pizza
from orders join order_details
on orders.order_id=order_details.order_id
group by orders.order_date
) as data;

-- Determine the top 3 most ordered pizza types based on revenue.
select pizza_types.name as Pizza_name,round(sum(order_details.quantity* pizzas.price),2) as Revenue
from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on order_details.pizza_id=pizzas.pizza_id
group by pizza_types.name
order by Revenue desc limit 3;

-- Calculate the percentage contribution of each pizza type to total revenue.
select
data.Pizza_name,
round((data.Revenue /total.Total_revenue)*100,2) as Percentage_contribution
from (
select pizza_types.category as Pizza_name,sum(order_details.quantity*pizzas.price) as Revenue
from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on order_details.pizza_id=pizzas.pizza_id
group by pizza_types.category) as data
cross join
(
Select sum(order_details.quantity*pizzas.price) as Total_revenue
from order_details join pizzas
on order_details.pizza_id=pizzas.pizza_id
) as total;

-- Analyze the cumulative revenue generated over time.
select orders.order_date as Date,
round(sum(order_details.quantity*pizzas.price),2) as Daily_Revenue,
round(
sum(sum(order_details.quantity*pizzas.price))
over(order by orders.order_date),2
) as Commulative_Revenue
from orders join order_details
on orders.order_id=order_details.order_id
join pizzas
on pizzas.pizza_id=order_details.pizza_id
group by orders.order_date
order by orders.order_date;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select Name,Category,Revenue,Calculated_rank
from(
select Category,Revenue,Name,
rank() over (partition by Category
 order by Revenue desc) as Calculated_rank
from(
select pizza_types.category as Category, 
pizza_types.name as Name,
round(sum(order_details.quantity*pizzas.price),2) as Revenue
from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on order_details.pizza_id=pizzas.pizza_id
group by pizza_types.category, pizza_types.name ) as pizza_revenue) as ranked_pizzas
where Calculated_rank <=3;
