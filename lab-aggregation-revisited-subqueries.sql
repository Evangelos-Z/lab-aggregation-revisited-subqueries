USE sakila;

# 1. Select the first name, last name, and email address of all the customers who have rented a movie.
SELECT 
    c.first_name, c.last_name, c.email
FROM
    customer c
        JOIN
    rental r USING (customer_id)
ORDER BY email , first_name , last_name;
# 15641 rows returned (*see NOTE at the end of 3rd task)


# 2. What is the average payment made by each customer (display the customer id, customer name (concatenated), and the average payment made).
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    AVG(p.amount) AS average_amount
FROM
    customer c
        JOIN
    rental r USING (customer_id)
        JOIN
    payment p USING (rental_id)
GROUP BY c.first_name , c.last_name , c.email
ORDER BY average_amount DESC;
# 584 rows returned


# 3. Select the name and email address of all the customers who have rented the "Action" movies.
### 3.1 Write the query using multiple join statements:
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email
FROM
    customer c
        JOIN
    rental r USING (customer_id)
        JOIN
    inventory i USING (inventory_id)
        JOIN
    film_category fc USING (film_id)
        JOIN
    category ca USING (category_id)
WHERE
    ca.name = 'Action'
ORDER BY email;
# Output: 1092 rows

### 3.2 Write the query using sub queries with multiple WHERE clauses and IN conditions
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email
FROM
    customer c
WHERE customer_id IN (
						SELECT customer_id
							FROM rental
						WHERE inventory_id IN (
												SELECT inventory_id
													FROM inventory
												WHERE film_id IN (
																	SELECT film_id
																		FROM film_category
																	WHERE category_id IN (
																							SELECT category_id
																								FROM category
																							WHERE name = "Action"))))
ORDER BY email;
# Output: 498 rows

### 3.3 Verify if the above two queries produce the same results or not
# The outputs are different. In the case of multiple joins all rentals of Action films made by each person are returned, which is not true in the case of multiple queries. 
# In this case the only thing that matters is whether or not the name of the customer could be matched through the series of filters applied.
# Writing a CTE to pick just one of the records for each customer could solve the problem that comes up with multiple joins:
WITH cte_action as (
	SELECT 
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		c.email,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY r.rental_date DESC) AS date_ranking
	FROM
		customer c
			JOIN
		rental r USING (customer_id)
			JOIN
		inventory i USING (inventory_id)
			JOIN
		film_category fc USING (film_id)
			JOIN
		category ca USING (category_id)
	WHERE
		ca.name = 'Action'
	ORDER BY email)
SELECT customer_name, email
	FROM cte_action
WHERE date_ranking = 1;
# By selecting only the first day in record for each customer that an action film was rented, the output changed and is the same as in the case of the query with multiple subqueries (498 customers).
# *NOTE: the exact same approach could be implemented in the first query written for this lab in order to fix the same issue, but since no conditions were provided by the task statements a simpler query was written * 

# 4. Use the case statement to create a new column classifying existing columns as low, medium or high value transactions based on the amount of payment.
# 	 If the amount is between 0 and 2, label should be low and if the amount is between 2 and 4, the label should be medium, and if it is more than 4, then it should be high.

# adding table
ALTER TABLE payment
ADD eval_trans TEXT DEFAULT NULL;

# importing the values of amount to the new table in order to use as a basis for assigning the new values later
UPDATE payment
SET eval_trans = amount;

# finally using a case statement to change the existing values to their corresponding evaluation values
UPDATE payment
SET eval_trans = CASE 
					WHEN eval_trans <= 2
						THEN "low"
					WHEN eval_trans > 2 AND eval_trans <= 4
						THEN "medium"
					WHEN eval_trans > 4
						THEN "high"
END;

# checking for errors
SELECT 
    eval_trans
FROM
    payment
WHERE eval_trans = NULL;
# no errors during copy or update of data

