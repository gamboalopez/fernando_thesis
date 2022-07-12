connection: "lookerdata_publicdata_standard_sql"

# include all the views
include: "/views/*.view.lkml"
#include: "/**/*.dashboard"
#Datagroups and caching
datagroup: fernando_thesis_default_datagroup {
  max_cache_age: "5 hours"
  sql_trigger: SELECT 1 ;;
}

datagroup: ecommerce_gamboalopez_default_datagroup {
  max_cache_age: "24 hours"
  sql_trigger: SELECT FLOOR((UNIX_TIMESTAMP(NOW()) - 60*60*11)/(60*60*24));; #Every day at 6:00AM
  label: "6AM Scheduled Email"
  description: "Sends an email every 24 hours at 6 AM"
}

persist_with: fernando_thesis_default_datagroup


#Base explores
explore: order_items {
  group_label: "Fernando Thesis - Ecommerce"
  label: "Order Items"
  view_name: order_items

  join: order_facts {
    view_label: "Orders"
    relationship: many_to_one
    sql_on: ${order_facts.order_id} = ${order_items.order_id} ;;
  }

  join: inventory_items {
    #Left Join only brings in items that have been sold as order_item
    type: full_outer
    relationship: one_to_one
    sql_on: ${inventory_items.id} = ${order_items.inventory_item_id} ;;
  }

  join: users {
    relationship: many_to_one
    sql_on: ${order_items.user_id} = ${users.id} ;;
  }

  join: user_order_facts {
    view_label: "Users"
    relationship: many_to_one
    sql_on: ${user_order_facts.user_id} = ${order_items.user_id} ;;
  }

  join: products {
    relationship: many_to_one
    sql_on: ${products.id} = ${inventory_items.product_id} ;;
  }

  join: repeat_purchase_facts {
    relationship: many_to_one
    type: full_outer
    sql_on: ${order_items.order_id} = ${repeat_purchase_facts.order_id} ;;
  }

  join: distribution_centers {
    type: left_outer
    sql_on: ${distribution_centers.id} = ${inventory_items.product_distribution_center_id};;
    relationship: many_to_one
  }
}

#Carbon Cruncher Explores

explore: co2 {
  hidden: no
  label: "Carbon Cruncher"
  extends: [order_items]
  view_name: order_items

  join: carbon_cruncher {
    type: left_outer
    relationship: one_to_one
    sql_on: ${order_items.order_id} = ${carbon_cruncher.order_id} AND ${order_items.id} = ${carbon_cruncher.order_item_id} ;;
  }

  join: orders {
    view_label: "Orders"
    type: left_outer
    sql_on: ${orders.id} = ${order_items.order_id} ;;
    relationship: many_to_one
  }
}
