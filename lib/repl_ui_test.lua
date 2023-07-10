-- A little test suite for the repl_ui library, starting with the
-- input history feature.
--
-- Tests run from from project root e.g. dust/code/repl/
--
-- FIXME: `prompts` as well as the two target functions
-- `get_previous_input` and `get_next_input` need to temporarily be
-- global, rather than local.

package.path = "../../../norns/lua/lib/?;../../../norns/lua/lib/?.lua;"..package.path
package.path = "../?;../?.lua;"..package.path

luaunit = require('luaunit')
tab = require("tabutil")
require('lib.repl_ui')

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
  table.insert(prompts[repl].hist, "oldest command") -- offset 3
  table.insert(prompts[repl].hist, "old command")    -- offset 2
  table.insert(prompts[repl].hist, "latest command") -- offset 1
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

function TestTesting:testRequiringTabutilsShouldWork()
  luaunit.assertNotNil(tab.count)
  luaunit.assertEquals(tab.count{1,2,3,4,5}, 5)
end

function TestTesting:testData()
  repl = "MAIDEN"
  have_history()

  luaunit.assertNotNil(prompts)
  luaunit.assertEquals(#prompts[repl].hist, 3)
end

-- class TestHistoryOffset
TestHistoryOffset = {}
function TestHistoryOffset:setUp()
  repl = "MAIDEN"
  have_history()
end

function TestHistoryOffset:testNotDoingAnythingShouldBeZero()
  luaunit.assertEquals(prompts[repl].offset, 0)
end

function TestHistoryOffset:testMovingBackShouldDecrementByOne()
  get_previous_input(repl)
  luaunit.assertEquals(prompts[repl].offset, 1)
end

function TestHistoryOffset:testMovingBackMultipleTimesShouldDecrementByAsMany()
  get_previous_input(repl)
  get_previous_input(repl)
  luaunit.assertEquals(prompts[repl].offset, 2)
end

function TestHistoryOffset:testMovingBackMultipleTimesShouldNotExceedHistory()
  get_previous_input(repl)
  get_previous_input(repl)
  get_previous_input(repl)
  get_previous_input(repl)
  luaunit.assertEquals(prompts[repl].offset, 3)
end

function TestHistoryOffset:testMovingForwardOnceShouldNotGetToFuture()
  get_next_input(repl)
  luaunit.assertEquals(prompts[repl].offset, 0)
end

function TestHistoryOffset:testMovingForwardMultipleTimesShouldNotGetToFuture()
  get_next_input(repl)
  get_next_input(repl)
  get_next_input(repl)
  luaunit.assertEquals(prompts[repl].offset, 0)
end

function TestHistoryOffset:testMovingBackAndForwardOnceShouldBeWhereStarted()
  local starting_offset = prompts[repl].offset
  get_previous_input(repl)
  get_next_input(repl)
  luaunit.assertEquals(prompts[repl].offset, starting_offset)
end

function TestHistoryOffset:testMovingBackTwiceAndForwardTwiceShouldBeWhereStarted()
  local starting_offset = prompts[repl].offset
  get_previous_input(repl)
  get_next_input(repl)
  get_previous_input(repl)
  get_next_input(repl)
  luaunit.assertEquals(prompts[repl].offset, starting_offset)
end

function TestHistoryOffset:testMovingBackTwiceAndForwardTwiceShouldBeWhereStarted()
  local starting_offset = prompts[repl].offset
  get_previous_input(repl)
  get_previous_input(repl)
  get_next_input(repl)
  get_next_input(repl)
  luaunit.assertEquals(prompts[repl].offset, starting_offset)
end

function TestHistoryOffset:testMovingBackToBeginningOfHistoryThenForwardShouldGetToNewest()
  get_previous_input(repl)
  get_previous_input(repl)
  get_previous_input(repl)
  get_next_input(repl)
  get_next_input(repl)
  get_next_input(repl)
  luaunit.assertEquals(prompts[repl].offset, 0)
end

function TestHistoryOffset:testMovingBackBeyondHistoryThenForwardShouldGetToNewest()
  local starting_offset = prompts[repl].offset
  get_previous_input(repl)
  get_previous_input(repl)
  get_previous_input(repl)
  get_previous_input(repl)
  get_previous_input(repl)
  get_previous_input(repl)
  get_next_input(repl)
  get_next_input(repl)
  get_next_input(repl)
  luaunit.assertEquals(prompts[repl].offset, starting_offset)
end
-- end of class TestHistoryOffset

-- class TestInputHistoryBackward
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
  luaunit.assertEquals(get_previous_input(repl), "latest command")
  luaunit.assertEquals(get_previous_input(repl), "old command")
  luaunit.assertEquals(get_next_input(repl), "latest command")
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
