-- A little test suite for the repl_ui library, starting with the
-- input history feature.
--
-- N.b. the `input_histories` as well `prompts` need to temporarily be
-- global, rather than local.

luaunit = require('luaunit')
require('repl/lib/repl_ui')

-- Mock data
function have_history()
  prompts = {
    MAIDEN = {
      text = "",
      hist = {},
      offset = 0
    },
    SC = {
      text = "",
      hist = {},
      offset = 0
    }
  }
  table.insert(prompts[repl].hist, "oldest command")
  table.insert(prompts[repl].hist, "old command")
  table.insert(prompts[repl].hist, "latest command")
end

function have_no_history()
  prompts = {
    MAIDEN = {
      text = "",
      hist = {},
      offset = 0
    },
    SC = {
      text = "",
      hist = {},
      offset = 0
    }
  }
end

TestTesting = {}
function TestTesting:testTesting()
  luaunit.assertTrue(true)
end

function TestTesting:testData()
  repl = "MAIDEN"
  have_history()

  luaunit.assertNotNil(prompts)
  luaunit.assertEquals(#prompts[repl].hist, 3)
end

-- class TestInputHistoryBackward <--
TestInputHistoryBackward = {}
function TestInputHistoryBackward:setUp()
  repl = "MAIDEN"
  have_history()
end

function TestInputHistoryBackward:testShouldGetPreviousInput()
  luaunit.assertEquals(get_previous_input(repl), "latest command")
end

function TestInputHistoryBackward:testShouldGetPreviousPreviousInput()
  get_previous_input(repl)
  luaunit.assertEquals(get_previous_input(repl), "old command")
end

function TestInputHistoryBackward:testShouldGetOldestInput()
  get_previous_input(repl)
  get_previous_input(repl)
  luaunit.assertEquals(get_previous_input(repl), "oldest command")
end

function TestInputHistoryBackward:testShouldGetOldestInputForever()
  get_previous_input(repl)
  get_previous_input(repl)
  get_previous_input(repl)
  luaunit.assertEquals(get_previous_input(repl), "oldest command")
end

function TestInputHistoryBackward:testShouldGetOldestInputForeverAndEver()
  get_previous_input(repl)
  get_previous_input(repl)
  luaunit.assertEquals(get_previous_input(repl), "oldest command")
  luaunit.assertEquals(get_previous_input(repl), "oldest command")
  luaunit.assertEquals(get_previous_input(repl), "oldest command")
end
-- end of class TestInputHistoryBackward

-- class TestInputHistoryBackwardNewSession
TestInputHistoryBackwardNewSession = {}
function TestInputHistoryBackwardNewSession:setUp()
  repl = "MAIDEN"
  have_no_history()
end

function TestInputHistoryBackwardNewSession:testShouldGetPreviousInput()
  luaunit.assertEquals(get_previous_input(repl), "")
end
-- end of class TestInputHistoryBackwardNewSession

-- class TestInputHistoryForward
TestInputHistoryForward = {}
function TestInputHistoryForward:setUp()
  repl = "MAIDEN"
  have_history()
end

function TestInputHistoryForward:testForwardShouldGetNextInput()
  get_previous_input(repl)
  get_previous_input(repl)
  luaunit.assertEquals(get_next_input(repl), "old command")
end

function TestInputHistoryForward:testForwardShouldReturnToBlankInput()
  luaunit.assertEquals(get_previous_input(repl), "latest command")
  luaunit.assertEquals(get_next_input(repl), "")
end

function TestInputHistoryForward:testForwardAtDraftShouldStayAtDraftInput()
  prompts[repl].text = "incomplete co"

  luaunit.assertEquals(get_next_input(repl), "incomplete co")
end

function TestInputHistoryForward:testForwardFromLastShouldReturnToDraftInput()
  prompts[repl].text = "incomplete co"

  luaunit.assertEquals(get_previous_input(repl), "latest command")
  luaunit.assertEquals(get_next_input(repl), "incomplete co")
end

function TestInputHistoryForward:testForwardShouldGetLatestInputForever()
  luaunit.assertEquals(get_previous_input(repl), "latest command")
  luaunit.assertEquals(get_next_input(repl), "")
end

function TestInputHistoryForward:testForwardShouldStayAtLatestInputForeverAndEver()
  luaunit.assertEquals(get_previous_input(repl), "latest command")
  luaunit.assertEquals(get_next_input(repl), "")
  luaunit.assertEquals(get_next_input(repl), "")
  luaunit.assertEquals(get_next_input(repl), "")
end
-- end of class TestInputHistoryForward

-- class TestInputHistoryForwardNewSession
TestInputHistoryForwardNewSession = {}
function TestInputHistoryForwardNewSession:setUp()
  repl = "MAIDEN"
  have_no_history()
end

function TestInputHistoryForwardNewSession:testShouldReturnToBlankInput()
  luaunit.assertEquals(get_previous_input(repl), "")
end

function TestInputHistoryForwardNewSession:testShouldReturnToDraftInput()
  prompts[repl].text = "incomplete co"

  get_previous_input(repl)
  get_next_input(repl)
  luaunit.assertEquals(get_next_input(repl), "incomplete co")
end
-- end of class TestInputHistoryForwardWithoutHistory

-- Runner
os.exit(luaunit.LuaUnit:run())
