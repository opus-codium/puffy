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
end

policy :log
