local FeedbackLogic = require(game.ReplicatedStorage.Shared.FeedbackLogic)

local function tablesMatch(actual, expected)
	for i = 1, 4 do
		if actual[i] ~= expected[i] then
			return false
		end
	end

	return true
end

local function printResult(testName, passed)
	if passed then
		print("PASS: " .. testName)
	else
		print("FAIL: " .. testName)
	end
end

local function testExactMatches(testName, secret, guess, expected)
	local actual = FeedbackLogic.getExactMatches(secret, guess)
	printResult(testName, tablesMatch(actual, expected))
end

testExactMatches("getExactMatches all 4 correct", "2209", "2209", {
	[1] = "2",
	[2] = "2",
	[3] = "0",
	[4] = "9",
})

testExactMatches("getExactMatches none correct", "2209", "3310", {})

testExactMatches("getExactMatches one correct", "4554", "1234", {
	[4] = "4",
})

testExactMatches("getExactMatches repeated digit in guess", "0339", "1133", {
	[3] = "3",
})

testExactMatches("getExactMatches leading zero", "0574", "0123", {
	[1] = "0",
})

printResult("isSolved full locked table", FeedbackLogic.isSolved({
	[1] = "2",
	[2] = "2",
	[3] = "0",
	[4] = "9",
}) == true)

printResult("isSolved partial locked table", FeedbackLogic.isSolved({
	[1] = "2",
	[4] = "9",
}) == false)

local merged = FeedbackLogic.mergeLocked({
	[1] = "2",
	[3] = "0",
}, {
	[2] = "2",
	[4] = "9",
})

printResult("mergeLocked partial tables", tablesMatch(merged, {
	[1] = "2",
	[2] = "2",
	[3] = "0",
	[4] = "9",
}))
