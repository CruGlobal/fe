# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160204164613) do

  create_table "fe_addresses", force: :cascade do |t|
    t.datetime "startdate"
    t.datetime "enddate"
    t.string   "address1",     limit: 255
    t.string   "address2",     limit: 255
    t.string   "address3",     limit: 255
    t.string   "address4",     limit: 255
    t.string   "address_type", limit: 255
    t.string   "city",         limit: 255
    t.string   "state",        limit: 255
    t.string   "zip",          limit: 255
    t.string   "country",      limit: 255
    t.integer  "person_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fe_answer_sheet_question_sheets", force: :cascade do |t|
    t.integer  "answer_sheet_id",   limit: 4
    t.integer  "question_sheet_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fe_answer_sheet_question_sheets", ["answer_sheet_id", "question_sheet_id"], name: "answer_sheet_question_sheet", using: :btree

  create_table "fe_answers", force: :cascade do |t|
    t.integer  "answer_sheet_id",         limit: 4,     null: false
    t.integer  "question_id",             limit: 4,     null: false
    t.text     "value",                   limit: 65535
    t.integer  "attachment_file_size",    limit: 4
    t.string   "attachment_content_type", limit: 255
    t.string   "attachment_file_name",    limit: 255
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fe_answers", ["answer_sheet_id", "question_id"], name: "answer_sheet_question", using: :btree

  create_table "fe_applications", force: :cascade do |t|
    t.integer  "applicant_id", limit: 4
    t.string   "status",       limit: 255
    t.datetime "submitted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "locale",       limit: 255, default: "en"
  end

  add_index "fe_applications", ["applicant_id"], name: "question_sheet_id", using: :btree

  create_table "fe_conditions", force: :cascade do |t|
    t.integer  "question_sheet_id", limit: 4,   null: false
    t.integer  "trigger_id",        limit: 4,   null: false
    t.string   "expression",        limit: 255, null: false
    t.integer  "toggle_page_id",    limit: 4,   null: false
    t.integer  "toggle_id",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fe_conditions", ["question_sheet_id"], name: "index_fe_conditions_on_question_sheet_id", using: :btree
  add_index "fe_conditions", ["toggle_id"], name: "index_fe_conditions_on_toggle_id", using: :btree
  add_index "fe_conditions", ["toggle_page_id"], name: "index_fe_conditions_on_toggle_page_id", using: :btree
  add_index "fe_conditions", ["trigger_id"], name: "index_fe_conditions_on_trigger_id", using: :btree

  create_table "fe_elements", force: :cascade do |t|
    t.integer  "question_grid_id",          limit: 4
    t.string   "kind",                      limit: 40,                    null: false
    t.string   "style",                     limit: 40
    t.string   "label",                     limit: 255
    t.text     "content",                   limit: 65535
    t.boolean  "required"
    t.string   "slug",                      limit: 36
    t.integer  "position",                  limit: 4
    t.string   "object_name",               limit: 255
    t.string   "attribute_name",            limit: 255
    t.string   "source",                    limit: 255
    t.string   "value_xpath",               limit: 255
    t.string   "text_xpath",                limit: 255
    t.string   "cols",                      limit: 255
    t.boolean  "is_confidential",                         default: false
    t.string   "total_cols",                limit: 255
    t.string   "css_id",                    limit: 255
    t.string   "css_class",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "related_question_sheet_id", limit: 4
    t.integer  "conditional_id",            limit: 4
    t.text     "tooltip",                   limit: 65535
    t.boolean  "hide_label",                              default: false
    t.boolean  "hide_option_labels",                      default: false
    t.integer  "max_length",                limit: 4
    t.string   "conditional_type",          limit: 255
    t.text     "conditional_answer",        limit: 65535
    t.integer  "choice_field_id",           limit: 4
    t.boolean  "share",                                   default: false
    t.text     "label_translations",        limit: 65535
    t.text     "tip_translations",          limit: 65535
    t.text     "content_translations",      limit: 65535
  end

  add_index "fe_elements", ["conditional_id"], name: "index_fe_elements_on_conditional_id", using: :btree
  add_index "fe_elements", ["question_grid_id"], name: "index_fe_elements_on_question_grid_id", using: :btree
  add_index "fe_elements", ["slug"], name: "index_fe_elements_on_slug", using: :btree

  create_table "fe_email_templates", force: :cascade do |t|
    t.string   "name",       limit: 1000,  null: false
    t.text     "content",    limit: 65535
    t.boolean  "enabled"
    t.string   "subject",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fe_page_elements", force: :cascade do |t|
    t.integer  "page_id",    limit: 4
    t.integer  "element_id", limit: 4
    t.integer  "position",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fe_page_elements", ["page_id", "element_id"], name: "page_element", using: :btree

  create_table "fe_pages", force: :cascade do |t|
    t.integer  "question_sheet_id",  limit: 4,                     null: false
    t.string   "label",              limit: 60,                    null: false
    t.integer  "number",             limit: 4
    t.boolean  "no_cache",                         default: false
    t.boolean  "hidden",                           default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "all_element_ids",    limit: 65535
    t.text     "label_translations", limit: 65535
  end

  create_table "fe_people", force: :cascade do |t|
    t.string   "first_name", limit: 50
    t.string   "last_name",  limit: 50
    t.integer  "user_id",    limit: 4
    t.boolean  "is_staff"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fe_question_sheets", force: :cascade do |t|
    t.string   "label",      limit: 100,                   null: false
    t.boolean  "archived",                 default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "languages",  limit: 65535
  end

  create_table "fe_references", force: :cascade do |t|
    t.integer  "question_id",               limit: 4
    t.integer  "applicant_answer_sheet_id", limit: 4
    t.datetime "email_sent_at"
    t.string   "relationship",              limit: 255
    t.string   "title",                     limit: 255
    t.string   "first_name",                limit: 255
    t.string   "last_name",                 limit: 255
    t.string   "phone",                     limit: 255
    t.string   "email",                     limit: 255
    t.string   "status",                    limit: 255
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.string   "access_key",                limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "locale",                    limit: 255, default: "en"
    t.integer  "question_sheet_id",         limit: 4
    t.boolean  "visible"
    t.string   "visibility_cache_key",      limit: 255
  end

  add_index "fe_references", ["applicant_answer_sheet_id"], name: "index_fe_references_on_applicant_answer_sheet_id", using: :btree
  add_index "fe_references", ["question_id"], name: "index_fe_references_on_question_id", using: :btree

  create_table "fe_users", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.datetime "last_login"
    t.string   "type",       limit: 255
    t.string   "role",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "phone_numbers", force: :cascade do |t|
    t.string   "number",           limit: 255
    t.string   "extensions",       limit: 255
    t.integer  "person_id",        limit: 4
    t.string   "location",         limit: 255
    t.boolean  "primary"
    t.string   "txt_to_email",     limit: 255
    t.integer  "carrier_id",       limit: 4
    t.datetime "email_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string  "username",  limit: 255
    t.string  "email",     limit: 255
    t.integer "person_id", limit: 4
  end

end
