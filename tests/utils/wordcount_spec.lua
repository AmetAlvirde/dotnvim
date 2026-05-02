local T = MiniTest.new_set()
local wc = require("utils.wordcount")

T["count_words_whitespace"] = MiniTest.new_set()

T["count_words_whitespace"]["returns 0 for empty string"] = function()
  MiniTest.expect.equality(wc.count_words_whitespace(""), 0)
end

T["count_words_whitespace"]["counts single word"] = function()
  MiniTest.expect.equality(wc.count_words_whitespace("hello"), 1)
end

T["count_words_whitespace"]["counts multiple whitespace-separated words"] = function()
  MiniTest.expect.equality(wc.count_words_whitespace("one two three"), 3)
end

T["count_words_whitespace"]["handles leading and trailing whitespace"] = function()
  MiniTest.expect.equality(wc.count_words_whitespace("  hello world  "), 2)
end

T["count_words_whitespace"]["handles multiple spaces between words"] = function()
  MiniTest.expect.equality(wc.count_words_whitespace("foo   bar"), 2)
end

T["count_words_whitespace"]["handles newlines as whitespace"] = function()
  MiniTest.expect.equality(wc.count_words_whitespace("foo\nbar\nbaz"), 3)
end

return T
