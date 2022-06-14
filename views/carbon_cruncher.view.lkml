view: carbon_cruncher {
  derived_table: {
    datagroup_trigger: fernando_thesis_default_datagroup
    sql: WITH order_item_facts AS (SELECT
          order_items.order_id  AS order_id,
          order_items.id  AS order_items_id,
          ((CASE WHEN distribution_centers.latitude  = users.latitude  AND distribution_centers.longitude  = users.longitude  THEN 0 ELSE ACOS(SIN((IFNULL(distribution_centers.latitude , 0.0) * 3.141592653589793 / 180)) * SIN((IFNULL(users.latitude , 0.0) * 3.141592653589793 / 180)) + COS((IFNULL(distribution_centers.latitude , 0.0) * 3.141592653589793 / 180)) * COS((IFNULL(users.latitude , 0.0) * 3.141592653589793 / 180)) * COS((IFNULL(users.longitude  - distribution_centers.longitude , 0.0) * 3.141592653589793 / 180))) * 6371 END) / 1.60934) AS order_items_ship_distance,
          order_items.ship_method  AS shipping_method,
          products.weight  AS products_weight_lbs,
          products.weight/2000.00 AS products_weight_tons,

      ((CASE WHEN distribution_centers.latitude  = users.latitude  AND distribution_centers.longitude  = users.longitude  THEN 0 ELSE ACOS(SIN((IFNULL(distribution_centers.latitude , 0.0) * 3.141592653589793 / 180)) * SIN((IFNULL(users.latitude , 0.0) * 3.141592653589793 / 180)) + COS((IFNULL(distribution_centers.latitude , 0.0) * 3.141592653589793 / 180)) * COS((IFNULL(users.latitude , 0.0) * 3.141592653589793 / 180)) * COS((IFNULL(users.longitude  - distribution_centers.longitude , 0.0) * 3.141592653589793 / 180))) * 6371 END) / 1.60934) * products.weight AS item_lbs_mi,
      ((CASE WHEN distribution_centers.latitude  = users.latitude  AND distribution_centers.longitude  = users.longitude  THEN 0 ELSE ACOS(SIN((IFNULL(distribution_centers.latitude , 0.0) * 3.141592653589793 / 180)) * SIN((IFNULL(users.latitude , 0.0) * 3.141592653589793 / 180)) + COS((IFNULL(distribution_centers.latitude , 0.0) * 3.141592653589793 / 180)) * COS((IFNULL(users.latitude , 0.0) * 3.141592653589793 / 180)) * COS((IFNULL(users.longitude  - distribution_centers.longitude , 0.0) * 3.141592653589793 / 180))) * 6371 END) / 1.60934) * (products.weight/2000.0000) AS item_tons_mi,
      (
      ((CASE WHEN distribution_centers.latitude  = users.latitude  AND distribution_centers.longitude  = users.longitude  THEN 0 ELSE ACOS(SIN((IFNULL(distribution_centers.latitude , 0.0) * 3.141592653589793 / 180)) * SIN((IFNULL(users.latitude , 0.0) * 3.141592653589793 / 180)) + COS((IFNULL(distribution_centers.latitude , 0.0) * 3.141592653589793 / 180)) * COS((IFNULL(users.latitude , 0.0) * 3.141592653589793 / 180)) * COS((IFNULL(users.longitude  - distribution_centers.longitude , 0.0) * 3.141592653589793 / 180))) * 6371 END) / 1.60934) * (products.weight/2000.0000)
      ) *
      CASE WHEN order_items.ship_method = 'air' THEN 1.23205
      WHEN order_items.ship_method = 'truck' THEN 0.11360
      WHEN order_items.ship_method = 'boat' THEN 0.01614
      ELSE null
      END AS carbon_footprint_kg
      FROM absolve.order_items  AS order_items
      FULL OUTER JOIN absolve.inventory_items  AS inventory_items ON inventory_items.id = order_items.inventory_item_id
      LEFT JOIN absolve.users  AS users ON order_items.user_id = users.id
      LEFT JOIN absolve.products  AS products ON products.id = inventory_items.product_id
      LEFT JOIN absolve.distribution_centers  AS distribution_centers ON distribution_centers.id = inventory_items.product_distribution_center_id)

      SELECT order_item_facts.order_id AS order_id, order_item_facts.order_items_id AS order_items_id, order_item_facts.shipping_method AS shipping_method,order_item_facts.carbon_footprint_kg AS carbon_footprint ,order_item_facts.item_lbs_mi AS item_lbs_mi,order_item_facts.item_tons_mi AS item_tons_mi,
      SUM(order_item_facts.item_lbs_mi) AS total_order_lbs_mi,SUM(order_item_facts.carbon_footprint_kg) AS total_order_footprint
      FROM order_item_facts
      GROUP BY 1,2,3,4,5,6
      ;;
  }

  dimension: order_id {
    type: number
    sql: ${TABLE}.order_id ;;
    hidden: yes
  }

  dimension: order_item_id {
    hidden: yes
    type: number
    sql: ${TABLE}.order_items_id;;
  }

  dimension: shipping_method {
    type: string
    sql: ${TABLE}.shipping_method ;;
  }

  dimension: order_level_lbs_mi {
    type: number
    sql: ${TABLE}.total_order_lbs_mi ;;
  }
  dimension: order_level_footprint {
    type: number
    sql: ${TABLE}.total_order_footprint ;;
  }

  measure: total_lbs_mi {
    type: sum
    sql: ${TABLE}.item_lbs_mi ;;
  }

  measure: total_tons_mi {
    label: "Total ton-miles"
    description: "a US short ton of freight traveling 1 mile, or a half ton of freight traveling two miles"
    type: sum
    sql: ${TABLE}.item_tons_mi/2000 ;;
  }

  measure: carbon_footprint_backend {
    #Used to feed the HTML of carbon_footprint_with_tgm
    type: sum
    hidden: yes
    sql: ${TABLE}.carbon_footprint;;
    value_format_name: decimal_2
    drill_fields: [order_level_lbs_mi]
    tags: ["co2_footprint"]
  }

  measure: carbon_footprint_with_tgm {
    label: "CO2e Footprint (kg)"
    type: number
    html: {{carbon_footprint_backend._linked_value}} ;;
    sql: {% if order_items.total_gross_margin._in_query %}
          CONCAT(CAST(${carbon_footprint_backend} AS STRING),',',CAST(${order_items.total_gross_margin} AS STRING))
               {% else %}
              ${carbon_footprint_backend}
              {% endif %};;
    tags: ["co2_footprint"]
    drill_fields: [order_level_lbs_mi]
    required_fields: [carbon_footprint_backend]
  }



}
