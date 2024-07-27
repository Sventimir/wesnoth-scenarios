function assert_equal(actual, expected)
  if expected ~= actual then
    error("Expected " .. expected .. " but got " .. actual)
  end
end

return {
  equal = assert_equal
}
