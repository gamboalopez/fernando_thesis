view: order_items {
  sql_table_name: absolve.order_items ;;
  ########## IDs, Foreign Keys, Counts ###########

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: inventory_item_id {
    type: number
    hidden: yes
    sql: ${TABLE}.inventory_item_id ;;
  }

  dimension: user_id {
    type: number
    hidden: yes
    sql: ${TABLE}.user_id ;;
  }

  measure: count {
    type: count_distinct
    sql: ${id} ;;
    drill_fields: [detail*]
  }

  measure: order_count {
    view_label: "Orders"
    type: count_distinct
    drill_fields: [detail*]
    sql: ${order_id} ;;
    html: {{ rendered_value }} || {{ list_test._rendered_value }} ;;
  }

  measure: list_test {
    type: list
    list_field: products.item_name
  }

  measure: Dummie_order_count {
    type: sum
    drill_fields: [detail*]
    sql: ${id};;
  }

  measure: count_last_28d {
    label: "Count Sold in Trailing 28 Days"
    type: count_distinct
    sql: ${id} ;;
    hidden: yes
    filters:
    {field:created_date
      value: "28 days"
    }}

  dimension: order_id {
    type: number
    hidden: yes
    sql: ${TABLE}.order_id ;;
  }

  ########## Time Dimensions ##########

  dimension_group: returned {
    type: time
    timeframes: [time, date, week, month, raw]
    sql: ${TABLE}.returned_at ;;
  }

  dimension_group: shipped {
    type: time
    timeframes: [date, week, month, raw]
    sql: ${TABLE}.shipped_at ;;
  }

  dimension_group: delivered {
    type: time
    timeframes: [date, week, month, raw]
    sql: ${TABLE}.delivered_at ;;
  }

  dimension_group: created {
    type: time
    datatype: timestamp
    timeframes: [time, hour, date, week, month, year, hour_of_day, day_of_week, month_num, month_name, raw, week_of_year]
    sql: CAST(${TABLE}.created_at AS TIMESTAMP) ;;
  }

  dimension: reporting_period {
    group_label: "Order Date"
    sql: CASE
        WHEN EXTRACT(YEAR FROM ${created_raw}) = EXTRACT(YEAR FROM CURRENT_DATE())
        AND ${created_raw} < CURRENT_TIMESTAMP()
        THEN 'This Year to Date'

      WHEN EXTRACT(YEAR FROM ${created_raw}) + 1 = EXTRACT(YEAR FROM CURRENT_DATE())
      AND EXTRACT(DAY FROM ${created_raw}) <= EXTRACT (DAY FROM CURRENT_DATE())
      THEN 'Last Year to Date'

      END
      ;;
  }

  dimension: days_since_sold {
    hidden: yes
    sql: date_diff(${created_date},CURRENT_DATE(),month) ;;
  }

  dimension: months_since_signup {
    view_label: "Orders"
    type: number
    sql: date_diff(${users.created_date},${created_date},month) ;;
  }

########## Logistics ##########

  dimension: status {
    description: "Modified label for thesis"
    label: "Status Now"
    sql: ${TABLE}.status ;;
    html: {% if value == 'Shipped' or value == 'Complete' %}
    <p><img src="http://findicons.com/files/icons/573/must_have/48/check.png" height=20 width=20>{{ rendered_value }}</p>
    {% elsif value == 'Processing' %}
    <p><img src="http://findicons.com/files/icons/1681/siena/128/clock_blue.png" height=20 width=20>{{ rendered_value }}</p>
    {% elsif value == 'Returned' %}
    <p><img src="https://findicons.com/files/icons/1681/siena/128/undo_blue.png" height=20 width=20>{{ rendered_value }}</p>
    {% else %}
    <p><img src="http://findicons.com/files/icons/719/crystal_clear_actions/64/cancel.png" height=20 width=20>{{ rendered_value }}</p>
    {% endif %}
    ;;
  }

  dimension: days_to_process {
    type: number
    sql: CASE
        WHEN ${status} = 'Processing' THEN DATE_DIFF(${created_date},current_date(),day)*1.0
        WHEN ${status} IN ('Shipped', 'Complete', 'Returned') THEN DATE_DIFF(${created_date},${shipped_date},day)*1.0
        WHEN ${status} = 'Cancelled' THEN NULL
      END
       ;;
  }

  dimension: shipping_time {
    type: number
    sql: TIMESTAMP_DIFF(CAST(${shipped_raw} AS TIMESTAMP),CAST(${delivered_raw} AS TIMESTAMP), day)*1.0 ;;
  }

  dimension: shipping_method {
    type: string
    sql: ${TABLE}.ship_method ;;
  }

  dimension: ship_distance{
    type: distance
    start_location_field: distribution_centers.location
    end_location_field: users.location
    units: miles
  }

  measure: average_days_to_process {
    type: average
    value_format_name: decimal_2
    sql: ${days_to_process} ;;
  }

  measure: average_shipping_time {
    type: average
    value_format_name: decimal_2
    sql: ${shipping_time} ;;
  }

########## Financial Information ##########

  dimension: sale_price {
    type: number
    value_format_name: usd
    sql: ${TABLE}.sale_price ;;
  }

  dimension: gross_margin {
    type: number
    value_format_name: usd
    sql: ${sale_price} - ${inventory_items.cost} ;;
  }

  dimension: item_gross_margin_percentage {
    type: number
    value_format_name: percent_2
    sql: 1.0 * ${gross_margin}/NULLIF(${sale_price},0) ;;
  }

  dimension: item_gross_margin_percentage_tier {
    type: tier
    sql: 100*${item_gross_margin_percentage} ;;
    tiers: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]
    style: interval
  }

  measure: total_sale_price {
    view_label: " Measures"
    type: sum
    value_format_name: decimal_0
    sql:coalesce(${sale_price},0) ;;
    drill_fields: [detail*]
  }


  measure: total_gross_margin {
    type: sum
    value_format_name: usd
    sql: ${gross_margin} ;;
    drill_fields: [detail*]
  }

  measure: average_sale_price {
    type: average
    value_format_name: usd
    sql: ${sale_price} ;;
    drill_fields: [detail*]
  }

  measure: median_sale_price {
    type: median
    value_format_name: usd
    sql: ${sale_price} ;;
    drill_fields: [detail*]
  }

  measure: average_gross_margin {
    type: average
    value_format_name: usd
    sql: ${gross_margin} ;;
    drill_fields: [detail*]
  }

  measure: total_gross_margin_percentage {
    type: number
    value_format_name: percent_2
    sql: 1.0 * ${total_gross_margin}/ NULLIF(${total_sale_price},0) ;;
  }

  measure: average_spend_per_user {
    type: number
    value_format_name: usd
    sql: 1.0 * ${total_sale_price} / NULLIF(${users.count},0) ;;
    drill_fields: [detail*]
  }

########## Return Information ##########

  dimension: is_returned {
    type: yesno
    sql: ${returned_raw} IS NOT NULL ;;
  }

  measure: returned_count {
    type: count_distinct
    sql: ${id} ;;
    filters: {
      field: is_returned
      value: "yes"
    }
    drill_fields: [detail*]
  }

  measure: returned_total_sale_price {
    type: sum
    value_format_name: usd
    sql: ${sale_price} ;;
    filters: {
      field: is_returned
      value: "yes"
    }
  }

  measure: return_rate {
    type: number
    value_format_name: percent_2
    sql: 1.0 * ${returned_count} / nullif(${count},0) ;;
  }


########## Repeat Purchase Facts ##########

  dimension: days_until_next_order {
    type: number
    view_label: "Repeat Purchase Facts"
    sql: TIMESTAMP_DIFF(${created_raw},CAST(${repeat_purchase_facts.next_order_raw} AS timestamp),DAY) ;;
  }

  dimension: repeat_orders_within_30d {
    type: yesno
    view_label: "Repeat Purchase Facts"
    sql: ${days_until_next_order} <= 30 ;;
  }

  measure: count_with_repeat_purchase_within_30d {
    type: count_distinct
    sql: ${id} ;;
    view_label: "Repeat Purchase Facts"

    filters: {
      field: repeat_orders_within_30d
      value: "Yes"
    }
  }

  measure: 30_day_repeat_purchase_rate {
    description: "The percentage of customers who purchase again within 30 days"
    view_label: "Repeat Purchase Facts"
    type: number
    value_format_name: percent_1
    sql: 1.0 * ${count_with_repeat_purchase_within_30d} / NULLIF(${count},0) ;;
    drill_fields: [products.brand, order_count, count_with_repeat_purchase_within_30d, 30_day_repeat_purchase_rate]
  }

  measure: first_purchase_count {
    view_label: "Orders"
    type: count_distinct
    sql: ${order_id} ;;

    filters: {
      field: order_facts.is_first_purchase
      value: "Yes"
    }
    # customized drill path for first_purchase_count
    drill_fields: [user_id, order_id, created_date, users.traffic_source]
    link: {
      label: "New User's Behavior by Traffic Source"
      url: "
      {% assign vis_config = '{
      \"type\": \"looker_column\",
      \"show_value_labels\": true,
      \"y_axis_gridlines\": true,
      \"show_view_names\": false,
      \"y_axis_combined\": false,
      \"show_y_axis_labels\": true,
      \"show_y_axis_ticks\": true,
      \"show_x_axis_label\": false,
      \"value_labels\": \"legend\",
      \"label_type\": \"labPer\",
      \"font_size\": \"13\",
      \"colors\": [
      \"#1ea8df\",
      \"#a2dcf3\",
      \"#929292\"
      ],
      \"hide_legend\": false,
      \"y_axis_orientation\": [
      \"left\",
      \"right\"
      ],
      \"y_axis_labels\": [
      \"Average Sale Price ($)\"
      ]
      }' %}
      {{ hidden_first_purchase_visualization_link._link }}&vis_config={{ vis_config | encode_uri }}&sorts=users.average_lifetime_orders+descc&toggle=dat,pik,vis&limit=5000"
    }
  }

########## Dynamic Sales Cohort App ##########

  filter: cohort_by {
    type: string
    hidden: yes
    suggestions: ["Week", "Month", "Quarter", "Year"]
  }

  filter: metric {
    type: string
    hidden: yes
    suggestions: ["Order Count", "Gross Margin", "Total Sales", "Unique Users"]
  }

  dimension_group: first_order_period {
    type: time
    timeframes: [date]
    hidden: yes
    sql: CAST(DATE_TRUNC({% parameter cohort_by %}, ${user_order_facts.first_order_date}) AS DATE)
      ;;
  }

  dimension: periods_as_customer {
    type: number
    hidden: yes
    sql: DATE_DIFF(${user_order_facts.first_order_date}, ${user_order_facts.latest_order_date},{% parameter cohort_by %})
      ;;
  }

  measure: cohort_values_0 {
    type: count_distinct
    hidden: yes
    sql: CASE WHEN {% parameter metric %} = 'Order Count' THEN ${id}
        WHEN {% parameter metric %} = 'Unique Users' THEN ${users.id}
        ELSE null
      END
       ;;
  }

  measure: cohort_values_1 {
    type: sum
    hidden: yes
    sql: CASE WHEN {% parameter metric %} = 'Gross Margin' THEN ${gross_margin}
        WHEN {% parameter metric %} = 'Total Sales' THEN ${sale_price}
        ELSE 0
      END
       ;;
  }

  measure: values {
    type: number
    hidden: yes
    sql: ${cohort_values_0} + ${cohort_values_1} ;;
  }

  measure: hidden_first_purchase_visualization_link {
    hidden: yes
    view_label: "Orders"
    type: count_distinct
    sql: ${order_id} ;;

    filters: {
      field: order_facts.is_first_purchase
      value: "Yes"
    }
    drill_fields: [users.traffic_source, user_order_facts.average_lifetime_revenue, user_order_facts.average_lifetime_orders]
  }

########## Parameters ##########
  parameter: using_parameters{
    default_value: "Blue"
    type: unquoted
    allowed_value: {
      label: "Blue"
      value: "blue"
    }
    allowed_value: {
      label: "Green"
      value: "green"
    }
  }

    measure: dynamic_parameter {
      type: count_distinct
      sql: ${order_id};;
      html: {% if using_parameters._parameter_value == 'blue' %}
              <p style="color: blue">{{ rendered_value }}</p>
            {% else %}
              <<p style="color: green">{{ rendered_value }}</p>
            {% endif %} ;;
    }


########## Sets ##########

  set: detail {
    fields: [id, order_id, status, created_date, sale_price, products.brand, products.item_name, users.portrait, users.name, users.email]
  }
  set: return_detail {
    fields: [id, order_id, status, created_date, returned_date, sale_price, products.brand, products.item_name, users.portrait, users.name, users.email]
  }
}
