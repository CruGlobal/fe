require 'global_registry_methods'
class EmailAddress < ActiveRecord::Base
  include GlobalRegistryMethods
  include Sidekiq::Worker
  belongs_to :person

  def async_push_to_global_registry(parent_id = nil, parent_type = 'person')
    return unless person
    
    person.async_push_to_global_registry unless person.global_registry_id.present?
    parent_id = person.global_registry_id unless parent_id

    super(parent_id, parent_type)
  end

  def self.columns_to_push
    super
    @columns_to_push + [{ name: 'email', type: 'email' }]
  end

  def self.push_structure_to_global_registry
    parent_id = GlobalRegistry::EntityType.get(
        {'filters[name]' => 'person'}
    )['entity_types'].first['id']
    super(parent_id)
  end

  def self.skip_fields_for_gr
    %w[id email created_at updated_at global_registry_id person_id]
  end
end