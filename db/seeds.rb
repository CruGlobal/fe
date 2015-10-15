unless User.where(email: 'example@example.com').first
  User.create(email: 'example@example.com', password: 'password', password_confirmation: 'password')
end
unless admin = User.where(email: 'admin@example.com').first
  admin = User.create(email: 'admin@example.com', password: 'password', password_confirmation: 'password')
end
Fe::User.where(user_id: admin.id).first_or_create
