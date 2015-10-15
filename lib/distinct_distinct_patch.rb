require 'active_record'

module DistinctDistinctPatch
  def construct_limited_ids_condition(relation)
    orders = relation.order_values.map { |val| val.presence }.compact
    values = @klass.connection.distinct("#{@klass.connection.quote_table_name table_name}.#{primary_key}", orders)

    relation = relation.dup.select(values)
    relation.uniq_value = nil

    id_rows = @klass.connection.select_all(relation.arel, 'SQL', relation.bind_values)
    ids_array = id_rows.map {|row| row[primary_key]}

    ids_array.empty? ? raise(ActiveRecord::ThrowResult) : table[primary_key].in(ids_array)
  end
end

class ActiveRecord::Relation
  include DistinctDistinctPatch
end
