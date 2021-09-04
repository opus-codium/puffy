# frozen_string_literal: true

policy :pass

host 'www1' do
  policy :block
end

host 'www2' do
  policy :pass
end

host(/db\d+/) do
  policy :block
end

host 'log' do
  # Empty
end

policy :log
