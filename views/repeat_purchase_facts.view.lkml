view: repeat_purchase_facts {

  derived_table: {
    sql: SELECT
        order_items.order_id
        , COUNT(DISTINCT repeat_order_items.id) AS number_subsequent_orders
        , MIN(repeat_order_items.created_at) AS next_order_date
        , MIN(repeat_order_items.order_id) AS next_order_id
      FROM absolve.order_items
      LEFT JOIN absolve.order_items repeat_order_items
        ON order_items.user_id = repeat_order_items.user_id
        AND order_items.created_at < repeat_order_items.created_at
      GROUP BY 1
       ;;
    datagroup_trigger: fernando_thesis_default_datagroup
  }

  dimension: order_id {
    type: number
    hidden: yes
    primary_key: yes
    sql: ${TABLE}.order_id ;;
  }

  dimension: next_order_id {
    type: number
    hidden: yes
    sql: ${TABLE}.next_order_id ;;
  }

  dimension: has_subsequent_order {
    type: yesno
    sql: ${next_order_id} > 0 ;;
  }

  dimension: number_subsequent_orders {
    type: number
    sql: ${TABLE}.number_subsequent_orders ;;
  }

  dimension_group: next_order {
    type: time
    timeframes: [raw, date]
    hidden: yes
    sql: ${TABLE}.next_order_date ;;
  }
}
