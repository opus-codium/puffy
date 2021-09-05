# frozen_string_literal: true

policy :pass

node 'www1' do
  policy :block
end

node 'www2' do
  policy :pass
end

node(/db\d+/) do
  policy :block
end

node 'log' do
  # Empty
end

policy :log
