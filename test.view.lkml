view: dt_tbdistro_rcpt_adjust {
  derived_table: {
    sql:
    SELECT
    i.TYPE,
    i.DATE_KEY,
    i.STORE,
    i.STORE_KEY,
    i.PRODUCT_KEY,
    i.UPC,
    i.NET_DISTRIBUTION_QUANTITY,
    i.NET_DISTRIBUTION_VALUE,
    i.NET_DISTRIBUTION_COST,
    i.ADJUSTMENT_UNITS,
    i.ADJUSTMENT_VALUE,
    i.ADJUSTMENT_COST,
    i.RECEIPTS_UNITS,
    i.RECEIPTS_VALUE,
    i.RECEIPTS_COST
        FROM TBDISTRO_RCPT_ADJUST i
{% if dt_tbdistro_rcpt_adjust.type._parameter_value == 'true' %} WHERE i.TYPE <> 'Pullback' {% endif %}
 ;;
  }

  parameter: type {
    label: "Exclude Pullbacks?"
    type: yesno
    #  description: "Describes the type of transaction. The possible values here are Retail Initial Buy (initial shipments of a new season's product from the DC to retail stores),
    #  Retail Replen (mid-season replenishment from the DC to retail stores), Store to Store (product transfers between retail stores), Pullback (end of season shipments from retail stores
    #  back to the DC), Segment Transfer (inventory transfers between DCs, generally between the RW / Omni and E-Com segments), and Adjustment (generally done by Accounting to fix inventory issues
    #  in the DC or stores)."
    description: "Filter on 'yes' to exclude pullbacks, which fall under 'Net Distributions'. A pullback is any distribution that goes from a store back to the home warehouse.
    Generally we exclude pullbacks to more accurately calculate store ST% for past selling seasons, but note that this filter will not change inventory numbers, only Net Distributions and Total Receipts Units.
    If you want to use this to look at ST% without pullbacks, you would need to create a custom calculation that divides sales by total receipts."
  }

  dimension: adjustment_units_dim {
    hidden: yes
    type: number
    sql: ${TABLE}.ADJUSTMENT_UNITS ;;
  }

  measure: adjustment_units {
    group_label: "Adjustments"
    label: "Adjustment Units"
    description: "Shows the total adjustment units. Generally adjustments are made by Accounting to fix inventory issues either in the warehouse or in stores."
    type: sum
    sql: ${adjustment_units_dim} ;;
  }

  dimension: receipts_units_dim {
    hidden: yes
    type: number
    sql: ${TABLE}.RECEIPTS_UNITS ;;
  }

  measure: receipts_units {
    group_label: "Receipts"
    label: "Receipts Units"
    description: "Shows the total receipts units. We consider a 'receipt' as anything received against a Retail Initial Buy order."
    type: sum
    sql: ${receipts_units_dim} ;;
  }

  dimension: receipts_value_dim {
    hidden: yes
    type: number
    sql: ${TABLE}.RECEIPTS_VALUE ;;
  }

  measure: receipts_value {
    group_label: "Receipts"
    label: "Receipts Value"
    description: "Shows the total receipts value. We consider a 'receipt' as anything received against a Retail Initial Buy order. Note that inventory is always valued at the high, meaning if a product is marked down from $100 to $80, we still consider the inventory value to be $100."
    type: sum
    sql: ${receipts_value_dim} ;;
    value_format_name: usd
  }

  dimension: receipts_cost_dim {
    hidden: yes
    type: number
    sql: ${TABLE}.RECEIPTS_COST ;;
  }

  measure: receipts_cost {
    group_label: "Receipts"
    label: "Receipts Cost"
    description: "Shows the total receipts cost, which uses 'Correct Cost' meaning actual cost, or estimate cost if the item's cost has not been actualized. We consider a 'receipt' as anything received against a Retail Initial Buy order."
    type: sum
    sql: ${receipts_cost_dim} ;;
    value_format_name: usd
  }






  measure: total_receipts_units {
    group_label: "Total Receipts"
    label: "Total Receipts Units"
    description: "Shows the total receipts units. This is calculated as Receipts Units + Adjustment Units + Net Distribution Units."
    type: number
    sql: ${adjustment_units} + ${receipts_units} + ${net_distribution_units} ;;
  }

  measure: total_receipts_value {
    group_label: "Total Receipts"
    label: "Total Receipts Value"
    description: "Shows the total receipts value. This is calculated as Receipts Value + Adjustment Value + Net Distribution Value."
    type: number
    sql: ${adjustment_value} + ${receipts_value} + ${net_distribution_value} ;;
    value_format_name: usd
  }


  dimension: adjustment_value_dim {
    hidden: yes
    type: number
    sql: ${TABLE}.ADJUSTMENT_VALUE ;;
  }

  measure: adjustment_value {
    group_label: "Adjustments"
    label: "Adjustment Value"
    description: "Shows the total adjustment value. Generally adjustments are made by Accounting to fix inventory issues either in the warehouse or in stores. Note that inventory is always valued at the high, meaning if a product is marked down from $100 to $80, we still consider the inventory value to be $100."
    type: sum
    sql: ${adjustment_value_dim} ;;
    value_format_name: usd
  }

  dimension: adjustment_cost_dim {
    hidden: yes
    type: number
    sql: ${TABLE}.ADJUSTMENT_COST ;;
  }

  measure: adjustment_cost {
    group_label: "Adjustments"
    label: "Adjustment Cost"
    description: "Shows the total adjustment cost, which uses 'Correct Cost' meaning actual cost, or estimate cost if the item's cost has not been actualized. Generally adjustments are made by Accounting to fix inventory issues either in the warehouse or in stores."
    type: sum
    sql: ${adjustment_cost_dim} ;;
    value_format_name: usd
  }



  dimension: primary_key {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.TYPE || '_' ||  ${TABLE}.DATE_KEY || '_' ||  ${TABLE}.STORE_KEY || '_' || ${TABLE}.UPC ;;
  }


  dimension: date_key {
    hidden: yes
    type: number
    sql: ${TABLE}.DATE_KEY ;;
  }

  dimension: net_distribution_quantity_dim {
    hidden: yes
    type: number
    sql: ${TABLE}.NET_DISTRIBUTION_QUANTITY ;;
  }

  measure: net_distribution_units {
    group_label: "Net Distributions"
    label: "Net Distribution Units"
    description: "Shows the total distribution units. We consider a 'distribution' as either a retail replen order, a store-to-store transfer, a segment transfer, or a pullback. 'Net' means that we take the total inventory received minus the total inventory shipped. If a store received 10 units of inventory against a retail replen, and shipped out 8 units of inventory against a pullback, this field would show 2 units."
    type: sum
    sql: ${net_distribution_quantity_dim} ;;
  }


  dimension: net_distribution_value_dim {
    hidden: yes
    type: number
    sql: ${TABLE}.NET_DISTRIBUTION_VALUE ;;
  }

  measure: net_distribution_value {
    group_label: "Net Distributions"
    label: "Net Distribution Value"
    description: "Shows the total distribution value. We consider a 'distribution' as either a retail replen order, a store-to-store transfer, a segment transfer, or a pullback. 'Net' means that we take the total inventory received minus the total inventory shipped. If a store received $1000 of inventory against a retail replen, and shipped out $800 of inventory against a pullback, this field would show $200. Note that inventory is always valued at the high, meaning if a product is marked down from $100 to $80, we still consider the inventory value to be $100."
    type: sum
    sql: ${net_distribution_value_dim} ;;
    value_format_name: usd
  }

  dimension: net_distribution_cost_dim {
    hidden: yes
    type: number
    sql: ${TABLE}.NET_DISTRIBUTION_COST ;;
  }

  measure: net_distribution_cost {
    group_label: "Net Distributions"
    label: "Net Distribution Cost"
    description: "Shows the total distribution cost, which uses 'Correct Cost' meaning actual cost, or estimate cost if the item's cost has not been actualized.
    We consider a 'distribution' as either a retail replen order, a store-to-store transfer, a segment transfer, or a pullback. 'Net' means that we take the total inventory received minus the total inventory shipped. If a store received $1000 of inventory cost against a retail replen, and shipped out $800 of inventory cost against a pullback, this field would show $200."
    type: sum
    sql: ${net_distribution_cost_dim} ;;
    value_format_name: usd
  }


  dimension: product_key {
    hidden: yes
    type: number
    sql: ${TABLE}.PRODUCT_KEY ;;
  }

  dimension: upc {
    hidden: yes
    type: number
    sql: ${TABLE}.UPC ;;
  }



  dimension: store {
    hidden: yes
    type: number
    sql: ${TABLE}.STORE ;;
  }

  dimension: store_key {
    hidden: yes
    type: number
    sql: ${TABLE}.STORE_KEY ;;
  }


}
