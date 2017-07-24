# frozen_string_literal: true

host 'example.com' do
  block :in
  pass :out
end
